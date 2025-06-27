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
        BackgroundTaskManager.shared.registerBackgroundTasks()
    }
    
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    // Clear badge when app comes to foreground
                    UIApplication.shared.applicationIconBadgeNumber = 0
                }
        }
    }
}
