//
//  EventDrivenManager.swift
//  Lucky Football Slip
//
//  Simplified event-driven system with clean API integration
//

import Foundation

// MARK: - Live Match Event

struct LiveMatchEvent {
    let id: String
    let type: LiveEventType
    let minute: Int
    let player: Player?
    let team: Team
    let timestamp: Date
    let description: String
    let substitutePlayer: Player?
    
    enum LiveEventType: String, CaseIterable {
        case goal = "GOAL"
        case assist = "ASSIST"
        case yellowCard = "YELLOW_CARD"
        case redCard = "RED_CARD"
        case substitution = "SUBSTITUTION"
        case penaltyMissed = "PENALTY_MISSED"
        case ownGoal = "OWN_GOAL"
        case penalty = "PENALTY"
        case kickoff = "KICKOFF"        // Add this
        case fulltime = "FULLTIME"      // Add this
        case unknown = "UNKNOWN"
    }
}

struct LiveMatchUpdate {
    let match: Match
    let newEvents: [LiveMatchEvent]
    let statusChanged: Bool
    let timestamp: Date
    
    init(match: Match, newEvents: [LiveMatchEvent], statusChanged: Bool = false) {
        self.match = match
        self.newEvents = newEvents
        self.statusChanged = statusChanged
        self.timestamp = Date()
    }
}

// MARK: - Event-Driven Manager

@MainActor
class EventDrivenManager: ObservableObject {
    static let shared = EventDrivenManager()
    
    private var activeGames: [String: GameEventMonitor] = [:]
    private let footballService: FootballDataMatchService
    
    private init() {
        self.footballService = ServiceProvider.shared.getMatchService() as! FootballDataMatchService
        print("🎯 EventDrivenManager initialized")
    }
    
    func startMonitoring(for gameSession: GameSession) {
        guard gameSession.isLiveMode else {
            print("⚠️ Cannot start monitoring: not in live mode")
            return
        }
        
        print("🎯 Starting event monitoring for game \(gameSession.id)")
        
        // Stop any existing monitoring for this game session first
        stopMonitoring(for: gameSession)
        
        // Start monitoring for ALL selected matches
        for match in gameSession.selectedMatches {
            let monitorKey = "\(gameSession.id.uuidString)_\(match.id)"
            
            let monitor = GameEventMonitor(
                gameSession: gameSession,
                match: match,
                footballService: footballService,
                onUpdate: { [weak self] update in
                    Task { @MainActor in
                        self?.processEventUpdate(update, for: gameSession)
                    }
                }
            )
            
            activeGames[monitorKey] = monitor
            monitor.start()
            
            print("✅ Event monitoring started for match \(match.homeTeam.shortName) vs \(match.awayTeam.shortName)")
        }
    }
    
    func stopMonitoring(for gameSession: GameSession) {
        // Stop all monitors for this game session
        let keysToRemove = activeGames.keys.filter { $0.starts(with: gameSession.id.uuidString) }
        
        for key in keysToRemove {
            if let monitor = activeGames[key] {
                print("🛑 Stopping event monitoring for key: \(key)")
                monitor.stop()
                activeGames.removeValue(forKey: key)
            }
        }
    }
    
