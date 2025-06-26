//
//  Enhanced SettingsView.swift
//  Lucky Football Slip
//
//  Vibrant settings interface with enhanced design system
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameSession: GameSession
    @AppStorage("selectedCurrency") private var selectedCurrency = "EUR"
    @AppStorage("currencySymbol") private var currencySymbol = "€"
    @AppStorage("isLiveMode") private var isLiveMode = false
    
    @State private var showingUpgradeView = false
    @State private var showingLiveSetupInfo = false
    @State private var showingMatchSelection = false
    @State private var animateGradient = false
    @State private var showingBackgroundSetup = false

    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var purchaseManager = AppPurchaseManager.shared
    
    private let currencies = [
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("NOK", "kr", "Norwegian Krone"),
        ("SEK", "kr", "Swedish Krona"),
        ("DKK", "kr", "Danish Krone")
    ]
    
    var body: some View {
        ZStack {
            // Enhanced animated background
            backgroundView
            
            NavigationView {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Game Mode Section
                        EnhancedSettingsSection(
                            title: "Game Mode",
                            icon: "gamecontroller.fill",
                            color: AppDesignSystem.Colors.primary
                        ) {
                            gameModeContent
                        }
                        
                        // Premium Features Section
                        EnhancedSettingsSection(
                            title: "Premium Features",
                            icon: "crown.fill",
                            color: AppDesignSystem.Colors.warning
                        ) {
                            premiumFeaturesContent
                        }
                        
                        // Currency Settings Section
                        EnhancedSettingsSection(
                            title: "Currency Settings",
                            icon: "dollarsign.circle.fill",
                            color: AppDesignSystem.Colors.success
                        ) {
                            currencySettingsContent
                        }
                        
                        // About Section
                        EnhancedSettingsSection(
                            title: "About",
                            icon: "info.circle.fill",
                            color: AppDesignSystem.Colors.info
                        ) {
                            aboutContent
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
                .navigationTitle("Settings")
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
        .sheet(isPresented: $showingUpgradeView) {
            UpgradeView()
        }
        .sheet(isPresented: $showingLiveSetupInfo) {
            LiveModeInfoView(onGetStarted: {
                NotificationCenter.default.post(
                    name: Notification.Name("StartLiveGameFlow"),
                    object: nil
                )
            })
        }
        .sheet(isPresented: $showingMatchSelection) {
            MatchSelectionView(gameSession: gameSession)
        }
        
        .sheet(isPresented: $showingBackgroundSetup) {
            BackgroundSetupGuideView()
        }
        
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
        .withSmartMonetization()
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
    
    // MARK: - Game Mode Content
    
    private var gameModeContent: some View {
        VStack(spacing: 16) {
            // Current mode display
            EnhancedSettingsRow(
                title: currentModeText,
                subtitle: "Current game mode",
                icon: currentModeIcon,
                color: isLiveMode ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.primary,
                hasAction: false
            )
            
            // Live mode specific options
            if isLiveMode {
                if let selectedMatch = gameSession.selectedMatch {
                    EnhancedSettingsRow(
                        title: "\(selectedMatch.homeTeam.name) vs \(selectedMatch.awayTeam.name)",
                        subtitle: "Current match",
                        icon: "sportscourt.fill",
                        color: AppDesignSystem.Colors.info
                    ) {
                        showingMatchSelection = true
                    }
                } else {
                    EnhancedSettingsRow(
                        title: "Select Match",
                        subtitle: "No match selected",
                        icon: "plus.circle.fill",
                        color: AppDesignSystem.Colors.warning
                    ) {
                        showingMatchSelection = true
                    }
                }
                
                EnhancedSettingsRow(
                    title: "About Live Mode",
                    subtitle: "Learn how live mode works",
                    icon: "questionmark.circle.fill",
                    color: AppDesignSystem.Colors.secondary
                ) {
                    showingLiveSetupInfo = true
                }
                
                EnhancedSettingsRow(
                    title: "Background Monitoring Setup",
                    subtitle: "Configure notifications and background updates",
                    icon: "bell.badge.fill",
                    color: AppDesignSystem.Colors.warning
                ) {
                    showingBackgroundSetup = true
                }
            }
        }
    }
    
    // MARK: - Premium Features Content
    
    private var premiumFeaturesContent: some View {
        VStack(spacing: 16) {
            // Main upgrade button - always visible
            EnhancedUpgradeRow(
                currentTier: purchaseManager.currentTier,
                remainingMatches: purchaseManager.remainingFreeMatchesToday
            ) {
                showingUpgradeView = true
            }
            
            // Daily matches info for free users
            if purchaseManager.currentTier == .free {
                dailyMatchesInfoCard
                
                // Watch ad option if available
                if purchaseManager.remainingFreeMatchesToday == 0 && AdManager.shared.isRewardedReady {
                    watchAdForExtraMatchCard
                }
            }
            
            // Restore purchases option
            if purchaseManager.currentTier == .free && !purchaseManager.availableProducts.isEmpty {
                EnhancedSettingsRow(
                    title: "Restore Purchases",
                    subtitle: "Restore previous purchases",
                    icon: "arrow.clockwise.circle.fill",
                    color: AppDesignSystem.Colors.info
                ) {
                    Task {
                        await purchaseManager.restorePurchases()
                    }
                }
            }
        }
    }
    
    private var dailyMatchesInfoCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 20))
                    .foregroundColor(purchaseManager.remainingFreeMatchesToday > 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Live Matches")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("\(purchaseManager.remainingFreeMatchesToday) of 1 remaining today")
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                // Visual indicator
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(purchaseManager.remainingFreeMatchesToday))
                        .stroke(
                            purchaseManager.remainingFreeMatchesToday > 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error,
                            style: StrokeStyle(lineWidth: 3, lineCap: .round)
                        )
                        .frame(width: 40, height: 40)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(purchaseManager.remainingFreeMatchesToday)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        purchaseManager.remainingFreeMatchesToday > 0 ?
                        AppDesignSystem.Colors.success.opacity(0.1) :
                        AppDesignSystem.Colors.error.opacity(0.1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                purchaseManager.remainingFreeMatchesToday > 0 ?
                                AppDesignSystem.Colors.success.opacity(0.3) :
                                AppDesignSystem.Colors.error.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
    }

    private var watchAdForExtraMatchCard: some View {
        Button(action: {
            showRewardedAdForExtraMatch()
        }) {
            HStack(spacing: 12) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Watch Ad for Extra Match")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("Get another live match for today")
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func showRewardedAdForExtraMatch() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        AdManager.shared.showRewardedAdForExtraMatch(from: rootViewController) { success in
            if success {
                print("✅ Extra match granted via rewarded ad from settings")
            } else {
                print("❌ Failed to show rewarded ad from settings")
            }
        }
    }
    
    // MARK: - Currency Settings Content
    
    private var currencySettingsContent: some View {
        VStack(spacing: 12) {
            ForEach(currencies, id: \.0) { currency in
                EnhancedCurrencyRow(
                    code: currency.0,
                    symbol: currency.1,
                    name: currency.2,
                    isSelected: selectedCurrency == currency.0
                ) {
                    withAnimation(AppDesignSystem.Animations.bouncy) {
                        selectedCurrency = currency.0
                        currencySymbol = currency.1
                    }
                }
            }
        }
    }
    
    // MARK: - About Content
    
    private var aboutContent: some View {
        VStack(spacing: 16) {
            EnhancedSettingsRow(
                title: "Version 1.0.0",
                subtitle: "Current app version",
                icon: "app.badge.fill",
                color: AppDesignSystem.Colors.primary,
                hasAction: false
            )
            
            #if DEBUG
            debugTestingSection
            #endif
            
            EnhancedSettingsRow(
                title: "Data by Football-Data.org",
                subtitle: "Live match data provider",
                icon: "link.circle.fill",
                color: AppDesignSystem.Colors.info,
                isExternalLink: true
            ) {
                if let url = URL(string: "https://football-data.org") {
                    UIApplication.shared.open(url)
                }
            }
            
            EnhancedSettingsRow(
                title: "Privacy Policy",
                subtitle: "How we protect your data",
                icon: "lock.shield.fill",
                color: AppDesignSystem.Colors.success,
                isExternalLink: true
            ) {
                if let url = URL(string: "https://lappeleken.com/privacy") {
                    UIApplication.shared.open(url)
                }
            }
            
            EnhancedSettingsRow(
                title: "Terms of Service",
                subtitle: "App usage terms",
                icon: "doc.text.fill",
                color: AppDesignSystem.Colors.secondary,
                isExternalLink: true
            ) {
                if let url = URL(string: "https://lappeleken.com/terms") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
    
    #if DEBUG
    // MARK: - Debug Testing Section

    private var debugTestingSection: some View {
        VStack(spacing: 12) {
            // Section header
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppDesignSystem.Colors.warning)
                
                Text("Debug & Testing")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.warning)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            
            // Premium testing buttons
            EnhancedSettingsRow(
                title: "Set to Premium",
                subtitle: "Unlock all features for testing",
                icon: "crown.fill",
                color: AppDesignSystem.Colors.success
            ) {
                AppPurchaseManager.shared.setToPremiumForTesting()
            }
            
            EnhancedSettingsRow(
                title: "Set to Free",
                subtitle: "Reset to free tier for testing",
                icon: "person.circle.fill",
                color: AppDesignSystem.Colors.primary
            ) {
                AppPurchaseManager.shared.setToFreeForTesting()
            }
            
            EnhancedSettingsRow(
                title: "Reset Daily Usage",
                subtitle: "Reset daily match limits",
                icon: "arrow.clockwise.circle.fill",
                color: AppDesignSystem.Colors.info
            ) {
                AppPurchaseManager.shared.resetDailyMatchUsageForTesting()
            }
            
            // Current status display
            EnhancedSettingsRow(
                title: "Current Tier: \(purchaseManager.currentTier.displayName)",
                subtitle: "Remaining matches: \(purchaseManager.remainingFreeMatchesToday)",
                icon: "info.circle.fill",
                color: AppDesignSystem.Colors.secondary,
                hasAction: false
            )
            
            EnhancedSettingsRow(
                title: "Event Sync Mode",
                subtitle: AppConfig.useStubData ? "Using mock events" : "Using real API",
                icon: AppConfig.useStubData ? "flask.fill" : "globe.fill",
                color: AppConfig.useStubData ? AppDesignSystem.Colors.warning : AppDesignSystem.Colors.success,
                hasAction: false
            )

            EnhancedSettingsRow(
                title: "Force Event Sync",
                subtitle: "Manually check for missed events",
                icon: "arrow.clockwise.circle.fill",
                color: AppDesignSystem.Colors.info
            ) {
                Task {
                    await EventSyncManager.shared.syncMissedEvents()
                }
            }
            
            EnhancedSettingsRow(
                title: "Test Missed Events Banner (3 events)",
                subtitle: "Manually trigger banner for testing",
                icon: "bell.badge.fill",
                color: AppDesignSystem.Colors.info
            ) {
                // Test with different numbers
                NotificationCenter.default.post(
                    name: Notification.Name("MissedEventsFound"),
                    object: nil,
                    userInfo: [
                        "eventCount": 3, // Different number each time
                        "matchName": "Real Test Match",
                        "gameId": UUID().uuidString
                    ]
                )
            }

            
            EnhancedSettingsRow(
                title: "Simulate Background/Foreground",
                subtitle: "Test app background/foreground cycle",
                icon: "arrow.up.and.down.circle.fill",
                color: AppDesignSystem.Colors.secondary
            ) {
                // Simulate going to background
                NotificationCenter.default.post(
                    name: UIApplication.didEnterBackgroundNotification,
                    object: nil
                )
                
                // Wait 180 seconds then simulate returning to foreground
                DispatchQueue.main.asyncAfter(deadline: .now() + 180) {
                    NotificationCenter.default.post(
                        name: UIApplication.didBecomeActiveNotification,
                        object: nil
                    )
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.warning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppDesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
                )
        )
    }
    #endif
    
    // MARK: - Computed Properties
    
    private var currentModeIcon: String {
        return isLiveMode ? "globe" : "gamecontroller.fill"
    }
    
    private var currentModeText: String {
        return isLiveMode ? "Live Mode" : "Manual Mode"
    }
    
    private var remainingFreeMatches: Int {
        return purchaseManager.remainingFreeMatchesToday
    }
    
    private var availableProducts: [String] {
        return purchaseManager.availableProducts.map { $0.id }
    }
}

// MARK: - Enhanced Components

struct EnhancedSettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    let content: Content
    
    @State private var isExpanded = true
    
    init(title: String, icon: String, color: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Section header
            Button(action: {
                withAnimation(AppDesignSystem.Animations.bouncy) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .shadow(
                        color: color.opacity(0.3),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                    
                    Text(title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Section content
            if isExpanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .enhancedCard()
    }
}

struct EnhancedSettingsRow: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    var hasAction: Bool = true
    var isExternalLink: Bool = false
    let action: (() -> Void)?
    
    @State private var isPressed = false
    
    init(title: String, subtitle: String, icon: String, color: Color, hasAction: Bool = true, isExternalLink: Bool = false, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.hasAction = hasAction
        self.isExternalLink = isExternalLink
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            guard hasAction, let action = action else { return }
            
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
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if hasAction {
                    if isExternalLink {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.1), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!hasAction)
    }
}

struct EnhancedUpgradeRow: View {
    let currentTier: AppPurchaseManager.PurchaseTier
    let remainingMatches: Int
    let action: () -> Void
    
    @State private var animateCrown = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
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
                                    startRadius: 10,
                                    endRadius: 30
                                )
                            )
                            .frame(width: 60, height: 60)
                            .scaleEffect(animateCrown ? 1.05 : 1.0)
                        
                        Image(systemName: currentTier == .premium ? "crown.fill" : "star.circle.fill")
                            .font(.system(size: 28, weight: .medium))
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
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        if currentTier == .premium {
                            Text("Premium Active")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.success)
                            
                            Text("You have full access to all features")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        } else {
                            Text("Upgrade to Premium")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Text("Unlock unlimited matches and remove ads")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    if currentTier == .premium {
                        VibrantStatusBadge("Active", color: AppDesignSystem.Colors.success)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.warning)
                    }
                }
                
                if currentTier == .free && remainingMatches > 0 {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Free Matches Remaining")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            
                            ProgressView(value: Double(remainingMatches), total: Double(AppConfig.maxFreeMatches))
                                .progressViewStyle(LinearProgressViewStyle(tint: AppDesignSystem.Colors.success))
                                .scaleEffect(y: 2)
                        }
                        
                        Spacer()
                        
                        Text("\(remainingMatches)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.success)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                currentTier == .premium ?
                                AppDesignSystem.Colors.success.opacity(0.1) :
                                AppDesignSystem.Colors.warning.opacity(0.1),
                                Color.white
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                currentTier == .premium ?
                                AppDesignSystem.Colors.success.opacity(0.3) :
                                AppDesignSystem.Colors.warning.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: currentTier == .premium ?
                AppDesignSystem.Colors.success.opacity(0.1) :
                AppDesignSystem.Colors.warning.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if currentTier == .premium {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    animateCrown = true
                }
            }
        }
    }
}

