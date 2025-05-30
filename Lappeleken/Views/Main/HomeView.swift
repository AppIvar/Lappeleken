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
    @State private var animateGradient = false
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
                    
                    // Enhanced mode selection cards
                    gameModeSelectionSection
                    
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
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseApp = true
            }
        }
        .showBannerAdForFreeUsers()
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.95, green: 0.97, blue: 1.0),
                    Color(red: 0.98, green: 0.95, blue: 1.0),
                    Color(red: 0.96, green: 0.98, blue: 1.0)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            
            // Floating football elements
            FloatingElementsView()
        }
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
                    features: ["Custom players", "Offline play", "Unlimited games", "Full control"]
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
                    features: ["Real matches", "Live updates", "Auto events", "Team lineups"]
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
                        Text(title)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
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

// MARK: - Floating Elements Background

struct FloatingElementsView: View {
    @State private var offset1 = CGSize.zero
    @State private var offset2 = CGSize.zero
    @State private var offset3 = CGSize.zero
    
    var body: some View {
        ZStack {
            // Floating football icons
            Image(systemName: "soccerball")
                .font(.system(size: 20))
                .foregroundColor(AppDesignSystem.Colors.primary.opacity(0.1))
                .offset(offset1)
                .animation(
                    Animation.easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: offset1
                )
            
            Image(systemName: "flag.fill")
                .font(.system(size: 16))
                .foregroundColor(AppDesignSystem.Colors.secondary.opacity(0.1))
                .offset(offset2)
                .animation(
                    Animation.easeInOut(duration: 5).repeatForever(autoreverses: true),
                    value: offset2
                )
            
            Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundColor(AppDesignSystem.Colors.accent.opacity(0.1))
                .offset(offset3)
                .animation(
                    Animation.easeInOut(duration: 6).repeatForever(autoreverses: true),
                    value: offset3
                )
        }
        .onAppear {
            offset1 = CGSize(width: 100, height: 80)
            offset2 = CGSize(width: -80, height: 120)
            offset3 = CGSize(width: 60, height: -100)
        }
    }
}
