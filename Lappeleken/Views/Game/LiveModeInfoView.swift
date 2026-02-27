//
//  LiveModeInfoView.swift
//  Lucky Football Slip
//
//  Football themed live mode info screen
//

import SwiftUI

struct LiveModeInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var animateFeatures = false
    let onGetStarted: () -> Void
    
    private var remainingFreeMatches: Int {
        AppPurchaseManager.shared.remainingFreeMatchesToday
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    heroSection
                    featuresSection
                    freeModeCard
                    networkNote
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .background(footballBackground)
            .navigationTitle("Live Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Get Started") {
                        onGetStarted()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.3)) {
                animateFeatures = true
            }
        }
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            
            VStack {
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.2 : 0.1),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Hero Section
    
    private var heroSection: some View {
        VStack(spacing: 20) {
            // Icon with glow
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateFeatures ? 1.05 : 0.95)
                    .animation(
                        Animation.easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                        value: animateFeatures
                    )
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppDesignSystem.Colors.grassGreen, AppDesignSystem.Colors.grassGreen.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "globe")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                .shadow(color: AppDesignSystem.Colors.grassGreen.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            
            VStack(spacing: 8) {
                Text("About Live Mode")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Connect your game to real football matches")
                    .font(.system(size: 15))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 10)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 10) {
            ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                LiveFeatureRow(
                    icon: feature.icon,
                    title: feature.title,
                    description: feature.description,
                    color: feature.color,
                    index: index,
                    isAnimated: animateFeatures
                )
            }
        }
    }
    
    // MARK: - Free Mode Card
    
    private var freeModeCard: some View {
        VStack(spacing: 14) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                
                Text("Free Mode")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Follow 1 live match per day for free.")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                HStack {
                    Text("Remaining today:")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Text("\(remainingFreeMatches)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(remainingFreeMatches > 0 ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.error)
                }
                
                Text("Watch ads for extra matches or upgrade to premium.")
                    .font(.system(size: 11))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppDesignSystem.Colors.grassGreen.opacity(0.3), lineWidth: 1.5)
                )
        )
    }
    
    // MARK: - Network Note
    
    private var networkNote: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi")
                .font(.system(size: 16))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("Requires internet. Updates may be delayed 1-2 minutes.")
                .font(.system(size: 12))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppDesignSystem.Colors.secondaryText.opacity(0.08))
        )
    }
    
    // MARK: - Features Data
    
    private var features: [(icon: String, title: String, description: String, color: Color)] {
        [
            ("sportscourt.fill", "Select a Match", "Choose from live or upcoming matches", AppDesignSystem.Colors.grassGreen),
            ("person.2.fill", "Add Participants", "Set up who's playing in your game", AppDesignSystem.Colors.goalYellow),
            ("scalemass.fill", "Configure Bets", "Set amounts for different events", AppDesignSystem.Colors.accent),
            ("person.crop.circle.badge.checkmark", "Pick Players", "Choose players from the match", AppDesignSystem.Colors.info),
            ("clock.arrow.circlepath", "Live Updates", "Get real-time event notifications", AppDesignSystem.Colors.grassGreen)
        ]
    }
}

// MARK: - Live Feature Row

struct LiveFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let index: Int
    let isAnimated: Bool
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            .scaleEffect(isAnimated ? 1.0 : 0.7)
            .opacity(isAnimated ? 1.0 : 0.0)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.08),
                value: isAnimated
            )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .opacity(isAnimated ? 1.0 : 0.0)
            .offset(x: isAnimated ? 0 : 15)
            .animation(
                .spring(response: 0.4, dampingFraction: 0.8).delay(Double(index) * 0.08 + 0.1),
                value: isAnimated
            )
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.15) : Color.black.opacity(0.04),
                    radius: 3,
                    x: 0,
                    y: 2
                )
        )
    }
}
