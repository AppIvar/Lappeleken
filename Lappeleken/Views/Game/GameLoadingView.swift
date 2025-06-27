//
//  GameLoadingView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 27/06/2025.
//

import SwiftUI

struct GameLoadingView: View {
    @State private var isAnimating = false
    @State private var currentTip = 0
    @State private var progress: CGFloat = 0
    @State private var showProgress = false
    
    private let loadingTips = [
        "🎯 Pro tip: Watch for yellow cards - they can change the game!",
        "⚽ You set the value on the bets",
        "🔄 You can substitute players during the match",
        "💰 Keep an eye on your balance in real-time",
        "🏆 The participant with the highest balance wins!",
        "📊 Check the timeline to see all events",
        "🎮 Tap players to record events as they happen"
    ]
    
    var body: some View {
        ZStack {
            // Dynamic background gradient
            LinearGradient(
                colors: [
                    AppDesignSystem.Colors.primary.opacity(0.1),
                    AppDesignSystem.Colors.secondary.opacity(0.05),
                    AppDesignSystem.Colors.accent.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Main loading animation
                VStack(spacing: 24) {
                    // Animated football icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.Colors.primary.opacity(0.2),
                                        AppDesignSystem.Colors.primary.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(isAnimating ? 1.1 : 0.9)
                            .animation(
                                Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                                value: isAnimating
                            )
                        
                        Image(systemName: "soccerball")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.primary)
                            .rotationEffect(.degrees(isAnimating ? 360 : 0))
                            .animation(
                                Animation.linear(duration: 3).repeatForever(autoreverses: false),
                                value: isAnimating
                            )
                    }
                    
                    // Loading text
                    VStack(spacing: 8) {
                        Text("Setting up your game...")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Preparing players and betting rules")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                
                // Progress bar (optional)
                if showProgress {
                    VStack(spacing: 12) {
                        ProgressView(value: progress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: AppDesignSystem.Colors.primary))
                            .scaleEffect(y: 2)
                            .padding(.horizontal, 40)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Rotating tips
                VStack(spacing: 16) {
                    Text("💡 Game Tip")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.accent)
                    
                    Text(loadingTips[currentTip])
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                        .id("tip-\(currentTip)")
                }
                .frame(minHeight: 80)
                
                Spacer()
            }
        }
        .onAppear {
            startLoadingAnimation()
        }
    }
    
    private func startLoadingAnimation() {
        withAnimation {
            isAnimating = true
        }
        
        // Start tip rotation
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.5)) {
                currentTip = (currentTip + 1) % loadingTips.count
            }
        }
        
        // Optional: Show progress animation after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation {
                showProgress = true
            }
            
            // Animate progress bar
            withAnimation(.easeInOut(duration: 2.0)) {
                progress = 1.0
            }
        }
    }
}

// MARK: - Simple Loading View (Alternative)

struct SimpleGameLoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Simple spinner
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppDesignSystem.Colors.primary))
                    .scaleEffect(1.5)
                
                Text("Starting Game...")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            .padding(40)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            )
        }
    }
}

#Preview {
    GameLoadingView()
}
