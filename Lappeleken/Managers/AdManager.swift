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
    
    private var interstitialAd: InterstitialAd?
    private var rewardedAd: RewardedAd?
    private var interstitialCompletion: ((Bool) -> Void)?
    
    // MARK: - Ad Unit IDs
    
    private struct AdUnitIDs {
        static let interstitialTest = "ca-app-pub-3940256099942544/1033173712"
        static let rewardedTest = "ca-app-pub-3940256099942544/5224354917"
        static let bannerTest = "ca-app-pub-3940256099942544/6300978111"
        
        static let interstitialProd = "ca-app-pub-5153687741487701/9783120087"
        static let rewardedProd = "ca-app-pub-5153687741487701/5916027268"
        static let bannerProd = "ca-app-pub-5153687741487701/5033356288"
        
        static let useProductionAds = false
        
        static var interstitial: String { useProductionAds ? interstitialProd : interstitialTest }
        static var rewarded: String { useProductionAds ? rewardedProd : rewardedTest }
        static var banner: String { useProductionAds ? bannerProd : bannerTest }
    }
    
    // MARK: - Feature Flag Integration
    
    var shouldShowAdsForUser: Bool { AppConfig.shouldShowAdsForCurrentUser }
    var shouldShowBannerAds: Bool { AppConfig.AdSettings.showBannerAds && shouldShowAdsForUser }
    var shouldShowInterstitialAds: Bool { AppConfig.AdSettings.showInterstitialAds && shouldShowAdsForUser }
    var shouldShowRewardedAds: Bool { AppConfig.AdSettings.showRewardedAds && shouldShowAdsForUser }
    
    // MARK: - Event-Based Ad System
    
    private var liveMatchEventCount: Int {
        get { UserDefaults.standard.integer(forKey: "liveMatchEventCount") }
        set { UserDefaults.standard.set(newValue, forKey: "liveMatchEventCount") }
    }
    
    private var eventsUntilNextAd: Int {
        get {
            let stored = UserDefaults.standard.integer(forKey: "eventsUntilNextAd")
            if stored == 0 {
                let threshold = Int.random(in: 2...3)
                UserDefaults.standard.set(threshold, forKey: "eventsUntilNextAd")
                return threshold
            }
            return stored
        }
        set { UserDefaults.standard.set(newValue, forKey: "eventsUntilNextAd") }
    }
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        Task { await initializeAds() }
    }
    
    func initializeAds() async {
        #if DEBUG
        MobileAds.shared.requestConfiguration.testDeviceIdentifiers = ["YOUR_TEST_DEVICE_ID"]
        #endif
        
        do {
            _ = try await MobileAds.shared.start()
            print("✅ AdMob initialized successfully")
            await loadInterstitialAd()
            await loadRewardedAd()
        } catch {
            print("❌ Failed to initialize AdMob: \(error)")
            await loadInterstitialAd()
            await loadRewardedAd()
        }
    }
    
    // MARK: - Ad Loading
    
    private func loadInterstitialAd() async {
        guard shouldShowInterstitialAds else { return }
        
        do {
            let ad = try await InterstitialAd.load(with: AdUnitIDs.interstitial, request: Request())
            interstitialAd = ad
            interstitialAd?.fullScreenContentDelegate = self
            isAdLoaded = true
            print("✅ Interstitial ad loaded")
        } catch {
            isAdLoaded = false
            print("❌ Failed to load interstitial: \(error)")
        }
    }
    
    private func loadRewardedAd() async {
        guard shouldShowRewardedAds else { return }
        
        do {
            let ad = try await RewardedAd.load(with: AdUnitIDs.rewarded, request: Request())
            rewardedAd = ad
            rewardedAd?.fullScreenContentDelegate = self
            isRewardedReady = true
            print("✅ Rewarded ad loaded")
        } catch {
            isRewardedReady = false
            print("❌ Failed to load rewarded: \(error)")
        }
    }
    
    // MARK: - Show Ads
    
    func showInterstitialAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard shouldShowInterstitialAds, let interstitialAd = interstitialAd, !isShowingAd else {
            completion(false)
            return
        }
        
        isShowingAd = true
        interstitialCompletion = completion
        interstitialAd.present(from: viewController)
    }
    
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard shouldShowRewardedAds, let rewardedAd = rewardedAd else {
            completion(false)
            return
        }
        
        isShowingAd = true
        rewardedAd.present(from: viewController) { [weak self] in
            print("✅ User earned reward")
            Task { @MainActor in
                completion(true)
                self?.trackAdImpression(type: "rewarded")
            }
        }
    }
    
    func showRewardedAdForExtraMatch(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard shouldShowRewardedAds, isRewardedReady else {
            completion(false)
            return
        }
        
        showRewardedAd(from: viewController) { success in
            if success {
                AppPurchaseManager.shared.grantAdRewardedMatch()
            }
            completion(success)
        }
    }
    
    func getBannerAdUnitID() -> String { AdUnitIDs.banner }
    
    // MARK: - Interstitial Trigger Logic
    
    func shouldShowInterstitial(for context: InterstitialContext) -> Bool {
        guard shouldShowInterstitialAds else { return false }
        
        switch context {
        case .gameComplete:
            let gameCount = UserDefaults.standard.integer(forKey: "completedGameCount")
            UserDefaults.standard.set(gameCount + 1, forKey: "completedGameCount")
            let shouldShow = gameCount > 0 && gameCount % 2 == 0
            if shouldShow { recordInterstitialShown(for: "game_complete") }
            return shouldShow
            
        case .historyView:
            return shouldShowInterstitialWithCooldown(for: "history_view", cooldownMinutes: 5)
            
        case .settingsView:
            return shouldShowInterstitialWithCooldown(for: "settings_view", cooldownMinutes: 10)
        }
    }
    
    private func shouldShowInterstitialWithCooldown(for key: String, cooldownMinutes: Int) -> Bool {
        let lastShownKey = "lastInterstitial_\(key)"
        let lastShown = UserDefaults.standard.double(forKey: lastShownKey)
        let now = Date().timeIntervalSince1970
        let shouldShow = (now - lastShown) > Double(cooldownMinutes * 60)
        if shouldShow { recordInterstitialShown(for: key) }
        return shouldShow
    }
    
    private func recordInterstitialShown(for key: String) {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastInterstitial_\(key)")
    }
    
    // MARK: - Live Match Event Tracking
    
    func recordLiveMatchEvent(eventType: String = "match_event") {
        guard shouldShowAdsForUser else { return }
        
        liveMatchEventCount += 1
        
        if liveMatchEventCount >= eventsUntilNextAd && isAdLoaded {
            showEventBasedInterstitial()
            resetEventCounting()
        }
    }
    
    private func resetEventCounting() {
        liveMatchEventCount = 0
        eventsUntilNextAd = Int.random(in: 2...3)
        
        if AppConfig.isFreeLiveTestingActive {
            let key = "freeTestingAdsShown_\(DateFormatter.yyyyMMdd.string(from: Date()))"
            let currentCount = UserDefaults.standard.integer(forKey: key)
            UserDefaults.standard.set(currentCount + 1, forKey: key)
        }
    }
    
    private func showEventBasedInterstitial() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else { return }
        
        showInterstitialAd(from: rootViewController) { [weak self] success in
            Task { @MainActor in
                if success {
                    self?.trackAdImpression(type: "interstitial_live_event")
                } else {
                    self?.liveMatchEventCount -= 1
                }
            }
        }
    }
    
    // MARK: - Session Management
    
    func startNewLiveMatchSession() {
        liveMatchEventCount = 0
        eventsUntilNextAd = Int.random(in: 2...3)
        
        if AppConfig.isFreeLiveTestingActive {
            let key = "freeTestingSessions_\(DateFormatter.yyyyMMdd.string(from: Date()))"
            let currentCount = UserDefaults.standard.integer(forKey: key)
            UserDefaults.standard.set(currentCount + 1, forKey: key)
        }
    }
    
    func endLiveMatchSession() {
        print("🏁 Live match session ended. Events: \(liveMatchEventCount)")
    }
    
    // MARK: - Analytics
    
    func trackAdImpression(type: String) {
        let key = "adImpressions_\(type)"
        let current = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(current + 1, forKey: key)
    }
    
    func recordViewTransition(from: String, to: String) {
        let key = "viewTransition_\(from)_to_\(to)"
        let count = UserDefaults.standard.integer(forKey: key)
        UserDefaults.standard.set(count + 1, forKey: key)
    }
    
    func getAdStats() -> [String: Int] {
        [
            "interstitial": UserDefaults.standard.integer(forKey: "adImpressions_interstitial"),
            "interstitial_live_event": UserDefaults.standard.integer(forKey: "adImpressions_interstitial_live_event"),
            "rewarded": UserDefaults.standard.integer(forKey: "adImpressions_rewarded"),
            "banner": UserDefaults.standard.integer(forKey: "adImpressions_banner")
        ]
    }
    
    func getLiveEventStats() -> (currentEvents: Int, eventsUntilAd: Int, adsShown: Int) {
        (liveMatchEventCount, eventsUntilNextAd, UserDefaults.standard.integer(forKey: "adImpressions_interstitial_live_event"))
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.isShowingAd = false
            self.interstitialCompletion?(true)
            self.interstitialCompletion = nil
            
            if ad is InterstitialAd {
                await self.loadInterstitialAd()
            } else if ad is RewardedAd {
                await self.loadRewardedAd()
            }
        }
    }
    
    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            self.isShowingAd = false
            self.interstitialCompletion?(false)
            self.interstitialCompletion = nil
            
            if ad is InterstitialAd {
                await self.loadInterstitialAd()
            } else if ad is RewardedAd {
                await self.loadRewardedAd()
            }
        }
    }
    
    nonisolated func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in self.isShowingAd = true }
    }
    
    nonisolated func adDidRecordImpression(_ ad: FullScreenPresentingAd) {}
    nonisolated func adDidRecordClick(_ ad: FullScreenPresentingAd) {}
}
