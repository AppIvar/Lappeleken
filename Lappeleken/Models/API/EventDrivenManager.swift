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
    
    // Track active games and their monitoring
    private var activeGames: [UUID: GameEventMonitor] = [:]
    
    private init() {
        print("🎯 EventDrivenManager initialized")
    }
    
    func startMonitoring(for gameSession: GameSession) {
        guard gameSession.isLiveMode,
              let selectedMatch = gameSession.selectedMatch else {
            print("⚠️ Cannot start monitoring: not in live mode or no match selected")
            return
        }
        
        print("🎯 Starting event monitoring for game \(gameSession.id)")
        
        // Stop any existing monitoring for this game
        stopMonitoring(for: gameSession)
        
        // Create and start a new monitor
        let monitor = GameEventMonitor(
            gameSession: gameSession,
            match: selectedMatch,
            onUpdate: { [weak self] update in
                Task { @MainActor in
                    self?.processEventUpdate(update, for: gameSession)
                }
            }
        )
        
        activeGames[gameSession.id] = monitor
        monitor.start()
        
        print("✅ Event monitoring started for game \(gameSession.id)")
        
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
        print("📡 Processing event update: \(update.newEvents.count) new events")
        
        // Convert live events to game events and add them
        for liveEvent in update.newEvents {
            if let gameEvent = convertToGameEvent(liveEvent, in: gameSession) {
                gameSession.recordEvent(player: gameEvent.player, eventType: gameEvent.eventType)
                print("✅ Recorded event: \(gameEvent.eventType) for \(gameEvent.player.name)")
            }
        }
        
        // Update match status if changed
        if update.statusChanged {
            gameSession.selectedMatch = update.match
        }
        
        gameSession.objectWillChange.send()
    }
    
    private func convertToGameEvent(_ liveEvent: LiveMatchEvent, in gameSession: GameSession) -> (player: Player, eventType: Bet.EventType)? {
        // Find if the event player is in our selected players
        guard let eventPlayer = liveEvent.player,
              let ourPlayer = gameSession.selectedPlayers.first(where: { $0.id == eventPlayer.id }) else {
            return nil
        }
        
        // Convert event type
        let betEventType = convertToBetEventType(liveEvent.type)
        
        return (player: ourPlayer, eventType: betEventType)
    }
    
    private func convertToBetEventType(_ liveEventType: LiveMatchEvent.LiveEventType) -> Bet.EventType {
        switch liveEventType {
        case .goal:
            return .goal
        case .assist:
            return .assist
        case .yellowCard:
            return .yellowCard
        case .redCard:
            return .redCard
        case .ownGoal:
            return .ownGoal
        case .penaltyMissed:
            return .penaltyMissed
        default:
            return .goal // Default fallback
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
    private let onUpdate: (LiveMatchUpdate) -> Void
    
    private var monitoringTask: Task<Void, Never>?
    private var lastEventTime: Date?
    private var pollCount = 0
    
    init(gameSession: GameSession, match: Match, onUpdate: @escaping (LiveMatchUpdate) -> Void) {
        self.gameSession = gameSession
        self.match = match
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
            // Check rate limit
            guard APIRateLimiter.shared.canMakeCall() else {
                let waitTime = APIRateLimiter.shared.timeUntilNextCall()
                print("⏳ Rate limited, waiting \(waitTime)s")
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                return
            }
            
            // For now, let's create a simple mock event occasionally
            // In a real implementation, this would call your actual API
            let newEvents = await generateMockEvents()
            
            if !newEvents.isEmpty {
                let update = LiveMatchUpdate(
                    match: match,
                    newEvents: newEvents,
                    statusChanged: false
                )
                
                onUpdate(update)
                lastEventTime = Date()
            }
            
            // Smart polling interval - longer gaps between checks
            let interval = calculatePollingInterval()
            print("⏰ Poll \(pollCount): waiting \(interval)s until next check")
            
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            
        } catch {
            print("❌ Error in monitoring cycle: \(error)")
            
            // Backoff on errors
            try? await Task.sleep(nanoseconds: 300_000_000_000) // 5 minutes
        }
    }
    
    private func generateMockEvents() async -> [LiveMatchEvent] {
        // Generate a mock event occasionally for testing
        // Remove this when you implement real API calls
        
        guard pollCount % 3 == 0,
              !gameSession.selectedPlayers.isEmpty else {
            return []
        }
        
        let randomPlayer = gameSession.selectedPlayers.randomElement()!
        
        let mockEvent = LiveMatchEvent(
            id: "mock_\(UUID().uuidString)",
            type: [.goal, .yellowCard, .assist].randomElement()!,
            minute: Int.random(in: 1...90),
            player: randomPlayer,
            team: randomPlayer.team,
            timestamp: Date(),
            description: "Mock event for testing"
        )
        
        print("🧪 Generated mock event: \(mockEvent.type.rawValue) for \(randomPlayer.name)")
        return [mockEvent]
    }
    
    private func calculatePollingInterval() -> TimeInterval {
        // Much longer intervals to reduce API usage
        // Adjust these based on your needs
        
        if pollCount < 5 {
            return 30
        } else if pollCount < 10 {
            return 60
        } else {
            return 120
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
            id: UUID(), // Use UUID instead of String
            name: "Manchester United",
            shortName: "MUN",
            logoName: "manchester_united", // Provide a string instead of nil
            primaryColor: "#FF0000"
        )
        
        let awayTeam1 = Team(
            id: UUID(), // Use UUID instead of String
            name: "Liverpool",
            shortName: "LIV",
            logoName: "liverpool", // Provide a string instead of nil
            primaryColor: "#C8102E"
        )
        
        let homeTeam2 = Team(
            id: UUID(), // Use UUID instead of String
            name: "Barcelona",
            shortName: "BAR",
            logoName: "barcelona", // Provide a string instead of nil
            primaryColor: "#A50044"
        )
        
        let awayTeam2 = Team(
            id: UUID(), // Use UUID instead of String
            name: "Real Madrid",
            shortName: "RMA",
            logoName: "real_madrid", // Provide a string instead of nil
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
