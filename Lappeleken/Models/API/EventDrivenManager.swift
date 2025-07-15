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
    
    private var activeGames: [UUID: GameEventMonitor] = [:]
    private let footballService: FootballDataMatchService
    
    private init() {
        self.footballService = ServiceProvider.shared.getMatchService() as! FootballDataMatchService
        print("🎯 EventDrivenManager initialized")
    }
    
    func startMonitoring(for gameSession: GameSession) {
        guard gameSession.isLiveMode,
              let selectedMatch = gameSession.selectedMatch else {
            print("⚠️ Cannot start monitoring: not in live mode or no match selected")
            return
        }
        
        print("🎯 Starting event monitoring for game \(gameSession.id)")
        
        stopMonitoring(for: gameSession)
        
        let monitor = GameEventMonitor(
            gameSession: gameSession,
            match: selectedMatch,
            footballService: footballService,
            onUpdate: { [weak self] update in
                Task { @MainActor in
                    self?.processEventUpdate(update, for: gameSession)
                }
            }
        )
        
        activeGames[gameSession.id] = monitor
        monitor.start()
        
        print("✅ Event monitoring started for game \(gameSession.id)")
    }
    
    func stopMonitoring(for gameSession: GameSession) {
        guard let monitor = activeGames[gameSession.id] else { return }
        
        print("🛑 Stopping event monitoring for game \(gameSession.id)")
        monitor.stop()
        activeGames.removeValue(forKey: gameSession.id)
    }
    
    private func processEventUpdate(_ update: LiveMatchUpdate, for gameSession: GameSession) {
        print("📡 Processing event update: \(update.newEvents.count) new events")
        
        for liveEvent in update.newEvents {
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
        - Game IDs: \(activeGames.keys.map { $0.uuidString.prefix(8) }.joined(separator: ", "))
        """
    }
}

// MARK: - Game Event Monitor

class GameEventMonitor {
    private let gameSession: GameSession
    private let match: Match
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
            return generateDemoEvents()
        }
    }
    
    private func convertAPIEventToLiveEvent(_ apiEvent: MatchEvent) -> LiveMatchEvent? {
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
            description: "\(player.name) - \(eventType.rawValue)"
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
    
    private func generateDemoEvents() -> [LiveMatchEvent] {
        guard pollCount % 5 == 0,
              !gameSession.selectedPlayers.isEmpty,
              Int.random(in: 1...10) <= 3 else {
            return []
        }
        
        let randomPlayer = gameSession.selectedPlayers.randomElement()!
        let eventTypes: [LiveMatchEvent.LiveEventType] = [.goal, .yellowCard, .assist, .redCard]
        let randomEventType = eventTypes.randomElement()!
        
        let demoEvent = LiveMatchEvent(
            id: "demo_\(UUID().uuidString.prefix(8))",
            type: randomEventType,
            minute: Int.random(in: 1...90),
            player: randomPlayer,
            team: randomPlayer.team,
            timestamp: Date(),
            description: "Demo: \(randomPlayer.name) - \(randomEventType.rawValue)"
        )
        
        print("🧪 Generated demo event: \(randomEventType.rawValue) for \(randomPlayer.name)")
        return [demoEvent]
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
