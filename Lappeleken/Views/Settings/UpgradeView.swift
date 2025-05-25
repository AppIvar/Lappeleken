//
//  UpgradeView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 16/05/2025.
//

import SwiftUI

struct UpgradeView: View {
    @ObservedObject private var purchaseManager = AppPurchaseManager.shared
    @ObservedObject private var adManager = AdManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedTab = 0
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var isLoadingProducts = true
    
    var body: some View {
        NavigationView {
            VStack {
                // Tab selector
                Picker("Options", selection: $selectedTab) {
                    Text("Premium").tag(0)
                    Text("Competitions").tag(1)
                    if purchaseManager.currentTier == .free {
                        Text("Free Options").tag(2)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                TabView(selection: $selectedTab) {
                    // Premium Tab
                    premiumUpgradeView
                        .tag(0)
                    
                    // Competitions Tab
                    competitionsView
                        .tag(1)
                    
                    // Free Options Tab (only for free users)
                    if purchaseManager.currentTier == .free {
                        freeOptionsView
                            .tag(2)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .alert(isPresented: $showingError) {
                Alert(title: Text("Purchase Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .onAppear {
                loadProducts()
            }
        }
    }
    
    // MARK: - Premium Upgrade View
    
    private var premiumUpgradeView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Premium Benefits
                VStack(alignment: .leading, spacing: 16) {
                    Text("Upgrade to Premium")
                        .font(AppDesignSystem.Typography.titleFont)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("Unlock the full potential of Lucky Football Slip")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    ForEach(AppPurchaseManager.PurchaseTier.premium.features, id: \.self) { feature in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppDesignSystem.Colors.success)
                            Text(feature)
                                .font(AppDesignSystem.Typography.bodyFont)
                            Spacer()
                        }
                    }
                }
                .padding()
                .background(AppDesignSystem.Colors.cardBackground)
                .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                
                // Current Status
                StatusCard(
                    title: "Current Plan",
                    subtitle: purchaseManager.currentTier.displayName,
                    icon: purchaseManager.currentTier == .premium ? "crown.fill" : "person.circle",
                    color: purchaseManager.currentTier == .premium ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.primary
                )
                
                if purchaseManager.currentTier == .free {
                    // Live Matches Status
                    StatusCard(
                        title: "Remaining Free Matches",
                        subtitle: "\(purchaseManager.remainingFreeMatches) left",
                        icon: "sportscourt",
                        color: purchaseManager.remainingFreeMatches > 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error
                    )
                    
                    // Purchase Button or Loading State
                    if isLoadingProducts {
                        VStack {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading premium options...")
                                .font(AppDesignSystem.Typography.bodyFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .padding(.top, 8)
                        }
                        .frame(height: 80)
                    } else if let premiumProduct = purchaseManager.availableProducts.first(where: { $0.id == AppPurchaseManager.ProductID.premium.rawValue }) {
                        PurchaseButton(
                            title: "Upgrade to Premium",
                            subtitle: premiumProduct.displayPrice,
                            isLoading: purchaseManager.isLoading
                        ) {
                            Task {
                                await purchasePremium()
                            }
                        }
                    } else {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 30))
                                .foregroundColor(AppDesignSystem.Colors.error)
                            Text("Premium options unavailable")
                                .font(AppDesignSystem.Typography.bodyFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            Text("Please check your internet connection and try again")
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                            
                            Button("Retry") {
                                loadProducts()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.top, 8)
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Competitions View
    
    private var competitionsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Premium Competitions")
                    .font(AppDesignSystem.Typography.headingFont)
                    .padding(.top)
                
                Text("Follow the world's biggest tournaments live")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 160))
                ], spacing: 16) {
                    // Always available competitions
                    CompetitionCard(
                        productID: .championsLeague,
                        title: "Champions League",
                        icon: "star.circle.fill",
                        description: "Europe's elite club competition",
                        isAvailable: true
                    )
                    
                    // Seasonal competitions with availability logic
                    CompetitionCard(
                        productID: .worldCup,
                        title: "World Cup 2026",
                        icon: "globe",
                        description: "The world's biggest tournament",
                        isAvailable: AppPurchaseManager.ProductID.worldCup.isCurrentlyAvailable,
                        availabilityMessage: AppPurchaseManager.ProductID.worldCup.availabilityMessage
                    )
                    
                    CompetitionCard(
                        productID: .euroChampionship,
                        title: "Euro 2028",
                        icon: "flag.circle.fill",
                        description: "European national teams",
                        isAvailable: AppPurchaseManager.ProductID.euroChampionship.isCurrentlyAvailable,
                        availabilityMessage: AppPurchaseManager.ProductID.euroChampionship.availabilityMessage
                    )
                    
                    CompetitionCard(
                        productID: .nationsCup,
                        title: "Nations Cup",
                        icon: "trophy.circle.fill",
                        description: "Continental competitions",
                        isAvailable: AppPurchaseManager.ProductID.nationsCup.isCurrentlyAvailable,
                        availabilityMessage: AppPurchaseManager.ProductID.nationsCup.availabilityMessage
                    )
                }
                .padding()
                
                // Debug section for testing (only in debug builds)
                #if DEBUG
                debugTournamentControls
                #endif
                
                Spacer()
            }
        }
    }


