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
    @State private var showingMatchSelection = false
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var showingPlayerUnavailableAlert = false
    @State private var unavailableMatchesMessage = ""
    @State private var temporaryStep: Int? = nil
    
    private let steps = ["Matches", "Participants", "Set Bets", "Select Players", "Review"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        VStack {
                            Circle()
                                .fill(index <= currentStep ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.secondaryText.opacity(0.3))
                                .frame(width: 20, height: 20)
                            
                            Text(steps[index])
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(index <= currentStep ? AppDesignSystem.Colors.primaryText : AppDesignSystem.Colors.secondaryText)
                        }
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.secondaryText.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
                .padding()
                
                // Content based on current step
                ScrollView {
                    VStack {
                        if isLoading {
                            ProgressView("Loading...")
                                .padding(.top, 100)
                        } else if let errorMessage = error {
                            VStack(spacing: 20) {
                                Image(systemName: "exclamationmark.triangle")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppDesignSystem.Colors.error)
                                
                                Text("Error")
                                    .font(AppDesignSystem.Typography.headingFont)
                                
                                Text(errorMessage)
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
                                Button("Try Again") {
                                    error = nil
                                    if currentStep == 0 {
                                        loadMatches()
                                    }
                                }
                                .buttonStyle(PrimaryButtonStyle())
                            }
                            .padding(.top, 60)
                        } else {
                            switch currentStep {
                            case 0:
                                matchSelectionView
                            case 1:
                                participantsSetupView
                            case 2:
                                setBetsView
                            case 3:
                                playersSelectionView
                            case 4:
                                reviewView
                            default:
                                EmptyView()
                            }
                        }
                    }
                    .padding()
                }
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            currentStep -= 1
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            validateAndProceed()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("Start Game") {
                            startGame()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding()
            }
            .navigationTitle("Live Game Setup")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
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
            .sheet(isPresented: $showingCustomBetSheet) {
                CustomBetView(gameSession: gameSession)
            }
            .alert(isPresented: $showingPlayerUnavailableAlert) {
                Alert(
                    title: Text("Lineup Not Available Yet"),
                    message: Text(unavailableMatchesMessage),
                    primaryButton: .default(Text("Continue with Placeholders")) {
                        if let nextStep = temporaryStep {
                            currentStep = nextStep
                            temporaryStep = nil
                        }
                    },
                    secondaryButton: .cancel(Text("Go Back")) {
                        temporaryStep = nil
                    }
                )
            }
        }
    }
    
    // MARK: - Step Views
    
    private var matchSelectionView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            Text("Select Matches")
                .font(AppDesignSystem.Typography.headingFont)
            
            Text("Choose which match(es) you want to follow:")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            if gameSession.availableMatches.isEmpty {
                VStack {
                    Text("No matches available")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .padding(.top, 40)
                }
                .frame(maxWidth: .infinity)
            } else {
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
            
            if selectedMatchIds.isEmpty {
                Text("Select at least one match to continue")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(.top, 4)
            }
            
            if !AppConfig.canSelectMultipleMatches && selectedMatchIds.count > 1 {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Multiple Match Selection")
                        .font(AppDesignSystem.Typography.subheadingFont)
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    
                    Text("You're in free mode which only allows one match at a time. Upgrade to premium to follow multiple matches simultaneously.")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Button("Upgrade to Premium") {
                        NotificationCenter.default.post(
                            name: Notification.Name("ShowUpgradePrompt"),
                            object: nil
                        )
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.top, 8)
                }
                .padding()
                .background(AppDesignSystem.Colors.primary.opacity(0.1))
                .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                .padding(.top, 20)
            }
        }
    }
    
    private var participantsSetupView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            Text("Add Participants")
                .font(AppDesignSystem.Typography.headingFont)
            
            HStack {
                TextField("Participant name", text: $participantName)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Button(action: {
                    if !participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        gameSession.addParticipant(participantName)
                        participantName = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            if gameSession.participants.isEmpty {
                Text("Add at least one participant to continue")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(.top, 4)
            }
            
            Text("Current Participants:")
                .font(AppDesignSystem.Typography.subheadingFont)
                .padding(.top)
            
            ForEach(gameSession.participants) { participant in
                HStack {
                    Text(participant.name)
                        .font(AppDesignSystem.Typography.bodyFont)
                    
                    Spacer()
                    
                    Button(action: {
                        if let index = gameSession.participants.firstIndex(where: { $0.id == participant.id }) {
                            gameSession.participants.remove(at: index)
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(AppDesignSystem.Colors.error)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    private var setBetsView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            HStack {
                Text("Set Betting Amounts")
                    .font(AppDesignSystem.Typography.headingFont)
                
                Spacer()
                
                Button(action: {
                    showingCustomBetSheet = true
                }) {
                    Label("Add Custom Bet", systemImage: "plus.circle")
                        .font(AppDesignSystem.Typography.bodyFont)
                }
            }
            
            // Currency Selection
            HStack {
                Text("Select Currency")
                    .font(AppDesignSystem.Typography.subheadingFont)
                
                Spacer()
                
                // Currency Picker (same as in NewGameSetupView)
                // ...
            }
            .padding(.bottom)
            
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
            
            // Check if we're using dummy players
            let hasDummyPlayers = gameSession.availablePlayers.contains { $0.name.contains("Player ") }
            
            if hasDummyPlayers {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Official Lineup Not Available")
                        .font(AppDesignSystem.Typography.subheadingFont)
                        .foregroundColor(AppDesignSystem.Colors.warning)
                    
                    Text("The official team lineup hasn't been announced yet. We've created placeholder players that you can use for now. Team lineups are typically announced about one hour before kickoff.")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Text("You can continue with these placeholders or check back closer to kickoff time for the actual lineups.")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .padding(.top, 4)
                }
                .padding()
                .background(AppDesignSystem.Colors.warning.opacity(0.1))
                .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                .padding(.vertical, 8)
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
                VStack {
                    Text("No players available")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .padding(.top, 40)
                }
                .frame(maxWidth: .infinity)
            } else {
                let teamGroups = Dictionary(grouping: gameSession.availablePlayers, by: { $0.team.id })
                
                ForEach(teamGroups.keys.sorted(), id: \.self) { teamId in
                    if let teamPlayers = teamGroups[teamId], let team = teamPlayers.first?.team {
                        VStack(alignment: .leading) {
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
        }
    }
    
    private var reviewView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            Text("Review Game Setup")
                .font(AppDesignSystem.Typography.headingFont)
            
            // Selected matches
            CardView {
                VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                    Text("Selected Matches")
                        .font(AppDesignSystem.Typography.subheadingFont)
                    
                    ForEach(gameSession.availableMatches.filter { selectedMatchIds.contains($0.id) }) { match in
                        HStack {
                            Text("\(match.homeTeam.name) vs \(match.awayTeam.name)")
                                .font(AppDesignSystem.Typography.bodyFont)
                            
                            Spacer()
                            
                            Text(match.competition.name)
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            // Participants
            CardView {
                VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                    Text("Participants (\(gameSession.participants.count))")
                        .font(AppDesignSystem.Typography.subheadingFont)
                    
                    Text(gameSession.participants.map { $0.name }.joined(separator: ", "))
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            
            // Selected players
            CardView {
                VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                    Text("Selected Players (\(selectedPlayerIds.count))")
                        .font(AppDesignSystem.Typography.subheadingFont)
                    
                    let selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
                    let playersByTeam = Dictionary(grouping: selectedPlayers) { $0.team.name }
                    
                    ForEach(playersByTeam.keys.sorted(), id: \.self) { teamName in
                        Text(teamName)
                            .font(AppDesignSystem.Typography.bodyFont.bold())
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                            .padding(.top, 4)
                        
                        if let players = playersByTeam[teamName] {
                            Text(players.map { $0.name }.joined(separator: ", "))
                                .font(AppDesignSystem.Typography.bodyFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                    }
                }
            }
            
            // Betting amounts
            CardView {
                VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                    Text("Betting Amounts")
                        .font(AppDesignSystem.Typography.subheadingFont)
                    
                    ForEach(Bet.EventType.allCases, id: \.self) { eventType in
                        let amount = betAmounts[eventType] ?? 0.0
                        let isNegative = amount < 0
                        let formattedAmount = formatCurrency(abs(amount))
                        
                        HStack {
                            Text(eventType.rawValue)
                                .font(AppDesignSystem.Typography.bodyFont)
                            
                            Spacer()
                            
                            Text("\(isNegative ? "-" : "+")\(formattedAmount)")
                                .font(AppDesignSystem.Typography.bodyFont.bold())
                                .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                        }
                    }
                }
            }
            
            Text("Ready to start the game? Players will be randomly assigned to participants, and you'll receive live updates during the match.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .padding(.top)
        }
    }
    
    // MARK: - Helper Methods
    
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
    
    private func showPlayerUnavailableWarning(matches: [Match]) {
        // Format the message
        if matches.count == 1 {
            let match = matches[0]
            unavailableMatchesMessage = "The official lineup for \(match.homeTeam.name) vs \(match.awayTeam.name) is not available yet. Team lineups are typically announced about one hour before kickoff.\n\nYou can continue with the generated placeholder players, or check back closer to match time for the official lineup."
        } else {
            let matchNames = matches.map { "\($0.homeTeam.name) vs \($0.awayTeam.name)" }.joined(separator: ", ")
            unavailableMatchesMessage = "The official lineups for \(matchNames) are not available yet. Team lineups are typically announced about one hour before kickoff.\n\nYou can continue with the generated placeholder players, or check back closer to match time for the official lineups."
        }
        
        // Store the step we want to proceed to after the alert
        temporaryStep = currentStep + 1
        
        // Show the alert
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
    
    private func validateAndProceed() {
        switch currentStep {
        case 0: // Match selection
            if selectedMatchIds.isEmpty {
                error = "Please select at least one match to continue."
                return
            }
            
            // Load players for selected matches if needed
            if currentStep == 0 && gameSession.availablePlayers.isEmpty {
                loadPlayersForSelectedMatches()
                return
            }
            
        case 1: // Participants
            if gameSession.participants.isEmpty {
                error = "Please add at least one participant to continue."
                return
            }
            
        case 2: // Bets
            // No validation needed, default bets are always set
            break
            
        case 3: // Player selection
            if selectedPlayerIds.isEmpty {
                error = "Please select at least one player to continue."
                return
            }
            
            // Update gameSession.selectedPlayers with the chosen players
            gameSession.selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
            
        default:
            break
        }
        
        // Proceed to next step
        currentStep += 1
    }
    
    private func loadPlayersForSelectedMatches() {
        isLoading = true
        error = nil
        
        Task {
            do {
                // Determine which matches to load based on premium status
                let matchIdsToLoad = AppConfig.canSelectMultipleMatches
                    ? self.selectedMatchIds
                    : [self.selectedMatchIds.first!]
                
                // Clear previous players
                await MainActor.run {
                    gameSession.availablePlayers = []
                }
                
                // Load players for each match
                var allPlayers: [Player] = []
                var loadedMatchIds: [String] = []
                var playerUnavailableMatches: [Match] = []
                
                for matchId in matchIdsToLoad {
                    if let match = gameSession.availableMatches.first(where: { $0.id == matchId }) {
                        // Load players for this match
                        do {
                            // Use a public method for accessing matchService instead of directly accessing a private property
                            let players = try await gameSession.fetchMatchPlayers(for: matchId) ?? []
                            
                            // Check if we got actual players or dummy ones
                            let hasDummyPlayers = players.isEmpty || players.contains(where: {
                                $0.name.contains("Player ") // Check for dummy player naming pattern
                            })
                            
                            if hasDummyPlayers {
                                // Store match that doesn't have real players yet
                                playerUnavailableMatches.append(match)
                            }
                            
                            // Add the players to our collection
                            allPlayers.append(contentsOf: players)
                            loadedMatchIds.append(matchId)
                            
                            // Increment match usage for free users
                            if AppPurchaseManager.shared.currentTier == .free {
                                AppConfig.incrementMatchUsage()
                            }
                        } catch {
                            print("Error loading players for match \(matchId): \(error)")
                            // Continue to next match even if this one fails
                        }
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                    
                    // Update game session with all players from all selected matches
                    gameSession.availablePlayers = allPlayers
                    
                    // If we found some players, proceed
                    if !allPlayers.isEmpty {
                        // Show lineup warning if any match has no real players
                        if !playerUnavailableMatches.isEmpty {
                            self.showPlayerUnavailableWarning(matches: playerUnavailableMatches)
                        } else {
                            // If all players are real, just proceed to next step
                            currentStep += 1
                        }
                    } else {
                        error = "No players found for the selected match(es). Players may not be available yet. You can try again closer to kickoff time when team lineups are announced."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = "Error loading players: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func startGame() {
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
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}

// Helper view for match selection cards
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
                VStack {
                    HStack {
                        Text(match.competition.name)
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Spacer()
                        
                        matchStatusBadge
                    }
                    
                    HStack(spacing: 20) {
                        VStack {
                            Text(match.homeTeam.name)
                                .font(AppDesignSystem.Typography.bodyFont.bold())
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                        }
                        
                        Text("vs")
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        VStack {
                            Text(match.awayTeam.name)
                                .font(AppDesignSystem.Typography.bodyFont.bold())
                                .lineLimit(1)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    Text(dateFormatter.string(from: match.startTime))
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(.horizontal, 4)
            }
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                    .stroke(isSelected ? AppDesignSystem.Colors.primary : Color.clear, lineWidth: 2)
            )
            .overlay(
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.secondaryText.opacity(0.7))
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
