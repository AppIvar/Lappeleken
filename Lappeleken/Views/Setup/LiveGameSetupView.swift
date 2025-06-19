//
//  LiveGameSetupView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import SwiftUI

struct LiveGameSetupView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    
    @State private var currentStep = 0
    @State private var participantName = ""
    @State private var selectedMatchIds = Set<String>()
    @State private var selectedPlayerIds = Set<UUID>()
    @State private var betAmounts = [Bet.EventType: Double]()
    @State private var betNegativeFlags = [Bet.EventType: Bool]()
    @State private var showingCustomBetSheet = false
    @State private var showingLiveSetupInfo = false
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var showingPlayerUnavailableAlert = false
    @State private var unavailableMatchesMessage = ""
    @State private var temporaryStep: Int? = nil
    @State private var isPresentingAlert = false

    
    private let steps = ["Matches", "Participants", "Set Bets", "Select Players", "Review"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Enhanced progress indicator
                progressIndicator
                
                // Content based on current step
                ScrollView {
                    VStack {
                        if isLoading {
                            loadingStateView
                        } else if let errorMessage = error {
                            errorStateView(errorMessage)
                        } else {
                            stepContentView
                        }
                    }
                    .padding()
                }
                
                // Enhanced navigation buttons
                navigationButtons
            }
            .navigationTitle("Live Game Setup")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Help") {
                    showingLiveSetupInfo = true
                }
                .foregroundColor(AppDesignSystem.Colors.primary)
            )
        }
        .withMinimalBanner()
        .onAppear {
            setupInitialState()
        }
        .sheet(isPresented: $showingCustomBetSheet) {
            CustomBetView(gameSession: gameSession)
        }
        .sheet(isPresented: $showingLiveSetupInfo) {
            LiveModeInfoView(onGetStarted: {
                // Already in setup, so just dismiss
            })
        }
        .alert(isPresented: $showingPlayerUnavailableAlert) {
            Alert(
                title: Text("Lineup Not Available Yet"),
                message: Text(unavailableMatchesMessage),
                primaryButton: .default(Text("Continue with Placeholders")) {
                    isPresentingAlert = false
                    if let nextStep = temporaryStep, nextStep < steps.count {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            currentStep = nextStep
                        }
                    }
                    temporaryStep = nil
                },
                secondaryButton: .cancel(Text("Go Back")) {
                    isPresentingAlert = false
                    temporaryStep = nil
                }
            )
        }
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        VStack(spacing: 12) {
            // Step indicator
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack {
                        // Step circle
                        ZStack {
                            Circle()
                                .fill(
                                    index <= currentStep ?
                                    AppDesignSystem.Colors.primary :
                                    AppDesignSystem.Colors.secondaryText.opacity(0.3)
                                )
                                .frame(width: 32, height: 32)
                            
                            if index < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(
                                        index == currentStep ? .white : AppDesignSystem.Colors.secondaryText
                                    )
                            }
                        }
                        
                        // Connecting line
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(
                                    index < currentStep ?
                                    AppDesignSystem.Colors.primary :
                                    AppDesignSystem.Colors.secondaryText.opacity(0.3)
                                )
                                .frame(height: 2)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            
            // Step title
            Text(currentStep < steps.count ? steps[currentStep] : "Setup")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            // Step description
            Text(stepDescription)
                .font(.system(size: 14))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: AppDesignSystem.Colors.primary.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .padding(.horizontal)
    }
    
    private var stepDescription: String {
        guard currentStep < steps.count else { return "Setup in progress..." }
        
        switch currentStep {
        case 0: return "Choose live matches to follow"
        case 1: return "Add people who will participate"
        case 2: return "Set betting amounts for events"
        case 3: return "Select players from the match"
        case 4: return "Review and start your game"
        default: return "Setup step"
        }
    }
    
    // MARK: - State Views
    
    private var loadingStateView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppDesignSystem.Colors.primary))
                .scaleEffect(1.5)
            
            Text("Loading...")
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
        }
        .padding(.top, 100)
        .frame(maxWidth: .infinity)
    }
    
    private func errorStateView(_ errorMessage: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(AppDesignSystem.Colors.error)
            
            Text("Something went wrong")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text(errorMessage)
                .font(.system(size: 16))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Try Again") {
                error = nil
                if currentStep == 0 {
                    loadMatches()
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding()
            .background(AppDesignSystem.Colors.primary)
            .cornerRadius(12)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContentView: some View {
        switch currentStep {
        case 0: matchSelectionView
        case 1: participantsSetupView
        case 2: setBetsView
        case 3: playersSelectionView
        case 4: reviewView
        default: EmptyView()
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack(spacing: 16) {
            if currentStep > 0 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentStep -= 1
                    }
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.primary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppDesignSystem.Colors.primary, lineWidth: 2)
                )
            }
            
            Button(currentStep < steps.count - 1 ? "Next" : "Start Game") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    validateAndProceed()
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
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
            .disabled(isLoading)
        }
        .padding()
    }
    
    // MARK: - Step Views
    
    private var matchSelectionView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            Text("Select Live Matches")
                .font(AppDesignSystem.Typography.headingFont)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("Choose which match(es) you want to follow in real-time:")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            if gameSession.availableMatches.isEmpty {
                emptyMatchesView
            } else {
                matchesListView
            }
            
            if selectedMatchIds.isEmpty {
                Text("Select at least one match to continue")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(.top, 4)
            }
            
            if !AppConfig.canSelectMultipleMatches && selectedMatchIds.count > 1 {
                multipleMatchWarningView
            }
        }
    }
    
    private var emptyMatchesView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
            
            Text("No matches available")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Button("Refresh") {
                loadMatches()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppDesignSystem.Colors.primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
    
    private var matchesListView: some View {
        VStack(spacing: 12) {
            ForEach(gameSession.availableMatches) { match in
                MatchSelectionCard(
                    match: match,
                    isSelected: selectedMatchIds.contains(match.id),
                    onToggle: {
                        toggleMatchSelection(match)
                    }
                )
            }
        }
    }
    
    private var multipleMatchWarningView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Multiple Match Selection")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primary)
            }
            
            Text("You're in free mode which only allows one match at a time. Upgrade to premium to follow multiple matches simultaneously.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Button("Upgrade to Premium") {
                NotificationCenter.default.post(
                    name: Notification.Name("ShowUpgradePrompt"),
                    object: nil
                )
            }
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppDesignSystem.Colors.primary)
            .cornerRadius(8)
        }
        .padding()
        .background(AppDesignSystem.Colors.primary.opacity(0.1))
        .cornerRadius(AppDesignSystem.Layout.cornerRadius)
        .padding(.top, 20)
    }
    
    private var participantsSetupView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            Text("Add Participants")
                .font(AppDesignSystem.Typography.headingFont)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("Add the people who will be playing the game:")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            // Add participant section with enhanced UI
            VStack(spacing: 16) {
                HStack {
                    TextField("Enter participant name", text: $participantName)
                        .font(AppDesignSystem.Typography.bodyFont)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                        .onSubmit {
                            addParticipant()
                        }
                    
                    Button(action: addParticipant) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Add")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                            Color.gray : AppDesignSystem.Colors.primary
                        )
                        .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                    }
                    .disabled(participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                if gameSession.participants.isEmpty {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(AppDesignSystem.Colors.error)
                        
                        Text("Add at least one participant to continue")
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.error)
                    }
                    .padding(.top, 4)
                }
            }
            
            // Participants list with enhanced cards
            if !gameSession.participants.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Participants (\(gameSession.participants.count)):")
                        .font(AppDesignSystem.Typography.subheadingFont)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .padding(.top)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(gameSession.participants) { participant in
                            EnhancedParticipantCard(
                                participant: participant,
                                onDelete: {
                                    withAnimation(.spring()) {
                                        removeParticipant(participant)
                                    }
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private var setBetsView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            HStack {
                Text("Set Betting Amounts")
                    .font(AppDesignSystem.Typography.headingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button(action: {
                    showingCustomBetSheet = true
                }) {
                    Label("Custom Bet", systemImage: "plus.circle")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
            
            Text("Set how much participants will pay for each event type.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("Toggle +/- to change who pays whom.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.primary)
                .padding(.bottom)
            
            ForEach(Bet.EventType.allCases, id: \.self) { eventType in
                BetSettingsRow(
                    eventType: eventType,
                    betAmount: Binding(
                        get: { abs(betAmounts[eventType] ?? 1.0) },
                        set: { amount in
                            let isNegative = betNegativeFlags[eventType] ?? false
                            betAmounts[eventType] = isNegative ? -abs(amount) : abs(amount)
                        }
                    ),
                    isNegative: Binding(
                        get: { betNegativeFlags[eventType] ?? false },
                        set: { isNegative in
                            betNegativeFlags[eventType] = isNegative
                            if let amount = betAmounts[eventType] {
                                betAmounts[eventType] = isNegative ? -abs(amount) : abs(amount)
                            }
                        }
                    )
                )
            }
        }
    }
    
    private var playersSelectionView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            Text("Select Players")
                .font(AppDesignSystem.Typography.headingFont)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            // Check if we're using dummy players
            let hasDummyPlayers = gameSession.availablePlayers.contains { $0.name.contains("Player ") }
            
            if hasDummyPlayers {
                dummyPlayersWarningView
            }
            
            Text("Choose players to include in your game. These will be randomly assigned to participants.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            if selectedPlayerIds.isEmpty {
                Text("Select at least one player to continue")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(.top, 4)
            }
            
            // Group players by team
            if gameSession.availablePlayers.isEmpty {
                emptyPlayersView
            } else {
                playersListView
            }
        }
    }
    
    private var dummyPlayersWarningView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(AppDesignSystem.Colors.warning)
                
                Text("Official Lineup Not Available")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.warning)
            }
            
            Text("The official team lineup hasn't been announced yet. We've created placeholder players that you can use for now. Team lineups are typically announced about one hour before kickoff.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("You can continue with these placeholders or check back closer to kickoff time for the actual lineups.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .padding(.top, 4)
        }
        .padding()
        .background(AppDesignSystem.Colors.warning.opacity(0.1))
        .cornerRadius(AppDesignSystem.Layout.cornerRadius)
        .overlay(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                .stroke(AppDesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
        )
        .padding(.vertical, 8)
    }
    
    private var emptyPlayersView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3")
                .font(.system(size: 60))
                .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
            
            Text("No players available")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
    
    private var playersListView: some View {
        let teamGroups = Dictionary(grouping: gameSession.availablePlayers, by: { $0.team.id })
        
        return ForEach(Array(teamGroups.keys).sorted(), id: \.self) { teamId in
            if let teamPlayers = teamGroups[teamId], let team = teamPlayers.first?.team {
                VStack(alignment: .leading, spacing: 8) {
                    Text(team.name)
                        .font(AppDesignSystem.Typography.subheadingFont)
                        .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
                        .padding(.top, 16)
                    
                    ForEach(teamPlayers) { player in
                        PlayerCard(
                            player: player,
                            isSelected: selectedPlayerIds.contains(player.id),
                            action: {
                                togglePlayerSelection(player)
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var reviewView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            Text("Review Game Setup")
                .font(AppDesignSystem.Typography.headingFont)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("Review your game configuration before starting:")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            // Selected matches
            reviewMatchesCard
            
            // Participants
            reviewParticipantsCard
            
            // Selected players
            reviewPlayersCard
            
            // Betting amounts
            reviewBetsCard
            
            // Final instructions
            VStack(alignment: .leading, spacing: 8) {
                Text("Ready to start?")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Players will be randomly assigned to participants, and you'll receive live updates during the match.")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding()
            .background(AppDesignSystem.Colors.primary.opacity(0.1))
            .cornerRadius(AppDesignSystem.Layout.cornerRadius)
            .padding(.top)
        }
    }
    
    // MARK: - Review Cards
    
    private var reviewMatchesCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Selected Matches")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                ForEach(gameSession.availableMatches.filter { selectedMatchIds.contains($0.id) }) { match in
                    HStack {
                        Text("\(match.homeTeam.name) vs \(match.awayTeam.name)")
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Text(match.competition.name)
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private var reviewParticipantsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Participants (\(gameSession.participants.count))")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(gameSession.participants.map { $0.name }.joined(separator: ", "))
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
    
    private var reviewPlayersCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Selected Players (\(selectedPlayerIds.count))")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                let selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
                let playersByTeam = Dictionary(grouping: selectedPlayers) { $0.team.name }
                
                ForEach(playersByTeam.keys.sorted(), id: \.self) { teamName in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(teamName)
                            .font(AppDesignSystem.Typography.bodyFont.bold())
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        if let players = playersByTeam[teamName] {
                            Text(players.map { $0.name }.joined(separator: ", "))
                                .font(AppDesignSystem.Typography.bodyFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                    }
                    .padding(.top, 4)
                }
            }
        }
    }
    
    private var reviewBetsCard: some View {
        CardView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Betting Amounts")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                ForEach(Bet.EventType.allCases, id: \.self) { eventType in
                    let amount = betAmounts[eventType] ?? 0.0
                    let isNegative = amount < 0
                    let formattedAmount = formatCurrency(abs(amount))
                    
                    HStack {
                        Text(eventType.rawValue)
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Text("\(isNegative ? "-" : "+")\(formattedAmount)")
                            .font(AppDesignSystem.Typography.bodyFont.bold())
                            .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialState() {
        // Clear any existing state when entering live mode setup
        gameSession.availablePlayers = []
        gameSession.selectedPlayers = []
        selectedPlayerIds = Set<UUID>()
        
        // Load available matches when the view appears
        loadMatches()
        
        // Initialize bet amounts and negative flags
        if betAmounts.isEmpty {
            for eventType in Bet.EventType.allCases {
                betAmounts[eventType] = 1.0
                
                // Set certain bets as negative by default
                if eventType == .ownGoal || eventType == .redCard ||
                   eventType == .yellowCard || eventType == .penaltyMissed {
                    betNegativeFlags[eventType] = true
                    betAmounts[eventType] = -1.0
                } else {
                    betNegativeFlags[eventType] = false
                }
            }
        }
    }
    
    private func loadMatches() {
        isLoading = true
        error = nil
        
        Task {
            do {
                try await gameSession.fetchAvailableMatches()
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = "There was a problem connecting to the football data service: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func validateAndProceed() {
        // Ensure currentStep is within bounds
        guard currentStep >= 0 && currentStep < steps.count else {
            print("⚠️ Current step \(currentStep) is out of bounds (max: \(steps.count))")
            return
        }
        
        // Clear any existing errors
        error = nil
        
        switch currentStep {
        case 0: // Match selection
            guard !selectedMatchIds.isEmpty else {
                error = "Please select at least one match to continue."
                return
            }
            
            // IMPORTANT: Always clear existing players when moving from match selection
            gameSession.availablePlayers = []
            gameSession.selectedPlayers = []
            selectedPlayerIds = Set<UUID>()
            
            // Load players for selected matches
            loadPlayersForSelectedMatches()
            return // Don't increment step here, loadPlayersForSelectedMatches will handle it
            
        case 1: // Participants
            // Auto-add participant if they typed a name but forgot to press add button
            let trimmedName = participantName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                // Check if this name doesn't already exist
                if !gameSession.participants.contains(where: { $0.name == trimmedName }) {
                    gameSession.addParticipant(trimmedName)
                    participantName = "" // Clear the field
                    print("✅ Auto-added participant: \(trimmedName)")
                }
            }
            
            guard !gameSession.participants.isEmpty else {
                error = "Please add at least one participant to continue."
                return
            }
            
        case 2: // Bets
            // No validation needed, default bets are always set
            break
            
        case 3: // Player selection
            guard !selectedPlayerIds.isEmpty else {
                error = "Please select at least one player to continue."
                return
            }
            
            // Update gameSession.selectedPlayers with the chosen players
            gameSession.selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
            
        case 4: // Review (final step)
            // Start the game instead of incrementing
            startGame()
            return
            
        default:
            print("⚠️ Unhandled step: \(currentStep)")
            return
        }
        
        // Safely proceed to next step
        let nextStep = currentStep + 1
        guard nextStep < steps.count else {
            print("⚠️ Cannot proceed beyond final step")
            startGame()
            return
        }
        
        currentStep = nextStep
    }
    
    private func loadPlayersForSelectedMatches() {
        guard !selectedMatchIds.isEmpty else {
            error = "No matches selected"
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let matchIdsToLoad = AppConfig.canSelectMultipleMatches
                ? Array(self.selectedMatchIds)
                : Array(self.selectedMatchIds.prefix(1)) // Safe array creation
                
                guard !matchIdsToLoad.isEmpty else {
                    await MainActor.run {
                        self.isLoading = false
                        self.error = "No valid matches to load"
                    }
                    return
                }
                
                await MainActor.run {
                    gameSession.availablePlayers = []
                }
                
                var allPlayers: [Player] = []
                var playerUnavailableMatches: [Match] = []
                
                print("🔄 Loading players for \(matchIdsToLoad.count) matches...")
                
                // Process matches sequentially with proper error handling
                for (index, matchId) in matchIdsToLoad.enumerated() {
                    guard let match = gameSession.availableMatches.first(where: { $0.id == matchId }) else {
                        print("⚠️ Match with ID \(matchId) not found in available matches")
                        continue
                    }
                    
                    do {
                        print("📥 Loading players for match \(index + 1)/\(matchIdsToLoad.count): \(match.homeTeam.name) vs \(match.awayTeam.name)")
                        
                        let players = try await gameSession.fetchMatchPlayersRobust(for: matchId) ?? []
                        
                        let hasDummyPlayers = players.isEmpty || players.contains(where: {
                            $0.name.contains("Player ")
                        })
                        
                        if hasDummyPlayers {
                            playerUnavailableMatches.append(match)
                        }
                        
                        allPlayers.append(contentsOf: players)
                        
                        // Rate limiting between requests
                        if index < matchIdsToLoad.count - 1 {
                            try await Task.sleep(nanoseconds: 2_000_000_000)
                        }
                        
                    } catch {
                        print("❌ Error loading players for match \(matchId): \(error)")
                        // Continue with other matches
                    }
                }
                
                await MainActor.run {
                    self.isLoading = false
                    gameSession.availablePlayers = allPlayers
                    
                    if !allPlayers.isEmpty {
                        if !playerUnavailableMatches.isEmpty {
                            self.showPlayerUnavailableWarning(matches: playerUnavailableMatches)
                        } else {
                            // Safely move to next step
                            if self.currentStep < self.steps.count - 1 {
                                self.currentStep += 1
                            }
                        }
                    } else {
                        self.error = "No players found for the selected match(es). Team lineups may not be available yet."
                    }
                    
                    gameSession.objectWillChange.send()
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.error = "Error loading players: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func showPlayerUnavailableWarning(matches: [Match]) {
        guard !isPresentingAlert else { return }
        
        isPresentingAlert = true
        
        // Format the message
        if matches.count == 1 {
            let match = matches[0]
            unavailableMatchesMessage = "The official lineup for \(match.homeTeam.name) vs \(match.awayTeam.name) is not available yet..."
        } else {
            let matchNames = matches.map { "\($0.homeTeam.name) vs \($0.awayTeam.name)" }.joined(separator: ", ")
            unavailableMatchesMessage = "The official lineups for \(matchNames) are not available yet..."
        }
        
        temporaryStep = min(currentStep + 1, steps.count - 1) // Safe bounds checking
        showingPlayerUnavailableAlert = true
    }
    
    private func toggleMatchSelection(_ match: Match) {
        if selectedMatchIds.contains(match.id) {
            selectedMatchIds.remove(match.id)
        } else {
            // If not in premium mode, only allow selecting one match
            if !AppConfig.canSelectMultipleMatches {
                selectedMatchIds = [match.id]
            } else {
                selectedMatchIds.insert(match.id)
            }
        }
    }
    
    private func togglePlayerSelection(_ player: Player) {
        if selectedPlayerIds.contains(player.id) {
            selectedPlayerIds.remove(player.id)
        } else {
            selectedPlayerIds.insert(player.id)
        }
    }
    
    private func addParticipant() {
        let name = participantName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty {
            gameSession.addParticipant(name)
            participantName = ""
        }
    }
    
    private func removeParticipant(_ participant: Participant) {
        if let index = gameSession.participants.firstIndex(where: { $0.id == participant.id }) {
            gameSession.participants.remove(at: index)
        }
    }
    
    private func startGame() {
        // Check if user can access live features
        guard AppPurchaseManager.shared.canUseLiveFeatures else {
            showNoMoreMatchesDialog()
            return
        }
        
        // Use a match if they're a free user
        if AppPurchaseManager.shared.currentTier == .free {
            AppPurchaseManager.shared.useFreeLiveMatch()
        }
        
        // Initialize ad session for event tracking
        AdManager.shared.startNewLiveMatchSession()
        
        // Add bets to game session
        gameSession.bets = []
        for (eventType, amount) in betAmounts {
            gameSession.addBet(eventType: eventType, amount: amount)
        }
        
        // Randomly assign players to participants
        gameSession.assignPlayersRandomly()
        
        // Close the setup view
        presentationMode.wrappedValue.dismiss()
        
        // Notify that game should start
        NotificationCenter.default.post(name: Notification.Name("StartGameWithSelectedMatch"), object: nil)
    }
    
    private func showNoMoreMatchesDialog() {
        let alert = UIAlertController(
            title: "Daily Limit Reached",
            message: "You've used your free match for today. Watch an ad to get another match or upgrade to Premium for unlimited matches.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Watch Ad", style: .default) { _ in
            self.showAdForExtraMatch()
        })
        
        alert.addAction(UIAlertAction(title: "Upgrade to Premium", style: .default) { _ in
            self.showUpgradeView()
        })
        
        alert.addAction(UIAlertAction(title: "Maybe Later", style: .cancel))
        
        // Present the alert
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true)
        }
    }
    
    private func showAdForExtraMatch() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        AdManager.shared.showRewardedAdForExtraMatch(from: rootViewController) { success in
            if success {
                DispatchQueue.main.async {
                    // Try to start the game again after ad
                    self.startGame()
                }
            }
        }
    }
    
    private func showUpgradeView() {
        // Present your UpgradeView using a sheet or navigation
        NotificationCenter.default.post(
            name: Notification.Name("ShowUpgradeView"),
            object: nil
        )
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}

// MARK: - Supporting Components

struct EnhancedParticipantCard: View {
    let participant: Participant
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
            // Participant avatar and info
            VStack(spacing: 8) {
                ZStack {
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
                    
                    Text(String(participant.name.prefix(1).uppercased()))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Text(participant.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            
            // Delete button
            Button(action: {
                withAnimation(.spring()) {
                    isPressed = true
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring()) {
                        isPressed = false
                    }
                    onDelete()
                }
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.error)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

struct ParticipantRow: View {
    let participant: Participant
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(AppDesignSystem.Colors.primary)
            
            Text(participant.name)
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 16))
                    .foregroundColor(AppDesignSystem.Colors.error)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        )
    }
}

// Helper view for match selection cards (Enhanced)
struct MatchSelectionCard: View {
    let match: Match
    let isSelected: Bool
    let onToggle: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Button(action: onToggle) {
            CardView {
                VStack(spacing: 12) {
                    // Header with competition and status
                    HStack {
                        Text(match.competition.name)
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Spacer()
                        
                        matchStatusBadge
                    }
                    
                    // Teams
                    HStack(spacing: 20) {
                        VStack {
                            Text(match.homeTeam.name)
                                .font(AppDesignSystem.Typography.bodyFont.bold())
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                        }
                        
                        Text("vs")
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        VStack {
                            Text(match.awayTeam.name)
                                .font(AppDesignSystem.Typography.bodyFont.bold())
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Date and time
                    Text(dateFormatter.string(from: match.startTime))
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(.horizontal, 4)
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                    .stroke(
                        isSelected ? AppDesignSystem.Colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
            .overlay(
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(
                                isSelected ?
                                AppDesignSystem.Colors.primary :
                                AppDesignSystem.Colors.secondaryText.opacity(0.7)
                            )
                            .font(.title2)
                            .padding(8)
                        Spacer()
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var matchStatusBadge: some View {
        let (text, color) = matchStatusInfo
        
        return Text(text)
            .font(AppDesignSystem.Typography.captionFont)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(8)
    }
    
    private var matchStatusInfo: (String, Color) {
        switch match.status {
        case .upcoming:
            return ("Upcoming", AppDesignSystem.Colors.primary)
        case .inProgress:
            return ("Live", AppDesignSystem.Colors.success)
        case .halftime:
            return ("Half-time", AppDesignSystem.Colors.primary)
        case .completed:
            return ("Finished", AppDesignSystem.Colors.secondary)
        case .unknown:
            return ("Unknown", AppDesignSystem.Colors.error)
        }
    }
}
