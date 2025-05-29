//
//  HomeView.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 08/05/2025.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var gameSession: GameSession
    @AppStorage("isLiveMode") private var isLiveMode = false
    @State private var showingNewGameSheet = false
    @State private var showingLiveInfoSheet = false
    @State private var showingHistoryView = false  // Add this state
    
    var body: some View {
        ZStack {
            AppDesignSystem.Colors.background
                .ignoresSafeArea()
            
            VStack(spacing: AppDesignSystem.Layout.largePadding) {
                // App logo and title
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                    .padding(.top, 40)
                
                Text("Lappeleken")
                    .font(AppDesignSystem.Typography.titleFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("The Football Betting Game")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .padding(.bottom, 20)
                
                // Mode selection
                gameModeSelection
                
                Spacer()
                
                // Bottom buttons
                bottomButtons
            }
            .padding()
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
    
    // MARK: - View Components
    
    private var gameModeSelection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Choose Game Mode")
                .font(AppDesignSystem.Typography.subheadingFont)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            HStack(spacing: 15) {
                manualModeButton
                liveModeButton
            }
        }
        .padding(.horizontal)
    }
    
    private var manualModeButton: some View {
        Button {
            isLiveMode = false
            UserDefaults.standard.set(false, forKey: "isLiveMode")
            NotificationCenter.default.post(
                name: Notification.Name("AppModeChanged"),
                object: nil
            )
            showingNewGameSheet = true
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 30))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Manual Mode")
                    .font(AppDesignSystem.Typography.bodyFont.bold())
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Create a custom game with your own players and events")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 180)
            .background(AppDesignSystem.Colors.cardBackground)
            .cornerRadius(AppDesignSystem.Layout.cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                    .stroke(!isLiveMode ? AppDesignSystem.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var liveModeButton: some View {
        Button {
            handleLiveModeSelection()
        } label: {
            VStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: 30))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Live Mode")
                    .font(AppDesignSystem.Typography.bodyFont.bold())
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Connect to real matches and get automatic updates")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: 180)
            .background(AppDesignSystem.Colors.cardBackground)
            .cornerRadius(AppDesignSystem.Layout.cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                    .stroke(isLiveMode ? AppDesignSystem.Colors.primary : Color.clear, lineWidth: 2)
            )
        }
    }
    
    private var bottomButtons: some View {
        VStack(spacing: 15) {
            // History button - with interstitial ad logic
            Button {
                openHistoryWithAd()
            } label: {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("Game History")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
            
            // About button
            NavigationLink(destination: HowToPlayView()) {
                HStack {
                    Image(systemName: "info.circle")
                    Text("How to Play")
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.bottom, 40)
    }
    
    private func openHistoryWithAd() {
        // Check if we should show an interstitial ad before opening history
        if AdManager.shared.shouldShowInterstitialForHistoryView() {
            showInterstitialThenOpenHistory()
        } else {
            showingHistoryView = true
        }
    }
    
    private func showInterstitialThenOpenHistory() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            // Fallback: just open history
            showingHistoryView = true
            return
        }
        
        AdManager.shared.showInterstitialAd(from: rootViewController) { success in
            DispatchQueue.main.async {
                // We can't use self here, but we can use a different approach
                // Post a notification to handle the history opening
                NotificationCenter.default.post(
                    name: Notification.Name("OpenHistoryAfterAd"),
                    object: nil
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func handleLiveModeSelection() {
        // Check for free match limit using MainActor
        Task { @MainActor in
            if AppConfig.hasReachedFreeMatchLimit {
                // Show upgrade prompt
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
        // Check if user can access live features
        if AppPurchaseManager.shared.canUseLiveFeatures {
            NotificationCenter.default.post(
                name: Notification.Name("StartLiveGameFlow"),
                object: nil
            )
        } else {
            // Show upgrade prompt
            NotificationCenter.default.post(
                name: Notification.Name("ShowUpgradePrompt"),
                object: nil
            )
        }
    }
}
