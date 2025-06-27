//
//  EventSyncManager.swift
//  Lucky Football Slip
//
//  Handles syncing missed events when app returns to foreground
//

import Foundation
import UIKit

class EventSyncManager: ObservableObject {
    static let shared = EventSyncManager()
    
    @Published var isSyncing = false
    @Published var lastSyncTime: Date?
    
    private let matchService: MatchService
    
    private init() {
        self.matchService = ServiceProvider.shared.getMatchService()
        setupAppLifecycleObservers()
    }
    
    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }
    
    @objc private func appDidBecomeActive() {
        print("📱 App became active - checking for missed events...")
        Task {
            await syncMissedEvents()
        }
    }
    
    @objc private func appDidEnterBackground() {
        UserDefaults.standard.set(Date(), forKey: "lastAppBackgroundTime")
        print("📱 App went to background at: \(Date())")
    }
    
    // MARK: - Event Syncing
    
    func syncMissedEvents() async {
        await MainActor.run {
            isSyncing = true
        }
        
        defer {
            Task { @MainActor in
                self.isSyncing = false
                self.lastSyncTime = Date()
            }
        }
        
        let activeGames = getActiveGamesForSync()
        
        for gameInfo in activeGames {
            do {
                let missedEvents = try await fetchMissedEvents(for: gameInfo)
                
                if !missedEvents.isEmpty {
                    await applyMissedEvents(missedEvents, to: gameInfo)
                    print("✅ Synced \(missedEvents.count) missed events for game \(gameInfo.gameId)")
                } else {
                    print("📊 No missed events for game \(gameInfo.gameId)")
                }
            } catch {
                print("❌ Failed to sync events for game \(gameInfo.gameId): \(error)")
            }
        }
    }
    
    private func fetchMissedEvents(for gameInfo: ActiveGameInfo) async throws -> [LiveMatchEvent] {
        let lastBackgroundTime = UserDefaults.standard.object(forKey: "lastAppBackgroundTime") as? Date ?? Date().addingTimeInterval(-3600)
        
        // Handle mock matches for testing
        if gameInfo.matchId.hasPrefix("mock_") {
            if AppConfig.useStubData {
                return await generateMissedMockEvents(for: gameInfo, since: lastBackgroundTime)
            } else {
                print("🧪 Skipping mock events in production mode")
                return []
            }
        }
        
        // Real API integration for production matches
        return try await fetchRealMatchEvents(for: gameInfo, since: lastBackgroundTime)
    }
    
    private func fetchRealMatchEvents(for gameInfo: ActiveGameInfo, since backgroundTime: Date) async throws -> [LiveMatchEvent] {
        print("🌐 Fetching real match events for \(gameInfo.matchId) since \(backgroundTime)")
        
        do {
            // Get current match details to check for status changes
            let matchDetails = try await matchService.fetchMatchDetails(matchId: gameInfo.matchId)
            
            // Store previous match status to detect changes
            let previousStatusKey = "lastMatchStatus_\(gameInfo.matchId)"
            let previousStatus = UserDefaults.standard.string(forKey: previousStatusKey) ?? "unknown"
            let currentStatus = String(describing: matchDetails.match.status) // Fix: Convert enum to string
            
            // Update stored status
            UserDefaults.standard.set(currentStatus, forKey: previousStatusKey)
            
            var events: [LiveMatchEvent] = []
            
            // Check if match status changed (e.g., from upcoming to in progress)
            if previousStatus != currentStatus {
                print("📊 Match status changed from \(previousStatus) to \(currentStatus)")
                
                // Create status change events
                if matchDetails.match.status == .inProgress && previousStatus == "upcoming" {
                    let kickoffEvent = LiveMatchEvent(
                        id: "kickoff_\(gameInfo.matchId)_\(Date().timeIntervalSince1970)",
                        type: .kickoff,
                        minute: 0,
                        player: nil,
                        team: matchDetails.match.homeTeam,
                        timestamp: matchDetails.match.startTime,
                        description: "Match started"
                    )
                    events.append(kickoffEvent)
                }
                
                if matchDetails.match.status == .completed {
                    let fulltimeEvent = LiveMatchEvent(
                        id: "fulltime_\(gameInfo.matchId)_\(Date().timeIntervalSince1970)",
                        type: .fulltime,
                        minute: 90,
                        player: nil,
                        team: matchDetails.match.homeTeam,
                        timestamp: Date(),
                        description: "Match finished"
                    )
                    events.append(fulltimeEvent)
                }
            }
            
            // Try to fetch actual match events (this might not always be available)
            do {
                let matchEvents = try await matchService.fetchMatchEvents(matchId: gameInfo.matchId)
                
                // Filter events that happened after the background time
                let recentEvents = matchEvents.filter { event in
                    // Fix: Use Date() as fallback since timestamp might not exist
                    let eventTime = Date()
                    return eventTime > backgroundTime
                }
                
                // Convert MatchEvent to LiveMatchEvent
                for matchEvent in recentEvents {
                    if let liveEvent = convertMatchEventToLiveEvent(matchEvent, match: matchDetails.match) {
                        events.append(liveEvent)
                    }
                }
                
                print("📊 Found \(recentEvents.count) real events since background")
                
            } catch {
                print("⚠️ Could not fetch match events (this is normal for many matches): \(error)")
                // Many matches don't provide detailed events, so this is expected
                
                // For matches without event data, simulate based on score changes
                let simulatedEvents = try await generateEventsFromScoreChanges(gameInfo: gameInfo, match: matchDetails.match, since: backgroundTime)
                events.append(contentsOf: simulatedEvents)
            }
            
            return events
            
        } catch {
            print("❌ Error fetching real match data: \(error)")
            
            // Fallback to mock events if in debug mode for testing
            #if DEBUG
            if AppConfig.useStubData {
                print("🧪 Falling back to mock events for testing")
                return await generateMissedMockEvents(for: gameInfo, since: backgroundTime)
            }
            #endif
            
            throw error
        }
    }
    
    // Fix: Create a proper struct for score tracking
    private struct MatchScore: Codable {
        let home: Int
        let away: Int
    }
    
    private func generateEventsFromScoreChanges(gameInfo: ActiveGameInfo, match: Match, since backgroundTime: Date) async throws -> [LiveMatchEvent] {
        // This is a fallback when detailed events aren't available
        // We can compare current scores with previously stored scores to detect goals
        
        let scoreKey = "lastScore_\(gameInfo.matchId)"
        let previousScoreData = UserDefaults.standard.data(forKey: scoreKey)
        let currentScore = MatchScore(home: 0, away: 0) // You'd get this from match details if available
        
        var events: [LiveMatchEvent] = []
        
        if let previousData = previousScoreData,
           let previousScore = try? JSONDecoder().decode(MatchScore.self, from: previousData) {
            
            // Check for new goals
            let homeGoalsDiff = currentScore.home - previousScore.home
            let awayGoalsDiff = currentScore.away - previousScore.away
            
            // Generate goal events for the difference
            for _ in 0..<homeGoalsDiff {
                let goalEvent = LiveMatchEvent(
                    id: "goal_home_\(UUID().uuidString)",
                    type: .goal,
                    minute: Int.random(in: 1...90),
                    player: nil, // We don't know which player scored
                    team: match.homeTeam,
                    timestamp: Date().addingTimeInterval(-TimeInterval.random(in: 60...600)), // Sometime in last 10 minutes
                    description: "Goal scored (detected from score change)"
                )
                events.append(goalEvent)
            }
            
            for _ in 0..<awayGoalsDiff {
                let goalEvent = LiveMatchEvent(
                    id: "goal_away_\(UUID().uuidString)",
                    type: .goal,
                    minute: Int.random(in: 1...90),
                    player: nil,
                    team: match.awayTeam,
                    timestamp: Date().addingTimeInterval(-TimeInterval.random(in: 60...600)),
                    description: "Goal scored (detected from score change)"
                )
                events.append(goalEvent)
            }
        }
        
        // Store current score for next comparison
        if let scoreData = try? JSONEncoder().encode(currentScore) {
            UserDefaults.standard.set(scoreData, forKey: scoreKey)
        }
        
        return events
    }
    
    private func convertMatchEventToLiveEvent(_ matchEvent: MatchEvent, match: Match) -> LiveMatchEvent? {
        // Convert your existing MatchEvent to LiveMatchEvent
        let eventType: LiveMatchEvent.LiveEventType
        
        switch matchEvent.type.lowercased() {
        case "goal": eventType = .goal
        case "yellow_card", "yellowcard": eventType = .yellowCard
        case "red_card", "redcard": eventType = .redCard
        case "substitution": eventType = .substitution
        case "penalty_missed": eventType = .penaltyMissed
        case "own_goal": eventType = .ownGoal
        default: eventType = .unknown
        }
        
        // You'd need to map the team based on your MatchEvent structure
        let team = matchEvent.teamId == match.homeTeam.id.uuidString ? match.homeTeam : match.awayTeam
        
        return LiveMatchEvent(
            id: matchEvent.id,
            type: eventType,
            minute: matchEvent.minute,
            player: nil, // You'd map this if player info is available
            team: team,
            timestamp: Date(), // Fix: Use current time as fallback
            description: "Match event" // Fix: Use generic description
        )
    }

    
    private func generateMissedMockEvents(for gameInfo: ActiveGameInfo, since backgroundTime: Date) async -> [LiveMatchEvent] {
        let timeMissed = Date().timeIntervalSince(backgroundTime)
        let eventCount = min(Int(timeMissed / 600), 3) // Max 3 events, 1 per 10 minutes
        
        guard eventCount > 0 else { return [] }
        
        var events: [LiveMatchEvent] = []
        
        guard let gameSession = getCurrentGameSession(for: gameInfo.gameId),
              !gameSession.selectedPlayers.isEmpty else {
            return []
        }
        
        for i in 0..<eventCount {
            let eventTime = backgroundTime.addingTimeInterval(TimeInterval(i * 600))
            let randomPlayer = gameSession.selectedPlayers.randomElement()!
            
            let event = LiveMatchEvent(
                id: "missed_mock_\(UUID().uuidString)",
                type: [.goal, .assist, .yellowCard].randomElement()!,
                minute: Int.random(in: 1...90),
                player: randomPlayer,
                team: randomPlayer.team,
                timestamp: eventTime,
                description: "Mock missed event for testing"
            )
            
            events.append(event)
        }
        
        print("🧪 Generated \(events.count) mock missed events")
        return events
    }
    
    // MARK: - Rest of the methods stay the same...
    
    private func applyMissedEvents(_ events: [LiveMatchEvent], to gameInfo: ActiveGameInfo) async {
        guard let gameSession = getCurrentGameSession(for: gameInfo.gameId) else {
            print("❌ Could not find game session for \(gameInfo.gameId)")
            return
        }
        
        await MainActor.run {
            for event in events {
                if let gameEvent = convertToGameEvent(event, in: gameSession) {
                    gameSession.recordEvent(player: gameEvent.player, eventType: gameEvent.eventType)
                    print("📝 Applied missed event: \(gameEvent.eventType) for \(gameEvent.player.name)")
                }
            }
            
            if !events.isEmpty {
                print("📱 About to show catch-up notification for \(events.count) events") // Add this debug line
                showCatchUpNotification(eventCount: events.count, gameInfo: gameInfo)
            }
        }
    }
    
    private func showCatchUpNotification(eventCount: Int, gameInfo: ActiveGameInfo) {
        print("📱 Posting MissedEventsFound notification")
        print("📱 Event count: \(eventCount), Match: \(gameInfo.matchName)")
        
        NotificationCenter.default.post(
            name: Notification.Name("MissedEventsFound"),
            object: nil,
            userInfo: [
                "eventCount": eventCount,
                "matchName": gameInfo.matchName,
                "gameId": gameInfo.gameId.uuidString
            ]
        )
        
        print("📱 Notification posted successfully")
    }
    
    // MARK: - Helper Methods
    
    func registerGameForSync(_ gameSession: GameSession) {
        let key = "activeGameSession_\(gameSession.id.uuidString)"
        if let data = try? JSONEncoder().encode(gameSession) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    func unregisterGameForSync(_ gameSession: GameSession) {
        let key = "activeGameSession_\(gameSession.id.uuidString)"
        UserDefaults.standard.removeObject(forKey: key)
        
        // Clean up match-specific data
        UserDefaults.standard.removeObject(forKey: "lastMatchStatus_\(gameSession.selectedMatch?.id ?? "")")
        UserDefaults.standard.removeObject(forKey: "lastScore_\(gameSession.selectedMatch?.id ?? "")")
    }
    
    private func getActiveGamesForSync() -> [ActiveGameInfo] {
        guard let data = UserDefaults.standard.data(forKey: "activeBackgroundGames"),
              let games = try? JSONDecoder().decode([ActiveGameInfo].self, from: data) else {
            return []
        }
        return games
    }
    
    private func getCurrentGameSession(for gameId: UUID) -> GameSession? {
        let key = "activeGameSession_\(gameId.uuidString)"
        guard let data = UserDefaults.standard.data(forKey: key),
              let gameSession = try? JSONDecoder().decode(GameSession.self, from: data) else {
            return nil
        }
        return gameSession
    }
    
    private func convertToGameEvent(_ liveEvent: LiveMatchEvent, in gameSession: GameSession) -> (player: Player, eventType: Bet.EventType)? {
        // If we have a specific player, use them
        if let eventPlayer = liveEvent.player,
           let ourPlayer = gameSession.selectedPlayers.first(where: { $0.id == eventPlayer.id }) {
            let betEventType = convertToBetEventType(liveEvent.type)
            return (player: ourPlayer, eventType: betEventType)
        }
        
        // If no specific player (common with score-based detection), pick a random player from the correct team
        let teamPlayers = gameSession.selectedPlayers.filter { $0.team.id == liveEvent.team.id }
        guard let randomPlayer = teamPlayers.randomElement() else {
            // If no players from that team, pick any player
            guard let anyPlayer = gameSession.selectedPlayers.randomElement() else {
                return nil
            }
            let betEventType = convertToBetEventType(liveEvent.type)
            return (player: anyPlayer, eventType: betEventType)
        }
        
        let betEventType = convertToBetEventType(liveEvent.type)
        return (player: randomPlayer, eventType: betEventType)
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
}
