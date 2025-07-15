//
//  LappelekenApp.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 18/03/2025.
//

import SwiftUI
import BackgroundTasks

@main
struct LuckyFootballSlipApp: App {
    
    init() {
        // Initialize background tasks
        BackgroundTaskManager.shared.registerBackgroundTasks()
        
        // Initialize manual mode manager
        ManualModeManager.shared.initialize()
        
        // 🆕 ADD THIS: Initialize and validate subscription setup
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
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Clear badge when app comes to foreground
                    UIApplication.shared.applicationIconBadgeNumber = 0
                    
                    // 🆕 ADD THIS: Refresh subscription status when app comes to foreground
                    Task {
                        await AppPurchaseManager.shared.updateEntitlements()
                    }
                }
        }
    }
}
