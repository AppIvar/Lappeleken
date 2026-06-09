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
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }
        
        containerView.addSubview(bannerView)
        
        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            bannerView.widthAnchor.constraint(lessThanOrEqualTo: containerView.widthAnchor),
            bannerView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        context.coordinator.loadAd(bannerView: bannerView)
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, BannerViewDelegate {
        private var retryCount = 0
        private let maxRetries = 2
        private var retryTimer: Timer?
        
        func loadAd(bannerView: BannerView) {
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
                let delay = pow(2.0, Double(retryCount))
                
                print("⏳ Retrying banner ad in \(delay) seconds (attempt \(retryCount)/\(maxRetries))")
                
                retryTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
                    self?.loadAd(bannerView: bannerView)
                }
            }
        }
        
        private func shouldRetry(error: Error) -> Bool {
            let nsError = error as NSError
            return nsError.code == -1005 || nsError.code == -1001 // Network lost or timeout
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

// MARK: - Banner Style

enum BannerStyle {
    case standard
    case minimal
    case tab(String)
}

// MARK: - Banner Gate

/// Wraps content with a banner ad, observing the purchase manager so the banner
/// disappears immediately when the user buys Remove Ads / Premium (no relaunch).
private struct BannerGate<Content: View>: View {
    let style: BannerStyle
    @ViewBuilder let content: () -> Content
    @ObservedObject private var purchaseManager = AppPurchaseManager.shared

    var body: some View {
        if AdManager.shared.shouldShowBannerAds {
            VStack(spacing: 0) {
                content()
                    .onAppear {
                        if case .tab(let name) = style {
                            AdManager.shared.recordViewTransition(from: "previous", to: name)
                        }
                    }

                if case .minimal = style {} else {
                    Divider().background(Color.gray.opacity(0.2))
                }

                BannerAdView()
                    .frame(height: 50)
                    .background(Color(UIColor.systemBackground))
                    .opacity({ () -> Double in
                        if case .minimal = style { return 0.9 }
                        return 1.0
                    }())
            }
        } else {
            content()
        }
    }
}

// MARK: - View Extensions

extension View {
    @MainActor
    func withBanner(style: BannerStyle = .standard) -> some View {
        BannerGate(style: style) { self }
    }
    
    // Convenience aliases
    @MainActor func withSmartBanner() -> some View { withBanner(style: .standard) }
    @MainActor func withMinimalBanner() -> some View { withBanner(style: .minimal) }
    @MainActor func withTabBanner(tabName: String) -> some View { withBanner(style: .tab(tabName)) }
    
    @MainActor
    func withInterstitialAd(trigger: InterstitialContext) -> some View {
        self.onAppear {
            Task { @MainActor in
                if AdManager.shared.shouldShowInterstitial(for: trigger) {
                    showInterstitialAd()
                }
            }
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
                    AdManager.shared.trackAdImpression(type: "interstitial")
                }
            }
        }
    }
}

// MARK: - Interstitial Context

enum InterstitialContext {
    case gameComplete
    case historyView
    case settingsView
}
