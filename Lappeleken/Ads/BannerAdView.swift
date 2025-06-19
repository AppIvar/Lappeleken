//
//  BannerAdView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 22/05/2025.
//

import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    @State private var adHeight: CGFloat = 50
    @State private var isLoaded = false
    
    init() {
        self.adUnitID = AdManager.shared.getBannerAdUnitID()
    }
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = UIColor.clear
        
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.delegate = context.coordinator
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        
        // Get the root view controller safely
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        
        containerView.addSubview(bannerView)
        
        // Set up constraints
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            bannerView.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor),
            bannerView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Load the ad
        context.coordinator.loadAd(bannerView: bannerView)
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        private var retryCount = 0
        private let maxRetries = 2
        private var bannerView: BannerView?
        private var retryTimer: Timer?
        
        func loadAd(bannerView: BannerView) {
            self.bannerView = bannerView
            
            let request = Request()
            print("🎯 Loading banner ad with unit ID: \(bannerView.adUnitID ?? "Unknown")")
            bannerView.load(request)
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ Banner ad loaded successfully")
            retryCount = 0
            retryTimer?.invalidate()
            retryTimer = nil
            
            AdManager.shared.trackAdImpression(type: "banner")
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Banner ad failed to load: \(error)")
            
            if shouldRetry(error: error) && retryCount < maxRetries {
                retryCount += 1
                let delay = pow(2.0, Double(retryCount)) // Exponential backoff: 2s, 4s
                
                print("⏳ Retrying banner ad in \(delay) seconds (attempt \(retryCount)/\(maxRetries))")
                
                retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    self?.loadAd(bannerView: bannerView)
                }
            } else {
                print("❌ Banner ad failed after \(retryCount) retries")
            }
        }
        
        private func shouldRetry(error: Error) -> Bool {
            let nsError = error as NSError
            
            switch nsError.code {
            case -1005: // Network connection lost
                return true
            case -1001: // Request timeout
                return true
            case 2: // No ad to show (AdMob)
                return false // Don't retry no-fill errors
            default:
                return false
            }
        }
        
        deinit {
            retryTimer?.invalidate()
        }
        
        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            print("📊 Banner ad recorded impression")
        }
        
        func bannerViewDidRecordClick(_ bannerView: BannerView) {
            print("🖱️ Banner ad was clicked")
        }
    }
}

// MARK: - Enhanced View Extensions for Optimal Banner Placement

