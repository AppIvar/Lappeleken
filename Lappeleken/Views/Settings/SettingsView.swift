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
                            title: "App Features",
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
            // Only show UpgradeView if subscriptions are enabled
            if AppConfig.subscriptionEnabled {
                UpgradeView()
            } else {
                // Show feature flags info instead
                featureFlagsInfoSheet
            }
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
        .withSmartMonetization()
    }
    
    // MARK: - Feature Flags Info Sheet (NEW)

    private var featureFlagsInfoSheet: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "heart.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppDesignSystem.Colors.success)
                        
                        Text("Thank You for Testing!")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("We're thrilled to have you try Lucky Football Slip during our testing period.")
                            .font(.system(size: 16))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Testing notice
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "gift.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppDesignSystem.Colors.warning)
                            
                            Text("Special Testing Access")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Spacer()
                        }
                        
                        Text("During this testing period, you have free access to premium features that will typically require a subscription. We want you to experience the full potential of our app!")
                            .font(.system(size: 14))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppDesignSystem.Colors.warning.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppDesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // What you get
                    VStack(spacing: 16) {
                        Text("What You Get During Testing")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        VStack(spacing: 12) {
                            featureStatusRow("Unlimited Live Matches", true)
                            featureStatusRow("All Football Leagues", true)
                            featureStatusRow("Real-Time Updates", true)
                            featureStatusRow("Background Monitoring", true)
                            featureStatusRow("Export Game Summaries", true)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppDesignSystem.Colors.cardBackground)
                    )
                    
                    // Feedback request
                    VStack(spacing: 12) {
                        Text("Help Us Improve")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Your feedback during this testing period is invaluable! Please let us know what you love, what could be better, and any bugs you encounter. Together, we'll make Lucky Football Slip the best football companion app!")
                            .font(.system(size: 14))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        Button(action: {
                            if let url = URL(string: "mailto:\(AppConfig.supportEmail)?subject=Testing%20Feedback%20-%20Lucky%20Football%20Slip") {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                Text("Send Feedback")
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding()
                            .background(AppDesignSystem.Colors.primary)
                            .cornerRadius(10)
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppDesignSystem.Colors.primary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    Spacer(minLength: 20)
                }
                .padding(20)
            }
            .navigationTitle("Testing Features")
            .navigationBarItems(
                trailing: Button("Done") {
                    showingUpgradeView = false
                }
            )
        }
    }

    private func featureStatusRow(_ title: String, _ isEnabled: Bool) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(AppDesignSystem.Colors.success)
            
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Text("Included")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.success)
        }
    }

    // MARK: - Background
    
    private var backgroundView: some View {
        AppDesignSystem.Colors.background
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
            // Only show subscription UI if subscriptions are enabled
            if AppConfig.subscriptionEnabled {
                // Main upgrade button
                EnhancedUpgradeRow(
                    currentTier: purchaseManager.currentTier,
                    remainingMatches: purchaseManager.remainingFreeMatchesToday
                ) {
                    showingUpgradeView = true
                }
                
                // Daily matches info for free users
                if purchaseManager.currentTier == .free {
                    dailyMatchesInfoCard
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
            } else {
                // Feature flags mode - show current feature status
                featureFlagsStatusView
            }
        }
    }
    
    // MARK: - Feature Flags Status View

    private var featureFlagsStatusView: some View {
        VStack(spacing: 16) {
            // Testing notice banner
            testingNoticeBanner
            
            // Header
            EnhancedSettingsRow(
                title: "App Features",
                subtitle: "Currently available during testing period",
                icon: "star.fill",
                color: AppDesignSystem.Colors.success,
                hasAction: false
            )
            
            // Feature status cards
            featureStatusCard(
                title: "Unlimited Live Matches",
                isEnabled: true,
                description: "No daily limit during testing period"
            )
            
            featureStatusCard(
                title: "All Competitions",
                isEnabled: true,
                description: "Access to all football leagues"
            )
            
            // Ad status card
            adStatusCard
            
            // Free testing status if active
            if AppConfig.isFreeLiveTestingActive {
                freeTestingActiveCard
            }
        }
    }
    
    private var testingNoticeBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppDesignSystem.Colors.warning)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Testing Period")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("Features temporarily available for testing")
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            Text("We're excited to have you try Lucky Football Slip! These premium features are currently available for free during our testing period. We hope you enjoy the experience and would love your feedback!")
                .font(.system(size: 14))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.warning.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppDesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func featureStatusCard(title: String, isEnabled: Bool, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: isEnabled ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(isEnabled ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Text(isEnabled ? "Included" : "Disabled")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isEnabled ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                .cornerRadius(6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke((isEnabled ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error).opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private var adStatusCard: some View {
        HStack(spacing: 16) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 20))
                .foregroundColor(AppDesignSystem.Colors.info)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Ad-Supported Experience")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Ads help keep the app free")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Text("Active")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(AppDesignSystem.Colors.info)
                .cornerRadius(6)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppDesignSystem.Colors.info.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var freeTestingActiveCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "gift.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppDesignSystem.Colors.success)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Free Testing Active")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.success)
                    
                    Text("Enhanced features for testing")
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                Text("🎁")
                    .font(.system(size: 24))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppDesignSystem.Colors.success.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppDesignSystem.Colors.success.opacity(0.3), lineWidth: 1)
                    )
            )
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
                        .stroke(Color.white.opacity(0.2), lineWidth: 3)
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

   /* private var watchAdForExtraMatchCard: some View {
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
    } */
    
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
                if let url = URL(string: "https://lucky-football-slip.netlify.app/#privacy") {
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
                if let url = URL(string: "https://lucky-football-slip.netlify.app/#terms") {
                    UIApplication.shared.open(url)
                }
            }
        }
    }
    
    #if DEBUG
    // MARK: - Debug Testing Section (FIXED)

    private var debugTestingSection: some View {
        VStack(spacing: 16) {
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
            
            // API Testing Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "globe.fill")
                        .foregroundColor(AppDesignSystem.Colors.info)
                    
                    Text("API Testing")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button("API Access") {
                            Task {
                                if let footballService = ServiceProvider.shared.getMatchService() as? FootballDataMatchService {
                                    await footballService.debugAPIAccess()
                                }
                            }
                        }
                        .debugButtonStyle(color: .blue)
                        
                        Button("Recent Matches") {
                            Task {
                                if let footballService = ServiceProvider.shared.getMatchService() as? FootballDataMatchService {
                                    await footballService.debugRecentFinishedMatches()
                                }
                            }
                        }
                        .debugButtonStyle(color: .green)
                        
                        Button("Upcoming") {
                            Task {
                                if let footballService = ServiceProvider.shared.getMatchService() as? FootballDataMatchService {
                                    await footballService.debugUpcomingMatches()
                                }
                            }
                        }
                        .debugButtonStyle(color: .orange)
                    }
                }
            }
            .debugCardStyle(color: AppDesignSystem.Colors.info)
            
            // System Toggles Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "gear.2")
                        .foregroundColor(AppDesignSystem.Colors.secondary)
                    
                    Text("System Toggles")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    // GameLogicManager toggle
                    HStack {
                        Text("GameLogicManager")
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                        Button(AppConfig.useNewGameLogicManager ? "NEW ✨" : "OLD 🔧") {
                            AppConfig.toggleGameLogicManagerForTesting()
                        }
                        .debugButtonStyle(color: AppConfig.useNewGameLogicManager ? .green : .orange)
                    }
                    
                    // DataManager toggle
                    HStack {
                        Text("DataManager")
                            .font(.system(size: 16, weight: .medium))
                        
                        Spacer()
                        
                        Button(AppConfig.useNewDataManager ? "NEW ✨" : "OLD 🔧") {
                            AppConfig.toggleDataManagerForTesting()
                        }
                        .debugButtonStyle(color: AppConfig.useNewDataManager ? .blue : .orange)
                    }
                    
                    Text("Toggle between old and new systems for testing")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .debugCardStyle(color: AppDesignSystem.Colors.secondary)
            
            // Live Mode Testing Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "hammer.and.wrench.fill")
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    
                    Text("Live Mode Testing")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                }
                
                // Navigation to full test suite
                NavigationLink(destination: DebugTestView()) {
                    HStack {
                        Image(systemName: "testtube.2")
                            .foregroundColor(AppDesignSystem.Colors.primary)
                            .frame(width: 20)
                        
                        Text("Open Test Suite")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppDesignSystem.Colors.primary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                
                // Quick test buttons
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button("Smoke Test") {
                            Task {
                                await LiveModeTestRunner.shared.smokeTest()
                            }
                        }
                        .debugButtonStyle(color: .orange)
                        
                        Button("Betting Flow") {
                            Task {
                                await LiveModeTestRunner.shared.quickBettingTest()
                            }
                        }
                        .debugButtonStyle(color: .green)
                        
                        Button("API Test") {
                            Task {
                                await LiveModeTestRunner.shared.quickAPITest()
                            }
                        }
                        .debugButtonStyle(color: .purple)
                    }
                    
                    HStack(spacing: 8) {
                        Button("Debug Live Status") {
                            print("🔍 Live Mode Debug Status:")
                            print(gameSession.debugLiveModeStatus())
                        }
                        .debugButtonStyle(color: .cyan)
                        
                        Button("Event Manager") {
                            print("🔍 EventDrivenManager stats:")
                            print(EventDrivenManager.shared.getAllStats())
                        }
                        .debugButtonStyle(color: .teal)
                    }
                }
            }
            .debugCardStyle(color: AppDesignSystem.Colors.primary)
            
            // Notification Testing Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "bell.fill")
                        .foregroundColor(AppDesignSystem.Colors.warning)
                    
                    Text("Notification Testing")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    Button("Test Notification") {
                        // Manually trigger a test notification
                        NotificationCenter.default.post(
                            name: Notification.Name("MissedEventsFound"),
                            object: nil,
                            userInfo: [
                                "eventCount": 1,
                                "matchName": "TEST vs MATCH",
                                "eventType": "goal",
                                "playerName": "Test Player"
                            ]
                        )
                    }
                    .debugButtonStyle(color: .blue, fullWidth: true)
                    
                    Text("This will trigger the missed events banner in GameView")
                        .font(.system(size: 10))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            .debugCardStyle(color: AppDesignSystem.Colors.warning)
            
            // Substitution Testing Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.left.arrow.right")
                        .foregroundColor(AppDesignSystem.Colors.success)
                    
                    Text("Substitution Testing")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Button("Manual Sub") {
                            testManualSubstitution()
                        }
                        .debugButtonStyle(color: .blue)
                        
                        Button("Live Sub") {
                            testLiveSubstitution()
                        }
                        .debugButtonStyle(color: .green)
                        
                        Button("Debug State") {
                            debugSubstitutionState()
                        }
                        .debugButtonStyle(color: .purple)
                    }
                    
                    // Substitution status display
                    if let currentGame = getCurrentActiveGame() {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Current Game Status:")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Text(SubstitutionManager.shared.debugSubstitutionState(in: currentGame))
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .padding(8)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(4)
                        }
                    } else {
                        Text("No active game session")
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .italic()
                    }
                }
            }
            .debugCardStyle(color: AppDesignSystem.Colors.success)
            
            // Feature Flags Section
            featureFlagsDebugSection
            
            // Free Testing Section
            freeTestingDebugSection
            
            // Legacy subscription testing (when enabled)
            if AppConfig.subscriptionEnabled {
                legacySubscriptionDebugSection
            }
            
            // App status display
            EnhancedSettingsRow(
                title: "App Status",
                subtitle: "Subscription: \(AppConfig.subscriptionEnabled ? "Enabled" : "Disabled"), Free Testing: \(AppConfig.isFreeLiveTestingActive ? "Active" : "Inactive")",
                icon: "info.circle.fill",
                color: AppDesignSystem.Colors.secondary,
                hasAction: false
            )
        }
    }
    
    
    // MARK: - Feature Flags Debug Section (NEW)

    private var featureFlagsDebugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "flag.fill")
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Feature Flags Control")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            // Feature toggles (Note: These would need UserDefaults implementation)
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Status:")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("• Multiple Matches: \(AppConfig.PremiumFeatures.multipleMatchSelection ? "✅" : "❌")")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Text("• Unlimited Daily: \(AppConfig.PremiumFeatures.unlimitedDailyMatches ? "✅" : "❌")")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Text("• Ad-Free: \(AppConfig.PremiumFeatures.adFreeExperience ? "✅" : "❌")")
                    .font(.system(size: 12, design: .monospaced))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding(8)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(4)
            
            // Note about feature flags
            VStack(alignment: .leading, spacing: 4) {
                Text("Note:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.warning)
                
                Text("Feature flags are compile-time constants. To change them, update AppConfig.swift and rebuild.")
                    .font(.system(size: 10))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppConfig.subscriptionEnabled ? Color.blue.opacity(0.1) : Color.green.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppConfig.subscriptionEnabled ? Color.blue.opacity(0.3) : Color.green.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: - Legacy Subscription Debug Section (when enabled)

    private var legacySubscriptionDebugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(AppDesignSystem.Colors.warning)
                
                Text("Subscription Testing")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            // Subscription testing buttons
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    Button("Set Premium") {
                        AppPurchaseManager.shared.setToPremiumForTesting()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green)
                    .cornerRadius(6)
                    
                    Button("Set Free") {
                        AppPurchaseManager.shared.setToFreeForTesting()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(6)
                    
                    Button("Reset Usage") {
                        AppPurchaseManager.shared.resetDailyMatchUsageForTesting()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .cornerRadius(6)
                }
                
                Text("Tier: \(purchaseManager.currentTier.displayName), Matches: \(purchaseManager.remainingFreeMatchesToday)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Free Testing Debug Section (NEW)
    
    private var freeTestingDebugSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "gift.fill")
                    .foregroundColor(AppDesignSystem.Colors.success)
                
                Text("Free Live Mode Testing")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            // Status display
            VStack(alignment: .leading, spacing: 8) {
                Text("Status: \(AppConfig.isFreeLiveTestingActive ? "ACTIVE ✅" : "INACTIVE ❌")")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppConfig.isFreeLiveTestingActive ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                
                if AppConfig.isFreeLiveTestingActive, let startDate = AppConfig.freeTestingStartDate {
                    Text("Started: \(formatStartDate(startDate))") // Fixed: moved formatting to helper method
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            .padding(.horizontal, 4)
            
            // Control buttons
            HStack(spacing: 12) {
                Button(action: {
                    if AppConfig.isFreeLiveTestingActive {
                        FreeLiveModeTesting.endFreeTesting()
                    } else {
                        FreeLiveModeTesting.startFreeTesting()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: AppConfig.isFreeLiveTestingActive ? "stop.fill" : "play.fill")
                            .font(.system(size: 14))
                        
                        Text(AppConfig.isFreeLiveTestingActive ? "End Testing" : "Start Testing")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppConfig.isFreeLiveTestingActive ? Color.red : Color.green)
                    .cornerRadius(8)
                }
                
                Button("Export Analytics") {
                    Task { @MainActor in
                        FreeLiveModeTesting.saveAnalyticsToFile()
                    }
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Analytics preview
            VStack(alignment: .leading, spacing: 4) {
                Text("Analytics Preview:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(getTestingStatusText())
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(4)
            }
            
            // Test buttons
            HStack(spacing: 8) {
                Button("Test Live Event Ad") {
                    AdManager.shared.recordLiveMatchEvent(eventType: "test_goal")
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(6)
                
                Button("Reset Event Count") {
                    AdManager.shared.startNewLiveMatchSession()
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.purple)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.purple.opacity(0.1))
                .cornerRadius(6)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppConfig.isFreeLiveTestingActive ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppConfig.isFreeLiveTestingActive ? Color.green.opacity(0.3) : Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helper methods
    
    @MainActor
    private func getTestingStatusText() -> String {
        if AppConfig.isFreeLiveTestingActive {
            return "🎁 FREE TESTING ACTIVE\nUnlimited matches enabled"
        } else {
            return "🔒 FREE TESTING INACTIVE\n1 match per day limit"
        }
    }

    private func formatStartDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: date)
    }
    
    private func getCurrentActiveGame() -> GameSession? {
        return gameSession
    }

    private func testManualSubstitution() {
        guard let currentGame = getCurrentActiveGame() else {
            print("❌ No active game session for testing")
            return
        }
        
        print("🧪 Testing manual substitution...")
        
        // Find two players for testing
        guard currentGame.selectedPlayers.count >= 2 else {
            print("❌ Need at least 2 players for substitution test")
            return
        }
        
        let playerOff = currentGame.selectedPlayers[0]
        let playerOn = currentGame.selectedPlayers[1]
        
        // Test the substitution
        SubstitutionManager.shared.processManualSubstitution(
            playerOff: playerOff,
            playerOn: playerOn,
            minute: 65,
            in: currentGame
        )
        
        print("✅ Manual substitution test completed")
    }

    private func testLiveSubstitution() {
        guard let currentGame = getCurrentActiveGame() else {
            print("❌ No active game session for testing")
            return
        }
        
        print("🧪 Testing live substitution...")
        
        // Find players with API IDs for testing
        guard let playerOff = currentGame.selectedPlayers.first(where: { $0.apiId != nil }),
              let playerOn = currentGame.availablePlayers.first(where: {
                  $0.apiId != nil && !currentGame.selectedPlayers.contains { $0.id == $0.id }
              }) else {
            print("❌ Need players with API IDs for live substitution test")
            return
        }
        
        // Test the live substitution
        SubstitutionManager.shared.processLiveSubstitution(
            playerOutId: playerOff.apiId!,
            playerInId: playerOn.apiId!,
            minute: 73,
            teamId: playerOff.team.id.uuidString,
            in: currentGame
        )
        
        print("✅ Live substitution test completed")
    }

    private func debugSubstitutionState() {
        guard let currentGame = getCurrentActiveGame() else {
            print("❌ No active game session for debugging")
            return
        }
        
        print("🔍 Substitution Debug State:")
        print(SubstitutionManager.shared.debugSubstitutionState(in: currentGame))
        
        // Additional debug info
        print("\n🧪 Testing substitution flow...")
        let testResult = SubstitutionManager.shared.testSubstitutionFlow(in: currentGame)
        print("Test result: \(testResult ? "✅ PASS" : "❌ FAIL")")
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

// MARK: - Enhanced Components (keeping your existing ones)

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
                    .fill(AppDesignSystem.Colors.cardBackground)
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
                            
                            ProgressView(value: Double(remainingMatches), total: Double(1))
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
                                AppDesignSystem.Colors.cardBackground
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
                                AppDesignSystem.Colors.cardBackground
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [AppDesignSystem.Colors.cardBackground, AppDesignSystem.Colors.cardBackground],
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


// MARK: - Enhanced Card Modifier

extension View {
    func enhancedCard() -> some View {
        self.padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
    }
    
    func debugButtonStyle(color: Color, fullWidth: Bool = false) -> some View {
        self
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, fullWidth ? 16 : 12)
            .padding(.vertical, 6)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(color)
            .cornerRadius(6)
    }
    
    func debugCardStyle(color: Color) -> some View {
        self
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
    }
}
