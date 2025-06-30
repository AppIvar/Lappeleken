//
//  FreeLiveModeTesting.swift
//  Lucky Football Slip
//
//  Easy controls for enabling/disabling free Live Mode testing
//

import Foundation
import UIKit

struct FreeLiveModeTesting {
    
    // MARK: - Easy Toggle Functions
    
    /// Start the free Live Mode testing period
    /// Call this function to enable unlimited Live Mode for all users
    static func startFreeTesting() {
        AppConfig.enableFreeLiveModeTesting()
        
        // Show confirmation alert in debug builds
        #if DEBUG
        showTestingAlert(
            title: "Free Testing Enabled ✅",
            message: "Live Mode is now FREE for all users with unlimited matches!\n\n• Ads will still be shown\n• Usage is tracked for analytics\n• Easy to disable later"
        )
        #endif
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: Notification.Name("FreeLiveModeTestingChanged"),
            object: ["enabled": true]
        )
    }
    
    /// End the free Live Mode testing period
    /// Call this function to return to normal 1-match-per-day limit
    static func endFreeTesting() {
        AppConfig.disableFreeLiveModeTesting()
        
        // Show confirmation alert in debug builds
        #if DEBUG
        showTestingAlert(
            title: "Free Testing Disabled ❌",
            message: "Live Mode is back to normal limits:\n\n• 1 match per day for free users\n• Premium users still unlimited\n• Testing analytics preserved"
        )
        #endif
        
        // Post notification for UI updates
        NotificationCenter.default.post(
            name: Notification.Name("FreeLiveModeTestingChanged"),
            object: ["enabled": false]
        )
    }
    
    /// Get current testing status and analytics
    @MainActor static func getTestingStatus() -> String {
        let config = AppConfig.getFreeLiveModeAnalytics()
        let adAnalytics = AdManager.shared.getFreeTestingAdAnalytics()
        
        if AppConfig.isFreeLiveTestingActive {
            let startDate = config["startDate"] as? Date ?? Date()
            let daysSinceStart = config["daysSinceStart"] as? Int ?? 0
            let totalMatches = config["totalMatches"] as? Int ?? 0
            let avgPerDay = config["averagePerDay"] as? Double ?? 0
            
            return """
            🎁 FREE TESTING ACTIVE
            
            📅 Started: \(DateFormatter.shortDate.string(from: startDate))
            📊 Days running: \(daysSinceStart)
            🎮 Total matches: \(totalMatches)
            📈 Avg per day: \(String(format: "%.1f", avgPerDay))
            
            📺 Ad Analytics:
            • Today's ads: \(adAnalytics["adsShownToday"] as? Int ?? 0)
            • Today's sessions: \(adAnalytics["sessionsToday"] as? Int ?? 0)
            • Ad frequency: \(adAnalytics["adFrequency"] as? String ?? "Unknown")
            """
        } else {
            return """
            🔒 FREE TESTING INACTIVE
            
            Current mode: 1 match per day limit
            Call FreeLiveModeTesting.startFreeTesting() to enable
            """
        }
    }
    
    // MARK: - Analytics Export
    
    /// Export detailed analytics for the testing period
    @MainActor static func exportTestingAnalytics() -> [String: Any] {
        var analytics: [String: Any] = [:]
        
        // Basic config
        analytics["testingActive"] = AppConfig.isFreeLiveTestingActive
        analytics["exportDate"] = Date()
        
        // Merge all analytics
        analytics.merge(AppConfig.getFreeLiveModeAnalytics()) { _, new in new }
        analytics.merge(AdManager.shared.getFreeTestingAdAnalytics()) { _, new in new }
        analytics.merge(AdManager.shared.getAdStats()) { _, new in new }
        
        // Additional calculated metrics
        if let totalMatches = analytics["totalMatches"] as? Int,
           let daysSinceStart = analytics["daysSinceStart"] as? Int,
           daysSinceStart > 0 {
            analytics["matchesPerDay"] = Double(totalMatches) / Double(daysSinceStart)
        }
        
        return analytics
    }
    
    /// Save analytics to a file (for debugging)
    @MainActor static func saveAnalyticsToFile() {
        #if DEBUG
        let analytics = exportTestingAnalytics()
        
        // Convert to JSON-safe format (no Date objects)
        var jsonSafeAnalytics: [String: Any] = [:]
        
        for (key, value) in analytics {
            switch value {
            case let date as Date:
                // Convert dates to strings
                let formatter = DateFormatter()
                formatter.dateStyle = .medium
                formatter.timeStyle = .short
                jsonSafeAnalytics[key] = formatter.string(from: date)
            case is NSNumber, is String, is Bool, is Int, is Double:
                // These are JSON-safe
                jsonSafeAnalytics[key] = value
            default:
                // Convert anything else to string
                jsonSafeAnalytics[key] = String(describing: value)
            }
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonSafeAnalytics, options: .prettyPrinted)
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent("free_testing_analytics.json")
            
            try data.write(to: fileURL)
            print("📊 Analytics saved to: \(fileURL.path)")
            
            showTestingAlert(
                title: "Analytics Exported",
                message: "Testing analytics saved to:\n\(fileURL.lastPathComponent)"
            )
        } catch {
            print("❌ Failed to save analytics: \(error)")
            showTestingAlert(
                title: "Export Failed",
                message: "Could not save analytics file: \(error.localizedDescription)"
            )
        }
        #endif
    }
    
    // MARK: - Helper Functions
    
    private static func showTestingAlert(title: String, message: String) {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                print("⚠️ \(title): \(message)")
                return
            }
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            rootViewController.present(alert, animated: true)
        }
    }
}

// MARK: - Quick Access Functions (for easy calling from anywhere)

/// Global function to quickly start free testing
func startFreeLiveTesting() {
    FreeLiveModeTesting.startFreeTesting()
}

/// Global function to quickly end free testing
func endFreeLiveTesting() {
    FreeLiveModeTesting.endFreeTesting()
}

/// Global function to check testing status
@MainActor func checkTestingStatus() -> String {
    return FreeLiveModeTesting.getTestingStatus()
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
}
