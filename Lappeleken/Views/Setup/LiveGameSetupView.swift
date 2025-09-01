//
//  LiveGameSetupView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import SwiftUI
import Network

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
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var isConnected = true
    @State private var showingRateLimit = false
    @State private var nextUpdateTime = 90
    @State private var showingLineupChoiceAlert = false
    @State private var pendingMatchId: String?
    @State private var pendingMatchName: String?
    @State private var expandedLeagues = Set<String>()

    private let steps = ["Matches", "Participants", "Set Bets", "Select Players", "Review"]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !networkMonitor.isConnected {
                    connectionStatusBar
                }
                
                if showingRateLimit {
                    RateLimitWarning()
                        .padding(.horizontal)
                        .transition(.slide)
                }
                
                progressIndicator
                
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
        .alert("Lineup Not Available", isPresented: $showingLineupChoiceAlert) {
            Button("Use Full Squad") {
                if let matchId = pendingMatchId {
                    loadFullSquadForMatch(matchId)
                }
                clearPendingMatch()
            }
            
            Button("Go Back") {
                clearPendingMatch()
            }
            
            Button("Cancel", role: .cancel) {
                clearPendingMatch()
            }
        } message: {
            Text("Lineups are not available yet for \(pendingMatchName ?? "this match"). Lineups are usually not available until 1-2 hours before match start.\n\nWould you like to use the full squad instead, or go back and try again later?")
        }
    }
    
    // MARK: - Helper Methods
    
    private func clearPendingMatch() {
        pendingMatchId = nil
        pendingMatchName = nil
    }
    
    private func setupInitialState() {
        // Clear any existing state when entering live mode setup
        gameSession.availablePlayers = []
        gameSession.selectedPlayers = []
        selectedPlayerIds = Set<UUID>()
        
        // Load available matches when the view appears
        loadMatches()
        
        // Initialize bet amounts and negative flags
        if betAmounts.isEmpty {
            initializeBetAmounts()
        }
    }
    
    private func initializeBetAmounts() {
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
    
    // MARK: - UI Components
    
    private var connectionStatusBar: some View {
        HStack {
            LiveConnectionStatus(isConnected: networkMonitor.isConnected)
            
            Spacer()
            
            if networkMonitor.isConnected && currentStep == 0 {
                NextUpdateTimer()
            }
        }
        .padding()
        .background(networkMonitor.isConnected ? AppDesignSystem.Colors.success.opacity(0.1) : AppDesignSystem.Colors.error.opacity(0.1))
    }
    
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
            
            // Step title and description
            Text(currentStep < steps.count ? steps[currentStep] : "Setup")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
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
    
    // MARK: - Step Content Views
    
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
    
    // MARK: - Match Selection View
    
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
            ForEach(leagueGroups, id: \.league) { leagueGroup in
                leagueDropdownSection(leagueGroup)
            }
        }
    }
    
    private var matchesByLeague: [String: [Match]] {
        Dictionary(grouping: gameSession.availableMatches) { match in
            match.competition.code
        }
    }

    private var leagueOrder: [String] {
        ["TIP", "WC", "CL", "BL1", "DED", "BSA", "PD", "FL1", "ELC", "PPL", "EC", "SA", "PL"]
    }

    private var sortedLeagueCodes: [String] {
        matchesByLeague.keys.sorted { league1, league2 in
            let index1 = leagueOrder.firstIndex(of: league1) ?? leagueOrder.count
            let index2 = leagueOrder.firstIndex(of: league2) ?? leagueOrder.count
            return index1 < index2
        }
    }

    private var leagueGroups: [LeagueGroup] {
        sortedLeagueCodes.compactMap { leagueCode in
            guard let leagueMatches = matchesByLeague[leagueCode] else { return nil }
            return LeagueGroup(
                league: leagueCode,
                name: leagueMatches.first?.competition.name ?? leagueCode,
                matches: leagueMatches
            )
        }
    }
    
    private func leagueDropdownSection(_ leagueGroup: LeagueGroup) -> some View {
        VStack(spacing: 0) {
            // Clickable header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    if expandedLeagues.contains(leagueGroup.league) {
                        expandedLeagues.remove(leagueGroup.league)
                    } else {
                        expandedLeagues.insert(leagueGroup.league)
                    }
                }
            }) {
                leagueDropdownHeader(leagueGroup)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if expandedLeagues.contains(leagueGroup.league) {
                VStack(spacing: 8) {
                    ForEach(dateGroups(for: leagueGroup.matches), id: \.date) { dateGroup in
                        dateSection(dateGroup, showDateHeader: dateGroups(for: leagueGroup.matches).count > 1)
                    }
                }
                .padding(.top, 8)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity.combined(with: .move(edge: .top))
                ))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: AppDesignSystem.Colors.primary.opacity(0.1),
                    radius: expandedLeagues.contains(leagueGroup.league) ? 8 : 4,
                    x: 0,
                    y: 2
                )
        )
        .padding(.vertical, 4)
    }

    private func leagueDropdownHeader(_ leagueGroup: LeagueGroup) -> some View {
        HStack {
            // League info
            VStack(alignment: .leading, spacing: 4) {
                Text(leagueGroup.name)
                    .font(AppDesignSystem.Typography.subheadingFont.bold())
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("\(leagueGroup.matches.count) match\(leagueGroup.matches.count == 1 ? "" : "es")")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Selected matches indicator
            let selectedCount = leagueGroup.matches.filter { match in
                selectedMatchIds.contains(match.id)
            }.count
            
            if selectedCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppDesignSystem.Colors.success)
                        .font(.system(size: 14))
                    
                    Text("\(selectedCount)")
                        .font(AppDesignSystem.Typography.captionFont.bold())
                        .foregroundColor(AppDesignSystem.Colors.success)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(AppDesignSystem.Colors.success.opacity(0.1))
                )
            }
            
            // Dropdown arrow
            Image(systemName: expandedLeagues.contains(leagueGroup.league) ? "chevron.up" : "chevron.down")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .rotationEffect(.degrees(expandedLeagues.contains(leagueGroup.league) ? 0 : 0))
                .animation(.easeInOut(duration: 0.2), value: expandedLeagues.contains(leagueGroup.league))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle()) // Makes entire area tappable
    }

    private func dateSection(_ dateGroup: DateGroup, showDateHeader: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if showDateHeader {
                Text(formatDate(dateGroup.date))
                    .font(AppDesignSystem.Typography.captionFont.bold())
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .padding(.leading, 16)
                    .padding(.top, 4)
            }
            
            ForEach(dateGroup.matches, id: \.id) { match in
                MatchSelectionCard(
                    match: match,
                    isSelected: selectedMatchIds.contains(match.id),
                    onToggle: {
                        toggleMatchSelection(match)
                    }
                )
                .padding(.horizontal, 8)
            }
        }
        .padding(.bottom, 8)
    }
    
    // Helper functions for matches
    private func dateGroups(for matches: [Match]) -> [DateGroup] {
        let matchesByDate = Dictionary(grouping: matches) { match in
            Calendar.current.startOfDay(for: match.startTime)
        }
        
        return matchesByDate.keys.sorted().map { date in
            let sortedMatches = matchesByDate[date]?.sorted { $0.startTime < $1.startTime } ?? []
            return DateGroup(date: date, matches: sortedMatches)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE" // Day of week
            return formatter.string(from: date)
        } else {
            formatter.dateStyle = .medium
            formatter.timeStyle = .none
            return formatter.string(from: date)
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
    
    // MARK: - Participants Setup View
    
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
                                .fill(AppDesignSystem.Colors.cardBackground)
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
    
    // MARK: - Set Bets View
    
    private var setBetsView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            HStack {
                Text("Set Betting Amounts")
                    .font(AppDesignSystem.Typography.headingFont)
                
                Spacer()
            }
            
            Text("Set how much participants will pay for each event type.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("Toggle +/- to change who pays whom.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.primary)
                .padding(.bottom)
            
            // Info about live mode limitations
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppDesignSystem.Colors.info)
                    
                    Text("Live Mode Events")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.info)
                }
                
                Text("In live mode, only standard football events from the API are available. Custom events are not supported as they cannot be automatically detected.")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding(12)
            .background(AppDesignSystem.Colors.info.opacity(0.1))
            .cornerRadius(8)
            .padding(.bottom)
            
            // Standard event types only (no custom events in live mode)
            ForEach(Bet.EventType.allCases.filter { $0 != .custom }, id: \.self) { eventType in
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
    
    // MARK: - Players Selection View
    
    private var playersSelectionView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            // Header with select all controls
            HStack {
                Text("Select Starting XI Players")
                    .font(AppDesignSystem.Typography.headingFont)
                
                Spacer()
                
                // Select All Controls
                HStack(spacing: 12) {
                    Button(action: {
                        selectAllStartingXIPlayers()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppDesignSystem.Colors.success)
                            Text("Select All")
                                .font(AppDesignSystem.Typography.captionFont)
                        }
                    }
                    .disabled(getStartingXIPlayers().isEmpty)
                    
                    Button(action: {
                        deselectAllPlayers()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(AppDesignSystem.Colors.error)
                            Text("Clear All")
                                .font(AppDesignSystem.Typography.captionFont)
                        }
                    }
                    .disabled(selectedPlayerIds.isEmpty)
                }
            }
            
            // Live mode explanation
            Text("Only starting XI players are assigned to participants. Substitutes will automatically replace them if substitutions occur during the match.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            // Selection summary
            if !gameSession.availablePlayers.isEmpty {
                HStack {
                    let startingXIPlayers = getStartingXIPlayers()
                    let substitutePlayers = getSubstitutePlayers()
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(selectedPlayerIds.count) of \(startingXIPlayers.count) starting XI selected")
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        if substitutePlayers.count > 0 {
                            Text("+ \(substitutePlayers.count) substitutes will be added automatically")
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(AppDesignSystem.Colors.info)
                        }
                    }
                    
                    Spacer()
                }
            }
            
            if selectedPlayerIds.isEmpty {
                Text("Select at least one starting XI player to continue")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(.top, 4)
            }
            
            // Players list organized by Starting XI and Substitutes
            if gameSession.availablePlayers.isEmpty {
                emptyPlayersView
            } else {
                organizedPlayersListView
            }
        }
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
    
    private var organizedPlayersListView: some View {
        let startingXIPlayers = getStartingXIPlayers()
        let substitutePlayers = getSubstitutePlayers()
        
        return VStack(spacing: 16) {
            if gameSession.matchLineups.isEmpty {
                // No lineup data - show all players as selectable
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(AppDesignSystem.Colors.info)
                        
                        Text("Full Squad Mode")
                            .font(AppDesignSystem.Typography.headingFont)
                            .foregroundColor(AppDesignSystem.Colors.info)
                    }
                    
                    Text("Official lineup not available. Select players from the full squad. All selected players will be treated as starting XI.")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .padding(.bottom, 8)
                    
                    let allPlayersByTeam = getPlayersByTeam(startingXIPlayers)
                    ForEach(allPlayersByTeam, id: \.team.id) { teamData in
                        FullSquadTeamSection(
                            team: teamData.team,
                            players: teamData.players,
                            selectedPlayerIds: $selectedPlayerIds,
                            onSelectTeam: { selectTeamPlayers(teamId: teamData.team.id) },
                            onTogglePlayer: { player in togglePlayerSelection(player) }
                        )
                    }
                }
            } else {
                // Normal lineup data available
                if !startingXIPlayers.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Starting XI Players")
                            .font(AppDesignSystem.Typography.headingFont)
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        let startingXIByTeam = getPlayersByTeam(startingXIPlayers)
                        ForEach(startingXIByTeam, id: \.team.id) { teamData in
                            StartingXITeamSection(
                                team: teamData.team,
                                players: teamData.players,
                                selectedPlayerIds: $selectedPlayerIds,
                                onSelectTeam: { selectTeamStartingXIPlayers(teamId: teamData.team.id) },
                                onTogglePlayer: { player in togglePlayerSelection(player) }
                            )
                        }
                    }
                }
                
                if !startingXIPlayers.isEmpty && !substitutePlayers.isEmpty {
                    Divider().padding(.vertical, 8)
                }
                
                if !substitutePlayers.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Substitutes")
                            .font(AppDesignSystem.Typography.headingFont)
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("These players will automatically replace starting XI players if substitutions occur during the match.")
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .padding(.bottom, 8)
                        
                        let substitutesByTeam = getPlayersByTeam(substitutePlayers)
                        ForEach(substitutesByTeam, id: \.team.id) { teamData in
                            SubstituteTeamSection(
                                team: teamData.team,
                                players: teamData.players
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Review View
    
    private var reviewView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            Text("Review Game Setup")
                .font(AppDesignSystem.Typography.headingFont)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("Review your game configuration before starting:")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            reviewMatchesCard
            reviewParticipantsCard
            reviewPlayersCard
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
                
                ForEach(Bet.EventType.allCases.filter { $0 != .custom }, id: \.self) { eventType in
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
    
    // MARK: - Data Loading Methods
    
    private func loadMatches() {
        isLoading = true
        error = nil
        
        Task {
            do {
                if AppConfig.useNewDataManager {
                    // NEW: Use centralized DataManager
                    let matches = try await DataManager.shared.fetchMatches(mode: .live)
                    
                    await MainActor.run {
                        gameSession.availableMatches = matches
                        isLoading = false
                        print("✨ Used NEW DataManager: loaded \(matches.count) matches")
                    }
                } else {
                    // OLD: Use existing GameSession method
                    try await gameSession.fetchAvailableMatches()
                    
                    await MainActor.run {
                        isLoading = false
                        print("🔧 Used OLD system: loaded \(gameSession.availableMatches.count) matches")
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
    
    private func loadPlayersForSelectedMatches() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let matchIdsToLoad = AppConfig.canSelectMultipleMatches
                    ? Array(self.selectedMatchIds)
                    : [self.selectedMatchIds.first!]
                
                await MainActor.run {
                    gameSession.availablePlayers = []
                }
                
                var allPlayers: [Player] = []
                var lineupFailures: [Match] = []
                
                print("🔄 Loading players for \(matchIdsToLoad.count) matches...")
                
                // Process matches sequentially to respect rate limits
                for (index, matchId) in matchIdsToLoad.enumerated() {
                    if let match = gameSession.availableMatches.first(where: { $0.id == matchId }) {
                        do {
                            print("📥 Loading players for match \(index + 1)/\(matchIdsToLoad.count): \(match.homeTeam.name) vs \(match.awayTeam.name)")
                            
                            var players: [Player] = []
                            
                            // Step 1: Try to fetch lineup data first
                            do {
                                print("📋 Attempting to fetch lineup for match \(matchId)")
                                try await gameSession.fetchMatchLineup(for: matchId)
                                
                                // If lineup fetch succeeds, extract players from the lineup
                                if let lineup = gameSession.matchLineups[matchId] {
                                    players = extractPlayersFromLineup(lineup)
                                    print("✅ Successfully loaded lineup: \(players.count) players")
                                }
                                
                            } catch {
                                print("⚠️ Lineup fetch failed: \(error)")
                                
                                // Step 2: Check if it's a lineup not available error and fallback to squad
                                if error.isLineupNotAvailable {
                                    print("📦 Lineup not available yet, falling back to full squad...")
                                    
                                    if let footballService = gameSession.matchService as? FootballDataMatchService {
                                        players = try await footballService.fetchMatchSquad(matchId: matchId)
                                        print("✅ Loaded full squad: \(players.count) players")
                                    } else {
                                        // Ultimate fallback: use fetchMatchPlayersRobust
                                        players = try await gameSession.fetchMatchPlayers(for: matchId) ?? []
                                        print("✅ Loaded players via robust method: \(players.count) players")
                                    }
                                    
                                    lineupFailures.append(match)
                                } else {
                                    // For other errors, try squad fallback too
                                    print("📦 Other error, trying squad fallback: \(error)")
                                    if let footballService = gameSession.matchService as? FootballDataMatchService {
                                        do {
                                            players = try await footballService.fetchMatchSquad(matchId: matchId)
                                            print("✅ Loaded squad after error: \(players.count) players")
                                            lineupFailures.append(match)
                                        } catch {
                                            print("❌ Squad fallback also failed: \(error)")
                                            throw error
                                        }
                                    } else {
                                        throw error
                                    }
                                }
                            }
                            
                            // Check if we got real players or dummy/placeholder players
                            let hasDummyPlayers = players.isEmpty || players.contains(where: {
                                $0.name.contains("Player ") || $0.name.contains("Dummy")
                            })
                            
                            if hasDummyPlayers {
                                print("⚠️ Got placeholder players for \(match.homeTeam.name) vs \(match.awayTeam.name)")
                                if !lineupFailures.contains(where: { $0.id == match.id }) {
                                    lineupFailures.append(match)
                                }
                            } else {
                                print("✅ Got \(players.count) real players for \(match.homeTeam.name) vs \(match.awayTeam.name)")
                            }
                            
                            allPlayers.append(contentsOf: players)
                            
                            // Track usage for free users
                            if AppPurchaseManager.shared.currentTier == .free {
                                AppConfig.incrementMatchUsage()
                            }
                            
                            // Rate limiting: Add delay between matches (except for the last one)
                            if index < matchIdsToLoad.count - 1 {
                                print("⏳ Waiting 2 seconds before next match to respect API limits...")
                                try await Task.sleep(nanoseconds: 2_000_000_000)
                            }
                            
                        } catch {
                            print("❌ Error loading players for match \(matchId): \(error)")
                            lineupFailures.append(match)
                            
                            // Continue processing other matches even if one fails
                            continue
                        }
                    }
                }
                
                await MainActor.run {
                    isLoading = false
                    gameSession.availablePlayers = allPlayers
                    
                    if !allPlayers.isEmpty {
                        print("✅ Successfully loaded \(allPlayers.count) total players")
                        
                        if !lineupFailures.isEmpty {
                            print("⚠️ \(lineupFailures.count) matches had lineup issues")
                            showLineupChoiceAlert(matches: lineupFailures)
                        } else {
                            // All lineups loaded successfully, proceed to next step
                            currentStep += 1
                        }
                    } else {
                        error = "No players found for the selected match(es). This might be because team lineups haven't been announced yet, or there's an issue with the football data service. Please try again later."
                    }
                    
                    gameSession.objectWillChange.send()
                }
                
            } catch {
                await MainActor.run {
                    isLoading = false
                    
                    if let dataError = error as? DataError {
                        switch dataError {
                        case .rateLimited(let retryAfter):
                            showingRateLimit = true
                            self.error = "Too many requests to the football API. Please wait \(Int(retryAfter)) seconds and try again."
                        case .networkUnavailable:
                            self.error = "Network connection issue. Please check your internet and try again."
                        case .fetchFailed(let resource, _):
                            self.error = "Failed to load \(resource). Please try again later."
                        default:
                            self.error = dataError.localizedDescription
                        }
                    } else if let apiError = error as? APIError {
                        switch apiError {
                        case .rateLimited:
                            showingRateLimit = true
                            self.error = "Too many requests to the football API. Please wait a moment and try again."
                        case .networkError:
                            self.error = "Network connection issue. Please check your internet and try again."
                        case .serverError(let code, _):
                            if code >= 500 {
                                self.error = "The football data service is temporarily unavailable. Please try again later."
                            } else if code == 429 {
                                showingRateLimit = true
                                self.error = "API rate limit exceeded. Please wait before trying again."
                            } else {
                                self.error = "There was a problem loading player data. Please try again."
                            }
                        default:
                            self.error = "Error loading players: \(error.localizedDescription)"
                        }
                    } else {
                        self.error = "Error loading players: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    private func showLineupChoiceAlert(matches: [Match]) {
        if matches.count == 1 {
            let match = matches[0]
            pendingMatchId = match.id
            pendingMatchName = "\(match.homeTeam.name) vs \(match.awayTeam.name)"
        } else {
            let matchNames = matches.map { "\($0.homeTeam.name) vs \($0.awayTeam.name)" }.joined(separator: ", ")
            pendingMatchName = matchNames
        }
        
        showingLineupChoiceAlert = true
    }
    
    private func extractPlayersFromLineup(_ lineup: Lineup) -> [Player] {
        var players: [Player] = []
        
        // Extract home team players
        players.append(contentsOf: lineup.homeTeam.startingXI)
        players.append(contentsOf: lineup.homeTeam.substitutes)
        
        // Extract away team players
        players.append(contentsOf: lineup.awayTeam.startingXI)
        players.append(contentsOf: lineup.awayTeam.substitutes)
        
        return players
    }
    
    private func loadFullSquadForMatch(_ matchId: String) {
        isLoading = true
        
        Task {
            do {
                if let footballService = gameSession.matchService as? FootballDataMatchService {
                    // Use fetchMatchSquad, not fetchTeamSquad
                    let squadPlayers = try await footballService.fetchMatchSquad(matchId: matchId)
                    
                    await MainActor.run {
                        self.isLoading = false
                        gameSession.availablePlayers = squadPlayers
                        
                        print("✅ Loaded full squad: \(squadPlayers.count) players")
                        
                        if self.currentStep < self.steps.count - 1 {
                            self.currentStep += 1
                        }
                        
                        gameSession.objectWillChange.send()
                    }
                } else {
                    throw NSError(domain: "SquadError", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Match service not available"
                    ])
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.error = "Error loading squad: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - Validation and Navigation
    
    private func validateAndProceed() {
        error = nil
        
        switch currentStep {
        case 0: // Match selection
            guard !selectedMatchIds.isEmpty else {
                error = "Please select at least one match to continue."
                return
            }
            
            gameSession.availablePlayers = []
            gameSession.selectedPlayers = []
            selectedPlayerIds = Set<UUID>()
            
            loadPlayersForSelectedMatches()
            return
            
        case 1: // Participants
            let trimmedName = participantName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                if !gameSession.participants.contains(where: { $0.name == trimmedName }) {
                    gameSession.addParticipant(trimmedName)
                    participantName = ""
                    print("✅ Auto-added participant: \(trimmedName)")
                }
            }
            
            guard !gameSession.participants.isEmpty else {
                error = "Please add at least one participant to continue."
                return
            }
            
        case 2: // Bets
            break // Always valid
            
        case 3: // Player selection
            guard !selectedPlayerIds.isEmpty else {
                error = "Please select at least one starting XI player to continue."
                return
            }
            
            let startingXIPlayers = getStartingXIPlayers()
            let selectedStartingXI = startingXIPlayers.filter { selectedPlayerIds.contains($0.id) }
            let substitutePlayers = getSubstitutePlayers()
            let allPlayersToAdd = selectedStartingXI + substitutePlayers
            
            // Remove duplicates
            var uniquePlayersToAdd: [Player] = []
            var seenIds: Set<UUID> = []

            for player in allPlayersToAdd {
                if !seenIds.contains(player.id) {
                    uniquePlayersToAdd.append(player)
                    seenIds.insert(player.id)
                }
            }
            
            for player in uniquePlayersToAdd {
                if !gameSession.availablePlayers.contains(where: { $0.id == player.id }) {
                    gameSession.availablePlayers.append(player)
                }
            }
            
            gameSession.selectedPlayers = selectedStartingXI
            print("✅ Added \(selectedStartingXI.count) starting XI players and \(substitutePlayers.count) substitutes")
            
        case 4: // Review (final step)
            startGame()
            return
            
        default:
            print("⚠️ Unhandled step: \(currentStep)")
            return
        }
        
        let nextStep = currentStep + 1
        guard nextStep < steps.count else {
            startGame()
            return
        }
        
        currentStep = nextStep
    }
    
    // MARK: - Game Management
    
    private func startGame() {
        Task {
            do {
                // Add bets to game session
                gameSession.bets = []
                for (eventType, amount) in betAmounts {
                    gameSession.addBet(eventType: eventType, amount: amount)
                }
                
                // 🔥 CRUCIAL: Set live mode flag
                gameSession.isLiveMode = true
                
                // 🔥 NEW: Store ALL selected matches, not just the first one
                let selectedMatches = gameSession.availableMatches.filter { selectedMatchIds.contains($0.id) }
                gameSession.selectedMatches = selectedMatches  
                
                // 🔥 CRUCIAL: Set the primary selected match (for backwards compatibility)
                if let firstSelectedMatchId = selectedMatchIds.first {
                    gameSession.selectedMatch = gameSession.availableMatches.first { $0.id == firstSelectedMatchId }
                }
                
                // Assign players using GameLogicManager
                if AppConfig.useNewGameLogicManager {
                    GameLogicManager.shared.assignPlayersRandomly(in: gameSession)
                    print("✨ Used NEW GameLogicManager for player assignment")
                } else {
                    gameSession.assignPlayersRandomly()
                    print("🔧 Used OLD system for player assignment")
                }
                
                // Save game using DataManager
                if AppConfig.useNewDataManager {
                    let gameName = generateGameName()
                    try await DataManager.shared.saveGame(gameSession, name: gameName)
                    print("✨ Used NEW DataManager for game saving")
                }
                
                await MainActor.run {
                    // Close the setup view
                    presentationMode.wrappedValue.dismiss()
                    
                    // 🔥 CRUCIAL: Start event-driven monitoring for ALL matches AFTER the view is dismissed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        Task { @MainActor in
                            gameSession.startRealEventDrivenModeForAllMatches()
                        }
                    }
                    
                    // Notify that game should start
                    NotificationCenter.default.post(name: Notification.Name("StartGameWithSelectedMatch"), object: nil)
                }
                
            } catch {
                print("❌ Error starting live game: \(error)")
                await MainActor.run {
                    self.error = "Failed to start game: \(error.localizedDescription)"
                }
            }
        }
    }

    private func generateGameName() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, HH:mm"
        
        if selectedMatchIds.count == 1,
           let selectedMatch = gameSession.availableMatches.first(where: { selectedMatchIds.contains($0.id) }) {
            return "\(selectedMatch.homeTeam.shortName) vs \(selectedMatch.awayTeam.shortName) - \(formatter.string(from: Date()))"
        } else if selectedMatchIds.count > 1 {
            return "Multi-Match Game - \(formatter.string(from: Date()))"
        } else {
            return "Live Game - \(formatter.string(from: Date()))"
        }
    }
    // MARK: - Helper Methods
    
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
    
    private func getStartingXIPlayers() -> [Player] {
        if !gameSession.matchLineups.isEmpty {
            return gameSession.availablePlayers.filter { player in
                for lineup in gameSession.matchLineups.values {
                    if lineup.homeTeam.startingXI.contains(where: { $0.id == player.id }) ||
                       lineup.awayTeam.startingXI.contains(where: { $0.id == player.id }) {
                        return true
                    }
                }
                return false
            }
        } else {
            print("🔍 No lineup data available, treating all players as selectable")
            return gameSession.availablePlayers
        }
    }

    private func getSubstitutePlayers() -> [Player] {
        if !gameSession.matchLineups.isEmpty {
            return gameSession.availablePlayers.filter { player in
                for lineup in gameSession.matchLineups.values {
                    if lineup.homeTeam.substitutes.contains(where: { $0.id == player.id }) ||
                       lineup.awayTeam.substitutes.contains(where: { $0.id == player.id }) {
                        return true
                    }
                }
                return false
            }
        } else {
            print("🔍 No lineup data available, no substitutes to show")
            return []
        }
    }

    private func selectAllStartingXIPlayers() {
        let startingXIPlayers = getStartingXIPlayers()
        selectedPlayerIds = Set(startingXIPlayers.map { $0.id })
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        error = nil
    }

    private func selectTeamStartingXIPlayers(teamId: UUID) {
        let startingXIPlayers = getStartingXIPlayers()
        let teamStartingXIPlayerIds = startingXIPlayers
            .filter { $0.team.id == teamId }
            .map { $0.id }
        
        selectedPlayerIds.formUnion(teamStartingXIPlayerIds)
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        error = nil
    }

    private func deselectAllPlayers() {
        selectedPlayerIds.removeAll()
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func selectTeamPlayers(teamId: UUID) {
        let teamPlayerIds = gameSession.availablePlayers
            .filter { $0.team.id == teamId }
            .map { $0.id }
        
        selectedPlayerIds.formUnion(teamPlayerIds)
        
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        error = nil
    }

    private func togglePlayerSelection(_ player: Player) {
        if selectedPlayerIds.contains(player.id) {
            selectedPlayerIds.remove(player.id)
        } else {
            selectedPlayerIds.insert(player.id)
        }
        
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        if !selectedPlayerIds.isEmpty {
            error = nil
        }
    }
    
    private func getPlayersByTeam(_ players: [Player]) -> [TeamPlayersData] {
        let groupedDict = Dictionary(grouping: players, by: { $0.team })
        
        return groupedDict.map { (team, players) in
            TeamPlayersData(team: team, players: players)
        }.sorted { $0.team.name < $1.team.name }
    }
    
    private func showPlayerUnavailableWarning(matches: [Match]) {
        guard !isPresentingAlert else { return }
        
        isPresentingAlert = true
        
        if matches.count == 1 {
            let match = matches[0]
            unavailableMatchesMessage = "The official lineup for \(match.homeTeam.name) vs \(match.awayTeam.name) is not available yet..."
        } else {
            let matchNames = matches.map { "\($0.homeTeam.name) vs \($0.awayTeam.name)" }.joined(separator: ", ")
            unavailableMatchesMessage = "The official lineups for \(matchNames) are not available yet..."
        }
        
        temporaryStep = min(currentStep + 1, steps.count - 1)
        showingPlayerUnavailableAlert = true
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
    
    // MARK: - Error Handling
    
    private func handleDataError(_ error: Error) -> String {
        if let dataError = error as? DataError {
            switch dataError {
            case .rateLimited(let retryAfter):
                showingRateLimit = true
                return "Too many requests. Please wait \(Int(retryAfter)) seconds and try again."
            case .networkUnavailable:
                return "No internet connection. Please check your network and try again."
            case .fetchFailed(let resource, let underlying):
                if let apiError = underlying as? APIError {
                    return handleAPIError(apiError, resource: resource)
                }
                return "Failed to load \(resource). Please try again."
            case .invalidData(let message):
                return "Invalid data received: \(message)"
            default:
                return dataError.localizedDescription
            }
        } else if let apiError = error as? APIError {
            return handleAPIError(apiError)
        } else {
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }

    private func handleAPIError(_ apiError: APIError, resource: String = "data") -> String {
        switch apiError {
        case .rateLimited:
            showingRateLimit = true
            return "Too many requests to the football API. Please wait a moment and try again."
        case .networkError:
            return "Network connection issue. Please check your internet and try again."
        case .serverError(let code, _):
            if code >= 500 {
                return "The football data service is temporarily unavailable. Please try again later."
            } else if code == 429 {
                showingRateLimit = true
                return "API rate limit exceeded. Please wait before trying again."
            } else {
                return "There was a problem loading \(resource). Please try again."
            }
        case .decodingError:
            return "Received invalid data from the service. Please try again."
        case .invalidURL:
            return "Configuration error. Please restart the app."
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}

// MARK: - Supporting Data Structures

struct LeagueGroup {
    let league: String
    let name: String
    let matches: [Match]
}

struct DateGroup {
    let date: Date
    let matches: [Match]
}

struct TeamPlayersData {
    let team: Team
    let players: [Player]
}

// MARK: - Supporting Components

struct EnhancedParticipantCard: View {
    let participant: Participant
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 12) {
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
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

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
        case .finished:
            return ("Finished", AppDesignSystem.Colors.accent)
        case .postponed:
            return ("Postponed", AppDesignSystem.Colors.error)
        case .cancelled:
            return ("Cancelled", AppDesignSystem.Colors.error)
        case .paused:
            return ("Paused", AppDesignSystem.Colors.warning)
        case .suspended:
            return ("Suspended", AppDesignSystem.Colors.warning)
        }
    }
}

struct FullSquadTeamSection: View {
    let team: Team
    let players: [Player]
    @Binding var selectedPlayerIds: Set<UUID>
    let onSelectTeam: () -> Void
    let onTogglePlayer: (Player) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(AppDesignSystem.TeamColors.getColor(for: team))
                    .frame(width: 24, height: 24)
                
                Text("\(team.name) - Full Squad")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
                
                Text("(\(players.count))")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Spacer()
                
                Button(action: onSelectTeam) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppDesignSystem.Colors.primary)
                        Text("Select All")
                            .font(AppDesignSystem.Typography.captionFont)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppDesignSystem.Colors.primary.opacity(0.1))
            .cornerRadius(8)
            
            VStack(spacing: 8) {
                ForEach(players, id: \.id) { player in
                    FullSquadPlayerCard(
                        player: player,
                        isSelected: selectedPlayerIds.contains(player.id),
                        onToggleSelection: { onTogglePlayer(player) }
                    )
                }
            }
        }
    }
}

struct FullSquadPlayerCard: View {
    let player: Player
    let isSelected: Bool
    let onToggleSelection: () -> Void
    
    var body: some View {
        Button(action: onToggleSelection) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(AppDesignSystem.Typography.bodyFont)
                        .fontWeight(.medium)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(player.position.rawValue)
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "person.3.fill")
                                .font(.caption)
                                .foregroundColor(AppDesignSystem.Colors.primary)
                            Text("Squad Player")
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(AppDesignSystem.Colors.primary)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.secondaryText)
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppDesignSystem.Colors.primary.opacity(0.1) : AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.secondaryText.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StartingXITeamSection: View {
    let team: Team
    let players: [Player]
    @Binding var selectedPlayerIds: Set<UUID>
    let onSelectTeam: () -> Void
    let onTogglePlayer: (Player) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(AppDesignSystem.TeamColors.getColor(for: team))
                    .frame(width: 24, height: 24)
                
                Text("\(team.name) - Starting XI")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
                
                Text("(\(players.count))")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Spacer()
                
                Button(action: onSelectTeam) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppDesignSystem.Colors.success)
                        Text("Select All")
                            .font(AppDesignSystem.Typography.captionFont)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppDesignSystem.Colors.success.opacity(0.1))
            .cornerRadius(8)
            
            VStack(spacing: 8) {
                ForEach(players, id: \.id) { player in
                    StartingXIPlayerCard(
                        player: player,
                        isSelected: selectedPlayerIds.contains(player.id),
                        onToggleSelection: { onTogglePlayer(player) }
                    )
                }
            }
        }
    }
}

struct StartingXIPlayerCard: View {
    let player: Player
    let isSelected: Bool
    let onToggleSelection: () -> Void
    
    var body: some View {
        Button(action: onToggleSelection) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(AppDesignSystem.Typography.bodyFont)
                        .fontWeight(.medium)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    HStack {
                        Text(player.position.rawValue)
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption)
                                .foregroundColor(AppDesignSystem.Colors.success)
                            Text("Starting XI")
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(AppDesignSystem.Colors.success)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.secondaryText)
                    .font(.title3)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppDesignSystem.Colors.success.opacity(0.1) : AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.secondaryText.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SubstituteTeamSection: View {
    let team: Team
    let players: [Player]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(AppDesignSystem.TeamColors.getColor(for: team))
                    .frame(width: 24, height: 24)
                
                Text("\(team.name) - Substitutes")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
                
                Text("(\(players.count))")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(AppDesignSystem.Colors.accent)
                    Text("Auto-added")
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.accent)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(AppDesignSystem.Colors.accent.opacity(0.1))
            .cornerRadius(8)
            
            VStack(spacing: 8) {
                ForEach(players, id: \.id) { player in
                    SubstitutePlayerCard(player: player)
                }
            }
        }
    }
}

