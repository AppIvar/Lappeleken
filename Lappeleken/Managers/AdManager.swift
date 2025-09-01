//
//  AdManager.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 22/05/2025.
//

import Foundation
import GoogleMobileAds
import UIKit

@MainActor
class AdManager: NSObject, ObservableObject {
    static let shared = AdManager()
    
    @Published var isAdLoaded = false
    @Published var isShowingAd = false
    @Published var isRewardedReady = false
    @Published var isBannerReady = false
    
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    
    // MARK: - Ad Unit IDs
    private struct AdUnitIDs {
        // Test IDs
        static let interstitialTest = "ca-app-pub-3940256099942544/1033173712"
        static let rewardedTest = "ca-app-pub-3940256099942544/5224354917"
        static let bannerTest = "ca-app-pub-3940256099942544/6300978111"
        
        // Production IDs
        static let interstitialProd = "ca-app-pub-5153687741487701/9783120087"
        static let rewardedProd = "ca-app-pub-5153687741487701/5916027268"
        static let bannerProd = "ca-app-pub-5153687741487701/5033356288"
        
        // Toggle between test and production
        static let useProductionAds = true // Set to true for production
        
        static var interstitial: String {
            let adUnit = useProductionAds ? interstitialProd : interstitialTest
            print("🎯 Using \(useProductionAds ? "PRODUCTION" : "TEST") interstitial ad unit: \(adUnit)")
            return adUnit
        }
        
        static var rewarded: String {
            let adUnit = useProductionAds ? rewardedProd : rewardedTest
            print("🎯 Using \(useProductionAds ? "PRODUCTION" : "TEST") rewarded ad unit: \(adUnit)")
            return adUnit
        }
        
        static var banner: String {
            let adUnit = useProductionAds ? bannerProd : bannerTest
            print("🎯 Using \(useProductionAds ? "PRODUCTION" : "TEST") banner ad unit: \(adUnit)")
            return adUnit
        }
    }
    
    // MARK: - Feature Flag Integration
    
    /// Should show ads for current user based on feature flags
    var shouldShowAdsForUser: Bool {
        return AppConfig.shouldShowAdsForCurrentUser
    }
    
    /// Should show banner ads specifically
    var shouldShowBannerAds: Bool {
        return AppConfig.AdSettings.showBannerAds && shouldShowAdsForUser
    }
    
    /// Should show interstitial ads specifically
    var shouldShowInterstitialAds: Bool {
        return AppConfig.AdSettings.showInterstitialAds && shouldShowAdsForUser
    }
    
    /// Should show rewarded ads specifically
    var shouldShowRewardedAds: Bool {
        return AppConfig.AdSettings.showRewardedAds && shouldShowAdsForUser
    }
    
    // MARK: - Event-Based Ad System Properties
    
