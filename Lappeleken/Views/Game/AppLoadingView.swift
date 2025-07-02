//
//  AppLoadingView.swift
//  Lucky Football Slip
//
//  App startup loading screen
//

import SwiftUI

struct AppLoadingView: View {
    @State private var isAnimating = false
    @State private var currentTip = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var showMainContent = false
    
    private let loadingTips = [
        "🎯 Welcome to Lucky Football Slip!",
        "⚽ Track goals, assists, and cards",
        "💰 See who wins and loses money",
        "🏆 The ultimate football betting game",
        "🎮 Ready to play? Let's get started!"
    ]
    
    var body: some View {
        ZStack {
            // App brand gradient background
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.primary,
                    AppDesignSystem.Colors.primary.opacity(0.8),
                    AppDesignSystem.Colors.secondary.opacity(0.6)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App logo/icon area
                VStack(spacing: 24) {
                    // Main app icon
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .scaleEffect(isAnimating ? 1.05 : 0.95)
                            .animation(
                                Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        VStack(spacing: 8) {
                            Image(systemName: "soccerball")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundColor(.white)
                            
                            Text("LFS")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)
                    
                    // App name and subtitle
                    VStack(spacing: 8) {
                        Text("Lucky Football Slip")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("The Ultimate Football Betting Game")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .opacity(textOpacity)
                }
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 20) {
                    // Spinning loading indicator
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                    
                    // Rotating tips
                    Text(loadingTips[currentTip])
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .id("tip-\(currentTip)")
                        .opacity(textOpacity)
                }
                
                Spacer()
            }
        }
        .onAppear {
            startLoadingSequence()
        }
    }
    
    private func startLoadingSequence() {
        // Logo animation
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        // Text animation (delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.6)) {
                textOpacity = 1.0
            }
        }
        
        // Start other animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation {
                isAnimating = true
            }
            
            // Start tip rotation
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentTip = (currentTip + 1) % loadingTips.count
                }
            }
        }
    }
}

// MARK: - Main App View with Loading State

struct MainAppView: View {
    @State private var isLoading = true
    @State private var hasCompletedStartup = false
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    
    var body: some View {
        ZStack {
            if isLoading {
                AppLoadingView()
                    .transition(.opacity)
            } else {
                ContentView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isLoading)
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
        .onAppear {
            if !hasCompletedStartup {
                startupSequence()
                hasCompletedStartup = true
            }
        }
    }
    
    private func startupSequence() {
        // Initialize app services
        ManualModeManager.shared.initialize()
        
        // Validate configuration
        AppConfig.validateConfiguration()
        
        // Simulate app initialization tasks
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeInOut(duration: 0.5)) {
                isLoading = false
            }
        }
    }
}

#Preview {
    MainAppView()
}
