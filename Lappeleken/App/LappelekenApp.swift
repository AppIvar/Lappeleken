//
//  LappelekenApp.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 18/03/2025.
//

import SwiftUI
import BackgroundTasks
import UserNotifications

@main
struct LuckyFootballSlipApp: App {
    @StateObject private var notificationDelegate = NotificationDelegate()
    
    init() {
        // Initialize manual mode manager
        ManualModeManager.shared.initialize()
        
        // Initialize and validate subscription setup
        Task {
            await AppPurchaseManager.shared.loadProducts()
            AppPurchaseManager.shared.validateSubscriptionConfiguration()
        }
        
        // Validate app configuration
        Task { @MainActor in
            AppConfig.validateConfiguration()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .environmentObject(notificationDelegate)
                .onAppear {
                    setupNotifications()
                }
                .onChange(of: notificationDelegate.lastNotificationGameId) { gameId in
                    if let gameId = gameId {
                        handleNotificationNavigation(gameId: gameId)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Clear badge when app comes to foreground
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    
                    // Refresh subscription status when app comes to foreground
                    Task {
                        await AppPurchaseManager.shared.updateEntitlements()
                    }
                }
        }
    }
    
    private func setupNotifications() {
        // Set the delegate
        UNUserNotificationCenter.current().delegate = notificationDelegate
        
        // Request permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notifications authorized")
                self.setupNotificationCategories()
            } else if let error = error {
                print("❌ Notification authorization error: \(error)")
            }
        }
    }
    
    private func setupNotificationCategories() {
        let matchEventCategory = UNNotificationCategory(
            identifier: "MATCH_EVENT",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([matchEventCategory])
    }
    
    private func handleNotificationNavigation(gameId: String) {
        print("📱 Opening game from notification: \(gameId)")
        // You'll need to implement actual navigation here
        // For example, post a notification that your view hierarchy can listen to:
        NotificationCenter.default.post(
            name: Notification.Name("NavigateToGame"),
            object: nil,
            userInfo: ["gameId": gameId]
        )
    }
}
