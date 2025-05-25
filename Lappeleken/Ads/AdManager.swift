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
        
        // Your production IDs
        static let interstitialProd = "ca-app-pub-5153687741487701/9783120087"
        static let rewardedProd = "ca-app-pub-5153687741487701/5916027268"
        static let bannerProd = "ca-app-pub-5153687741487701/5033356288"
        
        // Toggle between test and production
        static let useProductionAds = false // Set to true for production
        
        static var interstitial: String {
            return useProductionAds ? interstitialProd : interstitialTest
        }
        
        static var rewarded: String {
            return useProductionAds ? rewardedProd : rewardedTest
        }
        
        static var banner: String {
            return useProductionAds ? bannerProd : bannerTest
        }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        Task {
            await initializeAds()
        }
    }
    
    func initializeAds() async {
        await MobileAds.shared.start()
        print("✅ AdMob initialized")
        await loadInterstitialAd()
        await loadRewardedAd()
    }
    
    // MARK: - Interstitial Ads
    
    private func loadInterstitialAd() async {
        let request = Request()
        
        do {
            interstitialAd = try await InterstitialAd.load(with: AdUnitIDs.interstitial, request: request)
            interstitialAd?.fullScreenContentDelegate = self
            isAdLoaded = true
            print("✅ Interstitial ad loaded with ID: \(AdUnitIDs.interstitial)")
        } catch {
            print("❌ Failed to load interstitial ad: \(error)")
            isAdLoaded = false
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
        
        isShowingAd = true
        interstitialAd.present(from: viewController)
        
        // Call completion after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(true)
        }
    }
    
    // MARK: - Rewarded Ads
    
    private func loadRewardedAd() async {
        let request = Request()
        
        do {
            rewardedAd = try await RewardedAd.load(with: AdUnitIDs.rewarded, request: request)
            rewardedAd?.fullScreenContentDelegate = self
            isRewardedReady = true
            print("✅ Rewarded ad loaded with ID: \(AdUnitIDs.rewarded)")
        } catch {
            print("❌ Failed to load rewarded ad: \(error)")
            isRewardedReady = false
        }
    }
    
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let rewardedAd = rewardedAd else {
            print("❌ Rewarded ad not loaded")
            completion(false)
            return
        }
        
        isShowingAd = true
        rewardedAd.present(from: viewController) { [weak self] in
            print("✅ User earned reward")
            Task { @MainActor in
                completion(true)
                self?.grantFreeLiveMatchFromAd()
            }
        }
    }
    
    // MARK: - Banner Ads
    
    func getBannerAdUnitID() -> String {
        return AdUnitIDs.banner
    }
    
    // MARK: - Ad Strategy Methods
    
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
