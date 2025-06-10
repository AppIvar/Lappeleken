//
//  LappelekenApp.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 18/03/2025.
//

import SwiftUI

@main
struct LappelekenApp: App {
    
    init() {
        #if DEBUG
        AppConfig.checkForFreshInstall()
        #endif
        
        // Validate app configuration
        Task { @MainActor in
            AppConfig.validateConfiguration()
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
