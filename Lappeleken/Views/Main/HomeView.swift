//
//  Enhanced HomeView.swift
//  Lucky Football Slip
//
//  Vibrant and engaging landing page
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var gameSession: GameSession
    @AppStorage("isLiveMode") private var isLiveMode = false
    @State private var showingNewGameSheet = false
    @State private var showingLiveInfoSheet = false
    @State private var showingHistoryView = false
    @State private var pulseApp = false
    
    var body: some View {
        ZStack {
            // Enhanced animated background
            backgroundView
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer(minLength: 20)
                    
                    // Enhanced app branding
                    appBrandingSection
                    
                    // Free testing banner (if active)
                    freeTestingBannerSection
                    
                    // Enhanced mode selection cards
                    VStack(spacing: 20) {
                        Text("Choose Your Game Mode")
                            .font(.system(size: 22, weight: .semibold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        VStack(spacing: 16) {
                            // Manual mode card (unchanged)
                            EnhancedModeCard(
                                title: "Manual Mode",
                                subtitle: "Create custom games with your own players",
                                icon: "gamecontroller.fill",
                                color: AppDesignSystem.Colors.secondary,
                                isSelected: !isLiveMode,
                                features: ["Custom players", "Offline play", "Unlimited games", "Full control"],
                                badge: nil
                            ) {
                                withAnimation(AppDesignSystem.Animations.bouncy) {
                                    isLiveMode = false
                                    UserDefaults.standard.set(false, forKey: "isLiveMode")
                                    NotificationCenter.default.post(
                                        name: Notification.Name("AppModeChanged"),
                                        object: nil
                                    )
                                    showingNewGameSheet = true
                                }
                            }
                            
                            // Updated live mode card
                            updatedLiveModeCard
                        }
                    }
                    
                    // Enhanced quick actions
                    quickActionsSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showingNewGameSheet) {
            NewGameSetupView(gameSession: gameSession)
        }
        .sheet(isPresented: $showingLiveInfoSheet) {
            LiveModeInfoView(onGetStarted: {
                handleLiveModeStart()
            })
        }
        .sheet(isPresented: $showingHistoryView) {
            HistoryView()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenHistoryAfterAd"))) { _ in
            showingHistoryView = true
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseApp = true
            }
        }
        .withSmartBanner()
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        AppDesignSystem.Colors.background
            .ignoresSafeArea()
    }
    
    // MARK: - App Branding
    
    private var appBrandingSection: some View {
        VStack(spacing: 20) {
            // Enhanced app icon with glow effect
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
                    .scaleEffect(pulseApp ? 1.05 : 1.0)
                
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 70, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.primary,
                                AppDesignSystem.Colors.secondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: AppDesignSystem.Colors.primary.opacity(0.3),
                        radius: 20,
                        x: 0,
                        y: 10
                    )
            }
            
            VStack(spacing: 8) {
                Text("Lappeleken")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.primaryText,
                                AppDesignSystem.Colors.primary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("The Ultimate Football Betting Game")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Free Testing Banner
    
    private var freeTestingBannerSection: some View {
        Group {
            if AppConfig.isFreeLiveTestingActive {
                freeTestingActiveBanner
            }
        }
    }
    
    private var freeTestingActiveBanner: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("FREE LIVE MODE")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("BETA")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(AppDesignSystem.Colors.warning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppDesignSystem.Colors.cardBackground)
                            .cornerRadius(4)
                    }
                    
                    Text("Unlimited matches for everyone during testing!")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                    
                    Text("No limits")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("May contain bugs")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            AppDesignSystem.Colors.success,
                            AppDesignSystem.Colors.success.opacity(0.8)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: AppDesignSystem.Colors.success.opacity(0.4),
            radius: 12,
            x: 0,
            y: 6
        )
    }
    
    // MARK: - Updated Live Mode Card
    
    private var updatedLiveModeCard: some View {
        EnhancedModeCard(
            title: "Live Mode",
            subtitle: AppConfig.isFreeLiveTestingActive ?
                "Follow unlimited real matches (Free Testing)" :
                "Follow real matches with automatic updates",
            icon: "globe",
            color: AppDesignSystem.Colors.primary,
            isSelected: isLiveMode,
            features: AppConfig.isFreeLiveTestingActive ?
                ["Real matches", "Live updates", "Auto events", "Unlimited (Testing)"] :
                ["Real matches", "Live updates", "Auto events", "Team lineups"],
            badge: AppDesignSystem.BetaBadge()
        ) {
            withAnimation(AppDesignSystem.Animations.bouncy) {
                handleLiveModeSelection()
            }
        }
    }

    // MARK: - Game Mode Selection
    
    private var gameModeSelectionSection: some View {
        VStack(spacing: 20) {
            Text("Choose Your Game Mode")
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            VStack(spacing: 16) {
                EnhancedModeCard(
                    title: "Manual Mode",
                    subtitle: "Create custom games with your own players",
                    icon: "gamecontroller.fill",
                    color: AppDesignSystem.Colors.secondary,
                    isSelected: !isLiveMode,
                    features: ["Custom players", "Offline play", "Unlimited games", "Full control"],
                    badge: nil
                ) {
                    withAnimation(AppDesignSystem.Animations.bouncy) {
                        isLiveMode = false
                        UserDefaults.standard.set(false, forKey: "isLiveMode")
                        NotificationCenter.default.post(
                            name: Notification.Name("AppModeChanged"),
                            object: nil
                        )
                        showingNewGameSheet = true
                    }
                }
                
                EnhancedModeCard(
                    title: "Live Mode",
                    subtitle: "Follow real matches with automatic updates",
                    icon: "globe",
                    color: AppDesignSystem.Colors.primary,
                    isSelected: isLiveMode,
                    features: ["Real matches", "Live updates", "Auto events", "Team lineups"],
                    badge: AppDesignSystem.BetaBadge()
                ) {
                    withAnimation(AppDesignSystem.Animations.bouncy) {
                        handleLiveModeSelection()
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            Text("Quick Actions")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            HStack(spacing: 16) {
                QuickActionCard(
                    title: "Game History",
                    icon: "clock.arrow.circlepath",
                    color: AppDesignSystem.Colors.info
                ) {
                    openHistoryWithAd()
                }
                
                // Fixed How to Play navigation
                NavigationLink(destination: HowToPlayView()) {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [AppDesignSystem.Colors.accent, AppDesignSystem.Colors.accent.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                            
                            Image(systemName: "info.circle")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .shadow(
                            color: AppDesignSystem.Colors.accent.opacity(0.3),
                            radius: 6,
                            x: 0,
                            y: 3
                        )
                        
                        Text("How to Play")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppDesignSystem.Colors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppDesignSystem.Colors.accent.opacity(0.2), lineWidth: 1)
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.06),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Methods (keeping your existing logic)
    
    private func openHistoryWithAd() {
        if AdManager.shared.shouldShowInterstitialForHistoryView() {
            showInterstitialThenOpenHistory()
        } else {
            showingHistoryView = true
        }
    }
    
    private func showInterstitialThenOpenHistory() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            showingHistoryView = true
            return
        }
        
        AdManager.shared.showInterstitialAd(from: rootViewController) { success in
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: Notification.Name("OpenHistoryAfterAd"),
                    object: nil
                )
            }
        }
    }
    
    private func handleLiveModeSelection() {
        Task { @MainActor in
            if AppConfig.hasReachedFreeMatchLimit {
                NotificationCenter.default.post(
                    name: Notification.Name("ShowUpgradePrompt"),
                    object: nil
                )
            } else {
                isLiveMode = true
                UserDefaults.standard.set(true, forKey: "isLiveMode")
                NotificationCenter.default.post(
                    name: Notification.Name("AppModeChanged"),
                    object: nil
                )
                showingLiveInfoSheet = true
            }
        }
    }
    
    private func handleLiveModeStart() {
        if AppPurchaseManager.shared.canUseLiveFeatures {
            NotificationCenter.default.post(
                name: Notification.Name("StartLiveGameFlow"),
                object: nil
            )
        } else {
            NotificationCenter.default.post(
                name: Notification.Name("ShowUpgradePrompt"),
                object: nil
            )
        }
    }
}

// MARK: - Enhanced Mode Card

struct EnhancedModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let features: [String]
    let badge: (any View)?
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
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
            VStack(spacing: 20) {
                HStack(spacing: 16) {
                    // Enhanced icon with gradient background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 60)
                        
                        Image(systemName: icon)
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .shadow(
                        color: color.opacity(0.4),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(title)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            // Add badge here if provided
                            if let badge = badge {
                                AnyView(badge)
                            }
                        }
                        
                        Text(subtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.leading)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(AppDesignSystem.Colors.success)
                    }
                }
                
                // Feature list
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(color)
                            
                            Text(feature)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            
                            Spacer()
                        }
                    }
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        isSelected ? color : color.opacity(0.3),
                                        isSelected ? color.opacity(0.7) : color.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ? color.opacity(0.2) : Color.black.opacity(0.08),
                radius: isSelected ? 12 : 6,
                x: 0,
                y: isSelected ? 6 : 3
            )
            .scaleEffect(isPressed ? 0.98 : (isSelected ? 1.02 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
    }
}
// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
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
            VStack(spacing: 12) {
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
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(.white)
                }
                .shadow(
                    color: color.opacity(0.3),
                    radius: 6,
                    x: 0,
                    y: 3
                )
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
            .shadow(
                color: Color.black.opacity(0.06),
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