extension View {
    /// Add banner ad at bottom for general views
    @MainActor
    func withSmartBanner() -> some View {
        Group {
            if AppPurchaseManager.shared.currentTier == .free {
                VStack(spacing: 0) {
                    self
                    
                    // Smart banner with better UX
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.gray.opacity(0.2))
                        
                        BannerAdView()
                            .frame(height: 50)
                            .background(Color(UIColor.systemBackground))
                            .overlay(
                                Rectangle()
                                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
            } else {
                self
            }
        }
    }
    
    /// Add banner for tab views with transition tracking
    @MainActor
    func withTabBanner(tabName: String) -> some View {
        Group {
            if AppPurchaseManager.shared.currentTier == .free {
                VStack(spacing: 0) {
                    self
                        .onAppear {
                            // Track tab views for analytics
                            AdManager.shared.recordViewTransition(from: "previous", to: tabName)
                        }
                    
                    // Tab-specific banner
                    VStack(spacing: 0) {
                        Divider()
                            .background(Color.gray.opacity(0.15))
                        
                        BannerAdView()
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [
                                        Color(UIColor.systemBackground),
                                        Color(UIColor.systemBackground).opacity(0.95)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                }
            } else {
                self
                    .onAppear {
                        print("📊 Premium user viewing tab: \(tabName)")
                    }
            }
        }
    }
    
    /// Minimal banner for critical user flows (less obtrusive)
    @MainActor
    func withMinimalBanner() -> some View {
        Group {
            if AppPurchaseManager.shared.currentTier == .free {
                VStack(spacing: 0) {
                    self
                    
                    // Minimal banner design
                    BannerAdView()
                        .frame(height: 50)
                        .background(Color.clear)
                        .opacity(0.9) // Slightly transparent for less obtrusiveness
                }
            } else {
                self
            }
        }
    }
    
    /// Show upgrade prompt instead of banner occasionally
    @MainActor
    func withSmartMonetization() -> some View {
        Group {
            if AppPurchaseManager.shared.currentTier == .free {
                VStack(spacing: 0) {
                    self
                    
                    // Randomly show upgrade prompt vs banner (20% upgrade, 80% banner)
                    if shouldShowUpgradePrompt() {
                        UpgradePromptBanner()
                    } else {
                        BannerAdView()
                            .frame(height: 50)
                    }
                }
            } else {
                self
            }
        }
    }
    
    private func shouldShowUpgradePrompt() -> Bool {
        // Show upgrade prompt 20% of the time, but not more than once per session
        let hasShownThisSession = UserDefaults.standard.bool(forKey: "upgradePromptShownThisSession")
        guard !hasShownThisSession else { return false }
        
        let shouldShow = Int.random(in: 1...10) <= 2 // 20% chance
        if shouldShow {
            UserDefaults.standard.set(true, forKey: "upgradePromptShownThisSession")
        }
        return shouldShow
    }
}

// MARK: - Upgrade Prompt Banner Component

struct UpgradePromptBanner: View {
    @ObservedObject private var purchaseManager = AppPurchaseManager.shared
    @State private var showUpgradeView = false
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.2))
            
            HStack(spacing: 12) {
                Image(systemName: "star.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 16))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Go Premium")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Unlimited matches • No ads • $2.99/month")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Upgrade") {
                    showUpgradeView = true
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground))
        }
        .frame(height: 50)
        .sheet(isPresented: $showUpgradeView) {
            UpgradeView()
        }
    }
}

// MARK: - Helper Enums

enum BannerPlacement {
    case top
    case bottom
}

enum InterstitialTrigger {
    case gameComplete
    case historyView
    case settingsView
    case random
}

// MARK: - Legacy View Extension (Keep for backward compatibility)

extension View {
    @MainActor
    func showBannerAdForFreeUsers() -> some View {
        withSmartBanner()
    }
    
    @MainActor
    func withBannerAd(placement: BannerPlacement = .bottom) -> some View {
        withSmartBanner()
    }
    
    @MainActor
    func withInterstitialAd(trigger: InterstitialTrigger) -> some View {
        self.onAppear {
            Task { @MainActor in
                showInterstitialIfNeeded(for: trigger)
            }
        }
    }
    
    private func showInterstitialIfNeeded(for trigger: InterstitialTrigger) {
        guard AppPurchaseManager.shared.currentTier == .free else { return }
        
        let shouldShow = switch trigger {
        case .gameComplete:
            AdManager.shared.shouldShowInterstitialAfterGameComplete()
        case .historyView:
            AdManager.shared.shouldShowInterstitialForHistoryView()
        case .settingsView:
            AdManager.shared.shouldShowInterstitialForSettings()
        case .random:
            Int.random(in: 1...10) <= 3 // 30% chance
        }
        
        if shouldShow {
            showInterstitialAd()
        }
    }
    
    private func showInterstitialAd() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        Task { @MainActor in
            AdManager.shared.showInterstitialAd(from: rootViewController) { success in
                if success {
                    print("✅ Interstitial ad shown successfully")
                    AdManager.shared.trackAdImpression(type: "interstitial")
                } else {
                    print("❌ Failed to show interstitial ad")
                }
            }
        }
    }
}

/*
USAGE EXAMPLES:

// For main navigation tabs
TimelineView()
    .withTabBanner(tabName: "Timeline")

// For general content views
SomeContentView()
    .withSmartBanner()

// For critical user flows (payments, onboarding)
PaymentView()
    .withMinimalBanner()

// For high-value conversion opportunities
MainMenuView()
    .withSmartMonetization()
*/
