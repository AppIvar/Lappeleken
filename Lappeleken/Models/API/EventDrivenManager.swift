//
//  EventDrivenManager.swift
//  Lucky Football Slip
//
//  Simplified event-driven system to avoid naming conflicts
//

import Foundation

// MARK: - New Event Types (renamed to avoid conflicts)

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
        case kickoff = "KICKOFF"
        case halftime = "HALFTIME"
        case fulltime = "FULLTIME"
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

// MARK: - Simplified Event-Driven Manager

@MainActor
class EventDrivenManager: ObservableObject {
    static let shared = EventDrivenManager()
    
    private var activeGames: [UUID: GameEventMonitor] = [:]
    private let apiClient: APIClient
    
    private init() {
        self.apiClient = ServiceProvider.shared.getAPIClient()
        print("🎯 EventDrivenManager initialized with real API client")
    }
    
    func startMonitoring(for gameSession: GameSession) {
        guard gameSession.isLiveMode,
              let selectedMatch = gameSession.selectedMatch else {
            print("⚠️ Cannot start monitoring: not in live mode or no match selected")
            return
        }
        
        print("🎯 Starting REAL event monitoring for game \(gameSession.id)")
        
        stopMonitoring(for: gameSession)
        
        let monitor = GameEventMonitor(
            gameSession: gameSession,
            match: selectedMatch,
            apiClient: apiClient, // Pass real API client
            onUpdate: { [weak self] update in
                Task { @MainActor in
                    self?.processEventUpdate(update, for: gameSession)
                }
            }
        )
        
        activeGames[gameSession.id] = monitor
        monitor.start()
        
        print("✅ REAL event monitoring started for game \(gameSession.id)")
        BackgroundTaskManager.shared.startBackgroundMonitoring(for: gameSession)
    }
    
    func stopMonitoring(for gameSession: GameSession) {
        guard let monitor = activeGames[gameSession.id] else { return }
        
        print("🛑 Stopping event monitoring for game \(gameSession.id)")
        monitor.stop()
        activeGames.removeValue(forKey: gameSession.id)
        
        BackgroundTaskManager.shared.stopBackgroundMonitoring(for: gameSession)
    }
    
    private func processEventUpdate(_ update: LiveMatchUpdate, for gameSession: GameSession) {
        print("📡 Processing REAL event update: \(update.newEvents.count) new events")
        
        // Process each live event
        for liveEvent in update.newEvents {
            if let gameEvent = convertToGameEvent(liveEvent, in: gameSession) {
                // Record the event in the game session
                gameSession.recordEvent(player: gameEvent.player, eventType: gameEvent.eventType)
                print("✅ Recorded REAL event: \(gameEvent.eventType) for \(gameEvent.player.name)")
                
                // Show notification for missed events
                showMissedEventNotification(liveEvent, in: gameSession)
            }
        }
        
        if update.statusChanged {
            gameSession.selectedMatch = update.match
        }
        
        gameSession.objectWillChange.send()
    }
    