struct EnhancedFreeMatchesRow: View {
    let remaining: Int
    let total: Int
    
    private var progress: Double {
        guard total > 0 else { return 0 }
        return Double(remaining) / Double(total)
    }
    
    private var statusColor: Color {
        if remaining > total * 2 / 3 {
            return AppDesignSystem.Colors.success
        } else if remaining > total / 3 {
            return AppDesignSystem.Colors.warning
        } else {
            return AppDesignSystem.Colors.error
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free Live Matches")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("Watch ads to earn more matches")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(remaining)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(statusColor)
                    
                    Text("remaining")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            
            VStack(spacing: 6) {
                ProgressView(value: progress)
                    .progressViewStyle(LinearProgressViewStyle(tint: statusColor))
                    .scaleEffect(y: 3)
                
                HStack {
                    Text("0")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    Text("\(total)")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [statusColor.opacity(0.1), Color.white],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusColor.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct EnhancedCurrencyRow: View {
    let code: String
    let symbol: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(AppDesignSystem.Animations.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppDesignSystem.Animations.bouncy) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.success.opacity(isSelected ? 0.3 : 0.1),
                                    AppDesignSystem.Colors.success.opacity(isSelected ? 0.2 : 0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Text(symbol)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(
                            isSelected ?
                            AppDesignSystem.Colors.success :
                            AppDesignSystem.Colors.primaryText
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(code) - \(name)")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(symbol)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppDesignSystem.Colors.success)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.success.opacity(0.1),
                                Color.white
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white, Color.white],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                isSelected ?
                                AppDesignSystem.Colors.success.opacity(0.3) :
                                Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : (isSelected ? 1.02 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Live Mode Info View (Enhanced)

struct LiveModeInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    var onGetStarted: () -> Void
    
    @State private var animateFeatures = false
    
    private var remainingFreeMatches: Int {
        let used = UserDefaults.standard.integer(forKey: "usedLiveMatchCount")
        let adRewarded = UserDefaults.standard.integer(forKey: "adRewardedLiveMatches")
        let total = AppConfig.maxFreeMatches + adRewarded
        return max(0, total - used)
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Enhanced header
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            AppDesignSystem.Colors.primary.opacity(0.3),
                                            AppDesignSystem.Colors.primary.opacity(0.1),
                                            Color.clear
                                        ],
                                        center: .center,
                                        startRadius: 30,
                                        endRadius: 80
                                    )
                                )
                                .frame(width: 160, height: 160)
                            
                            Image(systemName: "globe.europe.africa.fill")
                                .font(.system(size: 70, weight: .medium))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [
                                            AppDesignSystem.Colors.primary,
                                            AppDesignSystem.Colors.info
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(
                                    color: AppDesignSystem.Colors.primary.opacity(0.3),
                                    radius: 12,
                                    x: 0,
                                    y: 6
                                )
                        }
                        
                        VStack(spacing: 12) {
                            Text("About Live Mode")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Text("Live Mode connects your game to real football matches happening now. Here's how it works:")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        
                        
                        // Enhanced feature list
                        VStack(spacing: 16) {
                            ForEach(Array(liveFeatures.enumerated()), id: \.offset) { index, feature in
                                EnhancedLiveModeFeature(
                                    feature: feature,
                                    index: index,
                                    isAnimated: animateFeatures
                                )
                            }
                        }
                        
                        // Free mode info (if applicable)
                        if AppPurchaseManager.shared.currentTier == .free {
                            freeModeInfoCard
                        }
                        
                        // Important note
                        VStack(spacing: 12) {
                            Text("📶 Network Required")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Text("Live Mode requires an internet connection and uses data. Updates may be delayed by 1-2 minutes from the actual match.")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .enhancedCard()
                        
                        // Get started button
                        Button("Get Started") {
                            presentationMode.wrappedValue.dismiss()
                            onGetStarted()
                        }
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppDesignSystem.Colors.primary,
                                            AppDesignSystem.Colors.primary.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .vibrantButton()
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
                .background(AppDesignSystem.Colors.background)
                .navigationTitle("Live Mode")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    }
                }
            }
            .onAppear {
                withAnimation(AppDesignSystem.Animations.standard.delay(0.5)) {
                    animateFeatures = true
                }
            }
        }
    }
    
    private var freeModeInfoCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gift.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppDesignSystem.Colors.warning)
                
                Text("Free Mode Limitations")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("You can follow up to \(AppConfig.maxFreeMatches) live matches in free mode.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                HStack {
                    Text("Remaining matches:")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Text("\(remainingFreeMatches)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.success)
                }
                
                Text("Upgrade to premium to get unlimited matches and the ability to follow multiple matches simultaneously.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
        .enhancedCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppDesignSystem.Colors.warning.opacity(0.3), lineWidth: 2)
        )
    }
    
