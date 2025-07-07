//
//  UpgradeView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 22/05/2025.
//

import SwiftUI
import StoreKit

struct UpgradeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var purchaseManager = AppPurchaseManager.shared
    @State private var selectedTab = 0
    @State private var isLoadingProducts = true
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Hero Section
                    heroSection
                    
                    // Main Content Based on Tab
                    if selectedTab == 0 {
                        subscriptionView
                    } else {
                        featuresView
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            loadProducts()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 16) {
            // Tab Selector
            Picker("View", selection: $selectedTab) {
                Text("Premium").tag(0)
                Text("Features").tag(1)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.horizontal)
            
            // Status Card
            EnhancedStatusCard(
                title: purchaseManager.currentTier == .premium ? "Premium Active" : "Free Plan",
                subtitle: purchaseManager.currentTier == .premium ? "Unlimited matches • No ads" : "\(purchaseManager.remainingFreeMatchesToday) matches left today",
                icon: purchaseManager.currentTier == .premium ? "crown.fill" : "person.circle",
                color: purchaseManager.currentTier == .premium ? AppDesignSystem.Colors.warning : AppDesignSystem.Colors.primary,
                isPremium: purchaseManager.currentTier == .premium
            )
        }
    }
    
    // MARK: - Subscription View
    
    private var subscriptionView: some View {
        VStack(spacing: 24) {
            if purchaseManager.currentTier == .premium {
                // Already Premium
                premiumActiveView
            } else {
                // Free User - Show Subscription
                freeUserSubscriptionView
            }
        }
    }
    
    private var premiumActiveView: some View {
        VStack(spacing: 20) {
            // Premium Status
            VStack(spacing: 16) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
                
                Text("You're Premium!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Enjoy unlimited live matches and an ad-free experience")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.warning.opacity(0.1),
                        AppDesignSystem.Colors.warning.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            
            // Manage Subscription Button
            Button("Manage Subscription") {
                if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.blue)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var freeUserSubscriptionView: some View {
        VStack(spacing: 20) {
            // Live matches status
            dailyMatchesStatusCard
            
            // Subscription offer
            if isLoadingProducts {
                LoadingCard()
            } else if let premiumProduct = purchaseManager.availableProducts.first(where: { $0.id == AppPurchaseManager.ProductID.premium.rawValue }) {
                SubscriptionOfferCard(product: premiumProduct)
            } else {
                ErrorCard {
                    loadProducts()
                }
            }
            
            // Watch Ad Option
            if purchaseManager.remainingFreeMatchesToday == 0 && AdManager.shared.isRewardedReady {
                watchAdCard
            }
        }
    }
    
    private var dailyMatchesStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "sportscourt")
                    .font(.system(size: 20))
                    .foregroundColor(purchaseManager.remainingFreeMatchesToday > 0 ? .green : .red)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Today's Live Matches")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("\(purchaseManager.remainingFreeMatchesToday) remaining")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Progress indicator
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
                        .frame(width: 30, height: 30)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(purchaseManager.remainingFreeMatchesToday))
                        .stroke(
                            purchaseManager.remainingFreeMatchesToday > 0 ? Color.green : Color.red,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 30, height: 30)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(purchaseManager.remainingFreeMatchesToday)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    private var watchAdCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Watch Ad for Extra Match")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Get another live match for today")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Watch Ad") {
                    showRewardedAd()
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue)
                .cornerRadius(8)
            }
            .padding()
            .background(Color.blue.opacity(0.05))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Features View
    
    private var featuresView: some View {
        VStack(spacing: 20) {
            // Comparison Cards
            FeatureComparisonCard(
                title: "Live Matches",
                freeFeature: "1 match per day",
                premiumFeature: "Unlimited matches",
                icon: "sportscourt.fill"
            )
            
            FeatureComparisonCard(
                title: "Ad Experience",
                freeFeature: "Banner & video ads",
                premiumFeature: "Completely ad-free",
                icon: "rectangle.slash"
            )
            
            FeatureComparisonCard(
                title: "Multiple Matches",
                freeFeature: "One at a time",
                premiumFeature: "Track multiple simultaneously",
                icon: "square.grid.2x2"
            )
            
            FeatureComparisonCard(
                title: "Data Export",
                freeFeature: "Not available",
                premiumFeature: "Export game summaries",
                icon: "square.and.arrow.up"
            )
            
            FeatureComparisonCard(
                title: "Support",
                freeFeature: "Standard support",
                premiumFeature: "Priority customer support",
                icon: "headphones"
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadProducts() {
        isLoadingProducts = true
        Task {
            await purchaseManager.loadProducts()
            await MainActor.run {
                isLoadingProducts = false
            }
        }
    }
    
    private func showRewardedAd() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        AdManager.shared.showRewardedAdForExtraMatch(from: rootViewController) { success in
            if success {
                // UI will automatically update due to @Published properties
                print("✅ Extra match granted via rewarded ad")
            } else {
                DispatchQueue.main.async {
                    errorMessage = "Unable to show ad right now. Please try again later."
                    showingError = true
                }
            }
        }
    }
    
    private func purchasePremium(product: Product) async {
        do {
            let success = try await purchaseManager.purchase(.premium)
            if success {
                await MainActor.run {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Subscription Offer Card

struct SubscriptionOfferCard: View {
    let product: Product
    @ObservedObject private var purchaseManager = AppPurchaseManager.shared
    @State private var isPurchasing = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            VStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                
                Text("Go Premium")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Unlimited live matches and ad-free experience")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Price
            VStack(spacing: 4) {
                Text(product.displayPrice)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("per month")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
            }
            
            // Features List
            VStack(alignment: .leading, spacing: 8) {
                FeatureBullet(text: "Unlimited live matches daily")
                FeatureBullet(text: "Completely ad-free experience")
                FeatureBullet(text: "Priority customer support")
            }
            
            // Subscribe Button
            Button(action: {
                Task {
                    isPurchasing = true
                    do {
                        _ = try await purchaseManager.purchase(.premium)
                    } catch {
                        print("Purchase failed: \(error)")
                    }
                    isPurchasing = false
                }
            }) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isPurchasing ? "Processing..." : "Start Premium Subscription")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
            }
            .disabled(isPurchasing)
            
            // Terms
            Text("Cancel anytime. Auto-renewable subscription.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.warning.opacity(0.05),
                    AppDesignSystem.Colors.primary.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppDesignSystem.Colors.warning.opacity(0.3),
                            AppDesignSystem.Colors.primary.opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
    }
}

// MARK: - Feature Comparison Card

struct FeatureComparisonCard: View {
    let title: String
    let freeFeature: String
    let premiumFeature: String
    let icon: String
    
    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.primary)
                
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Comparison
            HStack(spacing: 16) {
                // Free
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    Text(freeFeature)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Divider()
                    .frame(height: 30)
                
                // Premium
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Premium")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.blue)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                    
                    Text(premiumFeature)
                        .font(.system(size: 14))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Feature Bullet Point

struct FeatureBullet: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(.green)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

// MARK: - Enhanced Status Card

struct EnhancedStatusCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var showProgress: Bool = false
    var progress: Double = 0.0
    var isPremium: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                
                if showProgress {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: color))
                        .frame(height: 4)
                }
            }
            
            Spacer()
            
            // Premium badge
            if isPremium {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                    
                    Text("PREMIUM")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.yellow)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Loading Card

struct LoadingCard: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            
            Text("Loading subscription options...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Error Card

struct ErrorCard: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text("Unable to load subscription options")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            Text("Please check your internet connection and try again.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                onRetry()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Preview

struct UpgradeView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeView()
    }
}
