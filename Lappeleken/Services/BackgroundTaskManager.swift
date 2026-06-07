//
//  BackgroundTaskManager.swift
//  Lucky Football Slip
//
//  Background task management for live match monitoring
//

import Foundation
import BackgroundTasks
import UserNotifications
import UIKit  

// MARK: - Event Types
enum MatchEventType: String, CaseIterable {
    case goal = "goal"
    case yellowCard = "yellow_card"
    case redCard = "red_card"
    case penalty = "penalty"
    case matchStart = "match_start"
    case halfTime = "half_time"
    case matchEnd = "match_end"
    
    var notificationTitle: String {
        switch self {
        case .goal: return "⚽ GOAL!"
        case .yellowCard: return "🟨 YELLOW CARD!"
        case .redCard: return "🟥 RED CARD!"
        case .penalty: return "🥅 PENALTY!"
        case .matchStart: return "🏁 Match Started"
        case .halfTime: return "⏸️ Half Time"
        case .matchEnd: return "🏁 Match Ended"
        }
    }
    
    var priority: Int {
        switch self {
        case .goal: return 3
        case .penalty: return 3
        case .redCard: return 2
        case .yellowCard: return 1
        case .matchStart: return 1
        case .halfTime: return 1
        case .matchEnd: return 2
        }
    }
}

class BackgroundTaskManager: ObservableObject {
    static let shared = BackgroundTaskManager()
    
    private let taskIdentifier = "com.hovlandgames.luckyfootball.matchupdate"
    
    // Track if we've already registered to prevent double registration
    private var hasRegistered = false
    
    @Published var activeBackgroundGames: [UUID] = []
    
    private init() {
        registerBackgroundTasks()
        requestNotificationPermission()
    }
    
    // MARK: - Background Task Registration
    
    func registerBackgroundTasks() {
        // Prevent double registration
        guard !hasRegistered else {
            print("⚠️ Background tasks already registered, skipping...")
            return
        }
        
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            print("🔄 Background task started: \(self.taskIdentifier)")
            self.handleMatchUpdateTask(task as! BGProcessingTask)
        }
        
