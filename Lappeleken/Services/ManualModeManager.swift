//
//  ManualModeManager.swift
//  Lucky Football Slip
//
//  Manager for manual mode initialization and data management
//

import Foundation

/// Call this during app launch to ensure player data is loaded
class ManualModeManager {
    static let shared = ManualModeManager()
    
    private init() {}
    
    /// Initialize manual mode data management
    func initialize() {
        print("🚀 Initializing Manual Mode Manager...")
        
        // Check if this is first launch
        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            print("🆕 First launch detected - manual mode ready for fresh start")
        }
        
        // Perform any necessary migrations or data cleanup
        performDataMigration()
    }
    
    private func performDataMigration() {
        // Check app version for any necessary data migrations
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let savedVersion = UserDefaults.standard.string(forKey: "lastAppVersion") ?? "1.0"
        
        if currentVersion != savedVersion {
            print("🔄 App updated from \(savedVersion) to \(currentVersion)")
            
            // Perform any necessary data migrations here
            // For example, if we change the Player or Team structure
            
            UserDefaults.standard.set(currentVersion, forKey: "lastAppVersion")
        }
    }
    
    /// Get debug information about manual mode
    func getDebugInfo() -> String {
        let tempGameSession = GameSession()
        tempGameSession.loadCustomPlayers()
        let stats = tempGameSession.getPlayerStatistics()
        
        return """
        Manual Mode Debug Info:
        • \(stats.summary)
        • Position breakdown: \(stats.positionBreakdown.map { "\($0.key.rawValue): \($0.value)" }.joined(separator: ", "))
        • Has saved data: \(UserDefaults.standard.data(forKey: "userCustomPlayers") != nil)
        • App version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        """
    }
    
    /// Clear all manual mode data (for testing/reset purposes)
    func resetAllData() {
        let tempGameSession = GameSession()
        tempGameSession.clearAllSavedData()
        print("🗑️ Manual mode data reset complete")
    }
    
    /// Get current player statistics without affecting game state
    func getCurrentStats() -> PlayerStatistics {
        let tempGameSession = GameSession()
        tempGameSession.loadCustomPlayers()
        return tempGameSession.getPlayerStatistics()
    }
}
