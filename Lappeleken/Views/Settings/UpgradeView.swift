//
//  Enhanced UpgradeView.swift
//  Lucky Football Slip
//
//  Vibrant upgrade interface with enhanced design system
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
    @State private var animateGradient = false
    @State private var animateFeatures = false
    
    var body: some View {
        ZStack {
            // Enhanced animated background
            backgroundView
            
            NavigationView {
                VStack(spacing: 0) {
                    // Enhanced tab selector
                    enhancedTabSelector
                    
                    TabView(selection: $selectedTab) {
                        premiumUpgradeView
                            .tag(0)
                        
                        competitionsView
                            .tag(1)
                        
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
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    }
                }
            }
        }
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Purchase Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .onAppear {
            loadProducts()
            
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
            
            withAnimation(AppDesignSystem.Animations.standard.delay(0.5)) {
                animateFeatures = true
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 1.0),
                Color(red: 0.98, green: 0.96, blue: 1.0),
                Color(red: 0.96, green: 0.97, blue: 1.0)
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Enhanced Tab Selector
    
    private var enhancedTabSelector: some View {
        HStack(spacing: 0) {
            TabButton(title: "Premium", isSelected: selectedTab == 0, index: 0, selectedTab: $selectedTab)
            TabButton(title: "Competitions", isSelected: selectedTab == 1, index: 1, selectedTab: $selectedTab)
            
            if purchaseManager.currentTier == .free {
                TabButton(title: "Free Options", isSelected: selectedTab == 2, index: 2, selectedTab: $selectedTab)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(AppDesignSystem.Colors.cardBackground.opacity(0.9))
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
    
    // MARK: - Premium Upgrade View
    
    private var premiumUpgradeView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 32) {
                // Enhanced hero section
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppDesignSystem.Colors.warning.opacity(0.3),
                                        AppDesignSystem.Colors.warning.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 30,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 200)
                            .scaleEffect(animateGradient ? 1.05 : 1.0)
                        
                        Image(systemName: "crown.fill")
                            .font(.system(size: 80, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.Colors.warning,
                                        AppDesignSystem.Colors.secondary
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: AppDesignSystem.Colors.warning.opacity(0.4),
                                radius: 12,
                                x: 0,
                                y: 6
                            )
                    }
                    
                    VStack(spacing: 12) {
                        Text("Upgrade to Premium")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                            .multilineTextAlignment(.center)
                        
                        Text("Unlock the full potential of Lucky Football Slip")
                            .font(.system(size: 18, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Enhanced features list
                VStack(spacing: 16) {
                    ForEach(Array(AppPurchaseManager.PurchaseTier.premium.features.enumerated()), id: \.offset) { index, feature in
                        EnhancedFeatureRow(
                            feature: feature,
                            index: index,
                            isAnimated: animateFeatures
                        )
                    }
                }
                .enhancedCard()
                
                // Current status
                EnhancedStatusCard(
                    title: "Current Plan",
                    subtitle: purchaseManager.currentTier.displayName,
                    icon: purchaseManager.currentTier == .premium ? "crown.fill" : "person.circle",
                    color: purchaseManager.currentTier == .premium ? AppDesignSystem.Colors.warning : AppDesignSystem.Colors.primary,
                    isPremium: purchaseManager.currentTier == .premium
                )
                
                if purchaseManager.currentTier == .free {
                    // Live matches status
                    EnhancedStatusCard(
                        title: "Remaining Free Matches",
                        subtitle: "\(purchaseManager.remainingFreeMatches) left",
                        icon: "sportscourt",
                        color: purchaseManager.remainingFreeMatches > 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error,
                        showProgress: true,
                        progress: Double(purchaseManager.remainingFreeMatches) / Double(AppConfig.maxFreeMatches)
                    )
                    
                    // Purchase section
                    purchaseSection
                }
                
                Spacer(minLength: 40)
            }
            .padding(20)
        }
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(spacing: 20) {
            if isLoadingProducts {
                LoadingCard()
            } else if let premiumProduct = purchaseManager.availableProducts.first(where: { $0.id == AppPurchaseManager.ProductID.premium.rawValue }) {
                EnhancedPurchaseCard(
                    title: "Upgrade to Premium",
                    subtitle: premiumProduct.displayPrice,
                    description: "One-time purchase • Lifetime access",
                    isLoading: purchaseManager.isLoading,
                    color: AppDesignSystem.Colors.warning
                ) {
                    Task {
                        await purchasePremium()
                    }
                }
            } else {
                ErrorCard {
                    loadProducts()
                }
            }
        }
    }
    
    // MARK: - Competitions View
    
    private var competitionsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Enhanced header
                VStack(spacing: 16) {
                    Image(systemName: "globe.europe.africa.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.info,
                                    AppDesignSystem.Colors.primary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: AppDesignSystem.Colors.info.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    VStack(spacing: 8) {
                        Text("Premium Competitions")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Follow the world's biggest tournaments live")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Enhanced competition cards
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    EnhancedCompetitionCard(
                        productID: .championsLeague,
                        title: "Champions League",
                        icon: "star.circle.fill",
                        description: "Europe's elite club competition",
                        isAvailable: true,
                        color: AppDesignSystem.Colors.info
                    )
                    
                    EnhancedCompetitionCard(
                        productID: .worldCup,
                        title: "World Cup 2026",
                        icon: "globe",
                        description: "The world's biggest tournament",
                        isAvailable: AppPurchaseManager.ProductID.worldCup.isCurrentlyAvailable,
                        availabilityMessage: AppPurchaseManager.ProductID.worldCup.availabilityMessage,
                        color: AppDesignSystem.Colors.success
                    )
                    
                    EnhancedCompetitionCard(
                        productID: .euroChampionship,
                        title: "Euro 2028",
                        icon: "flag.circle.fill",
                        description: "European national teams",
                        isAvailable: AppPurchaseManager.ProductID.euroChampionship.isCurrentlyAvailable,
                        availabilityMessage: AppPurchaseManager.ProductID.euroChampionship.availabilityMessage,
                        color: AppDesignSystem.Colors.primary
                    )
                    
                    EnhancedCompetitionCard(
                        productID: .nationsCup,
                        title: "Nations Cup",
                        icon: "trophy.circle.fill",
                        description: "Continental competitions",
                        isAvailable: AppPurchaseManager.ProductID.nationsCup.isCurrentlyAvailable,
                        availabilityMessage: AppPurchaseManager.ProductID.nationsCup.availabilityMessage,
                        color: AppDesignSystem.Colors.warning
                    )
                }
                
                #if DEBUG
                debugTournamentControls
                #endif
                
                Spacer(minLength: 40)
            }
            .padding(20)
        }
    }
    
    #if DEBUG
    private var debugTournamentControls: some View {
        VStack(spacing: 16) {
            Text("Debug Controls")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.warning)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    DebugButton(title: "Enable World Cup", isEnabled: true) {
                        purchaseManager.enableWorldCupForTesting(true)
                    }
                    
                    DebugButton(title: "Disable World Cup", isEnabled: false) {
                        purchaseManager.enableWorldCupForTesting(false)
                    }
                }
                
                HStack(spacing: 12) {
                    DebugButton(title: "Enable Euro", isEnabled: true) {
                        purchaseManager.enableEuroForTesting(true)
                    }
                    
                    DebugButton(title: "Disable Euro", isEnabled: false) {
                        purchaseManager.enableEuroForTesting(false)
                    }
                }
                
                HStack(spacing: 12) {
                    DebugButton(title: "Enable Nations Cup", isEnabled: true) {
                        purchaseManager.enableNationsCupForTesting(true)
                    }
                    
                    DebugButton(title: "Disable Nations Cup", isEnabled: false) {
                        purchaseManager.enableNationsCupForTesting(false)
                    }
                }
            }
        }
        .enhancedCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppDesignSystem.Colors.warning.opacity(0.5), lineWidth: 2)
        )
    }
    #endif
    
    // MARK: - Free Options View
    
    private var freeOptionsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Enhanced header
                VStack(spacing: 16) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.success,
                                    AppDesignSystem.Colors.info
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: AppDesignSystem.Colors.success.opacity(0.3),
                            radius: 8,
                            x: 0,
                            y: 4
                        )
                    
                    VStack(spacing: 8) {
                        Text("Get More Free Matches")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Earn extra matches without upgrading")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                }
                
                // Watch ad option
                if adManager.isRewardedReady {
                    EnhancedFreeOptionCard(
                        title: "Watch Ad for Free Match",
                        subtitle: "Watch a short video to earn 1 additional live match",
                        icon: "play.tv.fill",
                        color: AppDesignSystem.Colors.success,
                        buttonText: "Watch Ad"
                    ) {
                        watchAdForFreeMatch()
                    }
                } else {
                    EnhancedFreeOptionCard(
                        title: "Ad Not Available",
                        subtitle: "Ads are loading. Please try again in a moment.",
                        icon: "clock",
                        color: AppDesignSystem.Colors.secondaryText,
                        buttonText: "Loading...",
                        isDisabled: true
                    ) {
                        // No action when disabled
                    }
                }
                
                // Share app option
                EnhancedFreeOptionCard(
                    title: "Share the App",
                    subtitle: "Share Lucky Football Slip with friends and family",
                    icon: "square.and.arrow.up",
                    color: AppDesignSystem.Colors.info,
                    buttonText: "Share App"
                ) {
                    shareApp()
                }
                
                Spacer(minLength: 40)
            }
            .padding(20)
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
        
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(
                x: rootViewController.view.bounds.midX,
                y: rootViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
        }
        
        rootViewController.present(activityViewController, animated: true)
    }
}

