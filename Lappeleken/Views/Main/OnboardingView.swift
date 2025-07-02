//
//  OnboardingView.swift
//  Lucky Football Slip
//
//  Simple onboarding flow for first-time users
//

import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @Binding var isPresented: Bool
    
    private let pages = [
        OnboardingPage(
            icon: "⚽",
            title: "Welcome to Lucky Football Slip",
            description: "The ultimate football betting game with friends",
            color: AppDesignSystem.Colors.primary
        ),
        OnboardingPage(
            icon: "🎯",
            title: "Virtual Betting Fun",
            description: "Place bets with friends using virtual money - completely free!",
            color: AppDesignSystem.Colors.accent
        ),
        OnboardingPage(
            icon: "📱",
            title: "Two Game Modes",
            description: "Choose Live Mode for real matches or Manual Mode for custom games",
            color: AppDesignSystem.Colors.info
        ),
        OnboardingPage(
            icon: "🎮",
            title: "Ready to Play!",
            description: "Start tracking matches and see who wins the most bets",
            color: AppDesignSystem.Colors.success
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    pages[currentPage].color.opacity(0.1),
                    pages[currentPage].color.opacity(0.05),
                    AppDesignSystem.Colors.background
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)
                
                // Bottom controls
                VStack(spacing: 24) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? pages[currentPage].color : Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                                .scaleEffect(currentPage == index ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Action buttons
                    HStack(spacing: 16) {
                        if currentPage > 0 {
                            Button("Back") {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage -= 1
                                }
                            }
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(pages[currentPage].color)
                        }
                        
                        Spacer()
                        
                        Button(currentPage == pages.count - 1 ? "Get Started!" : "Next") {
                            if currentPage == pages.count - 1 {
                                // Mark onboarding as completed
                                UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
                                withAnimation(.easeOut(duration: 0.5)) {
                                    isPresented = false
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    currentPage += 1
                                }
                            }
                        }
                        .font(AppDesignSystem.Typography.bodyBold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                                .fill(pages[currentPage].color)
                        )
                        .scaleEffect(currentPage == pages.count - 1 ? 1.05 : 1.0)
                        .animation(.spring(response: 0.3), value: currentPage)
                    }
                    .padding(.horizontal, AppDesignSystem.Layout.standardPadding)
                }
                .padding(.bottom, AppDesignSystem.Layout.largePadding)
            }
        }
        .onAppear {
            // Optional: Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
    }
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icon
            Text(page.icon)
                .font(.system(size: 80))
                .scaleEffect(1.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: page.icon)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(AppDesignSystem.Typography.titleFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, AppDesignSystem.Layout.standardPadding)
            
            Spacer()
        }
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}



#Preview {
    OnboardingView(isPresented: .constant(true))
}
