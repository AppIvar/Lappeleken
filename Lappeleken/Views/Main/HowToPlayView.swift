//
//  Enhanced HowToPlayView.swift
//  Lucky Football Slip
//
//  Vibrant and engaging tutorial experience
//

import SwiftUI

struct HowToPlayView: View {
    @State private var currentStep = 0
    @State private var animateBackground = false
    @State private var animateCards = false
    @State private var showAllSteps = false
    
    private let steps = [
        TutorialStep(
            number: "1",
            title: "Add Participants",
            description: "Enter the names of all players participating in the betting game.",
            icon: "person.3.fill",
            color: AppDesignSystem.Colors.primary,
            details: "Start by adding everyone who wants to play. Each participant will be assigned football players randomly."
        ),
        TutorialStep(
            number: "2",
            title: "Select Football Players",
            description: "Choose which football players will be part of the game.",
            icon: "sportscourt.fill",
            color: AppDesignSystem.Colors.secondary,
            details: "Pick real players from live matches or create your own custom roster for manual games."
        ),
        TutorialStep(
            number: "3",
            title: "Set Betting Amounts",
            description: "Decide how much to bet on different events like goals, assists, and cards.",
            icon: "scalemass.fill",
            color: AppDesignSystem.Colors.accent,
            details: "Configure positive and negative bets. Positive bets reward owners, negative bets penalize them."
        ),
        TutorialStep(
            number: "4",
            title: "Start the Game",
            description: "Players will be randomly assigned to participants.",
            icon: "shuffle",
            color: AppDesignSystem.Colors.info,
            details: "Watch as players are distributed fairly among all participants. The excitement begins!"
        ),
        TutorialStep(
            number: "5",
            title: "Record Events",
            description: "When a football player scores or gets a card, record it in the app.",
            icon: "plus.circle.fill",
            color: AppDesignSystem.Colors.success,
            details: "Register events as they happen. The app automatically calculates who wins and loses money for each event."
        ),
        TutorialStep(
            number: "6",
            title: "Track Winnings",
            description: "The app automatically calculates payments between participants.",
            icon: "chart.line.uptrend.xyaxis",
            color: AppDesignSystem.Colors.warning,
            details: "Watch balances update in real-time. See who's winning and losing throughout the match!"
        )
    ]
    
