//
//  AppConfig.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

struct AppConfig {
    
    // MARK: - Master Feature Flags
    
    /// Master toggle for subscription system
    static var subscriptionEnabled: Bool {
        return PurchaseConfig.purchasesEnabled
    }
    /// Individual premium feature flags (can be enabled separately for testing)
    struct PremiumFeatures {
        static let multipleMatchSelection = true    // â† Premium: Select multiple live matches
        static let unlimitedDailyMatches = true     // â† Premium: No 1-per-day limit
        static let adFreeExperience = false          // â† Premium: Remove all ads
        static let lineupSearchAccess = true
        
        //MARK: - Phase 1 Cleanup features
        static let useNewGameLogicManager = true
        static let useNewDataManager = true
    }
    
    /// Ad configuration
    struct AdSettings {
        static let showAdsForAllUsers = true         // â† Show ads to everyone for now
        static let showBannerAds = true              // â† Banner ads throughout app
        static let showInterstitialAds = true       // â† Interstitial ads after games
        static let showRewardedAds = false           // â† Rewarded ads for extra features
    }
    
    /// Purchase system configuration
    struct PurchaseConfig {
        /// Master toggle for all purchases (for testing without payments)
        static let purchasesEnabled = false  // Set to true when ready to enable purchases
        
        /// World Cup 2026 expiry date (August 1, 2026)
        static let worldCup2026ExpiryDate: Date = {
            Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 1)) ?? Date()
        }()
    }
    
    /// League configuration
    struct LeagueConfig {
        static let freeLeagues: Set<String> = ["DED", "PPL", "ELC", "EL"]
        static let bigLeagues: Set<String> = ["PL", "PD", "BL1", "SA"]
        static let championsLeague: Set<String> = ["CL"]
        static let worldCup: Set<String> = ["WC"]
        
        /// Free matches allowed per big league before requiring subscription
        static let freeMatchesPerBigLeague = 3
    }
    
    // MARK: - Feature Flag Helpers
    
    @MainActor
    static var canSelectMultipleMatches: Bool {
        if !subscriptionEnabled {
            return PremiumFeatures.multipleMatchSelection
        }
        // When subscription is enabled, check actual premium status
        return AppPurchaseManager.shared.currentTier == .premium || isFreeLiveTestingActive
    }
    
    @MainActor
    static var hasUnlimitedDailyMatches: Bool {
        if !subscriptionEnabled {
            return PremiumFeatures.unlimitedDailyMatches
        }
        // When subscription is enabled, check actual premium status
        return AppPurchaseManager.shared.currentTier == .premium || isFreeLiveTestingActive
    }
    
    @MainActor
    static var hasAdFreeExperience: Bool {
        if !subscriptionEnabled {
            return PremiumFeatures.adFreeExperience
        }
        // When subscription is enabled, check actual premium status
        return AppPurchaseManager.shared.currentTier == .premium
    }
    
    @MainActor
    static var shouldShowAdsForCurrentUser: Bool {
        // If ads are disabled globally, don't show
        if !AdSettings.showAdsForAllUsers {
            return false
        }
        
        // If user has ad-free experience, don't show
        if hasAdFreeExperience {
            return false
        }
        
        // Show ads for everyone else
        return true
    }
    
    @MainActor
    static var canAccessLineupSearch: Bool {
        if !subscriptionEnabled {
            return PremiumFeatures.lineupSearchAccess
        }
        // When subscription is enabled, check actual premium status
        return AppPurchaseManager.shared.currentTier == .premium || isFreeLiveTestingActive
    }
    
    // MARK: - Cleanup phase feature flags
    
    @MainActor
    static var useNewGameLogicManager: Bool {
        #if DEBUG
        // In debug, allow toggling via UserDefaults for testing
        return UserDefaults.standard.bool(forKey: "useNewGameLogicManager_debug") || PremiumFeatures.useNewGameLogicManager
        #else
        // In production, use the hardcoded flag
        return PremiumFeatures.useNewGameLogicManager
        #endif
    }
    
    static var useNewDataManager: Bool {
        #if DEBUG
        // In debug, allow toggling via UserDefaults for testing
        return UserDefaults.standard.bool(forKey: "useNewDataManager_debug") || PremiumFeatures.useNewDataManager
        #else
        // In production, use the hardcoded flag
        return PremiumFeatures.useNewDataManager
        #endif
    }
    
