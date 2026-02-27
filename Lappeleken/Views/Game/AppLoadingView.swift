//
//  AppLoadingView.swift
//  Lucky Football Slip
//
//  App startup loading screen - Football themed
//

import SwiftUI

struct AppLoadingView: View {
    @State private var isAnimating = false
    @State private var currentTip = 0
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var ballRotation: Double = 0
    
    private let loadingTips = [
        "🎯 Welcome to Lucky Football Slip!",
        "⚽ Track goals, assists, and cards",
        "💰 See who wins and loses money",
        "🏆 The ultimate football betting game",
        "🎮 Ready to play? Let's get started!"
    ]
    
    var body: some View {
        ZStack {
            // Football pitch gradient
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.grassGreen,
                    AppDesignSystem.Colors.grassGreen.opacity(0.85),
                    Color(red: 0.1, green: 0.4, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Pitch decorations
            pitchDecoration
            
            VStack(spacing: 40) {
                Spacer()
                logoSection
                Spacer()
                loadingSection
                Spacer()
            }
        }
        .onAppear { startLoadingSequence() }
    }
    
    // MARK: - Pitch Decoration
    
    private var pitchDecoration: some View {
        GeometryReader { geo in
            ZStack {
                // Center circle
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 2)
                    .frame(width: geo.size.width * 0.5)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
                
                // Center dot
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 12, height: 12)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
                
                // Halfway line
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: geo.size.width, height: 2)
                    .position(x: geo.size.width / 2, y: geo.size.height * 0.35)
            }
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        VStack(spacing: 24) {
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .scaleEffect(isAnimating ? 1.1 : 0.95)
                    .animation(Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                
                // Inner circle
                Circle()
                    .fill(Color.white)
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                
                // Football icon
                VStack(spacing: 6) {
                    Image(systemName: "soccerball")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                        .rotationEffect(.degrees(ballRotation))
                    
                    Text("LFS")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
            .scaleEffect(logoScale)
            .opacity(logoOpacity)
            
            // App name
            VStack(spacing: 10) {
                Text("Lucky Football Slip")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("The Ultimate Football Betting Game")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
            .opacity(textOpacity)
        }
    }
    
    // MARK: - Loading Section
    
    private var loadingSection: some View {
        VStack(spacing: 24) {
            // Loading dots
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .opacity(isAnimating ? 1.0 : 0.3)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            
            // Tips
            Text(loadingTips[currentTip])
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
                .id("tip-\(currentTip)")
                .opacity(textOpacity)
        }
    }
    
    // MARK: - Animation Sequence
    
    private func startLoadingSequence() {
        withAnimation(.easeOut(duration: 0.8)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.6)) { textOpacity = 1.0 }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation { isAnimating = true }
            withAnimation(Animation.linear(duration: 20).repeatForever(autoreverses: false)) {
                ballRotation = 360
            }
            Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    currentTip = (currentTip + 1) % loadingTips.count
                }
            }
        }
    }
}

// MARK: - Main App View

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
        ManualModeManager.shared.initialize()
        AppConfig.validateConfiguration()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeInOut(duration: 0.5)) { isLoading = false }
        }
    }
}

#Preview {
    AppLoadingView()
}