    var body: some View {
        ZStack {
            // Enhanced animated background
            backgroundView
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    // Enhanced header section
                    headerSection
                    
                    // Interactive tutorial controls
                    tutorialControls
                    
                    // Enhanced steps display
                    if showAllSteps {
                        allStepsView
                    } else {
                        singleStepView
                    }
                    
                    // Enhanced features section
                    featuresSection
                    
                    // Call-to-action section
                    callToActionSection
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
        }
        .navigationTitle("How to Play")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateBackground = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                    animateCards = true
                }
            }
        }
        .withSmartMonetization()
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 1.0),
                Color(red: 0.98, green: 0.95, blue: 1.0),
                Color(red: 0.96, green: 0.98, blue: 1.0),
                Color(red: 0.94, green: 0.97, blue: 1.0)
            ],
            startPoint: animateBackground ? .topLeading : .bottomTrailing,
            endPoint: animateBackground ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
        .overlay(
            FloatingTutorialElements()
        )
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Enhanced app icon with glow
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
                    .frame(width: 120, height: 120)
                    .scaleEffect(animateCards ? 1.05 : 1.0)
                
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 50, weight: .medium))
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
                        radius: 15,
                        x: 0,
                        y: 8
                    )
            }
            
            VStack(spacing: 12) {
                Text("How to Play Lappeleken")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
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
                    .multilineTextAlignment(.center)
                
                Text("Master the ultimate football betting game")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Tutorial Controls
    
    private var tutorialControls: some View {
        VStack(spacing: 16) {
            // View mode toggle
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(AppDesignSystem.Animations.bouncy) {
                        showAllSteps = false
                        currentStep = 0
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 16))
                        Text("Step by Step")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(showAllSteps ? AppDesignSystem.Colors.secondaryText : .white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                showAllSteps ?
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.Colors.primary,
                                        AppDesignSystem.Colors.primary.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    withAnimation(AppDesignSystem.Animations.bouncy) {
                        showAllSteps = true
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "list.bullet.circle.fill")
                            .font(.system(size: 16))
                        Text("Show All")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(!showAllSteps ? AppDesignSystem.Colors.secondaryText : .white)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                !showAllSteps ?
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.1)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.Colors.secondary,
                                        AppDesignSystem.Colors.secondary.opacity(0.8)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Step counter for single step view
            if !showAllSteps {
                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Circle()
                            .fill(
                                index <= currentStep ?
                                AppDesignSystem.Colors.primary :
                                AppDesignSystem.Colors.secondaryText.opacity(0.3)
                            )
                            .frame(width: 8, height: 8)
                            .scaleEffect(index == currentStep ? 1.3 : 1.0)
                            .animation(AppDesignSystem.Animations.bouncy, value: currentStep)
                    }
                }
                
                Text("Step \(currentStep + 1) of \(steps.count)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
    
    // MARK: - Single Step View
    
    private var singleStepView: some View {
        VStack(spacing: 24) {
            EnhancedTutorialCard(
                step: steps[currentStep],
                isExpanded: true,
                animateCards: animateCards
            )
            
            // Navigation buttons
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button(action: {
                        withAnimation(AppDesignSystem.Animations.bouncy) {
                            currentStep = max(0, currentStep - 1)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .medium))
                            Text("Previous")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(AppDesignSystem.Colors.primary)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppDesignSystem.Colors.primary.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                Spacer()
                
                if currentStep < steps.count - 1 {
                    Button(action: {
                        withAnimation(AppDesignSystem.Animations.bouncy) {
                            currentStep = min(steps.count - 1, currentStep + 1)
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text("Next")
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppDesignSystem.Colors.primary,
                                            AppDesignSystem.Colors.primary.opacity(0.8)
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .vibrantButton()
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
    
    // MARK: - All Steps View
    
    private var allStepsView: some View {
        VStack(spacing: 16) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                EnhancedTutorialCard(
                    step: step,
                    isExpanded: false,
                    animateCards: animateCards
                )
                .onTapGesture {
                    withAnimation(AppDesignSystem.Animations.bouncy) {
                        showAllSteps = false
                        currentStep = index
                    }
                }
            }
        }
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Game Features")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                FeatureCard(
                    icon: "globe",
                    title: "Live Mode",
                    description: "Follow real matches with automatic updates",
                    color: AppDesignSystem.Colors.success
                )
                
                FeatureCard(
                    icon: "gamecontroller.fill",
                    title: "Manual Mode",
                    description: "Create custom games with your own players",
                    color: AppDesignSystem.Colors.info
                )
                
                FeatureCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Live Stats",
                    description: "Track performance and winnings in real-time",
                    color: AppDesignSystem.Colors.accent
                )
                
                FeatureCard(
                    icon: "person.3.fill",
                    title: "Multiplayer",
                    description: "Play with friends and family members",
                    color: AppDesignSystem.Colors.warning
                )
            }
        }
    }
    
    // MARK: - Call to Action
    
    private var callToActionSection: some View {
        VStack(spacing: 16) {
            Text("Ready to Start Playing?")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
                .multilineTextAlignment(.center)
            
            Text("Create your first game and experience the excitement!")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            NavigationLink(destination: ContentView()) {
                HStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 20))
                    
                    Text("Start Playing Now")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.success,
                                    AppDesignSystem.Colors.grassGreen
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .vibrantButton(color: AppDesignSystem.Colors.success)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.success.opacity(0.3),
                                    AppDesignSystem.Colors.primary.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 12,
            x: 0,
            y: 6
        )
    }
}

// MARK: - Tutorial Step Model

struct TutorialStep {
    let number: String
    let title: String
    let description: String
    let icon: String
    let color: Color
    let details: String
}

// MARK: - Enhanced Tutorial Card

struct EnhancedTutorialCard: View {
    let step: TutorialStep
    let isExpanded: Bool
    let animateCards: Bool
    
    @State private var cardScale: CGFloat = 0.8
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Enhanced step number with glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    step.color.opacity(0.3),
                                    step.color.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 15,
                                endRadius: 30
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [step.color, step.color.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Text(step.number)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .shadow(
                    color: step.color.opacity(0.4),
                    radius: 8,
                    x: 0,
                    y: 4
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(step.title)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(step.description)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .lineLimit(isExpanded ? nil : 2)
                }
                
                Spacer()
                
                Image(systemName: step.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(step.color.opacity(0.7))
            }
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    step.color.opacity(0.3),
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1)
                    
                    Text(step.details)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .lineSpacing(4)
                    
                    HStack(spacing: 8) {
                        VibrantStatusBadge("Tip", color: step.color)
                        
                        Text("Tap any step card to learn more")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .italic()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            AppDesignSystem.Colors.cardBackground,
                            step.color.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    step.color.opacity(0.3),
                                    step.color.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: step.color.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
        .scaleEffect(cardScale)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(Double.random(in: 0...0.3))) {
                cardScale = 1.0
            }
        }
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Floating Tutorial Elements

struct FloatingTutorialElements: View {
    @State private var offset1 = CGSize.zero
    @State private var offset2 = CGSize.zero
    @State private var offset3 = CGSize.zero
    @State private var offset4 = CGSize.zero
    
    var body: some View {
        ZStack {
            Image(systemName: "person.3.fill")
                .font(.system(size: 18))
                .foregroundColor(AppDesignSystem.Colors.primary.opacity(0.1))
                .offset(offset1)
                .animation(
                    Animation.easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: offset1
                )
            
            Image(systemName: "soccerball")
                .font(.system(size: 16))
                .foregroundColor(AppDesignSystem.Colors.success.opacity(0.1))
                .offset(offset2)
                .animation(
                    Animation.easeInOut(duration: 5).repeatForever(autoreverses: true),
                    value: offset2
                )
            
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 14))
                .foregroundColor(AppDesignSystem.Colors.accent.opacity(0.1))
                .offset(offset3)
                .animation(
                    Animation.easeInOut(duration: 6).repeatForever(autoreverses: true),
                    value: offset3
                )
            
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 12))
                .foregroundColor(AppDesignSystem.Colors.info.opacity(0.1))
                .offset(offset4)
                .animation(
                    Animation.easeInOut(duration: 7).repeatForever(autoreverses: true),
                    value: offset4
                )
        }
        .onAppear {
            offset1 = CGSize(width: 100, height: 80)
            offset2 = CGSize(width: -80, height: 120)
            offset3 = CGSize(width: 60, height: -100)
            offset4 = CGSize(width: -60, height: -80)
        }
    }
}