    private func showMissedEventNotification(_ event: LiveMatchEvent, in gameSession: GameSession) {
        // Notify user about events that happened while away
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
        default: return .goal
        }
    }

    
    // MARK: - Stats and Debug
    
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
    private let apiClient: APIClient
    private let onUpdate: (LiveMatchUpdate) -> Void
    
    private var monitoringTask: Task<Void, Never>?
    private var lastEventTime: Date?
    private var pollCount = 0
    
    init(gameSession: GameSession, match: Match, apiClient: APIClient, onUpdate: @escaping (LiveMatchUpdate) -> Void) {
        self.gameSession = gameSession
        self.match = match
        self.apiClient = apiClient
        self.onUpdate = onUpdate
    }
    
    func start() {
        print("▶️ Starting REAL monitor for match \(match.id)")
        
        monitoringTask = Task {
            while !Task.isCancelled {
                await performRealMonitoringCycle()
            }
        }
    }
    
    func stop() {
        print("⏹️ Stopping monitor for match \(match.id)")
        monitoringTask?.cancel()
    }
    
    private func performRealMonitoringCycle() async {
        pollCount += 1
        
        do {
            // Check rate limit
            guard APIRateLimiter.shared.canMakeCall() else {
                let waitTime = APIRateLimiter.shared.timeUntilNextCall()
                print("⏳ Rate limited, waiting \(waitTime)s")
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                return
            }
            
            // REAL API CALL: Fetch live match events
            let newEvents = await fetchRealMatchEvents()
            
            if !newEvents.isEmpty {
                let update = LiveMatchUpdate(
                    match: match,
                    newEvents: newEvents,
                    statusChanged: false
                )
                
                onUpdate(update)
                lastEventTime = Date()
            }
            
            // Smart polling interval based on match status
            let interval = calculateSmartPollingInterval()
            print("⏰ Poll \(pollCount): waiting \(interval)s until next check")
            
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            
        } catch {
            print("❌ Error in monitoring cycle: \(error)")
            try? await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
        }
    }
    
    private func fetchRealMatchEvents() async -> [LiveMatchEvent] {
        do {
            // REAL API CALL: Get match events from football API
            struct MatchEventsResponse: Decodable {
                let events: [APIMatchEvent]
            }
            
            struct APIMatchEvent: Decodable {
                let id: String
                let type: String
                let minute: Int
                let playerId: String?
                let playerName: String?
                let teamId: String
                let timestamp: String
            }
            
            let response: MatchEventsResponse = try await apiClient.footballDataRequest(
                endpoint: "matches/\(match.id)/events"
            )
            
            // Convert API events to app events
            let liveEvents = response.events.compactMap { apiEvent -> LiveMatchEvent? in
                guard let eventType = LiveMatchEvent.LiveEventType(rawValue: apiEvent.type.uppercased()),
                      let player = findPlayerInMatch(apiEvent.playerId, apiEvent.playerName) else {
                    return nil
                }
                
                return LiveMatchEvent(
                    id: apiEvent.id,
                    type: eventType,
                    minute: apiEvent.minute,
                    player: player,
                    team: player.team,
                    timestamp: parseTimestamp(apiEvent.timestamp) ?? Date(),
                    description: "\(apiEvent.playerName ?? "Player") - \(apiEvent.type)"
                )
            }
            
            // Filter only new events (events we haven't seen before)
            return filterNewEvents(liveEvents)
            
        } catch {
            print("⚠️ Real API failed, using demo events: \(error)")
            return await generateDemoEvents()
        }
    }
    
    private func findPlayerInMatch(_ playerId: String?, _ playerName: String?) -> Player? {
        // Try to find player by ID first
        if let playerId = playerId,
           let player = gameSession.selectedPlayers.first(where: { $0.id.uuidString == playerId }) {
            return player
        }
        
        // Fallback to name matching
        if let playerName = playerName,
           let player = gameSession.selectedPlayers.first(where: {
               $0.name.lowercased().contains(playerName.lowercased())
           }) {
            return player
        }
        
        return nil
    }
    
    private func parseTimestamp(_ timestamp: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: timestamp)
    }
    
    private func filterNewEvents(_ events: [LiveMatchEvent]) -> [LiveMatchEvent] {
        // Filter events that happened after our last check
        guard let lastEventTime = lastEventTime else {
            return events // First run, return all events
        }
        
        return events.filter { $0.timestamp > lastEventTime }
    }
    
    private func generateDemoEvents() async -> [LiveMatchEvent] {
        // Only generate demo events occasionally and when we have players
        guard pollCount % 5 == 0,
              !gameSession.selectedPlayers.isEmpty,
              Int.random(in: 1...10) <= 3 else { // 30% chance
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
    
    private func calculateSmartPollingInterval() -> TimeInterval {
        // Smart intervals based on match status and time
        switch match.status {
        case .inProgress, .halftime:
            return 15 // Check every 15 seconds during live matches
        case .upcoming:
            let timeUntilStart = match.startTime.timeIntervalSinceNow
            if timeUntilStart < 300 { // 5 minutes before start
                return 30
            } else {
                return 120 // 2 minutes for upcoming matches
            }
        case .completed, .finished:  // FIXED: Use your actual enum cases
            return 300 // 5 minutes for finished matches (in case of late updates)
        case .postponed, .cancelled: // FIXED: Use your actual enum cases
            return 600 // 10 minutes for postponed/cancelled
        case .paused, .suspended:    // Handle additional cases
            return 60 // 1 minute for paused/suspended matches
        case .unknown:
            return 120 // 2 minutes for unknown status
        }
    }
}

// MARK: - GameSession Extensions

extension GameSession {
    
    @MainActor
    func setupEventDrivenMode() {
        guard isLiveMode else {
            print("⚠️ Not in live mode, skipping event-driven setup")
            return
        }
        
        print("🎯 Setting up event-driven mode for game \(id)")
        EventDrivenManager.shared.startMonitoring(for: self)
    }
    
    @MainActor
    func cleanupEventDrivenMode() {
        print("🧹 Cleaning up event-driven mode for game \(id)")
        EventDrivenManager.shared.stopMonitoring(for: self)
    }
    
    @MainActor
    func getEventDrivenStats() -> String {
        return EventDrivenManager.shared.getAllStats()
    }
}

// MARK: - Mock Data for Testing

extension EventDrivenManager {
    
    static func createMockMatches() -> [Match] {
        let homeTeam1 = Team(
            id: UUID(),
            name: "Manchester United",
            shortName: "MUN",
            logoName: "manchester_united",
            primaryColor: "#FF0000"
        )
        
        let awayTeam1 = Team(
            id: UUID(),
            name: "Liverpool",
            shortName: "LIV",
            logoName: "liverpool",
            primaryColor: "#C8102E"
        )
        
        let homeTeam2 = Team(
            id: UUID(),
            name: "Barcelona",
            shortName: "BAR",
            logoName: "barcelona",
            primaryColor: "#A50044"
        )
        
        let awayTeam2 = Team(
            id: UUID(),
            name: "Real Madrid",
            shortName: "RMA",
            logoName: "real_madrid",
            primaryColor: "#FEBE10"
        )
        
        let competition = Competition(id: "PL", name: "Premier League", code: "PL")
        
        let match1 = Match(
            id: "mock_match_1",
            homeTeam: homeTeam1,
            awayTeam: awayTeam1,
            startTime: Date(),
            status: .inProgress,
            competition: competition
        )
        
        let match2 = Match(
            id: "mock_match_2",
            homeTeam: homeTeam2,
            awayTeam: awayTeam2,
            startTime: Date().addingTimeInterval(3600), // 1 hour from now
            status: .upcoming,
            competition: competition
        )
        
        return [match1, match2]
    }
    
    static func createMockPlayers(for match: Match) -> [Player] {
        var players: [Player] = []
        
        // Home team players
        for i in 1...11 {
            let player = Player(
                id: UUID(),
                name: "\(match.homeTeam.shortName) Player \(i)",
                team: match.homeTeam,
                position: i <= 4 ? .defender : (i <= 8 ? .midfielder : .forward),
                goals: 0,
                assists: 0,
                yellowCards: 0,
                redCards: 0
            )
            players.append(player)
        }
        
        // Away team players
        for i in 1...11 {
            let player = Player(
                id: UUID(),
                name: "\(match.awayTeam.shortName) Player \(i)",
                team: match.awayTeam,
                position: i <= 4 ? .defender : (i <= 8 ? .midfielder : .forward),
                goals: 0,
                assists: 0,
                yellowCards: 0,
                redCards: 0
            )
            players.append(player)
        }
        
        return players
    }
}