// MARK: - Enhanced Components

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let index: Int
    @Binding var selectedTab: Int
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(AppDesignSystem.Animations.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppDesignSystem.Animations.bouncy) {
                    isPressed = false
                    selectedTab = index
                }
            }
        }) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .semibold, design: .rounded))
                .foregroundColor(
                    isSelected ? .white : AppDesignSystem.Colors.primaryText
                )
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.primary,
                                    AppDesignSystem.Colors.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [Color.clear, Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .conditionalModifier(isSelected) { view in
            view.vibrantButton()
        }
    }
}

struct EnhancedFeatureRow: View {
    let feature: String
    let index: Int
    let isAnimated: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.success,
                                AppDesignSystem.Colors.success.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 24, height: 24)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            .shadow(
                color: AppDesignSystem.Colors.success.opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
            
            Text(feature)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
        }
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(x: isAnimated ? 0 : -20)
        .animation(
            AppDesignSystem.Animations.bouncy.delay(Double(index) * 0.1),
            value: isAnimated
        )
    }
}

struct EnhancedStatusCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var isPremium: Bool = false
    var showProgress: Bool = false
    var progress: Double = 0.0
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(
                color: color.opacity(0.3),
                radius: 6,
                x: 0,
                y: 3
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Text(subtitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                if showProgress {
                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: color))
                        .scaleEffect(y: 2)
                }
            }
            
            Spacer()
            
            if isPremium {
                VibrantStatusBadge("Active", color: AppDesignSystem.Colors.success)
            }
        }
        .enhancedCard()
    }
}

