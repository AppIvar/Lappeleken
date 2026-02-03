//
//  NewGameSetupView.swift
//  Lucky Football Slip
//
//  Main coordinator for manual game setup - refactored modular version
//

import SwiftUI

struct NewGameSetupView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    
    // Step state
    @State private var currentStep = 0
    @State private var participantName = ""
    @State private var selectedPlayerIds: Set<UUID> = []
    @State private var betAmounts: [Bet.EventType: Double] = [:]
    @State private var betNegativeFlags: [Bet.EventType: Bool] = [:]
    
    // Sheet presentation
    @State private var showPlayerEntry = false
    @State private var showLineupSearch = false
    @State private var showCustomBetSheet = false
    @State private var showingPlayerDrawing = false
    
    // Player drawing
    @State private var playerAssignments: [Participant: [Player]] = [:]
    
    private let steps = ["Add Participants", "Select Players", "Set Bet Rules", "Review & Start"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                progressIndicator
                
                ScrollView {
                    VStack(spacing: 24) {
                        stepContent
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .background(AppDesignSystem.Colors.background)
                
                bottomButton
            }
            .navigationTitle("Manual Game Setup")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                    .foregroundColor(AppDesignSystem.Colors.primary)
            )
            .sheet(isPresented: $showPlayerEntry) {
                ManualPlayerEntryView(gameSession: gameSession)
            }
            .sheet(isPresented: $showLineupSearch) {
                LineupSearchView(gameSession: gameSession)
            }
            .sheet(isPresented: $showCustomBetSheet) {
                CustomBetView(gameSession: gameSession)
            }
            .sheet(isPresented: $showingPlayerDrawing) {
                PlayerDrawingView(
                    gameSession: gameSession,
                    selectedPlayers: gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) },
                    participants: gameSession.participants,
                    onComplete: { assignments in
                        applyPlayerAssignments(assignments)
                        playerAssignments = assignments
                        showingPlayerDrawing = false
                        currentStep += 1
                    },
                    onBack: {
                        showingPlayerDrawing = false
                    }
                )
            }
            .onAppear {
                setupInitialData()
            }
        }
        .withMinimalBanner()
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack {
            ForEach(0..<steps.count, id: \.self) { index in
                VStack(spacing: 8) {
                    Circle()
                        .fill(index <= currentStep ? AppDesignSystem.Colors.primary : Color.gray.opacity(0.3))
                        .frame(width: 36, height: 36)
                        .overlay(
                            Group {
                                if index < currentStep {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(index <= currentStep ? .white : .gray)
                                }
                            }
                        )
                        .shadow(color: index <= currentStep ? AppDesignSystem.Colors.primary.opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
                    
                    Text(steps[index])
                        .font(AppDesignSystem.Typography.captionFont)
                        .multilineTextAlignment(.center)
                        .foregroundColor(index <= currentStep ? AppDesignSystem.Colors.primaryText : AppDesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? AppDesignSystem.Colors.primary : Color.gray.opacity(0.3))
                        .frame(height: 3)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(1.5)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            SetupParticipantsView(gameSession: gameSession, participantName: $participantName)
        case 1:
            SetupPlayersView(
                gameSession: gameSession,
                selectedPlayerIds: $selectedPlayerIds,
                showPlayerEntry: $showPlayerEntry,
                showLineupSearch: $showLineupSearch,
                onDeletePlayer: deletePlayer
            )
        case 2:
            SetupBetsView(
                gameSession: gameSession,
                betAmounts: $betAmounts,
                betNegativeFlags: $betNegativeFlags,
                showCustomBetSheet: $showCustomBetSheet
            )
        case 3:
            SetupReviewView(
                gameSession: gameSession,
                selectedPlayerIds: selectedPlayerIds,
                betAmounts: betAmounts
            )
        default:
            EmptyView()
        }
    }
    
    // MARK: - Bottom Button
    
    private var bottomButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation(AppDesignSystem.Animations.standard) {
                            currentStep -= 1
                        }
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                            .stroke(AppDesignSystem.Colors.primary, lineWidth: 2)
                    )
                    .frame(maxWidth: .infinity)
                }
                
                Button(currentStep == steps.count - 1 ? "Start Game" : "Next") {
                    if currentStep == steps.count - 1 {
                        startGameWithAdCheck()
                    } else {
                        handleNextButton()
                    }
                }
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(canProceed ? AppDesignSystem.Colors.primary : Color.gray.opacity(0.5))
                .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                .frame(maxWidth: .infinity, minHeight: currentStep == 0 ? 50 : nil)
                .disabled(!canProceed)
                .vibrantButton()
                .scaleEffect(canProceed ? 1.0 : 0.95)
                .animation(AppDesignSystem.Animations.quick, value: canProceed)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                Rectangle()
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: -4)
            )
        }
    }
    
    // MARK: - Navigation Logic
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !gameSession.participants.isEmpty
        case 1: return !selectedPlayerIds.isEmpty
        case 2: return !playerAssignments.isEmpty
        case 3: return true
        default: return false
        }
    }
    
    private func handleNextButton() {
        // Auto-add participant if name entered
        if currentStep == 0 {
            let trimmedName = participantName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                gameSession.addParticipant(trimmedName)
                participantName = ""
            }
        }
        
        // Show player drawing after player selection
        if currentStep == 1 {
            guard !selectedPlayerIds.isEmpty else { return }
            showingPlayerDrawing = true
            return
        }
        
        if currentStep < steps.count - 1 {
            withAnimation(AppDesignSystem.Animations.standard) {
                currentStep += 1
            }
        }
    }
    
    // MARK: - Setup & Helpers
    
    private func setupInitialData() {
        gameSession.loadCustomPlayers()
        gameSession.selectedPlayers = []
        selectedPlayerIds = []
        gameSession.validateAndCleanupPlayerData()
        
        if betAmounts.isEmpty {
            setupDefaultBetRules()
        }
    }
    
    private func setupDefaultBetRules() {
        for eventType in Bet.EventType.allCases where eventType != .custom {
            let isNegative = getDefaultIsNegative(for: eventType)
            betAmounts[eventType] = isNegative ? -getDefaultBetAmount(for: eventType) : getDefaultBetAmount(for: eventType)
            betNegativeFlags[eventType] = isNegative
        }
    }
    
    private func deletePlayer(_ player: Player) {
        gameSession.availablePlayers.removeAll { $0.id == player.id }
        selectedPlayerIds.remove(player.id)
        gameSession.selectedPlayers.removeAll { $0.id == player.id }
        gameSession.saveCustomPlayers()
        gameSession.objectWillChange.send()
        
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func applyPlayerAssignments(_ assignments: [Participant: [Player]]) {
        for (participant, players) in assignments {
            if let index = gameSession.participants.firstIndex(where: { $0.id == participant.id }) {
                gameSession.participants[index].selectedPlayers = players
                gameSession.participants[index].balance = 0.0
            }
        }
    }
    
    // MARK: - Start Game
    
    private func startGameWithAdCheck() {
        guard AppPurchaseManager.shared.currentTier == .free else {
            startGame()
            return
        }
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            startGame()
            return
        }
        
        AdManager.shared.showInterstitialAd(from: rootViewController) { success in
            DispatchQueue.main.async {
                if success {
                    AdManager.shared.trackAdImpression(type: "interstitial_game_start")
                }
                self.startGame()
            }
        }
    }
    
    private func startGame() {
        // Set selected players
        gameSession.selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
        
        // Mark as manual mode
        gameSession.isLiveMode = false
        
        // Preserve and restore custom events
        let existingCustomEvents = gameSession.getCustomEvents()
        gameSession.bets.removeAll()
        gameSession.customEventMappings.removeAll()
        
        for (eventType, amount) in betAmounts where eventType != .custom {
            gameSession.addBet(eventType: eventType, amount: amount)
        }
        
        for customEvent in existingCustomEvents {
            gameSession.addCustomEvent(name: customEvent.name, amount: customEvent.amount)
        }
        
        gameSession.objectWillChange.send()
        
        // Dismiss view
        presentationMode.wrappedValue.dismiss()
        
        // Use the notification that ContentView actually handles!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(name: Notification.Name("StartGameWithSelectedMatch"), object: nil)
        }
    }
}
