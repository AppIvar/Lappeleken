//
//  Enhanced AssignPlayersView.swift
//  Lucky Football Slip
//
//  Vibrant and engaging player assignment experience
//

import SwiftUI

struct AssignPlayersView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @State private var assignmentComplete = false
    @State private var showConfetti = false
    @State private var currentParticipantIndex = -1
    @State private var assignedPlayerIds: [UUID] = []
    @State private var pulseButton = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced animated background
                backgroundView
                
                VStack(spacing: 0) {
                    if !assignmentComplete {
                        // Before assignment - vibrant waiting state
                        preAssignmentView
                    } else {
                        // After assignment - celebratory reveal
                        postAssignmentView
                    }
                }
                .padding()
            }
            .navigationTitle("Player Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulseButton = true
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        AppDesignSystem.Colors.background
            .ignoresSafeArea()
    }
    
    // MARK: - Pre-Assignment View
    
    private var preAssignmentView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Enhanced icon with glow effect
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
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)
                
                Image(systemName: "shuffle")
                    .font(.system(size: 80, weight: .medium))
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
            
            VStack(spacing: 16) {
                Text("Ready to Assign Players")
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
                
                Text("Players will be randomly assigned to participants")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                // Enhanced stats preview
                statsPreviewCard
            }
            
            Spacer()
            
            // Enhanced assign button
            Button(action: assignPlayers) {
                HStack(spacing: 12) {
                    Image(systemName: "shuffle.circle.fill")
                        .font(.system(size: 24))
                    
                    Text("Assign Players")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.primary,
                                    AppDesignSystem.Colors.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(
                    color: AppDesignSystem.Colors.primary.opacity(0.4),
                    radius: 12,
                    x: 0,
                    y: 6
                )
                .scaleEffect(pulseButton ? 1.02 : 1.0)
            }
            .padding(.horizontal, 30)
            
            Spacer(minLength: 40)
        }
    }
    
    // MARK: - Post-Assignment View
    
    private var postAssignmentView: some View {
        VStack(spacing: 24) {
            // Enhanced success header
            VStack(spacing: 16) {
                if showConfetti {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppDesignSystem.Colors.success.opacity(0.3),
                                        AppDesignSystem.Colors.success.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.Colors.success,
                                        AppDesignSystem.Colors.grassGreen
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: AppDesignSystem.Colors.success.opacity(0.3),
                                radius: 15,
                                x: 0,
                                y: 8
                            )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Text("Players Assigned!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.success,
                                AppDesignSystem.Colors.primary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // Enhanced participants list
            ScrollView(showsIndicators: false) {
                LazyVStack(spacing: 16) {
                    ForEach(0..<gameSession.participants.count, id: \.self) { index in
                        AssignmentParticipantCard(
                            participant: gameSession.participants[index],
                            isRevealed: index <= currentParticipantIndex,
                            assignedPlayerIds: assignedPlayerIds
                        )
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Enhanced start game button
            if currentParticipantIndex >= gameSession.participants.count - 1 {
                Button(action: startGameAction) {
                    HStack(spacing: 12) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 24))
                        
                        Text("Start Game")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
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
                    .shadow(
                        color: AppDesignSystem.Colors.success.opacity(0.4),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                }
                .padding(.horizontal, 30)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
    
    // MARK: - Stats Preview Card
    
    private var statsPreviewCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatPreviewItem(
                    icon: "person.2.fill",
                    value: "\(gameSession.participants.count)",
                    label: "Participants",
                    color: AppDesignSystem.Colors.primary
                )
                
                StatPreviewItem(
                    icon: "sportscourt.fill",
                    value: "\(gameSession.selectedPlayers.count)",
                    label: "Players",
                    color: AppDesignSystem.Colors.secondary
                )
                
                if !gameSession.selectedPlayers.isEmpty && !gameSession.participants.isEmpty {
                    StatPreviewItem(
                        icon: "divide.circle.fill",
                        value: "\(gameSession.selectedPlayers.count / gameSession.participants.count)",
                        label: "Per Person",
                        color: AppDesignSystem.Colors.accent
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppDesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Methods
    
    private func assignPlayers() {
        print("AssignPlayersView - Before assignment:")
        print("Participants: \(gameSession.participants.count)")
        print("Selected players: \(gameSession.selectedPlayers.count)")
        
        guard !gameSession.participants.isEmpty && !gameSession.selectedPlayers.isEmpty else {
            print("ERROR: Cannot assign players, starting game without assignment")
            NotificationCenter.default.post(name: Notification.Name("StartGame"), object: nil)
            presentationMode.wrappedValue.dismiss()
            return
        }
        
        gameSession.assignPlayersRandomly()
        
        withAnimation(AppDesignSystem.Animations.bouncy) {
            assignmentComplete = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateNextParticipant()
            }
        }
    }
    
    private func animateNextParticipant() {
        currentParticipantIndex += 1
        
        if currentParticipantIndex < gameSession.participants.count {
            let participant = gameSession.participants[currentParticipantIndex]
            
            for (index, player) in participant.selectedPlayers.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                    withAnimation(AppDesignSystem.Animations.bouncy) {
                        assignedPlayerIds.append(player.id)
                    }
                }
            }
            
            let playerCount = participant.selectedPlayers.count
            let delay = Double(playerCount) * 0.3 + 0.7
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                animateNextParticipant()
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(AppDesignSystem.Animations.bouncy) {
                    showConfetti = true
                }
            }
        }
    }
    
    private func startGameAction() {
        if AppPurchaseManager.shared.currentTier == .free && AdManager.shared.shouldShowInterstitialAfterGameComplete() {
            showInterstitialBeforeStartingGame()
        } else {
            startGame()
        }
    }
    
    private func showInterstitialBeforeStartingGame() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            startGame()
            return
        }
        
        print("🎯 Showing interstitial ad before starting game")
        
        AdManager.shared.showInterstitialAd(from: rootViewController) { success in
            DispatchQueue.main.async {
                if success {
                    print("✅ Interstitial ad shown before game start")
                    AdManager.shared.trackAdImpression(type: "interstitial_game_start")
                }
                self.startGame()
            }
        }
    }
    
    private func startGame() {
        // IMPORTANT: Preserve custom events before any transitions
        let existingCustomEvents = gameSession.getCustomEvents()
        print("🔄 Starting game with \(existingCustomEvents.count) custom events to preserve")
        
        // Force update to ensure UI reflects current state
        gameSession.objectWillChange.send()
        
        // Auto-fix custom event mappings before starting
        if !existingCustomEvents.isEmpty {
            gameSession.debugAndFixCustomEventMappings()
        }
        
        // Post the start game notification
        NotificationCenter.default.post(name: Notification.Name("StartGame"), object: nil)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Assignment Participant Card

struct AssignmentParticipantCard: View {
    let participant: Participant
    let isRevealed: Bool
    let assignedPlayerIds: [UUID]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Participant header
            HStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.primary,
                                AppDesignSystem.Colors.primary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(participant.name.prefix(1)).uppercased())
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(participant.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("\(participant.selectedPlayers.count) players")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if isRevealed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppDesignSystem.Colors.success)
                }
            }
            
            // Players list
            if isRevealed {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(participant.selectedPlayers) { player in
                        AssignmentPlayerChip(
                            player: player,
                            isVisible: assignedPlayerIds.contains(player.id)
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isRevealed ?
                            AppDesignSystem.Colors.primary.opacity(0.3) :
                            Color.gray.opacity(0.2),
                            lineWidth: isRevealed ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isRevealed ?
            AppDesignSystem.Colors.primary.opacity(0.15) :
            Color.black.opacity(0.05),
            radius: isRevealed ? 8 : 2,
            x: 0,
            y: isRevealed ? 4 : 1
        )
        .opacity(isRevealed ? 1.0 : 0.6)
        .scaleEffect(isRevealed ? 1.0 : 0.95)
        .animation(AppDesignSystem.Animations.bouncy, value: isRevealed)
    }
}

// MARK: - Assignment Player Chip

struct AssignmentPlayerChip: View {
    let player: Player
    let isVisible: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .lineLimit(1)
                
                Text(player.team.shortName)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.TeamColors.getAccentColor(for: player.team))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.3), lineWidth: 1)
                )
        )
        .opacity(isVisible ? 1.0 : 0.0)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .animation(
            AppDesignSystem.Animations.bouncy.delay(Double.random(in: 0...0.3)),
            value: isVisible
        )
    }
}

// MARK: - Stat Preview Item

struct StatPreviewItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
    }
}