struct SubstitutePlayerCard: View {
    let player: Player
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(AppDesignSystem.Typography.bodyFont)
                    .fontWeight(.medium)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Text(player.position.rawValue)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.2.squarepath")
                            .font(.caption)
                            .foregroundColor(AppDesignSystem.Colors.accent)
                        Text("Substitute")
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.accent)
                    }
                }
            }
            
            Spacer()
            
            Image(systemName: "clock.fill")
                .foregroundColor(AppDesignSystem.Colors.accent)
                .font(.title3)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppDesignSystem.Colors.accent.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(AppDesignSystem.Colors.accent.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct RateLimitWarning: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .foregroundColor(AppDesignSystem.Colors.warning)
            Text("Rate limit reached. Updates paused temporarily.")
                .font(AppDesignSystem.Typography.captionFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(8)
        .background(AppDesignSystem.Colors.warning.opacity(0.1))
        .cornerRadius(6)
    }
}

struct LiveConnectionStatus: View {
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                .frame(width: 8, height: 8)
            
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isConnected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
        }
    }
}

struct NextUpdateTimer: View {
    @State private var timeRemaining: Int = 90
    
    var body: some View {
        Text("Next update in \(timeRemaining)s")
            .font(.system(size: 11))
            .foregroundColor(AppDesignSystem.Colors.secondaryText)
            .onAppear {
                Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    if timeRemaining > 0 {
                        timeRemaining -= 1
                    } else {
                        timeRemaining = 90 // Reset
                    }
                }
            }
    }
}
