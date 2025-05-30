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
    
    // MARK: - Ad Unit IDs with better debugging
    private struct AdUnitIDs {
        // Test IDs
        static let interstitialTest = "ca-app-pub-3940256099942544/1033173712"
        static let rewardedTest = "ca-app-pub-3940256099942544/5224354917"
        static let bannerTest = "ca-app-pub-3940256099942544/6300978111"
        
        // Your production IDs
        static let interstitialProd = "ca-app-pub-5153687741487701/9783120087"
        static let rewardedProd = "ca-app-pub-5153687741487701/5916027268"
        static let bannerProd = "ca-app-pub-5153687741487701/5033356288"
        
        // Toggle between test and production
        static let useProductionAds = false // Set to true for production
        
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
    
    // MARK: - Enhanced Initialization
    
    override init() {
        super.init()
        print("🎯 AdManager initializing...")
        print("🔍 App Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        print("🔍 Production Ads Enabled: \(AdUnitIDs.useProductionAds)")
        
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
            "YOUR_TEST_DEVICE_ID" // Replace with your actual test device ID
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
    
    // MARK: - Enhanced Interstitial Ads
    
    private func loadInterstitialAd() async {
        print("🎯 Loading interstitial ad...")
        print("🔍 Ad Unit ID: \(AdUnitIDs.interstitial)")
        
        let request = Request()
        
        // Add request debugging
        print("🔍 Request created successfully")
        
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
                
                // More specific error handling
                if let gadError = error as NSError? {
                    print("🔍 GAD Error Code: \(gadError.code)")
                    print("🔍 GAD Error Domain: \(gadError.domain)")
                    print("🔍 GAD Error Description: \(gadError.localizedDescription)")
                    
                    print("💡 Error details: \(gadError.localizedDescription)")
                    if gadError.localizedDescription.lowercased().contains("no fill") {
                        print("💡 Suggestion: Try again later or check ad unit configuration")
                    } else if gadError.localizedDescription.lowercased().contains("network") {
                        print("💡 Suggestion: Check internet connection")
                    }
                }
            }
        }
    }
    
    func showInterstitialAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let interstitialAd = interstitialAd else {
            print("❌ Interstitial ad not loaded yet.")
            completion(false)
            return
        }
     
        // Check if user is premium
        guard AppPurchaseManager.shared.currentTier == .free else {
            print("ℹ️ User is premium, skipping interstitial ad")
            completion(true)
            return
        }
        
        print("🎯 Presenting interstitial ad...")
        isShowingAd = true
        interstitialAd.present(from: viewController)
        
        // Call completion after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(true)
        }
    }
    
    // MARK: - Enhanced Rewarded Ads
    
    private func loadRewardedAd() async {
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
                
                // Same detailed error handling as interstitial
                if let gadError = error as NSError? {
                    print("🔍 GAD Error Code: \(gadError.code)")
                    print("🔍 GAD Error Description: \(gadError.localizedDescription)")
                }
            }
        }
    }
    
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
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
                self?.grantFreeLiveMatchFromAd()
            }
        })
    }
    
    func debugAdLoading() async {
        print("🧪 Debug: Testing ad loading...")
        print("🔍 Current ad states:")
        print("  - Interstitial loaded: \(isAdLoaded)")
        print("  - Rewarded ready: \(isRewardedReady)")
        print("  - Banner ready: \(isBannerReady)")
        
        await loadInterstitialAd()
        await loadRewardedAd()
    }
    
    // MARK: - Ad Strategy Methods
    
    func shouldShowInterstitialAfterPlayerAssignment() -> Bool {
        guard AppPurchaseManager.shared.currentTier == .free else { return false }
        
        return shouldShowInterstitialWithCooldown(for: "player_assignment", cooldownMinutes: 15)
    }

    func shouldShowInterstitialAfterGameSetup() -> Bool {
        guard AppPurchaseManager.shared.currentTier == .free else { return false }
        
        // Show ad when starting a new game, but not too frequently
        return shouldShowInterstitialWithCooldown(for: "game_setup", cooldownMinutes: 20)
    }

    func shouldShowInterstitialBeforeGameSummary() -> Bool {
        guard AppPurchaseManager.shared.currentTier == .free else { return false }
        
        // Show ad before showing game summary (less intrusive than after game ends)
        return shouldShowInterstitialWithCooldown(for: "game_summary", cooldownMinutes: 10)
    }
    
    func shouldShowAfterEventsWithSmartTiming() -> Bool {
        guard AppPurchaseManager.shared.currentTier == .free else { return false }
        
        let eventCount = UserDefaults.standard.integer(forKey: "totalEventsRecorded")
        let lastAdShown = UserDefaults.standard.double(forKey: "lastInterstitial_events")
        let now = Date().timeIntervalSince1970
        
        // More sophisticated logic:
        // - Show after every 3rd event, but with cooldown
        // - Don't show if ad was shown in last 2 minutes
        // - Reduce frequency for very active sessions
        
        let shouldShowBasedOnCount = eventCount > 0 && eventCount % 3 == 0
        let cooldownExpired = (now - lastAdShown) > 120 // 2 minutes
        
        // If user is very active (more than 10 events), increase threshold to every 5th event
        let adjustedThreshold = eventCount > 10 ? 5 : 3
        let shouldShowWithAdjustment = eventCount > 0 && eventCount % adjustedThreshold == 0
        
        if shouldShowWithAdjustment && cooldownExpired {
            recordInterstitialShown(for: "events", withContext: "count_\(eventCount)")
            return true
        }
        
        return false
    }
    
    func shouldShowInterstitialForContinueGame() -> Bool {
        guard AppPurchaseManager.shared.currentTier == .free else { return false }
        
        // Show ad when continuing a saved game, but with cooldown to avoid annoyance
        return shouldShowInterstitialWithCooldown(for: "continue_game", cooldownMinutes: 3)
    }
    
    private func recordInterstitialShown(for key: String, withContext context: String = "") {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastInterstitial_\(key)")
        
        // Track additional context for analytics
        if !context.isEmpty {
            let contextKey = "adContext_\(key)"
            var contexts = UserDefaults.standard.array(forKey: contextKey) as? [String] ?? []
            contexts.append("\(context)_\(Date().timeIntervalSince1970)")
            
            // Keep only last 10 contexts to avoid storage bloat
            if contexts.count > 10 {
                contexts = Array(contexts.suffix(10))
            }
            
            UserDefaults.standard.set(contexts, forKey: contextKey)
        }
        
        print("📊 Recorded interstitial shown for: \(key) with context: \(context)")
    }
    
    // MARK: - Game Flow Integration Methods

    func showInterstitialForGameFlow(_ flowType: GameFlowType, from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        let shouldShow: Bool
        
        switch flowType {
        case .playerAssignment:
            shouldShow = shouldShowInterstitialAfterPlayerAssignment()
        case .gameSetup:
            shouldShow = shouldShowInterstitialAfterGameSetup()
        case .beforeSummary:
            shouldShow = shouldShowInterstitialBeforeGameSummary()
        }
        
        if shouldShow {
            showInterstitialAd(from: viewController, completion: completion)
        } else {
            completion(true) // Continue without ad
        }
    }

    enum GameFlowType {
        case playerAssignment
        case gameSetup
        case beforeSummary
    }
    
    // MARK: - Banner Ads
    
    func getBannerAdUnitID() -> String {
        return AdUnitIDs.banner
    }
    
    // MARK: - Legacy Ad Strategy Methods
    
    func shouldShowInterstitialAfterGameComplete() -> Bool {
        guard AppPurchaseManager.shared.currentTier == .free else { return false }
        
        let gameCount = UserDefaults.standard.integer(forKey: "completedGameCount")
        UserDefaults.standard.set(gameCount + 1, forKey: "completedGameCount")
        
        // Show ad every 2nd game completion, but with some randomness
        let shouldShow = gameCount > 0 && gameCount % 2 == 0 && Int.random(in: 1...10) <= 7
        
        if shouldShow {
            recordInterstitialShown(for: "game_complete")
        }
        
        return shouldShow
    }
    
    func shouldShowInterstitialForHistoryView() -> Bool {
        guard AppPurchaseManager.shared.currentTier == .free else { return false }
        
        return shouldShowInterstitialWithCooldown(for: "history_view", cooldownMinutes: 5)
    }
    
    func shouldShowInterstitialForSettings() -> Bool {
        guard AppPurchaseManager.shared.currentTier == .free else { return false }
        
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
    
    func shouldShowAfterEvents() -> Bool {
        let eventCount = UserDefaults.standard.integer(forKey: "totalEventsRecorded")
        UserDefaults.standard.set(eventCount + 1, forKey: "totalEventsRecorded")
        
        print("📊 Event count incremented to: \(eventCount + 1)")
        
        // Show ad every 8 events for free users (less aggressive)
        return eventCount > 0 && eventCount % 8 == 0 && AppPurchaseManager.shared.currentTier == .free
    }
    
    func canWatchAdForFreeLiveMatch() -> Bool {
        return AppPurchaseManager.shared.currentTier == .free && isRewardedReady
    }
    
    func grantFreeLiveMatchFromAd() {
        let current = UserDefaults.standard.integer(forKey: "adRewardedLiveMatches")
        UserDefaults.standard.set(current + 1, forKey: "adRewardedLiveMatches")
        
        print("✅ Granted free live match from ad. Total: \(current + 1)")
        
        // Update AppPurchaseManager to reflect the change
        AppPurchaseManager.shared.objectWillChange.send()
    }
    
    // MARK: - Ad Performance Tracking
    
    func trackAdImpression(type: String) {
        let key = "adImpressions_\(type)"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
        
        print("📈 Ad impression tracked: \(type) (total: \(current + 1))")
    }
    
    func getAdStats() -> [String: Int] {
        return [
            "interstitial": UserDefaults.standard.integer(forKey: "adImpressions_interstitial"),
            "rewarded": UserDefaults.standard.integer(forKey: "adImpressions_rewarded"),
            "banner": UserDefaults.standard.integer(forKey: "adImpressions_banner")
        ]
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        print("✅ Ad dismissed")
        Task { @MainActor in
            self.isShowingAd = false
            
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
