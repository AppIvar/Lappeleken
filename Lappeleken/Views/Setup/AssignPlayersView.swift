//
//  AssignPlayersView.swift
//  Lucky Football Slip
//
//  Player assignment experience - Football themed
//

import SwiftUI

struct AssignPlayersView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var assignmentComplete = false
    @State private var showConfetti = false
    @State private var currentParticipantIndex = -1
    @State private var assignedPlayerIds: [UUID] = []
    @State private var pulseButton = false
    
    var body: some View {
        NavigationView {
            ZStack {
                footballBackground
                
                VStack(spacing: 0) {
                    if !assignmentComplete {
                        preAssignmentView
                    } else {
                        postAssignmentView
                    }
                }
                .padding()
            }
            .navigationTitle("Player Assignment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
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
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            
            VStack {
                LinearGradient(
                    colors: [AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.15 : 0.08), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Pre-Assignment View
    
    private var preAssignmentView: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon with glow
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseButton ? 1.1 : 1.0)
                
                Image(systemName: "shuffle")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
            }
            
            VStack(spacing: 12) {
                Text("Ready to Assign")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Players will be randomly distributed")
                    .font(.system(size: 15))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            // Stats preview
            statsPreviewCard
            
            Spacer()
            
            // Assign button
            Button(action: assignPlayers) {
                HStack(spacing: 10) {
                    Image(systemName: "shuffle.circle.fill")
                        .font(.system(size: 20))
                    Text("Assign Players")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppDesignSystem.Colors.grassGreen)
                        .shadow(color: AppDesignSystem.Colors.grassGreen.opacity(0.3), radius: 10, x: 0, y: 5)
                )
            }
            .scaleEffect(pulseButton ? 1.02 : 1.0)
            .padding(.horizontal, 20)
            
            Spacer(minLength: 30)
        }
    }
    
    // MARK: - Stats Preview Card
    
    private var statsPreviewCard: some View {
        HStack(spacing: 0) {
            AssignStatItem(
                icon: "person.3.fill",
                value: "\(gameSession.participants.count)",
                label: "Participants",
                color: AppDesignSystem.Colors.grassGreen
            )
            
            Divider()
                .frame(height: 40)
                .padding(.horizontal, 8)
            
            AssignStatItem(
                icon: "sportscourt.fill",
                value: "\(gameSession.selectedPlayers.count)",
                label: "Players",
                color: AppDesignSystem.Colors.info
            )
            
            Divider()
                .frame(height: 40)
                .padding(.horizontal, 8)
            
            let perParticipant = gameSession.participants.isEmpty ? 0 : gameSession.selectedPlayers.count / gameSession.participants.count
            AssignStatItem(
                icon: "person.crop.circle.badge.checkmark",
                value: "~\(perParticipant)",
                label: "Each",
                color: AppDesignSystem.Colors.goalYellow
            )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Post-Assignment View
    
    private var postAssignmentView: some View {
        VStack(spacing: 20) {
            // Success header
            if showConfetti {
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(AppDesignSystem.Colors.grassGreen)
                    }
                    
                    Text("Players Assigned!")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Participant cards
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(gameSession.participants.enumerated()), id: \.element.id) { index, participant in
                        AssignParticipantCard(
                            participant: participant,
                            isRevealed: currentParticipantIndex >= index,
                            assignedPlayerIds: assignedPlayerIds
                        )
                    }
                }
            }
            
            // Start Game button
            Button(action: startGameAction) {
                HStack(spacing: 10) {
                    Image(systemName: "play.fill")
                    Text("Start Game")
                }
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(showConfetti ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.3))
                )
            }
            .disabled(!showConfetti)
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Assignment Logic
    
    private func assignPlayers() {
        var shuffledPlayers = gameSession.selectedPlayers.shuffled()
        let participantCount = gameSession.participants.count
        
        guard participantCount > 0 else { return }
        
        // Clear existing assignments
        for i in 0..<gameSession.participants.count {
            gameSession.participants[i].selectedPlayers = []
        }
        
        // Distribute players round-robin
        for (index, player) in shuffledPlayers.enumerated() {
            let participantIndex = index % participantCount
            gameSession.participants[participantIndex].selectedPlayers.append(player)
        }
        
        assignmentComplete = true
        revealAssignmentsAnimated()
    }
    
    private func revealAssignmentsAnimated() {
        for (index, participant) in gameSession.participants.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.4) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    currentParticipantIndex = index
                }
                
                for (playerIndex, player) in participant.selectedPlayers.enumerated() {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(playerIndex) * 0.1) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                            assignedPlayerIds.append(player.id)
                        }
                    }
                }
            }
        }
        
        // Show confetti after all reveals
        let totalDelay = Double(gameSession.participants.count) * 0.4 + 0.5
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showConfetti = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    private func startGameAction() {
        if AppPurchaseManager.shared.currentTier == .free && AdManager.shared.shouldShowInterstitial(for: .gameComplete) {
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
        
        AdManager.shared.showInterstitialAd(from: rootViewController) { _ in
            DispatchQueue.main.async { self.startGame() }
        }
    }
    
    private func startGame() {
        let existingCustomEvents = gameSession.getCustomEvents()
        if !existingCustomEvents.isEmpty {
            gameSession.debugAndFixCustomEventMappings()
        }
        
        gameSession.objectWillChange.send()
        NotificationCenter.default.post(name: Notification.Name("StartGame"), object: nil)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Assign Stat Item

struct AssignStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Assign Participant Card

struct AssignParticipantCard: View {
    let participant: Participant
    let isRevealed: Bool
    let assignedPlayerIds: [UUID]
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(participant.name.prefix(1)).uppercased())
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("\(participant.selectedPlayers.count) players")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if isRevealed {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
            
            // Players list
            if isRevealed {
                VStack(spacing: 6) {
                    ForEach(participant.selectedPlayers) { player in
                        AssignPlayerRow(player: player, isVisible: assignedPlayerIds.contains(player.id))
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isRevealed ? AppDesignSystem.Colors.grassGreen.opacity(0.3) : Color.clear, lineWidth: 1.5)
                )
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
        .opacity(isRevealed ? 1.0 : 0.5)
        .scaleEffect(isRevealed ? 1.0 : 0.95)
    }
}

// MARK: - Assign Player Row

struct AssignPlayerRow: View {
    let player: Player
    let isVisible: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 2)
                .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                .frame(width: 3, height: 24)
            
            Text(player.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Text(player.team.shortName)
                .font(.system(size: 11))
                .foregroundColor(AppDesignSystem.TeamColors.getColor(for: player.team))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.08))
        )
        .opacity(isVisible ? 1.0 : 0.0)
        .scaleEffect(isVisible ? 1.0 : 0.8)
        .animation(.spring(response: 0.4, dampingFraction: 0.6).delay(Double.random(in: 0...0.2)), value: isVisible)
    }
}
