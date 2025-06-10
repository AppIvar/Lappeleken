//
//  TestMonitoringBridge.swift
//  Lucky Football Slip
//
//  Bridge to connect test mode events to GameSession
//

import Foundation

#if DEBUG
class TestMonitoringBridge: ObservableObject {
    static let shared = TestMonitoringBridge()
    
    private var gameSession: GameSession?
    private var monitoringTask: Task<Void, Never>?
    
    private init() {}
    
    // Connect the bridge to a game session
    func connectToGameSession(_ gameSession: GameSession) {
        print("🌉 Connecting test bridge to GameSession")
        self.gameSession = gameSession
        
        // If test mode is active, start monitoring
        if TestConfiguration.shared.isTestMode {
            startTestMonitoring()
        }
    }
    
    // Disconnect the bridge
    func disconnect() {
        print("🌉 Disconnecting test bridge")
        monitoringTask?.cancel()
        monitoringTask = nil
        gameSession = nil
    }
    
    // Start monitoring the mock service for test events
    private func startTestMonitoring() {
        guard let mockService = TestConfiguration.shared.mockService,
              let gameSession = gameSession else {
            print("❌ Cannot start test monitoring - missing mock service or game session")
            return
        }
        
        print("🎯 Starting test monitoring bridge")
        
        // Cancel any existing monitoring
        monitoringTask?.cancel()
        
        // Start monitoring the first available match for testing
        if let firstMatch = mockService.getCurrentTestMatch() {
            print("🏟️ Test bridge monitoring match: \(firstMatch.homeTeam.name) vs \(firstMatch.awayTeam.name)")
            
            monitoringTask = mockService.startMonitoringMatch(
                matchId: firstMatch.id,
                updateInterval: 5, // Faster updates for testing
                onUpdate: { [weak self] update in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        self.processTestUpdate(update)
                    }
                }
            )
        }
    }
    
    // Process updates from the mock service
    @MainActor
    private func processTestUpdate(_ update: MatchUpdate) {
        guard let gameSession = gameSession else { return }
        
        print("🌉 Test bridge processing update with \(update.newEvents.count) events")
        
        // Update the selected match
        gameSession.selectedMatch = update.match
        
        // Process each new event
        for event in update.newEvents {
            processTestEvent(event, in: gameSession)
        }
        
        gameSession.objectWillChange.send()
    }
    
    // Convert mock events to game events
    @MainActor private func processTestEvent(_ event: MatchEvent, in gameSession: GameSession) {
        print("🎯 Processing test event: \(event.type) by \(event.playerName)")
        
        // Find the player in the game session
        guard let player = gameSession.availablePlayers.first(where: {
            $0.id.uuidString == event.playerId
        }) else {
            print("⚠️ Player not found in game session: \(event.playerName)")
            return
        }
        
        // Map event type to bet type
        guard let betType = mapEventToBetType(event.type) else {
            print("⚠️ Unknown event type: \(event.type)")
            return
        }
        
        // Record the event in the game session
        gameSession.recordEvent(player: player, eventType: betType)
        print("✅ Recorded \(betType.rawValue) for \(player.name)")
    }
    
    // Map mock event types to bet types
    private func mapEventToBetType(_ eventType: String) -> Bet.EventType? {
        switch eventType.lowercased() {
        case "goal":
            return .goal
        case "yellow_card":
            return .yellowCard
        case "red_card":
            return .redCard
        case "assist":
            return .assist
        case "penalty":
            return .penalty
        case "penalty_missed":
            return .penaltyMissed
        case "own_goal":
            return .ownGoal
        default:
            return nil
        }
    }
    
    // Manually trigger an event for testing
    func triggerTestEventManually(_ eventType: String) {
        print("🚀 Manually triggering test event: \(eventType)")
        
        guard let mockService = TestConfiguration.shared.mockService else {
            print("❌ No mock service available for manual trigger")
            return
        }
        
        // Add event directly to mock service without going through TestConfiguration
        mockService.addTestEvent(eventType)
        
        // Force an immediate update check
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.checkForNewEvents(in: mockService)
        }
    }
    
    // Check for new events manually
    private func checkForNewEvents(in mockService: MockFootballDataService) {
        // This is a workaround to force updates when test buttons are pressed
        if let currentMatch = mockService.getCurrentTestMatch() {
            Task {
                do {
                    let events = try await mockService.fetchMatchEvents(matchId: currentMatch.id)
                    
                    await MainActor.run {
                        let update = MatchUpdate(match: currentMatch, newEvents: events)
                        self.processTestUpdate(update)
                    }
                } catch {
                    print("❌ Error fetching test events: \(error)")
                }
            }
        }
    }
}

#endif