    private var liveFeatures: [(icon: String, title: String, description: String, color: Color)] {
        [
            ("sportscourt.fill", "Select a Match", "Choose from live or upcoming matches from major leagues.", AppDesignSystem.Colors.primary),
            ("person.2.fill", "Set Up Participants", "Add the people who will be participating in your game.", AppDesignSystem.Colors.success),
            ("scalemass.fill", "Configure Bets", "Set your bet amounts for different types of events.", AppDesignSystem.Colors.warning),
            ("person.crop.circle.badge.checkmark", "Select Players", "Choose football players from the match to include in your game.", AppDesignSystem.Colors.info),
            ("bell.fill", "Real-time Updates", "Goals, cards, and other events are automatically recorded as they happen.", AppDesignSystem.Colors.secondary),
            ("arrow.left.arrow.right", "Automatic Substitutions", "When a player is substituted in the real match, the same happens in your game.", AppDesignSystem.Colors.accent)
        ]
    }
}

struct EnhancedLiveModeFeature: View {
    let feature: (icon: String, title: String, description: String, color: Color)
    let index: Int
    let isAnimated: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [feature.color, feature.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(
                color: feature.color.opacity(0.3),
                radius: 6,
                x: 0,
                y: 3
            )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(feature.description)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .enhancedCard()
        .opacity(isAnimated ? 1.0 : 0.0)
        .offset(x: isAnimated ? 0 : -30)
        .animation(
            AppDesignSystem.Animations.bouncy.delay(Double(index) * 0.1),
            value: isAnimated
        )
    }
}

