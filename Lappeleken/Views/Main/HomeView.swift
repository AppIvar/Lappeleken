//
//  HomeView.swift
//  Lucky Football Slip
//
//  Football pitch themed home - Apple Sports inspired
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var gameSession: GameSession
    @AppStorage("isLiveMode") private var isLiveMode = false
    @State private var showingNewGameSheet = false
    @State private var showingLiveInfoSheet = false
    @State private var showingHistoryView = false
    
    var body: some View {
        ZStack {
            // Football pitch themed background
            FootballPitchBackground()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    Spacer(minLength: 16)
                    
                    // App branding
                    appBrandingSection
                    
                    // Mode selection
                    modeSelectionSection
                    
                    // Quick actions
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
        .withMinimalBanner()
    }
    
    // MARK: - App Branding
    
    private var appBrandingSection: some View {
        VStack(spacing: 16) {
            // App icon with football styling
            ZStack {
                // Glow effect
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(0.3))
                    .frame(width: 120, height: 120)
                    .blur(radius: 20)
                
                // Main icon
                ZStack {
                    Circle()
                        .fill(AppDesignSystem.Colors.grassGreen)
                        .frame(width: 88, height: 88)
                    
                    // Pitch lines on icon
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(.white)
                }
                .shadow(color: AppDesignSystem.Colors.grassGreen.opacity(0.5), radius: 16, x: 0, y: 8)
            }
            
            VStack(spacing: 6) {
                Text("Lucky Football Slip")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("The Ultimate Football Betting Game")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
    
    // MARK: - Mode Selection
    
    private var modeSelectionSection: some View {
        VStack(spacing: 16) {
            // Section header
            HStack {
                Text("Choose Game Mode")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                Spacer()
            }
            
            VStack(spacing: 12) {
                // Live Mode Card
                GameModeCard(
                    title: "Live Mode",
                    subtitle: "Real matches with automatic updates",
                    icon: "antenna.radiowaves.left.and.right",
                    accentColor: AppDesignSystem.Colors.grassGreen,
                    features: ["Real lineups", "Live events", "Auto tracking"],
                    badge: isLiveMode ? "SELECTED" : nil
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        handleLiveModeSelection()
                    }
                }
                
                // Manual Mode Card
                GameModeCard(
                    title: "Manual Mode",
                    subtitle: "Custom games with your own players",
                    icon: "gamecontroller.fill",
                    accentColor: AppDesignSystem.Colors.goalYellow,
                    features: ["Custom players", "Offline play", "Full control"],
                    badge: !isLiveMode ? "SELECTED" : nil
                ) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        isLiveMode = false
                        UserDefaults.standard.set(false, forKey: "isLiveMode")
                        NotificationCenter.default.post(
                            name: Notification.Name("AppModeChanged"),
                            object: nil
                        )
                        showingNewGameSheet = true
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Quick Actions")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                Spacer()
            }
            
            HStack(spacing: 12) {
                QuickActionCard(
                    title: "History",
                    icon: "clock.arrow.circlepath",
                    color: AppDesignSystem.Colors.primary
                ) {
                    openHistoryWithAd()
                }
                
                NavigationLink(destination: HowToPlayView()) {
                    QuickActionCardContent(
                        title: "How to Play",
                        icon: "questionmark.circle",
                        color: AppDesignSystem.Colors.accent
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func openHistoryWithAd() {
        if AdManager.shared.shouldShowInterstitial(for: .historyView) {
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

// MARK: - Football Pitch Background

struct FootballPitchBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    private var isDark: Bool { colorScheme == .dark }
    
    var body: some View {
        ZStack {
            // Base - slightly tinted green instead of pure gray
            Color(isDark ? UIColor(red: 0.05, green: 0.09, blue: 0.07, alpha: 1) : UIColor(red: 0.95, green: 0.97, blue: 0.95, alpha: 1))
            
            // Strong green gradient from top
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.grassGreen.opacity(isDark ? 0.25 : 0.12),
                    AppDesignSystem.Colors.grassGreen.opacity(isDark ? 0.08 : 0.04),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .center
            )
            
            // Bottom subtle gold accent
            VStack {
                Spacer()
                LinearGradient(
                    colors: [
                        Color.clear,
                        AppDesignSystem.Colors.goalYellow.opacity(isDark ? 0.06 : 0.03)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
            }
            
            // Pitch line decorations
            GeometryReader { geo in
                // Center circle
                Circle()
                    .stroke(
                        AppDesignSystem.Colors.grassGreen.opacity(isDark ? 0.15 : 0.08),
                        lineWidth: 1.5
                    )
                    .frame(width: geo.size.width * 0.5)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.12)
                
                // Center dot
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(isDark ? 0.2 : 0.1))
                    .frame(width: 8, height: 8)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.12)
                
                // Halfway line
                Rectangle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(isDark ? 0.1 : 0.05))
                    .frame(width: geo.size.width, height: 1.5)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.12)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Game Mode Card

struct GameModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let features: [String]
    let badge: String?
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Accent top strip
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 4)
                
                VStack(alignment: .leading, spacing: 14) {
                    // Header
                    HStack(spacing: 12) {
                        // Icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(accentColor.opacity(0.15))
                                .frame(width: 48, height: 48)
                            
                            Image(systemName: icon)
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 8) {
                                Text(title)
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                
                                if let badge = badge {
                                    Text(badge)
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(accentColor))
                                }
                            }
                            
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    // Features row
                    HStack(spacing: 6) {
                        ForEach(features, id: \.self) { feature in
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                Text(feature)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(accentColor.opacity(0.1))
                            )
                        }
                        Spacer()
                    }
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            QuickActionCardContent(title: title, icon: icon, color: color)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct QuickActionCardContent: View {
    let title: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.06),
                    radius: 6,
                    x: 0,
                    y: 3
                )
        )
    }
}
// MARK: - Previews

#if DEBUG
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let gameSession = GameSession()
        
        return Group {
            NavigationView {
                HomeView()
                    .environmentObject(gameSession)
            }
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")
            
            NavigationView {
                HomeView()
                    .environmentObject(gameSession)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}

struct FootballPitchBackground_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FootballPitchBackground()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            FootballPitchBackground()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}

struct GameModeCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            GameModeCard(
                title: "Live Mode",
                subtitle: "Real matches with automatic updates",
                icon: "antenna.radiowaves.left.and.right",
                accentColor: AppDesignSystem.Colors.grassGreen,
                features: ["Real lineups", "Live events", "Auto tracking"],
                badge: "SELECTED"
            ) { }
            
            GameModeCard(
                title: "Manual Mode",
                subtitle: "Custom games with your own players",
                icon: "gamecontroller.fill",
                accentColor: AppDesignSystem.Colors.goalYellow,
                features: ["Custom players", "Offline play", "Full control"],
                badge: nil
            ) { }
        }
        .padding()
        .background(AppDesignSystem.Colors.background)
    }
}
#endif

