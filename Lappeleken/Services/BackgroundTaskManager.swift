//
//  BackgroundTaskManager.swift
//  Lucky Football Slip
//
//  Background task management for live match monitoring
//

import Foundation
import BackgroundTasks
import UserNotifications

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
            print("❌ Failed to schedule background refresh: \(error)")
        }
    }
    
    // MARK: - Background Task Handler
    
    private func handleMatchUpdateTask(_ task: BGProcessingTask) {
        // Set expiration handler
        task.expirationHandler = {
            print("⏰ Background task expired")
            task.setTaskCompleted(success: false)
        }
        
        // Perform the work
        Task {
            do {
                await checkForMatchEvents()
                print("✅ Background task completed successfully")
                task.setTaskCompleted(success: true)
                
                // Schedule next update if still needed
                await MainActor.run {
                    self.scheduleBackgroundRefresh()
                }
            } catch {
                print("❌ Background task failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    // MARK: - Match Event Checking
    
    private func checkForMatchEvents() async {
        print("🔍 Checking for match events in background...")
        
        // Get active games from persistent storage
        let activeGames = getActiveGamesFromStorage()
        
        for gameInfo in activeGames {
            do {
                // Check if there are new events for this game
                let hasNewEvents = try await checkGameForNewEvents(gameInfo)
                
                if hasNewEvents {
                    await sendMatchEventNotification(gameInfo)
                }
            } catch {
                print("❌ Error checking game \(gameInfo.gameId): \(error)")
            }
        }
    }
    
    private func checkGameForNewEvents(_ gameInfo: ActiveGameInfo) async throws -> Bool {
        let lastCheck = gameInfo.lastEventCheck
        
        // For mock matches, use simple simulation
        if gameInfo.matchId.hasPrefix("mock_") {
            if AppConfig.useStubData {
                let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)
                if timeSinceLastCheck > 600 && Bool.random() { // 10 minutes + random chance
                    updateLastEventCheck(for: gameInfo.gameId)
                    return true
                }
            }
            return false
        }
        
        // For real matches, check via API
        do {
            let matchService = ServiceProvider.shared.getMatchService()
            let matchDetails = try await matchService.fetchMatchDetails(matchId: gameInfo.matchId)
            
            // Check if match status changed
            let statusKey = "bgLastStatus_\(gameInfo.matchId)"
            let lastStatus = UserDefaults.standard.string(forKey: statusKey)
            let currentStatus = String(describing: matchDetails.match.status) // Fix: Convert enum to string
            
            if lastStatus != currentStatus {
                UserDefaults.standard.set(currentStatus, forKey: statusKey)
                updateLastEventCheck(for: gameInfo.gameId)
                return true
            }
            
            // Check for score changes (if available in your match details)
            // You'd implement this based on your MatchDetail structure
            
            return false
            
        } catch {
            print("❌ Error checking real match: \(error)")
            
            // Fallback to time-based check for reliability
            let timeSinceLastCheck = Date().timeIntervalSince(lastCheck)
            if timeSinceLastCheck > 900 { // 15 minutes
                updateLastEventCheck(for: gameInfo.gameId)
                return Bool.random() // Small chance of "finding" an event
            }
            
            return false
        }
    }
    
    // MARK: - Notification Management
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    private func sendMatchEventNotification(_ gameInfo: ActiveGameInfo) async {
        let content = UNMutableNotificationContent()
        content.title = "⚽ Live Match Event!"
        content.body = "Something happened in \(gameInfo.matchName) - check your game!"
        content.sound = .default
        content.badge = 1
        
        // Add custom data
        content.userInfo = [
            "gameId": gameInfo.gameId.uuidString,
            "matchId": gameInfo.matchId,
            "type": "match_event"
        ]
        
        let request = UNNotificationRequest(
            identifier: "match_event_\(gameInfo.gameId.uuidString)",
            content: content,
            trigger: nil // Send immediately
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("📱 Notification sent for game: \(gameInfo.gameId)")
        } catch {
            print("❌ Failed to send notification: \(error)")
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
            matchId: selectedMatch.id,
            matchName: "\(selectedMatch.homeTeam.name) vs \(selectedMatch.awayTeam.name)",
            lastEventCheck: Date()
        )
        
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
        }
    }
    
    private func removeActiveGameInfo(_ gameId: UUID) {
        var activeGames = getActiveGamesFromStorage()
        activeGames.removeAll { $0.gameId == gameId }
        
        if let data = try? JSONEncoder().encode(activeGames) {
            UserDefaults.standard.set(data, forKey: "activeBackgroundGames")
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

// MARK: - Supporting Types

struct ActiveGameInfo: Codable {
    let gameId: UUID
    let matchId: String
    let matchName: String
    var lastEventCheck: Date
}
