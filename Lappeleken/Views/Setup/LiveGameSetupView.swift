//
//  LiveGameSetupView.swift
//  Lucky Football Slip
//
//  Live game setup wizard - Football themed
//

import SwiftUI
import Network

struct LiveGameSetupView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var currentStep = 0
    @State private var participantName = ""
    @State private var selectedMatchIds = Set<String>()
    @State private var selectedPlayerIds = Set<UUID>()
    @State private var startingXIPlayerIds = Set<UUID>()  // Track which players are Starting XI
    @State private var betAmounts = [Bet.EventType: Double]()
    @State private var betNegativeFlags = [Bet.EventType: Bool]()
    @State private var showingCustomBetSheet = false
    @State private var showingLiveSetupInfo = false
    @State private var isLoading = false
    @State private var error: String? = nil
    @State private var showingPlayerUnavailableAlert = false
    @State private var unavailableMatchesMessage = ""
    @ObservedObject private var reminderManager = MatchReminderManager.shared
    @State private var reminderHint: String? = nil
    @State private var temporaryStep: Int? = nil
    @State private var isPresentingAlert = false
    @State private var isConnected = true
    @State private var showingRateLimit = false
    @State private var nextUpdateTime = 90
    @State private var showingLineupChoiceAlert = false
    @State private var pendingMatchId: String?
    @State private var pendingMatchName: String?
    @State private var expandedLeagues = Set<String>()
    @State private var playerAssignments: [Participant: [Player]] = [:]
    @State private var showingPlayerDrawing = false
    @State private var showingUpgradeSheet = false
    @State private var selectedLeagueForUpgrade: String? = nil
    
    @StateObject private var networkMonitor = NetworkMonitor()
    @ObservedObject private var leagueManager = LeagueAccessManager.shared

    private let steps = ["Matches", "Participants", "Set Bets", "Select Players", "Review"]
    
    var body: some View {
        NavigationView {
            ZStack {
                footballBackground
                
                VStack(spacing: 0) {
                    if !networkMonitor.isConnected {
                        connectionStatusBar
                    }
                    
                    if showingRateLimit {
                        rateLimitWarningBar
                    }
                    
                    progressIndicator
                    
                    // Main content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            if isLoading {
                                loadingStateView
                            } else if let errorMessage = error {
                                errorStateView(errorMessage)
                            } else {
                                stepContentView
                            }
                        }
                        .padding(20)
                    }
                    
                    navigationButtons
                }
            }
            .navigationTitle("Live Game Setup")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingLiveSetupInfo = true }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(AppDesignSystem.Colors.grassGreen)
                    }
                }
            }
        }
        .onAppear { setupInitialState() }
        .sheet(isPresented: $showingCustomBetSheet) {
            CustomBetView(gameSession: gameSession)
        }
        .sheet(isPresented: $showingLiveSetupInfo) {
            LiveModeInfoView(onGetStarted: {})
        }
        .sheet(isPresented: $showingPlayerDrawing) {
            PlayerDrawingView(
                gameSession: gameSession,
                selectedPlayers: gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) },
                participants: gameSession.participants,
                onComplete: { assignments in
                    for (participant, players) in assignments {
                        if let index = gameSession.participants.firstIndex(where: { $0.id == participant.id }) {
                            gameSession.participants[index].selectedPlayers = players
                            gameSession.participants[index].balance = 0.0
                        }
                    }
                    playerAssignments = assignments
                    showingPlayerDrawing = false
                    currentStep += 1
                },
                onBack: { showingPlayerDrawing = false }
            )
        }
        .sheet(isPresented: $showingUpgradeSheet) {
            UpgradeView()
        }
        .alert("Lineup Not Available", isPresented: $showingLineupChoiceAlert) {
            Button("Use Full Squad") {
                if let matchId = pendingMatchId { loadFullSquadForMatch(matchId) }
                clearPendingMatch()
            }
            Button("Go Back") { clearPendingMatch() }
            Button("Cancel", role: .cancel) { clearPendingMatch() }
        } message: {
            Text("Lineups are not available yet for \(pendingMatchName ?? "this match"). Would you like to use the full squad instead?")
        }
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            
            VStack {
                LinearGradient(
                    colors: [AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.12 : 0.06), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Connection Status
    
    private var connectionStatusBar: some View {
        HStack(spacing: 8) {
            Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                .font(.system(size: 14))
            Text(networkMonitor.isConnected ? "Connected" : "No Connection")
                .font(.system(size: 13, weight: .medium))
            Spacer()
        }
        .foregroundColor(networkMonitor.isConnected ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.error)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            (networkMonitor.isConnected ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.error).opacity(0.1)
        )
    }
    
    private var rateLimitWarningBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
            Text("Rate limited - please wait before retrying")
                .font(.system(size: 13, weight: .medium))
            Spacer()
        }
        .foregroundColor(AppDesignSystem.Colors.warning)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppDesignSystem.Colors.warning.opacity(0.1))
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<steps.count, id: \.self) { index in
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .fill(index <= currentStep ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.3))
                            .frame(width: 28, height: 28)
                        
                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(index == currentStep ? .white : AppDesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Text(steps[index])
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(index <= currentStep ? AppDesignSystem.Colors.primaryText : AppDesignSystem.Colors.secondaryText)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
                
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: 20)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    // MARK: - Loading State
    
    private var loadingStateView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppDesignSystem.Colors.grassGreen))
                    .scaleEffect(1.3)
            }
            
            Text("Loading matches...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("Fetching live data from football API")
                .font(.system(size: 13))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    // MARK: - Error State
    
    private func errorStateView(_ errorMessage: String) -> some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.error.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(AppDesignSystem.Colors.error)
            }
            
            VStack(spacing: 8) {
                Text("Something went wrong")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(errorMessage)
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: {
                error = nil
                if currentStep == 0 { loadMatches() }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(RoundedRectangle(cornerRadius: 10).fill(AppDesignSystem.Colors.grassGreen))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContentView: some View {
        switch currentStep {
        case 0: matchSelectionStep
        case 1: participantsStep
        case 2: betsStep
        case 3: playersStep
        case 4: reviewStep
        default: EmptyView()
        }
    }
    
    // MARK: - Step 0: Match Selection
    
    private var matchSelectionStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            SetupStepHeader(
                icon: "sportscourt.fill",
                iconColor: AppDesignSystem.Colors.grassGreen,
                title: "Select Matches",
                subtitle: "Choose which matches to follow in real-time"
            )
            
            if gameSession.availableMatches.isEmpty {
                emptyMatchesView
            } else {
                matchesListView
            }

            if let reminderHint = reminderHint {
                HStack(spacing: 6) {
                    Image(systemName: "bell.slash.fill")
                        .font(.system(size: 12))
                    Text(reminderHint)
                        .font(.system(size: 13))
                }
                .foregroundColor(AppDesignSystem.Colors.warning)
            }

            if selectedMatchIds.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                    Text("Select at least one match to continue")
                        .font(.system(size: 13))
                }
                .foregroundColor(AppDesignSystem.Colors.warning)
            }
        }
    }
    
    private var emptyMatchesView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.secondaryText.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sportscourt")
                    .font(.system(size: 36))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
            }
            
            VStack(spacing: 6) {
                Text("No Matches Available")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Check back later for upcoming matches")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Button(action: loadMatches) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.grassGreen)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    }
    
    private var matchesListView: some View {
        VStack(spacing: 12) {
            ForEach(leagueGroups, id: \.league) { leagueGroup in
                LiveLeagueSection(
                    leagueGroup: leagueGroup,
                    isExpanded: expandedLeagues.contains(leagueGroup.league),
                    selectedMatchIds: selectedMatchIds,
                    onToggleExpand: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            if expandedLeagues.contains(leagueGroup.league) {
                                expandedLeagues.remove(leagueGroup.league)
                            } else {
                                expandedLeagues.insert(leagueGroup.league)
                            }
                        }
                    },
                    onSelectMatch: { match in
                        toggleMatchSelection(match)
                    },
                    reminderMatchIds: reminderManager.reminderMatchIds,
                    onToggleReminder: { match in
                        toggleReminder(for: match)
                    }
                )
            }
        }
    }
    
    // MARK: - Step 1: Participants
    
    private var participantsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            SetupStepHeader(
                icon: "person.3.fill",
                iconColor: AppDesignSystem.Colors.grassGreen,
                title: "Add Participants",
                subtitle: "Who's playing in this game?"
            )
            
            // Add participant input
            HStack(spacing: 10) {
                HStack {
                    Image(systemName: "person")
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    TextField("Enter name", text: $participantName)
                        .font(.system(size: 14))
                        .submitLabel(.done)
                        .onSubmit { addParticipant() }
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                )
                
                Button(action: addParticipant) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(participantName.isEmpty ? AppDesignSystem.Colors.secondaryText.opacity(0.4) : AppDesignSystem.Colors.grassGreen)
                }
                .disabled(participantName.isEmpty)
            }
            
            // Participants list
            if gameSession.participants.isEmpty {
                Text("Add at least 2 participants to continue")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.warning)
                    .padding(.top, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(gameSession.participants.enumerated()), id: \.element.id) { index, participant in
                        ParticipantRowNew(participant: participant, index: index) {
                            removeParticipant(participant)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Step 2: Bets
    
    private var betsStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            SetupStepHeader(
                icon: "dollarsign.circle.fill",
                iconColor: AppDesignSystem.Colors.grassGreen,
                title: "Set Bet Amounts",
                subtitle: "Configure how much each event is worth"
            )
            
            VStack(spacing: 10) {
                ForEach(Bet.EventType.liveAPISupported, id: \.self) { eventType in
                    LiveBetRow(
                        eventType: eventType,
                        amount: betAmounts[eventType] ?? 0,
                        isNegative: betNegativeFlags[eventType] ?? false,
                        onAmountChange: { newAmount in
                            betAmounts[eventType] = newAmount
                        },
                        onToggleNegative: {
                            betNegativeFlags[eventType] = !(betNegativeFlags[eventType] ?? false)
                        }
                    )
                }
            }
            
            Button(action: { showingCustomBetSheet = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle")
                    Text("Add Custom Event")
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.grassGreen)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(AppDesignSystem.Colors.grassGreen.opacity(0.4), lineWidth: 1.5)
                )
            }
        }
    }
    
    // MARK: - Step 3: Players
    
    private var playersStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            SetupStepHeader(
                icon: "person.crop.rectangle.stack.fill",
                iconColor: AppDesignSystem.Colors.grassGreen,
                title: "Select Players",
                subtitle: "Choose players from the starting lineup"
            )
            
            if gameSession.availablePlayers.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: AppDesignSystem.Colors.grassGreen))
                    Text("Loading players...")
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                // Quick actions
                HStack(spacing: 10) {
                    Button(action: selectAllStartingXI) {
                        Text("Select All")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(AppDesignSystem.Colors.grassGreen))
                    }
                    
                    Button(action: deselectAllPlayers) {
                        Text("Clear")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.error)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 8).stroke(AppDesignSystem.Colors.error.opacity(0.5), lineWidth: 1))
                    }
                    
                    Spacer()
                    
                    Text("\(selectedPlayerIds.count) selected")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                // Players by team (with Starting XI and Reserves sections)
                ForEach(getPlayersByTeam(gameSession.availablePlayers), id: \.team.id) { teamData in
                    LiveTeamPlayersSection(
                        team: teamData.team,
                        players: teamData.players,
                        selectedIds: selectedPlayerIds,
                        startingXIIds: startingXIPlayerIds,
                        onTogglePlayer: { player in
                            // Only allow toggling Starting XI players
                            if startingXIPlayerIds.contains(player.id) {
                                togglePlayerSelection(player)
                            }
                        },
                        onSelectTeam: {
                            selectTeamStartingXI(teamId: teamData.team.id)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Step 4: Review
    
    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 24) {
            SetupStepHeader(
                icon: "checkmark.circle.fill",
                iconColor: AppDesignSystem.Colors.grassGreen,
                title: "Review & Start",
                subtitle: "Everything looks good? Let's go!"
            )
            
            // Summary cards
            VStack(spacing: 12) {
                LiveSummaryCard(
                    icon: "sportscourt.fill",
                    title: "Matches",
                    value: "\(selectedMatchIds.count)",
                    color: AppDesignSystem.Colors.grassGreen
                )
                
                LiveSummaryCard(
                    icon: "person.3.fill",
                    title: "Participants",
                    value: "\(gameSession.participants.count)",
                    color: AppDesignSystem.Colors.info
                )
                
                LiveSummaryCard(
                    icon: "figure.run",
                    title: "Players",
                    value: "\(selectedPlayerIds.count)",
                    color: AppDesignSystem.Colors.goalYellow
                )
                
                let activeBets = betAmounts.filter { $0.value != 0 }.count
                LiveSummaryCard(
                    icon: "dollarsign.circle.fill",
                    title: "Active Bets",
                    value: "\(activeBets)",
                    color: AppDesignSystem.Colors.accent
                )
            }
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 12) {
                if currentStep > 0 {
                    Button(action: { withAnimation { currentStep -= 1 } }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppDesignSystem.Colors.grassGreen.opacity(0.12))
                        )
                    }
                }
                
                let isLastStep = currentStep == steps.count - 1
                Button(action: {
                    if canProceed {
                        if isLastStep {
                            startGame()
                        } else {
                            validateAndProceed()
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Text(isLastStep ? "Start Game" : "Continue")
                        Image(systemName: isLastStep ? "play.fill" : "chevron.right")
                    }
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canProceed ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.3))
                    )
                }
                .disabled(!canProceed)
            }
            .padding(16)
            .background(AppDesignSystem.Colors.cardBackground)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !selectedMatchIds.isEmpty
        case 1: return gameSession.participants.count >= 2
        case 2: return true
        case 3: return !selectedPlayerIds.isEmpty
        case 4: return true
        default: return false
        }
    }
    
    private var matchesByLeague: [String: [Match]] {
        Dictionary(grouping: gameSession.availableMatches) { $0.competition.code }
    }
    
    private var leagueGroups: [LeagueGroup] {
        let leagueOrder = ["TIP", "WC", "CL", "PL", "BL1", "DED", "BSA", "PD", "FL1", "ELC", "PPL", "EC", "SA"]
        
        return matchesByLeague.keys
            .sorted { (leagueOrder.firstIndex(of: $0) ?? 999) < (leagueOrder.firstIndex(of: $1) ?? 999) }
            .compactMap { code in
                guard let matches = matchesByLeague[code] else { return nil }
                return LeagueGroup(
                    league: code,
                    name: matches.first?.competition.name ?? code,
                    matches: matches
                )
            }
    }
    
    // MARK: - Actions
    
    private func setupInitialState() {
        gameSession.availablePlayers = []
        gameSession.selectedPlayers = []
        selectedPlayerIds = Set<UUID>()
        loadMatches()
        if betAmounts.isEmpty { initializeBetAmounts() }
    }
    
    private func initializeBetAmounts() {
        for eventType in Bet.EventType.allCases {
            betAmounts[eventType] = 0.0
            betNegativeFlags[eventType] = (eventType == .ownGoal || eventType == .penaltyMissed)
        }
    }
    
    private func loadMatches() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let matches = try await DataManager.shared.fetchMatches()
                await MainActor.run {
                    gameSession.availableMatches = matches
                    isLoading = false
                    // Auto-expand first league if it has matches
                    if let firstLeague = leagueGroups.first {
                        expandedLeagues.insert(firstLeague.league)
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = handleDataError(error)
                }
            }
        }
    }
    
    private func toggleReminder(for match: Match) {
        let wasSet = reminderManager.hasReminder(match.id)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        Task {
            let nowSet = await reminderManager.toggleReminder(for: match)
            // If we tried to turn it ON but it's still off, permission was denied.
            if !wasSet && !nowSet {
                await MainActor.run { showReminderHint() }
            }
        }
    }

    private func showReminderHint() {
        withAnimation { reminderHint = "Enable notifications in Settings to get match reminders." }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            withAnimation { reminderHint = nil }
        }
    }

    private func toggleMatchSelection(_ match: Match) {
        if selectedMatchIds.contains(match.id) {
            selectedMatchIds.remove(match.id)
        } else {
            if !AppConfig.canSelectMultipleMatches {
                selectedMatchIds = [match.id]
            } else {
                selectedMatchIds.insert(match.id)
            }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func addParticipant() {
        let name = participantName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        gameSession.addParticipant(name)
        participantName = ""
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func removeParticipant(_ participant: Participant) {
        if let index = gameSession.participants.firstIndex(where: { $0.id == participant.id }) {
            gameSession.participants.remove(at: index)
        }
    }
    
    private func togglePlayerSelection(_ player: Player) {
        if selectedPlayerIds.contains(player.id) {
            selectedPlayerIds.remove(player.id)
        } else {
            selectedPlayerIds.insert(player.id)
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func selectAllStartingXI() {
        // Only select Starting XI players (not reserves)
        selectedPlayerIds = startingXIPlayerIds
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func selectTeamStartingXI(teamId: UUID) {
        // Select only Starting XI players from this team
        let teamStartingXI = gameSession.availablePlayers
            .filter { $0.team.id == teamId && startingXIPlayerIds.contains($0.id) }
            .map { $0.id }
        selectedPlayerIds.formUnion(teamStartingXI)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }
    
    private func deselectAllPlayers() {
        selectedPlayerIds.removeAll()
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }
    
    private func getPlayersByTeam(_ players: [Player]) -> [TeamPlayersData] {
        return Dictionary(grouping: players) { $0.team }
            .map { team, teamPlayers in
                // Sort alphabetically by name
                let sortedPlayers = teamPlayers.sorted { $0.name < $1.name }
                return TeamPlayersData(team: team, players: sortedPlayers)
            }
            .sorted { $0.team.name < $1.team.name }
    }
    
    private func validateAndProceed() {
        // Auto-add participant if name entered
        if currentStep == 1 && !participantName.isEmpty {
            addParticipant()
        }
        
        // Show player drawing after player selection
        if currentStep == 3 && !selectedPlayerIds.isEmpty {
            showingPlayerDrawing = true
            return
        }
        
        // Load players when moving to player selection step
        if currentStep == 0 && !selectedMatchIds.isEmpty {
            loadPlayersForSelectedMatches()
        }
        
        withAnimation { currentStep += 1 }
    }
    
    private func loadPlayersForSelectedMatches() {
        isLoading = true
        
        Task {
            do {
                var startingXIApiIds = Set<String>()
                var allPlayers: [Player] = []
                var seenApiIds = Set<String>()  // Use API ID for deduplication
                
                for matchId in selectedMatchIds {
                    try await gameSession.fetchMatchLineup(for: matchId)
                    
                    if let lineup = gameSession.matchLineups[matchId] {
                        // Get Starting XI
                        let homeStartingXI = lineup.homeTeam.startingXI
                        let awayStartingXI = lineup.awayTeam.startingXI
                        
                        // Get Substitutes
                        let homeSubstitutes = lineup.homeTeam.substitutes
                        let awaySubstitutes = lineup.awayTeam.substitutes
                        
                        // Track Starting XI API IDs
                        for player in homeStartingXI + awayStartingXI {
                            if let apiId = player.apiId {
                                startingXIApiIds.insert(apiId)
                            }
                        }
                        
                        // Add ALL players, avoiding duplicates by API ID
                        let matchPlayers = homeStartingXI + awayStartingXI + homeSubstitutes + awaySubstitutes
                        for player in matchPlayers {
                            let playerKey = player.apiId ?? player.id.uuidString
                            if !seenApiIds.contains(playerKey) {
                                seenApiIds.insert(playerKey)
                                allPlayers.append(player)
                            }
                        }
                    }
                }
                
                // Build startingXIPlayerIds from the final player list
                let startingXIIds = Set(allPlayers.filter {
                    guard let apiId = $0.apiId else { return false }
                    return startingXIApiIds.contains(apiId)
                }.map { $0.id })
                
                await MainActor.run {
                    // Clear existing players and set fresh list
                    gameSession.availablePlayers = allPlayers
                    
                    // Store starting XI IDs for UI differentiation
                    self.startingXIPlayerIds = startingXIIds
                    // No auto-selection
                    selectedPlayerIds = Set<UUID>()
                    isLoading = false
                    
                    let startingCount = startingXIIds.count
                    let totalCount = allPlayers.count
                    print("✅ Loaded \(startingCount) starting XI + \(totalCount - startingCount) substitutes (deduplicated by apiId)")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = "Failed to load players: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func loadFullSquadForMatch(_ matchId: String) {
        isLoading = true
        error = nil
        
        Task {
            do {
                let players = try await DataManager.shared.fetchSquad(for: matchId)
                
                await MainActor.run {
                    // Add players to available players (avoiding duplicates)
                    let existingIds = Set(gameSession.availablePlayers.map { $0.id })
                    let newPlayers = players.filter { !existingIds.contains($0.id) }
                    gameSession.availablePlayers.append(contentsOf: newPlayers)
                    
                    isLoading = false
                    print("✅ Loaded \(newPlayers.count) squad players for match \(matchId)")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = "Failed to load squad: \(error.localizedDescription)"
                    print("❌ Failed to load squad: \(error)")
                }
            }
        }
    }
    
    private func clearPendingMatch() {
        pendingMatchId = nil
        pendingMatchName = nil
    }
    
    private func startGame() {
        // Apply bets to game session
        gameSession.bets = betAmounts.compactMap { eventType, amount in
            guard amount != 0 else { return nil }
            let finalAmount = (betNegativeFlags[eventType] ?? false) ? -abs(amount) : abs(amount)
            return Bet(eventType: eventType, amount: finalAmount)
        }
        
        // Set selected players
        gameSession.selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
        
        // Set live mode
        gameSession.isLiveMode = true
        
        // Store selected matches
        gameSession.selectedMatches = gameSession.availableMatches.filter { selectedMatchIds.contains($0.id) }
        if let firstMatch = gameSession.selectedMatches.first {
            gameSession.selectedMatch = firstMatch
        }
        
        // Notify and dismiss
        NotificationCenter.default.post(name: Notification.Name("StartGameWithSelectedMatch"), object: nil)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func handleDataError(_ error: Error) -> String {
        if let dataError = error as? DataError {
            switch dataError {
            case .rateLimited:
                showingRateLimit = true
                return "Too many requests. Please wait and try again."
            case .networkUnavailable:
                return "No internet connection. Please check your network."
            case .fetchFailed(let resource, _):
                return "Failed to load \(resource). Please try again."
            default:
                return dataError.localizedDescription
            }
        }
        return error.localizedDescription
    }
}



// MARK: - Supporting Components

struct LiveBetRow: View {
    let eventType: Bet.EventType
    let amount: Double
    let isNegative: Bool
    let onAmountChange: (Double) -> Void
    let onToggleNegative: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var icon: String {
        switch eventType {
        case .goal: return "soccerball"
        case .assist: return "arrow.up.forward"
        case .yellowCard: return "square.fill"
        case .redCard: return "square.fill"
        case .ownGoal: return "arrow.uturn.backward"
        case .penalty: return "p.circle"
        case .penaltyMissed: return "p.circle.fill"
        case .cleanSheet: return "lock.shield"
        case .custom: return "star.fill"
        }
    }
    
    private var iconColor: Color {
        switch eventType {
        case .goal, .penalty: return AppDesignSystem.Colors.grassGreen
        case .assist, .cleanSheet: return AppDesignSystem.Colors.info
        case .yellowCard: return AppDesignSystem.Colors.goalYellow
        case .redCard, .penaltyMissed: return AppDesignSystem.Colors.error
        case .ownGoal: return AppDesignSystem.Colors.warning
        case .custom: return AppDesignSystem.Colors.accent
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(eventType.rawValue.capitalized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Button(action: onToggleNegative) {
                Image(systemName: isNegative ? "minus.circle.fill" : "plus.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.grassGreen)
            }
            
            TextField("0", value: .init(
                get: { amount },
                set: { onAmountChange($0) }
            ), format: .number)
                .font(.system(size: 14, weight: .semibold))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03)))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
        )
    }
}

struct LiveLeagueSection: View {
    let leagueGroup: LeagueGroup
    let isExpanded: Bool
    let selectedMatchIds: Set<String>
    let onToggleExpand: () -> Void
    let onSelectMatch: (Match) -> Void
    var reminderMatchIds: Set<String> = []
    var onToggleReminder: ((Match) -> Void)? = nil

    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggleExpand) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(leagueGroup.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        Text("\(leagueGroup.matches.count) matches")
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    let selectedCount = leagueGroup.matches.filter { selectedMatchIds.contains($0.id) }.count
                    if selectedCount > 0 {
                        Text("\(selectedCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(AppDesignSystem.Colors.grassGreen))
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppDesignSystem.Colors.cardBackground)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Matches
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(leagueGroup.matches, id: \.id) { match in
                        LiveMatchRow(
                            match: match,
                            isSelected: selectedMatchIds.contains(match.id),
                            onTap: { onSelectMatch(match) },
                            hasReminder: reminderMatchIds.contains(match.id),
                            onToggleReminder: onToggleReminder.map { toggle in { toggle(match) } }
                        )
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

struct LiveMatchRow: View {
    let match: Match
    let isSelected: Bool
    let onTap: () -> Void
    var hasReminder: Bool = false
    var onToggleReminder: (() -> Void)? = nil

    @Environment(\.colorScheme) var colorScheme

    /// A reminder only makes sense for a match that hasn't started yet.
    private var canRemind: Bool {
        onToggleReminder != nil
            && match.startTime > Date()
            && (match.status == .upcoming)
    }

    var body: some View {
        // Plain tap gesture (not an outer Button) so the bell Button below keeps
        // its own independent hit target.
        rowContent
            .contentShape(Rectangle())
            .onTapGesture { onTap() }
    }

    private var rowContent: some View {
        HStack(spacing: 12) {
            homeTeamLabel
            statusLabel
            awayTeamLabel
            if canRemind {
                reminderBell
            }
            selectionIndicator
        }
        .padding(14)
        .background(rowBackground)
    }

    private var reminderBell: some View {
        Button(action: { onToggleReminder?() }) {
            Image(systemName: hasReminder ? "bell.fill" : "bell")
                .font(.system(size: 18))
                .foregroundColor(hasReminder
                    ? AppDesignSystem.Colors.grassGreen
                    : AppDesignSystem.Colors.secondaryText.opacity(0.5))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var homeTeamLabel: some View {
        Text(match.homeTeam.shortName)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(AppDesignSystem.Colors.primaryText)
            .frame(maxWidth: .infinity)
    }
    
    private var awayTeamLabel: some View {
        Text(match.awayTeam.shortName)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(AppDesignSystem.Colors.primaryText)
            .frame(maxWidth: .infinity)
    }
    
    private var statusLabel: some View {
        VStack(spacing: 2) {
            if match.status == .inProgress {
                Circle()
                    .fill(AppDesignSystem.Colors.error)
                    .frame(width: 8, height: 8)
                Text("LIVE")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.error)
            } else if match.status == .completed || match.status == .finished {
                Text("\(match.homeScore) - \(match.awayScore)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                Text("FT")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            } else {
                Text(formattedTime)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
    
    private var selectionIndicator: some View {
        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
            .font(.system(size: 22))
            .foregroundColor(isSelected ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.4))
    }
    
    private var rowBackground: some View {
        let fillColor = isSelected
            ? AppDesignSystem.Colors.grassGreen.opacity(0.08)
            : (colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
        let strokeColor = isSelected ? AppDesignSystem.Colors.grassGreen.opacity(0.4) : Color.clear
        
        return RoundedRectangle(cornerRadius: 10)
            .fill(fillColor)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(strokeColor, lineWidth: 1.5)
            )
    }
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(match.startTime) {
            formatter.timeStyle = .short
        } else {
            // Day-aware so a week of fixtures is legible, e.g. "Sat 16:00".
            formatter.setLocalizedDateFormatFromTemplate("EEE HH:mm")
        }
        return formatter.string(from: match.startTime)
    }
}

struct LiveTeamPlayersSection: View {
    let team: Team
    let players: [Player]
    let selectedIds: Set<UUID>
    let startingXIIds: Set<UUID>
    let onTogglePlayer: (Player) -> Void
    let onSelectTeam: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded = true
    
    private var startingXI: [Player] {
        players.filter { startingXIIds.contains($0.id) }.sorted { $0.name < $1.name }
    }
    
    private var reserves: [Player] {
        players.filter { !startingXIIds.contains($0.id) }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Team header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppDesignSystem.TeamColors.getColor(for: team))
                        .frame(width: 4, height: 24)
                    
                    Text(team.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    let selectedCount = startingXI.filter { selectedIds.contains($0.id) }.count
                    Text("\(selectedCount)/\(startingXI.count)")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    Button(action: onSelectTeam) {
                        Text("Select All")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.grassGreen)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Players
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    // Starting XI section
                    if !startingXI.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Starting XI")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(AppDesignSystem.Colors.grassGreen)
                                .textCase(.uppercase)
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                                ForEach(startingXI) { player in
                                    LivePlayerChip(
                                        player: player,
                                        isSelected: selectedIds.contains(player.id),
                                        isReserve: false,
                                        onTap: { onTogglePlayer(player) }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Reserves section
                    if !reserves.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Text("Reserves")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    .textCase(.uppercase)
                                
                                Text("(available if subbed on)")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.7))
                            }
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                                ForEach(reserves) { player in
                                    LivePlayerChip(
                                        player: player,
                                        isSelected: false,
                                        isReserve: true,
                                        onTap: { } // No action for reserves
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
        )
    }
}

struct LivePlayerChip: View {
    let player: Player
    let isSelected: Bool
    var isReserve: Bool = false
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(AppDesignSystem.TeamColors.getColor(for: player.team).opacity(isReserve ? 0.4 : 1.0))
                    .frame(width: 3, height: 20)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(player.name)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(isReserve ? AppDesignSystem.Colors.secondaryText.opacity(0.6) : AppDesignSystem.Colors.primaryText)
                        .lineLimit(1)
                    Text(player.position.rawValue)
                        .font(.system(size: 10))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(isReserve ? 0.5 : 1.0))
                }
                
                Spacer(minLength: 4)
                
                if isReserve {
                    // Show "SUB" badge for reserves
                    Text("SUB")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                        )
                } else {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.4))
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isReserve
                        ? (colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.02))
                        : (isSelected ? AppDesignSystem.Colors.grassGreen.opacity(0.08) : colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected && !isReserve ? AppDesignSystem.Colors.grassGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
            .opacity(isReserve ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isReserve)
    }
}

struct LiveSummaryCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}


// MARK: - Data Structures

struct LeagueGroup {
    let league: String
    let name: String
    let matches: [Match]
}

struct TeamPlayersData {
    let team: Team
    let players: [Player]
}
