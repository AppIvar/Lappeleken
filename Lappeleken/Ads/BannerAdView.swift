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
        private let maxRetries = 3
        private var bannerView: BannerView?
        
        func loadAd(bannerView: BannerView) {
            self.bannerView = bannerView
            
            let request = Request()
            bannerView.load(request)
            print("🎯 Loading banner ad (attempt \(retryCount + 1))")
        }
        
        func bannerViewDidReceiveAd(_ bannerView: BannerView) {
            print("✅ Banner ad loaded successfully")
            retryCount = 0
            AdManager.shared.trackAdImpression(type: "banner")
        }
        
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            print("❌ Banner ad failed to load: \(error.localizedDescription)")
            
            if shouldRetry(error: error) && retryCount < maxRetries {
                retryCount += 1
                print("🔄 Retrying banner ad load in 5 seconds (attempt \(retryCount + 1)/\(maxRetries))")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.loadAd(bannerView: bannerView)
                }
            } else {
                print("⚠️ Banner ad loading failed permanently after \(retryCount + 1) attempts")
            }
        }
        
        func bannerViewDidRecordImpression(_ bannerView: BannerView) {
            print("📊 Banner ad recorded impression")
        }
        
        func bannerViewDidRecordClick(_ bannerView: BannerView) {
            print("🖱️ Banner ad was clicked")
        }
        
        private func shouldRetry(error: Error) -> Bool {
            let nsError = error as NSError
            let retryableErrors = [-1009, -1001, -1017, 2]
            return retryableErrors.contains(nsError.code)
        }
    }
}

// MARK: - Enhanced View Extensions

extension View {
    @MainActor
    func showBannerAdForFreeUsers() -> some View {
        VStack(spacing: 0) {
            self
            
            // Only show banner for free users
            if AppPurchaseManager.shared.currentTier == .free {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    BannerAdView()
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.05))
                }
            }
        }
    }
    
    @MainActor
    func withBannerAd(placement: BannerPlacement = .bottom) -> some View {
        Group {
            if AppPurchaseManager.shared.currentTier == .free {
                VStack(spacing: 0) {
                    if placement == .top {
                        bannerAdSection
                    }
                    
                    self
                    
                    if placement == .bottom {
                        bannerAdSection
                    }
                }
            } else {
                self
            }
        }
    }
    
    private var bannerAdSection: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.gray.opacity(0.3))
            
            BannerAdView()
                .frame(height: 50)
                .background(Color.gray.opacity(0.05))
        }
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