    private func processEventUpdate(_ update: LiveMatchUpdate, for gameSession: GameSession) {
        print("📡 Processing event update: \(update.newEvents.count) new events")
        
        for liveEvent in update.newEvents {
            // Handle substitutions separately
            if liveEvent.type == .substitution {
                // We need to get both player IDs from the original MatchEvent
                // This requires passing more data through the LiveMatchEvent
                print("🔄 Substitution detected - should be handled in GameSession")
                continue
            }
            
            if let gameEvent = convertToGameEvent(liveEvent, in: gameSession) {
                gameSession.recordEvent(player: gameEvent.player, eventType: gameEvent.eventType)
                print("✅ Recorded event: \(gameEvent.eventType) for \(gameEvent.player.name)")
                
                showMissedEventNotification(liveEvent, in: gameSession)
            }
        }
        
        if update.statusChanged {
            gameSession.selectedMatch = update.match
        }
        
        gameSession.objectWillChange.send()
    }
    private func showMissedEventNotification(_ event: LiveMatchEvent, in gameSession: GameSession) {
        let matchName = "\(gameSession.selectedMatch?.homeTeam.shortName ?? "HOME") vs \(gameSession.selectedMatch?.awayTeam.shortName ?? "AWAY")"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: Notification.Name("MissedEventsFound"),
                object: nil,
                userInfo: [
                    "eventCount": 1,
                    "matchName": matchName,
                    "eventType": event.type.rawValue,
                    "playerName": event.player?.name ?? "Unknown"
                ]
            )
        }
    }
    
    private func convertToGameEvent(_ liveEvent: LiveMatchEvent, in gameSession: GameSession) -> (player: Player, eventType: Bet.EventType)? {
        // Handle substitutions separately - don't convert them to bet events
        if liveEvent.type == .substitution {
            // Process the substitution in GameSession instead
            if let playerOff = liveEvent.player {
                // This should call handleSubstitution in GameSession
                // But we need the substitute player info, which might not be in liveEvent.player
                print("🔄 Substitution detected but needs separate handling in GameSession")
            }
            return nil // Don't create a bet event for substitutions
        }
        
        guard let eventPlayer = liveEvent.player,
              let ourPlayer = gameSession.selectedPlayers.first(where: { $0.id == eventPlayer.id }) else {
            return nil
        }
        
        let betEventType = convertToBetEventType(liveEvent.type)
        return (player: ourPlayer, eventType: betEventType)
    }
    
    private func convertToBetEventType(_ liveEventType: LiveMatchEvent.LiveEventType) -> Bet.EventType {
        switch liveEventType {
        case .goal: return .goal
        case .assist: return .assist
        case .yellowCard: return .yellowCard
        case .redCard: return .redCard
        case .ownGoal: return .ownGoal
        case .penaltyMissed: return .penaltyMissed
        case .penalty: return .penalty
        default: return .goal
        }
    }
    
    func getActiveGamesCount() -> Int {
        return activeGames.count
    }
    
    func getAllStats() -> String {
        return """
        Event-Driven Manager Stats:
        - Active Games: \(activeGames.count)
        - Game IDs: \(activeGames.keys.map { String($0.prefix(8)) }.joined(separator: ", "))
        - Monitoring: \(activeGames.values.map { "Match \(String($0.match.id.prefix(8)))" }.joined(separator: ", "))
        """
    }
}

// MARK: - Game Event Monitor

class GameEventMonitor {
    private let gameSession: GameSession
    internal let match: Match
    private let footballService: FootballDataMatchService
    private let onUpdate: (LiveMatchUpdate) -> Void
    
    private var monitoringTask: Task<Void, Never>?
    private var lastEventTime: Date?
    private var pollCount = 0
    private var previousEventIds: Set<String> = []
    
    init(gameSession: GameSession, match: Match, footballService: FootballDataMatchService, onUpdate: @escaping (LiveMatchUpdate) -> Void) {
        self.gameSession = gameSession
        self.match = match
        self.footballService = footballService
        self.onUpdate = onUpdate
    }
    
    func start() {
        print("▶️ Starting monitor for match \(match.id)")
        
        monitoringTask = Task {
            while !Task.isCancelled {
                await performMonitoringCycle()
            }
        }
    }
    
    func stop() {
        print("⏹️ Stopping monitor for match \(match.id)")
        monitoringTask?.cancel()
    }
    