#if DEBUG
static func toggleGameLogicManagerForTesting() {
    let currentValue = UserDefaults.standard.bool(forKey: "useNewGameLogicManager_debug")
    UserDefaults.standard.set(!currentValue, forKey: "useNewGameLogicManager_debug")
    print("ðŸ”„ GameLogicManager debug toggle: \(!currentValue ? "NEW" : "OLD") system")
}
#endif

#if DEBUG
static func toggleDataManagerForTesting() {
    let currentValue = UserDefaults.standard.bool(forKey: "useNewDataManager_debug")
    UserDefaults.standard.set(!currentValue, forKey: "useNewDataManager_debug")
    print("ðŸ”„ DataManager debug toggle: \(!currentValue ? "NEW" : "OLD") system")
}
#endif
    
    // MARK: - Environment Configuration
    
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
    
    // MARK: - Cache Server Configuration
    
    /// Configuration for server-side caching to reduce football-data.org API load
    struct CacheServer {
        /// Enable routing API calls through your cache server
        static var enabled: Bool {
            #if DEBUG
            return UserDefaults.standard.bool(forKey: "cacheServer_enabled")
            #else
            // Enable in production once server is deployed
            return UserDefaults.standard.bool(forKey: "cacheServer_enabled")
            #endif
        }
        
        /// Cache server base URL (Cloudflare Worker; *.workers.dev until a custom domain is set up)
        static var baseURL: String {
            return "https://lucky-football-slip-cache.ivarhovland.workers.dev"
        }
        
        /// Endpoints that should be routed through cache server
        /// Format: /v4/matches → /api/football/matches
        static let cachedEndpoints: Set<String> = [
            "matches",
            "competitions",
            "teams"
        ]
        
        // Cache TTLs live entirely on the Worker (cloudflare-worker/worker.ts);
        // the client only hints liveness via ?live=1. No client-side TTL table.

        /// Enable for testing
        static func enable() {
            UserDefaults.standard.set(true, forKey: "cacheServer_enabled")
        }
        
        /// Disable cache server (direct API calls)
        static func disable() {
            UserDefaults.standard.set(false, forKey: "cacheServer_enabled")
        }
    }
    
    static let footballDataAPIKey: String = {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "FOOTBALL_DATA_API_KEY") as? String,
           !apiKey.isEmpty,
           apiKey != "$(FOOTBALL_DATA_API_KEY)" {   // guard against an unsubstituted xcconfig placeholder
            return apiKey
        }

        // No key found. Fail loudly in every configuration rather than shipping a key in source.
        #if DEBUG
        fatalError("FOOTBALL_DATA_API_KEY missing. Add it to Secrets.xcconfig (see setup notes).")
        #else
        fatalError("FOOTBALL_DATA_API_KEY not found in Info.plist")
        #endif
    }()

    /// Optional shared secret sent as `X-Client-Secret` to the cache server (Cloudflare
    /// Worker). Unlike `footballDataAPIKey`, this is not required — the Worker only
    /// checks it when `CLIENT_SHARED_SECRET` is configured on its side.
    static let clientSharedSecret: String? = {
        if let secret = Bundle.main.object(forInfoDictionaryKey: "CLIENT_SHARED_SECRET") as? String,
           !secret.isEmpty,
           secret != "$(CLIENT_SHARED_SECRET)" {
            return secret
        }
        return nil
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
    static let liveModeFreeTesting: Bool = {
        return UserDefaults.standard.bool(forKey: "liveModeFreeTesting_enabled")
    }()
    
    /// Enable free Live Mode testing (call this to start the free period)
    static func enableFreeLiveModeTesting() {
        UserDefaults.standard.set(true, forKey: "liveModeFreeTesting_enabled")
        UserDefaults.standard.set(Date(), forKey: "liveModeFreeTesting_startDate")
        print("ðŸŽ FREE Live Mode testing ENABLED - unlimited matches for all users!")
    }
    
    /// Disable free Live Mode testing (call this to end the free period)
    static func disableFreeLiveModeTesting() {
        UserDefaults.standard.set(false, forKey: "liveModeFreeTesting_enabled")
        UserDefaults.standard.removeObject(forKey: "liveModeFreeTesting_startDate")
        print("ðŸ”’ FREE Live Mode testing DISABLED - back to 1 match per day limit")
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
        return isFreeLiveTestingActive ? Int.max : 1
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
    
    // MARK: - Live Mode First-Use Tracking

    /// Check if user has ever used Live Mode (for showing "NEW" badge)
    static var hasUsedFreeLiveMatch: Bool {
        return UserDefaults.standard.bool(forKey: "hasUsedFreeLiveMatch")
    }

    /// Mark that user has used Live Mode
    static func markFreeLiveMatchUsed() {
        UserDefaults.standard.set(true, forKey: "hasUsedFreeLiveMatch")
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
    
    @MainActor
    static func recordFreeLiveModeUsage() {
        guard isFreeLiveTestingActive else { return }
        
        let key = "freeLiveModeUsage_\(DateFormatter.yyyyMMdd.string(from: Date()))"
        let currentCount = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(currentCount + 1, forKey: key)
        
        print("ðŸ“Š Free Live Mode usage recorded: \(currentCount + 1) today")
    }
    
    @MainActor
    static func getFreeLiveModeAnalytics() -> [String: Any] {
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
        print("âœ… App configuration validated")
        print("ðŸ”‘ API Key: \(footballDataAPIKey.prefix(8))...")
        print("ðŸŒ Environment: \(environment)")
        print("ðŸ“Š Logging enabled: \(enableDetailedLogging)")
        print("ðŸ’° Purchase tier: \(AppPurchaseManager.shared.currentTier.displayName)")
        print("ðŸŽ Free Live Mode Testing: \(isFreeLiveTestingActive ? "ACTIVE" : "INACTIVE")")
        print("ðŸš€ Subscription enabled: \(subscriptionEnabled)")
        print("ðŸŽ¯ Feature flags: Multiple matches=\(canSelectMultipleMatches), Unlimited=\(hasUnlimitedDailyMatches), Ad-free=\(hasAdFreeExperience)")
        print("ðŸ“± Ads shown: \(shouldShowAdsForCurrentUser)")
        print("ðŸŽ¯ GameLogicManager: \(useNewGameLogicManager ? "NEW" : "OLD") system")
        print("ðŸ—‚ï¸ DataManager: \(useNewDataManager ? "NEW" : "OLD") system")
#endif
    }
    
    // MARK: - App Store Configuration
    
    static let appStoreID = "6746332040"
    static let appStoreURL = "https://apps.apple.com/app/id6746332040"
    
    // MARK: - iOS Version support
    static let minimumIOSVersion = "15.6"
    
    // MARK: - Support and Legal
    
    static let supportEmail = "luckyfootballslip@gmail.com"
    static let privacyPolicyURL = "https://lucky-football-slip.netlify.app/#privacy"
    static let termsOfServiceURL = "https://lucky-football-slip.netlify.app/#terms"
}

// MARK: - Production Control (No Server Required)
extension AppConfig {
    /// Set this to true when you want to enable free testing for everyone
    /// Change this value and release an app update to control the feature
    private static let PRODUCTION_FREE_TESTING_ENABLED = true // â† Change this to true/false
    
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