        hasRegistered = true
        print("✅ Background tasks registered successfully")
    }
    
    // MARK: - Schedule Background Updates
    
    func scheduleBackgroundRefresh() {
        guard !activeBackgroundGames.isEmpty else {
            print("⏹️ No active games, skipping background schedule")
            return
        }
        
        let request = BGProcessingTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60) // 2 minutes minimum
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("✅ Background refresh scheduled for: \(request.earliestBeginDate!)")
        } catch {
            print("❌ Could not schedule background refresh: \(error)")
        }
    }
    
    // MARK: - Background Task Handler
    
    private func handleMatchUpdateTask(_ task: BGProcessingTask) {
        task.expirationHandler = {
            print("⏰ Background task expired")
            task.setTaskCompleted(success: false)
        }
        
        Task {
            await performBackgroundUpdate()
            
            // Schedule next update if still have active games
            if !activeBackgroundGames.isEmpty {
                scheduleBackgroundRefresh()
            }
            
            task.setTaskCompleted(success: true)
        }
    }
    
    private func performBackgroundUpdate() async {
        print("🔄 Performing background update for \(activeBackgroundGames.count) games")
        
        let activeGames = getActiveGamesFromStorage()
        var eventsFound = 0
        
        for gameInfo in activeGames {
            let events = await checkForNewEvents(gameInfo: gameInfo)
            eventsFound += events.count
            
            // Send notifications for each event
            for event in events {
                await sendEventNotification(event, gameInfo: gameInfo)
            }
            
            if !events.isEmpty {
                updateLastEventCheck(for: gameInfo.gameId)
            }
        }
        
        print("🎯 Background update complete: \(eventsFound) events found")
    }
    
    // MARK: - Enhanced Event Detection
    
    private func checkForNewEvents(gameInfo: ActiveGameInfo) async -> [MatchEventType] {
        var detectedEvents: [MatchEventType] = []

        // Respect the shared rate limiter even in the background.
        guard APIRateLimiter.shared.canMakeCall() else {
            print("⏳ Background check skipped: rate limited")
            return []
        }

        do {
            // One call gives us fresh status + score. matchId is stored as Int; the API wants String.
            let detail = try await DataManager.shared.fetchMatchDetails(String(gameInfo.matchId))
            let match = detail.match

            let statusKey = "lastStatus_\(gameInfo.matchId)"
            let scoreKey  = "lastScore_\(gameInfo.matchId)"

            let previousStatus = UserDefaults.standard.string(forKey: statusKey) ?? "notStarted"
            let previousScore  = UserDefaults.standard.string(forKey: scoreKey) ?? "0-0"

            let currentStatus = String(describing: match.status)
            // TODO: compare MatchStatus by rawValue, not String(describing:)
            let currentScore  = "\(detail.homeScore)-\(detail.awayScore)"

            // Score went up → at least one goal since we last looked.
            if currentScore != previousScore, goalsIncreased(from: previousScore, to: currentScore) {
                detectedEvents.append(.goal)
            }

            // Status transitions worth a nudge.
            if currentStatus != previousStatus {
                switch match.status {
                case .inProgress where previousStatus == "notStarted" || previousStatus.contains("upcoming"):
                    detectedEvents.append(.matchStart)
                case .halftime:
                    detectedEvents.append(.halfTime)
                case .completed, .finished:
                    detectedEvents.append(.matchEnd)
                default:
                    break
                }
            }

            // Persist the new baseline for next time.
            UserDefaults.standard.set(currentStatus, forKey: statusKey)
            UserDefaults.standard.set(currentScore, forKey: scoreKey)

            print("📊 Background diff for \(gameInfo.matchName): \(previousScore)→\(currentScore), \(previousStatus)→\(currentStatus)")

        } catch {
            // No fabrication on failure — just report nothing this cycle.
            print("❌ Background event check failed: \(error)")
        }

        return detectedEvents
    }

    /// True if the total goals in `to` exceeds the total in `from` (guards against score corrections going down).
    private func goalsIncreased(from: String, to: String) -> Bool {
        func total(_ s: String) -> Int {
            let parts = s.split(separator: "-").compactMap { Int($0) }
            return parts.count == 2 ? parts[0] + parts[1] : 0
        }
        return total(to) > total(from)
    }
    
    // MARK: - Enhanced Notification Management
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func sendEventNotification(_ eventType: MatchEventType, gameInfo: ActiveGameInfo) async {
        // Check notification permission first
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        guard settings.authorizationStatus == .authorized else {
            print("🔕 Notifications not authorized, status: \(settings.authorizationStatus.rawValue)")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = eventType.notificationTitle
        content.body = generateNotificationBody(for: eventType, matchName: gameInfo.matchName)
        content.sound = .default
        content.badge = NSNumber(value: UIApplication.shared.applicationIconBadgeNumber + 1)
        
        content.userInfo = [
            "gameId": gameInfo.gameId.uuidString,
            "matchId": String(gameInfo.matchId),
            "eventType": eventType.rawValue,
            "type": "match_event"
        ]
        
        content.categoryIdentifier = "MATCH_EVENT"
        
        let request = UNNotificationRequest(
            identifier: "match_event_\(gameInfo.gameId.uuidString)_\(eventType.rawValue)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        
        do {
            try await center.add(request)
            print("📱 \(eventType.notificationTitle) notification sent for: \(gameInfo.matchName)")
        } catch {
            print("❌ Failed to send \(eventType.rawValue) notification: \(error)")
        }
    }
    
    private func generateNotificationBody(for eventType: MatchEventType, matchName: String) -> String {
        switch eventType {
        case .goal:
            return "A goal was scored in \(matchName)! Check your game to see how it affects your bets."
        case .yellowCard:
            return "A yellow card was shown in \(matchName)! Player discipline could impact the game."
        case .redCard:
            return "A player received a red card in \(matchName)! This could change everything."
        case .penalty:
            return "A penalty was awarded in \(matchName)! Will it be converted?"
        case .matchStart:
            return "\(matchName) has kicked off! Your live game is now active."
        case .halfTime:
            return "\(matchName) has reached half time. Check your current standings!"
        case .matchEnd:
            return "\(matchName) has finished! See how your bets performed."
        }
    }
    
    // MARK: - Game Management
    
    func startBackgroundMonitoring(for gameSession: GameSession) {
        guard let selectedMatch = gameSession.selectedMatch else {
            print("❌ Cannot start background monitoring: no match selected")
            return
        }
        
        let gameInfo = ActiveGameInfo(
            gameId: gameSession.id,
            matchId: Int(selectedMatch.id) ?? 0, // Fix: Convert string to int safely
            matchName: "\(selectedMatch.homeTeam.name) vs \(selectedMatch.awayTeam.name)",
            lastEventCheck: Date()
        )
        
        // Initialize tracking data
        let statusKey = "lastStatus_\(selectedMatch.id)"
        let scoreKey = "lastScore_\(selectedMatch.id)"
        let eventCountKey = "eventCount_\(selectedMatch.id)"
        
        UserDefaults.standard.set("notStarted", forKey: statusKey)
        UserDefaults.standard.set("0-0", forKey: scoreKey)
        UserDefaults.standard.set(0, forKey: eventCountKey)
        
        // Save to persistent storage
        saveActiveGameInfo(gameInfo)
        
        // Add to current session
        if !activeBackgroundGames.contains(gameSession.id) {
            activeBackgroundGames.append(gameSession.id)
        }
        
        // Schedule background updates
        scheduleBackgroundRefresh()
        
        print("🎯 Background monitoring started for: \(gameInfo.matchName)")
    }
    
    func stopBackgroundMonitoring(for gameSession: GameSession) {
        // Remove from current session
        activeBackgroundGames.removeAll { $0 == gameSession.id }
        
        // Remove from persistent storage
        removeActiveGameInfo(gameSession.id)
        
        // Clean up tracking data
        if let selectedMatch = gameSession.selectedMatch {
            let statusKey = "lastStatus_\(selectedMatch.id)"
            let scoreKey = "lastScore_\(selectedMatch.id)"
            let eventCountKey = "eventCount_\(selectedMatch.id)"
            
            UserDefaults.standard.removeObject(forKey: statusKey)
            UserDefaults.standard.removeObject(forKey: scoreKey)
            UserDefaults.standard.removeObject(forKey: eventCountKey)
        }
        
        print("⏹️ Background monitoring stopped for game: \(gameSession.id)")
        
        // Cancel background tasks if no more active games
        if activeBackgroundGames.isEmpty {
            BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
            print("🚫 All background tasks cancelled")
        }
    }
    
    // MARK: - Persistent Storage
    
    private func saveActiveGameInfo(_ gameInfo: ActiveGameInfo) {
        var activeGames = getActiveGamesFromStorage()
        activeGames.removeAll { $0.gameId == gameInfo.gameId } // Remove duplicates
        activeGames.append(gameInfo)
        
        if let data = try? JSONEncoder().encode(activeGames) {
            UserDefaults.standard.set(data, forKey: "activeBackgroundGames")
            print("💾 Saved \(activeGames.count) active games to storage")
        }
    }
    
    private func removeActiveGameInfo(_ gameId: UUID) {
        var activeGames = getActiveGamesFromStorage()
        activeGames.removeAll { $0.gameId == gameId }
        
        if let data = try? JSONEncoder().encode(activeGames) {
            UserDefaults.standard.set(data, forKey: "activeBackgroundGames")
            print("💾 Removed game from storage, \(activeGames.count) games remaining")
        }
    }
    
    private func getActiveGamesFromStorage() -> [ActiveGameInfo] {
        guard let data = UserDefaults.standard.data(forKey: "activeBackgroundGames"),
              let games = try? JSONDecoder().decode([ActiveGameInfo].self, from: data) else {
            return []
        }
        return games
    }
    
    private func updateLastEventCheck(for gameId: UUID) {
        var activeGames = getActiveGamesFromStorage()
        if let index = activeGames.firstIndex(where: { $0.gameId == gameId }) {
            activeGames[index].lastEventCheck = Date()
            if let data = try? JSONEncoder().encode(activeGames) {
                UserDefaults.standard.set(data, forKey: "activeBackgroundGames")
            }
        }
    }
}

// MARK: - Supporting Structures

struct ActiveGameInfo: Codable {
    let gameId: UUID
    let matchId: Int
    let matchName: String
    var lastEventCheck: Date
}