    private func performMonitoringCycle() async {
        pollCount += 1
        
        do {
            guard APIRateLimiter.shared.canMakeCall() else {
                let waitTime = APIRateLimiter.shared.timeUntilNextCall()
                print("⏳ Rate limited, waiting \(waitTime)s")
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                return
            }
            
            let matchEvents = await fetchMatchEvents()
            let newEvents = filterNewEvents(matchEvents)
            
            if !newEvents.isEmpty {
                let update = LiveMatchUpdate(
                    match: match,
                    newEvents: newEvents,
                    statusChanged: false
                )
                
                onUpdate(update)
                lastEventTime = Date()
            }
            
            let interval = calculatePollingInterval()
            print("⏰ Poll \(pollCount): waiting \(interval)s until next check")
            
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            
        } catch {
            print("❌ Error in monitoring cycle: \(error)")
            try? await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
        }
    }
    
    private func fetchMatchEvents() async -> [LiveMatchEvent] {
        do {
            let apiEvents = try await footballService.fetchMatchEvents(matchId: match.id)
            return apiEvents.compactMap { convertAPIEventToLiveEvent($0) }
        } catch {
            print("⚠️ Real API failed, using demo events: \(error)")
            return []
        }
    }
    
    private func convertAPIEventToLiveEvent(_ apiEvent: MatchEvent) -> LiveMatchEvent? {
        if apiEvent.type.lowercased() == "substitution" {
            // For substitutions, we need both players
            guard let playerOff = findPlayerForEvent(apiEvent),
                  let playerOnId = apiEvent.playerOnId,
                  let playerOn = gameSession.selectedPlayers.first(where: { $0.apiId == playerOnId }) else {
                return nil
            }
            
            return LiveMatchEvent(
                id: apiEvent.id,
                type: .substitution,
                minute: apiEvent.minute,
                player: playerOff,  // Player going OFF
                team: playerOff.team,
                timestamp: Date(),
                description: "Substitution: \(playerOff.name) OFF → \(playerOn.name) ON",
                substitutePlayer: playerOn  // Player coming ON
            )
        }
        
        // Handle regular events...
        guard let player = findPlayerForEvent(apiEvent) else {
            return nil
        }
        
        let eventType = mapAPIEventTypeToLive(apiEvent.type)
        
        return LiveMatchEvent(
            id: apiEvent.id,
            type: eventType,
            minute: apiEvent.minute,
            player: player,
            team: player.team,
            timestamp: Date(),
            description: "\(player.name) - \(eventType.rawValue)",
            substitutePlayer: nil
        )
    }
    
    private func findPlayerForEvent(_ apiEvent: MatchEvent) -> Player? {
        return gameSession.selectedPlayers.first { player in
            player.apiId == apiEvent.playerId ||
            player.name.lowercased() == (apiEvent.playerName ?? "").lowercased()
        }
    }
    
    private func mapAPIEventTypeToLive(_ apiType: String) -> LiveMatchEvent.LiveEventType {
        switch apiType.uppercased() {
        case "REGULAR", "PENALTY", "OWN": return .goal
        case "ASSIST": return .assist // Custom type we create from goal assist data
        case "YELLOW": return .yellowCard
        case "RED": return .redCard
        case "SUBSTITUTION": return .substitution
        default: return .unknown
        }
    }
    
    private func filterNewEvents(_ events: [LiveMatchEvent]) -> [LiveMatchEvent] {
        let newEvents = events.filter { !previousEventIds.contains($0.id) }
        
        for event in newEvents {
            previousEventIds.insert(event.id)
        }
        
        return newEvents
    }
    
    
    private func calculatePollingInterval() -> TimeInterval {
        switch match.status {
        case .inProgress, .halftime:
            return 15
        case .upcoming:
            let timeUntilStart = match.startTime.timeIntervalSinceNow
            return timeUntilStart < 300 ? 30 : 120
        case .completed, .finished:
            return 300
        case .postponed, .cancelled:
            return 600
        case .paused, .suspended:
            return 60
        case .unknown:
            return 120
        }
    }
}
