//
//  AppConfig.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

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
    
    // IMPORTANT: Secure your API key properly
    static let footballDataAPIKey: String = {
        // Try to get from Info.plist first
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "FOOTBALL_DATA_API_KEY") as? String, !apiKey.isEmpty {
            return apiKey
        }
        
        // Fallback for development
#if DEBUG
        return "23b9a294b92a48d3b50444a6ee280aca" // Your actual API key
#else
        fatalError("API key not found in Info.plist")
#endif
    }()
    
    // Production settings
    static var useStubData: Bool {
#if DEBUG
        return false // Set to false even in debug for TestFlight
#else
        return false
#endif
    }
    
    static var enableDetailedLogging: Bool {
#if DEBUG
        return true
#else
        return false // Disable detailed logging in production
#endif
    }
    
    // MARK: - Free Tier Limits
    
    static var maxFreeMatches: Int {
        return 3
    }
    
    @MainActor
    static var canSelectMultipleMatches: Bool {
        return AppPurchaseManager.shared.currentTier == .premium
    }
    
    @MainActor
    static var hasReachedFreeMatchLimit: Bool {
        return !AppPurchaseManager.shared.canUseLiveFeatures
    }
    
    @MainActor
    static func incrementMatchUsage() {
        if AppPurchaseManager.shared.currentTier == .free {
            AppPurchaseManager.shared.useFreeLiveMatch()
        }
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
    
    // MARK: - Ad Configuration
    
    @MainActor
    static var shouldShowAdsForUser: Bool {
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
        return AppPurchaseManager.shared.currentTier == .premium
    }
    
    @MainActor
    static var enableAdvancedStats: Bool {
        return AppPurchaseManager.shared.currentTier == .premium
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
#endif
    }
    
    // MARK: - App Store Configuration
    
    static let appStoreID = "YOUR_APP_ID" // Set this when you get your App Store ID
    static let appStoreURL = "https://apps.apple.com/app/lucky-football-slip"
    
    // MARK: - Support and Legal
    
    static let supportEmail = "support@lappeleken.com"
    static let privacyPolicyURL = "https://lappeleken.com/privacy"
    static let termsOfServiceURL = "https://lappeleken.com/terms"
}