    private var liveMatchEventCount: Int {
        get {
            return UserDefaults.standard.integer(forKey: "liveMatchEventCount")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "liveMatchEventCount")
        }
    }
    
    private var eventsUntilNextAd: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: "eventsUntilNextAd")
            if stored == 0 {
                // First time - set random threshold between 2-3 events
                let threshold = Int.random(in: 2...3)
                UserDefaults.standard.set(threshold, forKey: "eventsUntilNextAd")
                return threshold
            }
            return stored
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "eventsUntilNextAd")
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        print("🎯 AdManager initializing...")
        print("🔍 App Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        print("🔍 Production Ads Enabled: \(AdUnitIDs.useProductionAds)")
        print("🎯 Ads enabled for user: \(shouldShowAdsForUser)")
        
        Task {
            await initializeAds()
        }
    }
    
    func initializeAds() async {
        print("🎯 Starting AdMob initialization...")
        
        // Configure request configuration for better debugging
        let requestConfiguration = MobileAds.shared.requestConfiguration
        
        // Add test device IDs for production testing
#if DEBUG
        requestConfiguration.testDeviceIdentifiers = [
            "YOUR_TEST_DEVICE_ID" // Replace with actual test device ID
        ]
        print("🔍 Test device IDs configured for debug mode")
#endif
        
        // Start AdMob initialization using async/await
        do {
            let initializationStatus = try await MobileAds.shared.start()
            print("✅ AdMob initialized successfully")
            print("🔍 Adapter statuses:")
            
            let adapterStatuses = initializationStatus.adapterStatusesByClassName
            for (adapterName, status) in adapterStatuses {
                print("  - \(adapterName): \(status.state.rawValue) - \(status.description)")
            }
            
            // Load ads after successful initialization
            await loadInterstitialAd()
            await loadRewardedAd()
        } catch {
            print("❌ Failed to initialize AdMob: \(error)")
            // Still try to load ads even if initialization fails
            await loadInterstitialAd()
            await loadRewardedAd()
        }
    }
    
    // MARK: - Ad Loading
    
    private func loadInterstitialAd() async {
        guard shouldShowInterstitialAds else {
            print("💡 Interstitial ads disabled by feature flags")
            return
        }
        
        print("🎯 Loading interstitial ad...")
        print("🔍 Ad Unit ID: \(AdUnitIDs.interstitial)")
        
        let request = Request()
        
        do {
            let ad = try await InterstitialAd.load(with: AdUnitIDs.interstitial, request: request)
            interstitialAd = ad
            interstitialAd?.fullScreenContentDelegate = self
            
            await MainActor.run {
                self.isAdLoaded = true
                print("✅ Interstitial ad loaded successfully")
            }
        } catch {
            await MainActor.run {
                self.isAdLoaded = false
                print("❌ Failed to load interstitial ad: \(error)")
            }
        }
    }
    
    private func loadRewardedAd() async {
        guard shouldShowRewardedAds else {
            print("💡 Rewarded ads disabled by feature flags")
            return
        }
        
        print("🎯 Loading rewarded ad...")
        print("🔍 Ad Unit ID: \(AdUnitIDs.rewarded)")
        
        let request = Request()
        
        do {
            let ad = try await RewardedAd.load(with: AdUnitIDs.rewarded, request: request)
            rewardedAd = ad
            rewardedAd?.fullScreenContentDelegate = self
            
            await MainActor.run {
                self.isRewardedReady = true
                print("✅ Rewarded ad loaded successfully")
            }
        } catch {
            await MainActor.run {
                self.isRewardedReady = false
                print("❌ Failed to load rewarded ad: \(error)")
            }
        }
    }
    
    // MARK: - Live Match Event Tracking
    
    /// Call this when live match events occur (goals, cards, etc.)
    func recordLiveMatchEvent(eventType: String = "match_event") {
        // Only track events if ads are enabled
        guard shouldShowAdsForUser else {
            print("ℹ️ Ads disabled - no event tracking")
            return
        }
        
        liveMatchEventCount += 1
        print("📊 Live event recorded: \(eventType). Total events: \(liveMatchEventCount)")
        
        // Show ads based on frequency
        if shouldShowAdAfterLiveEvent() {
            showEventBasedInterstitial()
        }
    }
    
    private func shouldShowAdAfterLiveEvent() -> Bool {
        let currentEvents = liveMatchEventCount
        let threshold = eventsUntilNextAd
        
        print("🎯 Events: \(currentEvents), Threshold: \(threshold)")
        
        if currentEvents >= threshold {
            // Reset for next ad cycle
            resetEventCounting()
            return isAdLoaded && shouldShowInterstitialAds
        }
        
        return false
    }
    
    private func resetEventCounting() {
        liveMatchEventCount = 0
        eventsUntilNextAd = Int.random(in: 2...3) // Show ad every 2-3 events
        print("🔄 Event counting reset. Next ad in \(eventsUntilNextAd) events")
        
        // Track ad frequency during free testing
        if AppConfig.isFreeLiveTestingActive {
            let key = "freeTestingAdsShown_\(DateFormatter.yyyyMMdd.string(from: Date()))"
            let currentCount = UserDefaults.standard.integer(forKey: key)
            UserDefaults.standard.set(currentCount + 1, forKey: key)
        }
    }
    
    private func showEventBasedInterstitial() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("❌ Cannot get root view controller for event-based ad")
            return
        }
        
        print("🎯 Showing event-based interstitial ad")
        
        showInterstitialAd(from: rootViewController) { [weak self] success in
            Task { @MainActor in
                if success {
                    print("✅ Event-based interstitial shown successfully")
                    self?.trackAdImpression(type: "interstitial_live_event")
                } else {
                    print("❌ Failed to show event-based interstitial")
                    // Don't reset counter if ad failed to show
                    self?.liveMatchEventCount -= 1
                }
            }
        }
    }
    
    // MARK: - Session Management
    
    /// Call when starting a new live match
    func startNewLiveMatchSession() {
        liveMatchEventCount = 0
        eventsUntilNextAd = Int.random(in: 2...3)
        print("🎮 New live match session started. First ad in \(eventsUntilNextAd) events")
        
        // Track session starts during free testing
        if AppConfig.isFreeLiveTestingActive {
            let key = "freeTestingSessions_\(DateFormatter.yyyyMMdd.string(from: Date()))"
            let currentCount = UserDefaults.standard.integer(forKey: key)
            UserDefaults.standard.set(currentCount + 1, forKey: key)
            print("📊 Free testing session tracked: \(currentCount + 1) today")
        }
    }
    
    /// Call when ending a live match
    func endLiveMatchSession() {
        print("🏁 Live match session ended. Events recorded: \(liveMatchEventCount)")
    }
    
    // MARK: - Interstitial Ads
    
    func showInterstitialAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard shouldShowInterstitialAds else {
            print("ℹ️ Interstitial ads disabled by feature flags")
            completion(true)
            return
        }
        
        guard let interstitialAd = interstitialAd, !isShowingAd else {
            print("❌ Interstitial ad not ready or already showing")
            completion(false)
            return
        }
        
        isShowingAd = true
        print("🎯 Presenting interstitial ad")
        
        // Store completion for delegate callback
        self.interstitialCompletion = completion
        
        interstitialAd.present(from: viewController)
    }
    
    private var interstitialCompletion: ((Bool) -> Void)?
    
    // MARK: - Rewarded Ads
    
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard shouldShowRewardedAds else {
            print("ℹ️ Rewarded ads disabled by feature flags")
            completion(false)
            return
        }
        
        guard let rewardedAd = rewardedAd else {
            print("❌ Rewarded ad not loaded")
            completion(false)
            return
        }
        
        isShowingAd = true
        rewardedAd.present(from: viewController, userDidEarnRewardHandler: { [weak self] in
            print("✅ User earned reward")
            Task { @MainActor in
                completion(true)
                self?.trackAdImpression(type: "rewarded")
            }
        })
    }
    
    func showRewardedAdForExtraMatch(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard shouldShowRewardedAds else {
            print("ℹ️ Rewarded ads disabled by feature flags")
            completion(false)
            return
        }
        
        guard isRewardedReady else {
            print("❌ Rewarded ad not ready")
            completion(false)
            return
        }
        
        print("🎯 Showing rewarded ad for extra daily match")
        
        showRewardedAd(from: viewController) { success in
            if success {
                AppPurchaseManager.shared.grantAdRewardedMatch()
                print("✅ Extra daily match granted via ad")
            }
            completion(success)
        }
    }
    
    // MARK: - Banner Ads
    
    func getBannerAdUnitID() -> String {
        return AdUnitIDs.banner
    }
    
    // MARK: - Legacy Ad Methods (Keep for compatibility)
    
    func shouldShowInterstitialAfterGameComplete() -> Bool {
        guard shouldShowInterstitialAds else { return false }
        
        let gameCount = UserDefaults.standard.integer(forKey: "completedGameCount")
        UserDefaults.standard.set(gameCount + 1, forKey: "completedGameCount")
        
        // Show ad every 2nd game completion
        let shouldShow = gameCount > 0 && gameCount % 2 == 0
        
        if shouldShow {
            recordInterstitialShown(for: "game_complete")
        }
        
        return shouldShow
    }
    
    func shouldShowInterstitialForHistoryView() -> Bool {
        guard shouldShowInterstitialAds else { return false }
        return shouldShowInterstitialWithCooldown(for: "history_view", cooldownMinutes: 5)
    }
    
    func shouldShowInterstitialForSettings() -> Bool {
        guard shouldShowInterstitialAds else { return false }
        return shouldShowInterstitialWithCooldown(for: "settings_view", cooldownMinutes: 10)
    }
    
    private func shouldShowInterstitialWithCooldown(for key: String, cooldownMinutes: Int) -> Bool {
        let lastShownKey = "lastInterstitial_\(key)"
        let lastShown = UserDefaults.standard.double(forKey: lastShownKey)
        let now = Date().timeIntervalSince1970
        let cooldownSeconds = Double(cooldownMinutes * 60)
        
        let shouldShow = (now - lastShown) > cooldownSeconds
        
        if shouldShow {
            recordInterstitialShown(for: key)
        }
        
        return shouldShow
    }
    
    private func recordInterstitialShown(for key: String) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastInterstitial_\(key)")
    }
    
    // MARK: - Analytics and Tracking
    
    func trackAdImpression(type: String) {
        let key = "adImpressions_\(type)"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
        
        print("📈 Ad impression tracked: \(type) (total: \(current + 1))")
    }
    
    func recordViewTransition(from: String, to: String) {
        let key = "viewTransition_\(from)_to_\(to)"
        let count = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(count + 1, forKey: key)
        
        print("📊 View transition: \(from) → \(to) (count: \(count + 1))")
    }
    
    func getAdStats() -> [String: Int] {
        return [
            "interstitial": UserDefaults.standard.integer(forKey: "adImpressions_interstitial"),
            "interstitial_live_event": UserDefaults.standard.integer(forKey: "adImpressions_interstitial_live_event"),
            "rewarded": UserDefaults.standard.integer(forKey: "adImpressions_rewarded"),
            "banner": UserDefaults.standard.integer(forKey: "adImpressions_banner")
        ]
    }
    
    func getLiveEventStats() -> (currentEvents: Int, eventsUntilAd: Int, adsShown: Int) {
        let adsShown = UserDefaults.standard.integer(forKey: "adImpressions_interstitial_live_event")
        return (liveMatchEventCount, eventsUntilNextAd, adsShown)
    }
    
    // MARK: - Free Testing Analytics
    
    func getFreeTestingAdAnalytics() -> [String: Any] {
        guard AppConfig.isFreeLiveTestingActive else {
            return ["error": "Free testing not active"]
        }
        
        let today = DateFormatter.yyyyMMdd.string(from: Date())
        let adsToday = UserDefaults.standard.integer(forKey: "freeTestingAdsShown_\(today)")
        let sessionsToday = UserDefaults.standard.integer(forKey: "freeTestingSessions_\(today)")
        
        return [
            "adsShownToday": adsToday,
            "sessionsToday": sessionsToday,
            "adFrequency": "Every 2-3 events",
            "currentEventCount": liveMatchEventCount,
            "eventsUntilNextAd": eventsUntilNextAd
        ]
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("✅ Ad dismissed")
        Task { @MainActor in
            self.isShowingAd = false
            
            // Call completion if available
            if let completion = self.interstitialCompletion {
                completion(true)
                self.interstitialCompletion = nil
            }
            
            // Reload the ad for next time
            if ad is InterstitialAd {
                await self.loadInterstitialAd()
            } else if ad is RewardedAd {
                await self.loadRewardedAd()
            }
        }
    }
    
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("❌ Ad failed to present: \(error)")
        Task { @MainActor in
            self.isShowingAd = false
            
            // Call completion with failure
            if let completion = self.interstitialCompletion {
                completion(false)
                self.interstitialCompletion = nil
            }
            
            // Reload the ad
            if ad is InterstitialAd {
                await self.loadInterstitialAd()
            } else if ad is RewardedAd {
                await self.loadRewardedAd()
            }
        }
    }
    
    nonisolated func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("📱 Ad will present")
        Task { @MainActor in
            self.isShowingAd = true
        }
    }
    
    nonisolated func adDidRecordImpression(_ ad: FullScreenPresentingAd) {
        print("📊 Ad recorded impression")
    }
    
    nonisolated func adDidRecordClick(_ ad: FullScreenPresentingAd) {
        print("🖱️ Ad recorded click")
    }
}