struct EnhancedPurchaseCard: View {
    let title: String
    let subtitle: String
    let description: String
    let isLoading: Bool
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(color)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Button(action: {
                withAnimation(AppDesignSystem.Animations.quick) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AppDesignSystem.Animations.quick) {
                        isPressed = false
                    }
                    action()
                }
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 18))
                        
                        Text("Upgrade Now")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isLoading)
            .vibrantButton(color: color)
        }
        .enhancedCard()
    }
}

struct LoadingCard: View {
    @State private var animateLoading = false
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(AppDesignSystem.Colors.primary.opacity(0.2), lineWidth: 4)
                    .frame(width: 50, height: 50)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [AppDesignSystem.Colors.primary, AppDesignSystem.Colors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 50, height: 50)
                    .rotationEffect(.degrees(animateLoading ? 360 : 0))
            }
            
            VStack(spacing: 4) {
                Text("Loading Premium Options")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Please wait while we fetch the latest pricing...")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .enhancedCard()
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                animateLoading = true
            }
        }
    }
}

struct ErrorCard: View {
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 40))
                .foregroundColor(AppDesignSystem.Colors.error)
            
            VStack(spacing: 8) {
                Text("Premium Options Unavailable")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Please check your internet connection and try again")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button("Retry") {
                onRetry()
            }
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppDesignSystem.Colors.primary)
            )
        }
        .enhancedCard()
    }
}

