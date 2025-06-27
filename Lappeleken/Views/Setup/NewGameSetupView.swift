//
//  NewGameSetupView.swift
//  Lucky Football Slip
//
//  Enhanced version with all original functionality plus new features
//

import SwiftUI

struct NewGameSetupView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentStep = 0
    @State private var participantName = ""
    @State private var selectedPlayerIds: Set<UUID> = []
    @State private var betAmounts: [Bet.EventType: Double] = [:]
    @State private var betNegativeFlags: [Bet.EventType: Bool] = [:]
    @State private var showPlayerEntry = false
    @State private var showLineupSearch = false
    @State private var showCustomBetSheet = false
    
    private let steps = ["Add Participants", "Select Players", "Set Bet Rules", "Review & Start"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced progress indicator
                progressIndicator
                
                // Main content with improved scrolling
                ScrollView {
                    VStack(spacing: 24) {
                        stepContent
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                }
                .background(AppDesignSystem.Colors.background)
                
                // Enhanced bottom button
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
            .onAppear {
                setupInitialData()
            }
        }
        .withMinimalBanner()
    }
    
    // MARK: - Enhanced Views
    
    private var progressIndicator: some View {
        HStack {
            ForEach(0..<steps.count, id: \.self) { index in
                VStack(spacing: 8) {
                    // Simplified circle without complex gradients
                    Circle()
                        .fill(
                            index <= currentStep ?
                            AppDesignSystem.Colors.primary :
                            Color.gray.opacity(0.3)
                        )
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
                        .shadow(
                            color: index <= currentStep ? AppDesignSystem.Colors.primary.opacity(0.3) : Color.clear,
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    
                    Text(steps[index])
                        .font(AppDesignSystem.Typography.captionFont)
                        .multilineTextAlignment(.center)
                        .foregroundColor(index <= currentStep ? AppDesignSystem.Colors.primaryText : AppDesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(
                            index < currentStep ?
                            AppDesignSystem.Colors.primary :
                            Color.gray.opacity(0.3)
                        )
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
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case 0:
            participantStep
        case 1:
            playerSelectionStep
        case 2:
            betRulesStep
        case 3:
            reviewStep
        default:
            EmptyView()
        }
    }
    
    private var participantStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Who's Playing?")
                    .font(AppDesignSystem.Typography.headingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Add the names of everyone who will be participating in this game.")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Add participant section
            VStack(spacing: 16) {
                HStack {
                    TextField("Enter participant name", text: $participantName)
                        .font(AppDesignSystem.Typography.bodyFont)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                                .fill(AppDesignSystem.Colors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                                        .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .onSubmit {
                            addParticipant()
                        }
                    
                    Button(action: addParticipant) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Add")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                            Color.gray.opacity(0.5) :
                            AppDesignSystem.Colors.primary
                        )
                        .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                        .vibrantButton()
                    }
                    .disabled(participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            
            // Participants list
            if !gameSession.participants.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Participants")
                            .font(AppDesignSystem.Typography.subheadingFont)
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        VibrantStatusBadge("\(gameSession.participants.count)", color: AppDesignSystem.Colors.success)
                    }
                    
                    LazyVStack(spacing: 12) {
                        ForEach(gameSession.participants) { participant in
                            HStack {
                                Circle()
                                    .fill(AppDesignSystem.Colors.primary)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Text(String(participant.name.prefix(1)).uppercased())
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                Text(participant.name)
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                
                                Spacer()
                                
                                Button(action: {
                                    deleteParticipant(participant)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(AppDesignSystem.Colors.error)
                                        .padding(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                                    .fill(AppDesignSystem.Colors.cardBackground)
                                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var playerSelectionStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppDesignSystem.Colors.secondary)
                
                Text("Select Players")
                    .font(AppDesignSystem.Typography.headingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Choose the football players that will be available for selection during the game.")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Add Players") {
                    showPlayerEntry = true
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppDesignSystem.Colors.primary)
                .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                .vibrantButton()
                
                Button("Search Lineups") {
                    showLineupSearch = true
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                        .stroke(AppDesignSystem.Colors.primary, lineWidth: 2)
                )
            }
            
            // Players by team
            if !gameSession.availablePlayers.isEmpty {
                playersGroupedByTeam
            } else {
                emptyPlayersView
            }
        }
    }
    
    private var emptyPlayersView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("No players added yet")
                .font(AppDesignSystem.Typography.subheadingFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("Add players manually or search for team lineups to get started")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.largeCornerRadius)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    private var playersGroupedByTeam: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Available Players")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                VibrantStatusBadge("\(gameSession.availablePlayers.count)", color: AppDesignSystem.Colors.info)
            }
            
            let teamGroups = Dictionary(grouping: gameSession.availablePlayers) { $0.team.id }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(teamGroups.keys).sorted(by: { teamGroups[$0]!.first!.team.name < teamGroups[$1]!.first!.team.name }), id: \.self) { teamId in
                    if let players = teamGroups[teamId], let team = players.first?.team {
                        TeamPlayerGroup(
                            team: team,
                            players: players,
                            selectedPlayerIds: $selectedPlayerIds,
                            onDeletePlayer: { player in
                                deletePlayer(player)
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var betRulesStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "target")
                    .font(.system(size: 48))
                    .foregroundColor(AppDesignSystem.Colors.accent)
                
                Text("Bet Rules")
                    .font(AppDesignSystem.Typography.headingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Set the money values for different football events. Positive values reward players who have the event player, while negative values penalize them.")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            // Currency selection - restored from old version
            VStack(alignment: .leading, spacing: 12) {
                Text("Currency")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                CurrencySelector()
            }
            
            // Standard bet rules
            VStack(spacing: 16) {
                Text("Standard Events")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    ForEach(Array(Bet.EventType.allCases.filter { $0 != .custom }.enumerated()), id: \.offset) { index, eventType in
                        BetRuleCard(
                            eventType: eventType,
                            amount: Binding(
                                get: { abs(betAmounts[eventType] ?? getDefaultAmount(for: eventType)) },
                                set: { newValue in
                                    let isNegative = betNegativeFlags[eventType] ?? getDefaultIsNegative(for: eventType)
                                    betAmounts[eventType] = isNegative ? -abs(newValue) : abs(newValue)
                                }
                            ),
                            isNegative: Binding(
                                get: { betNegativeFlags[eventType] ?? getDefaultIsNegative(for: eventType) },
                                set: { isNegative in
                                    betNegativeFlags[eventType] = isNegative
                                    let currentAmount = abs(betAmounts[eventType] ?? getDefaultAmount(for: eventType))
                                    betAmounts[eventType] = isNegative ? -currentAmount : currentAmount
                                }
                            )
                        )
                    }
                }
            }
            
            // Custom events section - enhanced with proper sheet
            VStack(spacing: 16) {
                HStack {
                    Text("Custom Events")
                        .font(AppDesignSystem.Typography.subheadingFont)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Button("Add Custom") {
                        showCustomBetSheet = true
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppDesignSystem.Colors.accent)
                    .cornerRadius(AppDesignSystem.Layout.smallCornerRadius)
                    .vibrantButton(color: AppDesignSystem.Colors.accent)
                    
                    if !gameSession.getCustomEvents().isEmpty {
                        VibrantStatusBadge("\(gameSession.getCustomEvents().count)", color: AppDesignSystem.Colors.accent)
                    }
                }
                
                // Display existing custom events
                if !gameSession.getCustomEvents().isEmpty {
                    VStack(spacing: 8) {
                        ForEach(gameSession.getCustomEvents(), id: \.id) { customEvent in
                            CustomEventDisplayCard(
                                name: customEvent.name,
                                amount: customEvent.amount,
                                onDelete: {
                                    gameSession.removeCustomEvent(id: customEvent.id)
                                }
                            )
                        }
                    }
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "star.circle")
                            .font(.system(size: 32))
                            .foregroundColor(AppDesignSystem.Colors.accent.opacity(0.5))
                        
                        Text("No custom events added yet")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Text("Tap 'Add Custom' to create your own events")
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                            .fill(AppDesignSystem.Colors.accent.opacity(0.05))
                    )
                }
            }
        }
    }
    
    private var reviewStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppDesignSystem.Colors.success)
                
                Text("Review & Start")
                    .font(AppDesignSystem.Typography.headingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Review your game setup and start playing!")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                // Participants summary
                summaryCard(
                    title: "Participants",
                    count: gameSession.participants.count,
                    color: AppDesignSystem.Colors.primary
                ) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(gameSession.participants) { participant in
                            HStack {
                                Circle()
                                    .fill(AppDesignSystem.Colors.primary)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text(String(participant.name.prefix(1)).uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                Text(participant.name)
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Players summary
                summaryCard(
                    title: "Selected Players",
                    count: selectedPlayerIds.count,
                    color: AppDesignSystem.Colors.secondary
                ) {
                    Text(playersFromTeamsText)
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                // Bet rules summary
                summaryCard(
                    title: "Bet Rules",
                    count: betAmounts.count + gameSession.getCustomEvents().count,
                    color: AppDesignSystem.Colors.accent
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Standard bets
                        ForEach(Array(betAmounts.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { eventType in
                            HStack {
                                Text(eventType.rawValue.capitalized)
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                
                                Spacer()
                                
                                Text(formatCurrencyAmount(betAmounts[eventType] ?? 0))
                                    .font(AppDesignSystem.Typography.bodyBold)
                                    .foregroundColor(betAmounts[eventType] ?? 0 < 0 ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                            }
                        }
                        
                        // Custom events
                        ForEach(gameSession.getCustomEvents(), id: \.id) { customEvent in
                            HStack {
                                Text(customEvent.name)
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                
                                Spacer()
                                
                                Text(formatCurrencyAmount(customEvent.amount))
                                    .font(AppDesignSystem.Typography.bodyBold)
                                    .foregroundColor(customEvent.amount < 0 ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func summaryCard<Content: View>(
        title: String,
        count: Int,
        color: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                VibrantStatusBadge("\(count)", color: color)
            }
            
            content()
        }
        .padding(AppDesignSystem.Layout.standardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private var playersFromTeamsText: String {
        let selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
        let teamNames = selectedPlayers.map { $0.team.name }
        let uniqueTeams = Set(teamNames)
        return "Players from \(uniqueTeams.count) team\(uniqueTeams.count == 1 ? "" : "s")"
    }
    
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
                .background(
                    canProceed ?
                    AppDesignSystem.Colors.primary :
                    Color.gray.opacity(0.5)
                )
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
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: -4
                    )
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialData() {
        // Load user's previously saved players
        gameSession.loadCustomPlayers()
        
        // Clear any previous game state
        gameSession.selectedPlayers = []
        selectedPlayerIds = []
        
        // Validate and cleanup any corrupted data
        gameSession.validateAndCleanupPlayerData()
        
        // Setup default bet amounts if not already configured
        if betAmounts.isEmpty {
            setupDefaultBetRules()
        }
        
        // Print statistics for debugging
        let stats = gameSession.getPlayerStatistics()
        print("📊 Manual Mode Initialized: \(stats.summary)")
    }
    
    private func setupDefaultBetRules() {
        for eventType in Bet.EventType.allCases {
            if eventType != .custom {
                let defaultAmount = getDefaultAmount(for: eventType)
                let isNegative = getDefaultIsNegative(for: eventType)
                
                betAmounts[eventType] = isNegative ? -defaultAmount : defaultAmount
                betNegativeFlags[eventType] = isNegative
            }
        }
    }
    
    private func getDefaultAmount(for eventType: Bet.EventType) -> Double {
        switch eventType {
        case .goal, .assist, .penalty, .cleanSheet:
            return 1.0
        case .yellowCard, .redCard, .ownGoal, .penaltyMissed:
            return 1.0
        case .custom:
            return 1.0
        }
    }
    
    private func getDefaultIsNegative(for eventType: Bet.EventType) -> Bool {
        switch eventType {
        case .ownGoal, .redCard, .yellowCard, .penaltyMissed:
            return true
        case .goal, .assist, .penalty, .cleanSheet, .custom:
            return false
        }
    }
    
    private func addParticipant() {
        let trimmedName = participantName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            gameSession.addParticipant(trimmedName)
            participantName = ""
        }
    }
    
    private func deleteParticipant(_ participant: Participant) {
        if let index = gameSession.participants.firstIndex(where: { $0.id == participant.id }) {
            gameSession.participants.remove(at: index)
        }
    }
    
    private func deletePlayer(_ player: Player) {
        print("🗑️ Attempting to delete player: \(player.name) from \(player.team.name)")
        
        // Remove from available players
        gameSession.availablePlayers.removeAll { $0.id == player.id }
        
        // Remove from selected players if selected
        selectedPlayerIds.remove(player.id)
        gameSession.selectedPlayers.removeAll { $0.id == player.id }
        
        // FIXED: Save the updated players list to make deletion permanent
        gameSession.saveCustomPlayers()
        
        print("✅ Player \(player.name) deleted and changes saved")
        print("📊 Remaining players: \(gameSession.availablePlayers.count)")
        
        // Force UI update
        gameSession.objectWillChange.send()
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
    
    private func formatCurrencyAmount(_ amount: Double) -> String {
        let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        let sign = amount >= 0 ? "+" : ""
        return "\(sign)\(currencySymbol)\(String(format: "%.2f", abs(amount)))"
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !gameSession.participants.isEmpty
        case 1: return !selectedPlayerIds.isEmpty
        case 2: return true
        case 3: return true
        default: return false
        }
    }
    
    private func handleNextButton() {
        // Auto-add participant if name is entered but not added (for step 0)
        if currentStep == 0 {
            let trimmedName = participantName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                gameSession.addParticipant(trimmedName)
                participantName = ""
            }
        }
        
        if currentStep < steps.count - 1 {
            withAnimation(AppDesignSystem.Animations.standard) {
                currentStep += 1
            }
        }
    }
    
    private func startGameWithAdCheck() {
        // Check if this is a free user and should show interstitial ad
        guard AppPurchaseManager.shared.currentTier == .free else {
            startGame()
            return
        }
        
        // Show interstitial ad for free users before starting game
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
        // Set selected players
        gameSession.selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
        
        // FIXED: Preserve custom events before clearing bets
        let existingCustomEvents = gameSession.getCustomEvents()
        print("🔄 Preserving \(existingCustomEvents.count) custom events before bet recreation")
        
        // Clear existing bets completely
        gameSession.bets.removeAll()
        gameSession.customEventMappings.removeAll()
        
        // Add standard bets first
        for (eventType, amount) in betAmounts {
            if eventType != .custom {
                gameSession.addBet(eventType: eventType, amount: amount)
            }
        }
        
        // FIXED: Restore custom events AFTER standard bets are added
        for customEvent in existingCustomEvents {
            print("🔄 Restoring custom event: \(customEvent.name) with amount \(customEvent.amount)")
            gameSession.addCustomEvent(name: customEvent.name, amount: customEvent.amount)
        }
        
        // Force update the game session
        gameSession.objectWillChange.send()
        
        print("🎮 Starting game with:")
        print("  - Participants: \(gameSession.participants.count)")
        print("  - Selected Players: \(gameSession.selectedPlayers.count)")
        print("  - Bet Rules: \(gameSession.bets.count)")
        print("  - Custom Events: \(gameSession.getCustomEvents().count)")
        
        // Debug custom events specifically
        for customEvent in gameSession.getCustomEvents() {
            print("  - Custom Event: \(customEvent.name) = \(customEvent.amount)")
        }
        
        // Dismiss this view first
        presentationMode.wrappedValue.dismiss()
        
        // Use the proper notification that ContentView listens for to trigger assignment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(name: Notification.Name("ShowAssignment"), object: nil)
        }
    }
    
    // MARK: - Helper functions for event types
    
    private func getEventDescription(_ eventType: Bet.EventType) -> String {
        switch eventType {
        case .goal:
            return "Player scores a goal"
        case .assist:
            return "Player provides an assist"
        case .yellowCard:
            return "Player receives a yellow card"
        case .redCard:
            return "Player receives a red card"
        case .ownGoal:
            return "Player scores an own goal"
        case .penalty:
            return "Player scores a penalty"
        case .penaltyMissed:
            return "Player misses a penalty"
        case .cleanSheet:
            return "Goalkeeper keeps a clean sheet"
        case .custom:
            return "Custom event"
        }
    }
}

// MARK: - Enhanced Team Player Group Component

struct TeamPlayerGroup: View {
    let team: Team
    let players: [Player]
    @Binding var selectedPlayerIds: Set<UUID>
    let onDeletePlayer: (Player) -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 12) {
            // Enhanced team header - simplified for compiler
            Button(action: {
                withAnimation(AppDesignSystem.Animations.standard) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Circle()
                        .fill(AppDesignSystem.TeamColors.getColor(for: team))
                        .frame(width: 28, height: 28)
                        .shadow(color: AppDesignSystem.TeamColors.getColor(for: team).opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(team.name)
                            .font(.system(size: 18, weight: .semibold, design: .default))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("\(players.count) player\(players.count == 1 ? "" : "s")")
                            .font(.system(size: 12, weight: .regular, design: .default))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    // Select all/none button
                    Button(allPlayersSelected ? "Deselect All" : "Select All") {
                        withAnimation(AppDesignSystem.Animations.quick) {
                            if allPlayersSelected {
                                for player in players {
                                    selectedPlayerIds.remove(player.id)
                                }
                            } else {
                                for player in players {
                                    selectedPlayerIds.insert(player.id)
                                }
                            }
                        }
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppDesignSystem.TeamColors.getAccentColor(for: team))
                    )
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                        .fill(AppDesignSystem.TeamColors.getAccentColor(for: team))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                                .stroke(AppDesignSystem.TeamColors.getColor(for: team).opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Players grid with enhanced animation
            if isExpanded {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(players, id: \.id) { player in
                        SetupPlayerSelectionCard(
                            player: player,
                            isSelected: selectedPlayerIds.contains(player.id),
                            onToggleSelection: {
                                withAnimation(AppDesignSystem.Animations.quick) {
                                    if selectedPlayerIds.contains(player.id) {
                                        selectedPlayerIds.remove(player.id)
                                    } else {
                                        selectedPlayerIds.insert(player.id)
                                    }
                                }
                            },
                            onDelete: {
                                onDeletePlayer(player)
                            }
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var allPlayersSelected: Bool {
        players.allSatisfy { selectedPlayerIds.contains($0.id) }
    }
}

// MARK: - Enhanced Setup Player Selection Card Component

struct SetupPlayerSelectionCard: View {
    let player: Player
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(player.position.rawValue)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                // FIXED: Delete button with confirmation
                Button(action: {
                    // Add a small delay to ensure the action is registered properly
                    DispatchQueue.main.async {
                        onDelete()
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.error)
                        .padding(6)
                        .background(Circle().fill(AppDesignSystem.Colors.error.opacity(0.1)))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Selection toggle
            Button(action: onToggleSelection) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(
                            isSelected ?
                            AppDesignSystem.Colors.success :
                            AppDesignSystem.Colors.secondaryText
                        )
                        .font(.system(size: 18))
                    
                    Text(isSelected ? "Selected" : "Select")
                        .font(.system(size: 12, weight: .semibold, design: .default))
                        .foregroundColor(
                            isSelected ?
                            AppDesignSystem.Colors.success :
                            AppDesignSystem.Colors.secondaryText
                        )
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            isSelected ?
                            AppDesignSystem.Colors.success.opacity(0.1) :
                            AppDesignSystem.Colors.cardBackground
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    isSelected ?
                                    AppDesignSystem.Colors.success :
                                    AppDesignSystem.Colors.secondaryText.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                .fill(
                    isSelected ?
                    AppDesignSystem.TeamColors.getAccentColor(for: player.team) :
                    AppDesignSystem.Colors.cardBackground
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                        .stroke(
                            isSelected ?
                            AppDesignSystem.TeamColors.getColor(for: player.team) :
                            Color.gray.opacity(0.2),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
        )
        .shadow(
            color: isSelected ?
            AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.2) :
            Color.black.opacity(0.05),
            radius: isSelected ? 6 : 2,
            x: 0,
            y: isSelected ? 3 : 1
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppDesignSystem.Animations.quick, value: isSelected)
    }
}

// MARK: - Enhanced Bet Rule Card Component

struct BetRuleCard: View {
    let eventType: Bet.EventType
    @Binding var amount: Double
    @Binding var isNegative: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(eventType.rawValue.capitalized)
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(getEventDescription(eventType))
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    // Always show positive/negative toggle for full flexibility
                    Button(action: {
                        withAnimation(AppDesignSystem.Animations.quick) {
                            isNegative.toggle()
                        }
                    }) {
                        Image(systemName: isNegative ? "minus.circle.fill" : "plus.circle.fill")
                            .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                            .font(.title2)
                    }
                    .scaleEffect(isNegative ? 1.1 : 1.0)
                    .animation(AppDesignSystem.Animations.bouncy, value: isNegative)
                    
                    TextField("Amount", value: $amount, format: .number)
                        .font(.system(size: 16, weight: .semibold, design: .default))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(width: 80)
                        .background(
                            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.smallCornerRadius)
                                .fill(AppDesignSystem.Colors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.smallCornerRadius)
                                        .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .keyboardType(.decimalPad)
                }
            }
            
            // Enhanced visual indicator for negative/positive with explanation
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: isNegative ? "arrow.down" : "arrow.up")
                            .font(.system(size: 12, weight: .bold))
                        
                        Text(isNegative ? "Penalty" : "Reward")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                    
                    Text(isNegative ? "Others gain money" : "Player owners gain money")
                        .font(.system(size: 10))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill((isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success).opacity(0.1))
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                        .stroke(
                            (isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success).opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func getEventDescription(_ eventType: Bet.EventType) -> String {
        switch eventType {
        case .goal:
            return "Player scores a goal"
        case .assist:
            return "Player provides an assist"
        case .yellowCard:
            return "Player receives a yellow card"
        case .redCard:
            return "Player receives a red card"
        case .ownGoal:
            return "Player scores an own goal"
        case .penalty:
            return "Player scores a penalty"
        case .penaltyMissed:
            return "Player misses a penalty"
        case .cleanSheet:
            return "Goalkeeper keeps a clean sheet"
        case .custom:
            return "Custom event"
        }
    }
}

// MARK: - Currency Selector Component

struct CurrencySelector: View {
    @AppStorage("selectedCurrency") private var selectedCurrency = "EUR"
    @AppStorage("currencySymbol") private var currencySymbol = "€"
    
    private let currencies = [
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("NOK", "kr", "Norwegian Krone"),
        ("SEK", "kr", "Swedish Krona"),
        ("DKK", "kr", "Danish Krone")
    ]
    
    var body: some View {
        Menu {
            ForEach(currencies, id: \.0) { currency in
                Button(action: {
                    selectedCurrency = currency.0
                    currencySymbol = currency.1
                }) {
                    HStack {
                        Text("\(currency.1) \(currency.0) - \(currency.2)")
                        if selectedCurrency == currency.0 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 20))
                    .foregroundColor(AppDesignSystem.Colors.warning)
                
                Text(selectedCurrency)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(currencySymbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                            .stroke(AppDesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Custom Event Display Card

struct CustomEventDisplayCard: View {
    let name: String
    let amount: Double
    let onDelete: () -> Void
    
    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
    }
    
    private var isNegative: Bool {
        amount < 0
    }
    
    var body: some View {
        HStack {
            // Event icon
            Image(systemName: "star.fill")
                .font(.system(size: 16))
                .foregroundColor(AppDesignSystem.Colors.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(eventDescription)
                    .font(.system(size: 11))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Amount display
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: isNegative ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                    
                    Text("\(currencySymbol)\(String(format: "%.2f", abs(amount)))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                }
                
                Text(isNegative ? "Penalty" : "Reward")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
            }
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(6)
                    .background(Circle().fill(AppDesignSystem.Colors.error.opacity(0.1)))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                        .stroke(AppDesignSystem.Colors.accent.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var eventDescription: String {
        let amountString = String(format: "%.2f", abs(amount))
        return isNegative ?
        "Players WITH this event pay \(currencySymbol)\(amountString)" :
        "Players WITHOUT this event pay \(currencySymbol)\(amountString)"
    }
}