    #if DEBUG
    private var debugTournamentControls: some View {
        VStack(spacing: 12) {
            Text("Debug Controls")
                .font(.headline)
                .foregroundColor(.orange)
            
            HStack {
                Button("Enable World Cup") {
                    purchaseManager.enableWorldCupForTesting(true)
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Disable World Cup") {
                    purchaseManager.enableWorldCupForTesting(false)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            HStack {
                Button("Enable Euro") {
                    purchaseManager.enableEuroForTesting(true)
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Disable Euro") {
                    purchaseManager.enableEuroForTesting(false)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            
            HStack {
                Button("Enable Nations Cup") {
                    purchaseManager.enableNationsCupForTesting(true)
                }
                .buttonStyle(SecondaryButtonStyle())
                
                Button("Disable Nations Cup") {
                    purchaseManager.enableNationsCupForTesting(false)
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    #endif
    
    // MARK: - Free Options View
    
    private var freeOptionsView: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Get More Free Matches")
                    .font(AppDesignSystem.Typography.headingFont)
                
                // Watch Ad Option
                if adManager.isRewardedReady {
                    CardView {
                        VStack(spacing: 16) {
                            Image(systemName: "play.tv")
                                .font(.system(size: 40))
                                .foregroundColor(AppDesignSystem.Colors.primary)
                            
                            Text("Watch Ad for Free Match")
                                .font(AppDesignSystem.Typography.subheadingFont)
                            
                            Text("Watch a short video to earn 1 additional live match")
                                .font(AppDesignSystem.Typography.bodyFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                            
                            Button("Watch Ad") {
                                watchAdForFreeMatch()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                        .padding()
                    }
                } else {
                    CardView {
                        VStack(spacing: 16) {
                            Image(systemName: "clock")
                                .font(.system(size: 40))
                                .foregroundColor(AppDesignSystem.Colors.secondary)
                            
                            Text("Ad Not Available")
                                .font(AppDesignSystem.Typography.subheadingFont)
                            
                            Text("Ads are loading. Please try again in a moment.")
                                .font(AppDesignSystem.Typography.bodyFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    }
                }
                
                // Share App Option
                CardView {
                    VStack(spacing: 16) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 40))
                            .foregroundColor(AppDesignSystem.Colors.success)
                        
                        Text("Share the App")
                            .font(AppDesignSystem.Typography.subheadingFont)
                        
                        Text("Share Lucky Football Slip with friends and family")
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        Button("Share App") {
                            shareApp()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding()
        }
    }
    
    // MARK: - Helper Methods
    

    private func loadProducts() {
        isLoadingProducts = true
        
        Task {
            await purchaseManager.loadProducts()
            
            await MainActor.run {
                isLoadingProducts = false
                if !purchaseManager.availableProducts.isEmpty {
                    print("✅ Products loaded successfully")
                } else {
                    print("⚠️ No products available (possibly in debug mode)")
                }
            }
        }
    }
    
    private func purchasePremium() async {
        do {
            try await purchaseManager.purchaseProduct(AppPurchaseManager.ProductID.premium.rawValue)
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.showingError = true
            }
        }
    }
    
    private func watchAdForFreeMatch() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        adManager.showRewardedAd(from: rootViewController) { success in
            if success {
                // Ad was watched successfully, reward is handled in AdManager
                print("✅ User watched ad and earned free match")
            } else {
                print("❌ Failed to show rewarded ad")
            }
        }
    }
    
    private func shareApp() {
        let shareText = "Check out Lucky Football Slip - the best football betting game! \(AppConfig.appStoreURL)"
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        
        // For iPad
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(x: rootViewController.view.bounds.midX, y: rootViewController.view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        rootViewController.present(activityViewController, animated: true)
    }
}
