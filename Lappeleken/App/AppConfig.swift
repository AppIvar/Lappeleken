//
//  AppConfig.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

// MARK: - Updated AppConfig.swift with Free Live Mode Testing

struct AppConfig {
    static let environment: Environment = {
#if DEBUG
        return .development
#else
        return .production
#endif
    }()
    
    enum Environment {
        case development
        case staging
        case production
    }
    
    static var apiBaseURL: String {
        switch environment {
        case .development:
            return "https://dev-api.lappeleken.com"
        case .staging:
            return "https://staging-api.lappeleken.com"
        case .production:
            return "https://api.lappeleken.com"
        }
    }
    
    static let footballDataAPIKey: String = {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "FOOTBALL_DATA_API_KEY") as? String, !apiKey.isEmpty {
            return apiKey
        }
        
#if DEBUG
        return "23b9a294b92a48d3b50444a6ee280aca"
#else
        fatalError("API key not found in Info.plist")
#endif
    }()
    
    static var useStubData: Bool {
#if DEBUG
        return false
#else
        return false
#endif
    }
    
    static var enableDetailedLogging: Bool {
#if DEBUG
        return true
#else
        return false
#endif
    }
    
    // MARK: - FREE LIVE MODE TESTING FEATURE
    
    /// Master flag to enable/disable free Live Mode testing
    /// Set this to false after testing period to revert to 1 match limit
    static let liveModeFreeTesting: Bool = {
        return UserDefaults.standard.bool(forKey: "liveModeFreeTesting_enabled")
    }()
    
    /// Enable free Live Mode testing (call this to start the free period)
    static func enableFreeLiveModeTesting() {
        UserDefaults.standard.set(true, forKey: "liveModeFreeTesting_enabled")
        UserDefaults.standard.set(Date(), forKey: "liveModeFreeTesting_startDate")
        print("🎁 FREE Live Mode testing ENABLED - unlimited matches for all users!")
    }
    
    /// Disable free Live Mode testing (call this to end the free period)
    static func disableFreeLiveModeTesting() {
        UserDefaults.standard.set(false, forKey: "liveModeFreeTesting_enabled")
        UserDefaults.standard.removeObject(forKey: "liveModeFreeTesting_startDate")
        print("🔒 FREE Live Mode testing DISABLED - back to 1 match per day limit")
    }
    
    /// Get testing start date (for analytics)
    static var freeTestingStartDate: Date? {
        guard liveModeFreeTesting else { return nil }
        return UserDefaults.standard.object(forKey: "liveModeFreeTesting_startDate") as? Date
    }
    
    // MARK: - Updated Free Tier Limits with Testing Override
    
    /// Daily free match limit (1 normally, unlimited during testing)
    @MainActor
    static var dailyFreeMatchLimit: Int {
        return isFreeLiveTestingActive ? Int.max : 1 // Unlimited during testing, 1 after
    }
    
    @MainActor
    static var canSelectMultipleMatches: Bool {
        // Allow multiple matches if premium OR during free testing
        return AppPurchaseManager.shared.currentTier == .premium || isFreeLiveTestingActive
    }
    
    @MainActor
    static var hasReachedFreeMatchLimit: Bool {
        // Never reached limit during free testing
        if isFreeLiveTestingActive {
            return false
        }
        
        // Normal limit checking for non-testing periods
        return !AppPurchaseManager.shared.canUseLiveFeatures
    }
    
    @MainActor
    static func recordLiveMatchUsage() {
        // Don't count usage during free testing period
        if !isFreeLiveTestingActive {
            if AppPurchaseManager.shared.currentTier == .free {
                AppPurchaseManager.shared.useFreeLiveMatch()
            }
        }
    }
    
    @MainActor
    static func incrementMatchUsage() {
        recordLiveMatchUsage()
    }
    
    // MARK: - Competition Access Control
    
    @MainActor
    static func canAccessCompetition(_ competitionCode: String) -> Bool {
        return AppPurchaseManager.shared.canAccessCompetition(competitionCode)
    }
    
    static var basicLeagues: [String] {
        return ["PL", "BL1", "SA", "PD", "EL"]
    }
    
    static var premiumCompetitions: [String: String] {
        return [
            "CL": "Champions League",
            "WC": "World Cup",
            "EC": "Euro Championship",
            "NC": "Nations Cup"
        ]
    }
    
    // MARK: - Ad Configuration (Updated for Free Testing)
    
    @MainActor
    static var shouldShowAdsForUser: Bool {
        // Show ads for free users, even during testing period
        return AppPurchaseManager.shared.currentTier == .free
    }
    
    @MainActor
    static var shouldShowInterstitialAfterGame: Bool {
        return AdManager.shared.shouldShowInterstitialAfterGameComplete()
    }
    
    static func incrementGameCount() {
        let current = UserDefaults.standard.integer(forKey: "completedGameCount")
        UserDefaults.standard.set(current + 1, forKey: "completedGameCount")
    }
    
    // MARK: - Feature Flags
    
    @MainActor
    static var enablePushNotifications: Bool {
        return AppPurchaseManager.shared.currentTier == .premium
    }
    
    @MainActor
    static var enableMultipleMatchTracking: Bool {
        return AppPurchaseManager.shared.currentTier == .premium || isFreeLiveTestingActive
    }
    
    @MainActor
    static var enableAdvancedStats: Bool {
        return AppPurchaseManager.shared.currentTier == .premium
    }
    
    // MARK: - Analytics for Free Testing
    
    @MainActor static func recordFreeLiveModeUsage() {
        guard isFreeLiveTestingActive else { return }
        
        let key = "freeLiveModeUsage_\(DateFormatter.yyyyMMdd.string(from: Date()))"
        let currentCount = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(currentCount + 1, forKey: key)
        
        print("📊 Free Live Mode usage recorded: \(currentCount + 1) today")
    }
    
    @MainActor static func getFreeLiveModeAnalytics() -> [String: Any] {
        guard let startDate = freeTestingStartDate else {
            return ["error": "Free testing not active"]
        }
        
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        
        // Count usage across all days
        var totalUsage = 0
        let calendar = Calendar.current
        var currentDate = startDate
        
        while currentDate <= Date() {
            let key = "freeLiveModeUsage_\(DateFormatter.yyyyMMdd.string(from: currentDate))"
            totalUsage += UserDefaults.standard.integer(forKey: key)
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? Date()
        }
        
        return [
            "isActive": isFreeLiveTestingActive,
            "startDate": startDate,
            "daysSinceStart": daysSinceStart,
            "totalMatches": totalUsage,
            "averagePerDay": daysSinceStart > 0 ? Double(totalUsage) / Double(daysSinceStart) : 0
        ]
    }
    
    // MARK: - Validation
    
    @MainActor
    static func validateConfiguration() {
        assert(!footballDataAPIKey.isEmpty, "API key must be configured")
        assert(footballDataAPIKey != "your-api-key-here", "Replace placeholder API key")
        
#if DEBUG
        print("✅ App configuration validated")
        print("🔑 API Key: \(footballDataAPIKey.prefix(8))...")
        print("🌍 Environment: \(environment)")
        print("📊 Logging enabled: \(enableDetailedLogging)")
        print("💰 Purchase tier: \(AppPurchaseManager.shared.currentTier.displayName)")
        print("🎁 Free Live Mode Testing: \(isFreeLiveTestingActive ? "ACTIVE" : "INACTIVE")")
#endif
    }
    
    // MARK: - App Store Configuration
    
    static let appStoreID = "YOUR_APP_ID"
    static let appStoreURL = "https://apps.apple.com/app/lucky-football-slip"
    
    // MARK: - Support and Legal
    
    static let supportEmail = "support@lappeleken.com"
    static let privacyPolicyURL = "https://lappeleken.com/privacy"
    static let termsOfServiceURL = "https://lappeleken.com/terms"
}

// MARK: - Production Control (No Server Required)
extension AppConfig {
    /// Set this to true when you want to enable free testing for everyone
    /// Change this value and release an app update to control the feature
    private static let PRODUCTION_FREE_TESTING_ENABLED = true // ← Change this to true/false
    
    /// Production version of free testing check
    @MainActor
    static var isFreeLiveTestingActiveProduction: Bool {
        #if DEBUG
        // In debug, use the UserDefaults version (controlled by settings)
        return liveModeFreeTesting
        #else
        // In production, use the hardcoded flag above
        return PRODUCTION_FREE_TESTING_ENABLED
        #endif
    }
    
    /// Use this instead of isFreeLiveTestingActive throughout your app
    @MainActor
    static var isFreeLiveTestingActive: Bool {
        return isFreeLiveTestingActiveProduction
    }
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}
