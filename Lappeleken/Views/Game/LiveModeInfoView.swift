//
//  Enhanced LiveModeInfoView.swift
//  Lucky Football Slip
//
//  Enhanced for Free Testing Period
//

import SwiftUI

struct LiveModeInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var animateFeatures = false
    let onGetStarted: () -> Void
    
    private var remainingFreeMatches: Int {
        AppPurchaseManager.shared.remainingFreeMatchesToday
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer(minLength: 20)
                    
                    // Hero section with free testing banner
                    heroSectionWithFreeTesting
                    
                    // Feature showcase
                    liveModeFeaturesSection
                    
                    // Free testing info or normal limitations
                    if AppConfig.isFreeLiveTestingActive {
                        freeTestingInfoCard
                    } else {
                        freeModeInfoCard
                    }
                    
                    // Important notes
                    importantNotesSection
                    
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)
            }
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.98, blue: 1.0),
                        Color(red: 0.98, green: 0.96, blue: 1.0),
                        Color(red: 0.96, green: 0.97, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            )
            .navigationTitle("Live Mode")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Get Started") {
                    onGetStarted()
                    presentationMode.wrappedValue.dismiss()
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppDesignSystem.Colors.primary)
            )
        }
        .onAppear {
            withAnimation(AppDesignSystem.Animations.standard.delay(0.5)) {
                animateFeatures = true
            }
        }
    }
    
    // MARK: - Hero Section with Free Testing
    
    private var heroSectionWithFreeTesting: some View {
        VStack(spacing: 24) {
            // Free testing banner (if active)
            if AppConfig.isFreeLiveTestingActive {
                freeTestingBanner
            }
            
            // App icon with enhanced glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppDesignSystem.Colors.primary.opacity(0.4),
                                AppDesignSystem.Colors.primary.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                    .scaleEffect(animateFeatures ? 1.1 : 1.0)
                
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.primary,
                                    AppDesignSystem.Colors.info
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                
                    Image(systemName: "globe")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.white)
                }
                .shadow(
                    color: AppDesignSystem.Colors.primary.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 6
                )
            }
            
            VStack(spacing: 12) {
                Text("About Live Mode")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Live Mode connects your game to real football matches happening now. Here's how it works:")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Free Testing Banner
    
    private var freeTestingBanner: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "gift.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                Text("FREE TESTING PERIOD")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                // Beta badge
                Text("BETA")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.warning)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white)
                    .cornerRadius(4)
            }
            
            Text("Unlimited Live Mode matches for everyone! Help us test and improve the feature.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
            
            Text("⚠️ This is beta software and may contain bugs")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
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
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
        .shadow(
            color: AppDesignSystem.Colors.success.opacity(0.3),
            radius: 8,
            x: 0,
            y: 4
        )
    }
    
    // MARK: - Features Section
    
    private var liveModeFeaturesSection: some View {
        VStack(spacing: 16) {
            ForEach(Array(liveFeatures.enumerated()), id: \.offset) { index, feature in
                EnhancedLiveModeFeature(
                    feature: feature,
                    index: index,
                    isAnimated: animateFeatures
                )
            }
        }
    }
    
    // MARK: - Free Testing Info Card
    
    private var freeTestingInfoCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 24))
                    .foregroundColor(AppDesignSystem.Colors.success)
                
                Text("Free Testing Features")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureCheckmark(text: "Unlimited Live Mode matches")
                FeatureCheckmark(text: "Multiple match tracking")
                FeatureCheckmark(text: "All leagues and competitions")
                FeatureCheckmark(text: "Real-time event updates")
                
                Divider()
                    .background(AppDesignSystem.Colors.success.opacity(0.3))
                
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.warning)
                    
                    Text("Testing phase - ads will be shown and bugs may occur")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Text("After the testing period ends, Live Mode will be limited to 1 match per day for free users.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
        .enhancedCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            AppDesignSystem.Colors.success.opacity(0.5),
                            AppDesignSystem.Colors.success.opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
        )
    }
    
    // MARK: - Regular Free Mode Info Card
    
    private var freeModeInfoCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Free Mode Limitations")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("You can follow 1 live match per day in free mode.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                HStack {
                    Text("Remaining matches today:")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Text("\(remainingFreeMatches)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(remainingFreeMatches > 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                }
                
                Text("Watch ads for extra matches or upgrade to premium for unlimited access.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
        .enhancedCard()
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 2)
        )
    }
    
    // MARK: - Important Notes
    
    private var importantNotesSection: some View {
        VStack(spacing: 12) {
            Text("📶 Network Required")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("Live Mode requires an internet connection and uses data. Updates may be delayed by 1-2 minutes from the actual match.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .enhancedCard()
    }
    
    // MARK: - Supporting Data
    
    private var liveFeatures: [(icon: String, title: String, description: String, color: Color)] {
        [
            ("sportscourt.fill", "Select a Match", "Choose from live or upcoming matches from major leagues.", AppDesignSystem.Colors.primary),
            ("person.2.fill", "Set Up Participants", "Add the people who will be participating in your game.", AppDesignSystem.Colors.success),
            ("scalemass.fill", "Configure Bets", "Set your bet amounts for different types of events.", AppDesignSystem.Colors.warning),
            ("person.crop.circle.badge.checkmark", "Select Players", "Choose football players from the match to include in your game.", AppDesignSystem.Colors.info),
            ("clock.arrow.circlepath", "Live Updates", "Get real-time notifications when events happen during the match.", AppDesignSystem.Colors.secondary)
        ]
    }
}

// MARK: - Supporting Components

struct FeatureCheckmark: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(AppDesignSystem.Colors.success)
            
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
        }
    }
}

struct EnhancedLiveModeFeature: View {
    let feature: (icon: String, title: String, description: String, color: Color)
    let index: Int
    let isAnimated: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Feature icon
            ZStack {
                Circle()
                    .fill(feature.color.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: feature.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(feature.color)
            }
            .scaleEffect(isAnimated ? 1.0 : 0.8)
            .opacity(isAnimated ? 1.0 : 0.0)
            .animation(
                AppDesignSystem.Animations.standard.delay(Double(index) * 0.1),
                value: isAnimated
            )
            
            // Feature content
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(feature.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(isAnimated ? 1.0 : 0.0)
            .offset(x: isAnimated ? 0 : 20)
            .animation(
                AppDesignSystem.Animations.standard.delay(Double(index) * 0.1 + 0.2),
                value: isAnimated
            )
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}