struct EnhancedCompetitionCard: View {
    let productID: AppPurchaseManager.ProductID
    let title: String
    let icon: String
    let description: String
    let isAvailable: Bool
    let availabilityMessage: String?
    let color: Color
    
    @ObservedObject private var purchaseManager = AppPurchaseManager.shared
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    init(productID: AppPurchaseManager.ProductID, title: String, icon: String, description: String, isAvailable: Bool = true, availabilityMessage: String? = nil, color: Color) {
        self.productID = productID
        self.title = title
        self.icon = icon
        self.description = description
        self.isAvailable = isAvailable
        self.availabilityMessage = availabilityMessage
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.3),
                                color.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 50
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(isAvailable ? color : AppDesignSystem.Colors.secondaryText)
            }
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isAvailable ? AppDesignSystem.Colors.primaryText : AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                
                Text(description)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            
            if isAvailable {
                purchaseStatusView
            } else {
                unavailableView
            }
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isAvailable ? color.opacity(0.3) : AppDesignSystem.Colors.secondaryText.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 8,
            x: 0,
            y: 4
        )
        .opacity(isAvailable ? 1.0 : 0.6)
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Purchase Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    @ViewBuilder
    private var purchaseStatusView: some View {
        if purchaseManager.hasAccess(to: productID) {
            VibrantStatusBadge("Owned", color: AppDesignSystem.Colors.success)
        } else if let product = purchaseManager.availableProducts.first(where: { $0.id == productID.rawValue }) {
            Button(action: {
                Task {
                    await purchaseCompetition()
                }
            }) {
                Text("Buy \(product.displayPrice)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            }
            .disabled(isLoading || purchaseManager.isLoading)
            .opacity(isLoading || purchaseManager.isLoading ? 0.6 : 1.0)
        } else {
            Text("Loading...")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
    }
    
    @ViewBuilder
    private var unavailableView: some View {
        VStack(spacing: 4) {
            VibrantStatusBadge("Coming Soon", color: AppDesignSystem.Colors.secondaryText)
            
            if let message = availabilityMessage {
                Text(message)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func purchaseCompetition() async {
        isLoading = true
        errorMessage = ""
        
        do {
            try await purchaseManager.purchaseProduct(productID.rawValue)
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        
        isLoading = false
    }
}

struct EnhancedFreeOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let buttonText: String
    var isDisabled: Bool = false
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundColor(color)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                guard !isDisabled else { return }
                
                withAnimation(AppDesignSystem.Animations.quick) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(AppDesignSystem.Animations.quick) {
                        isPressed = false
                    }
                    action()
                }
            }) {
                Text(buttonText)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .scaleEffect(isPressed ? 0.98 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .enhancedCard()
    }
}

#if DEBUG
struct DebugButton: View {
    let title: String
    let isEnabled: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            isEnabled ?
                            AppDesignSystem.Colors.success :
                            AppDesignSystem.Colors.error
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
#endif


extension View {
    @ViewBuilder func conditionalModifier<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
