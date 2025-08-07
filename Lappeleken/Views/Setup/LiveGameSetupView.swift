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
    
    // Helper method to clear pending match data
    private func clearPendingMatch() {
        pendingMatchId = nil
        pendingMatchName = nil
    }
    
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
    
    struct LeagueGroup {
        let league: String
        let name: String
        let matches: [Match]
    }

    struct DateGroup {
        let date: Date
        let matches: [Match]
    }

    // MARK: - Matches List view

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

    // Helper functions
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
    
    private var expandCollapseControls: some View {
        HStack(spacing: 16) {
            Button("Expand All") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    expandedLeagues = Set(leagueGroups.map { $0.league })
                }
            }
            .font(AppDesignSystem.Typography.captionFont)
            .foregroundColor(AppDesignSystem.Colors.primary)
            
            Button("Collapse All") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    expandedLeagues.removeAll()
                }
            }
            .font(AppDesignSystem.Typography.captionFont)
            .foregroundColor(AppDesignSystem.Colors.secondary)
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.bottom, 8)
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
    
    private var setBetsView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            HStack {
                Text("Set Betting Amounts")
                    .font(AppDesignSystem.Typography.headingFont)
                
                Spacer()
                
                // Don't show custom event button in live mode
                // Since live API won't track custom events
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
    
    struct CustomEventRow: View {
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
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Custom event icon
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppDesignSystem.Colors.accent)
                    
                    Text(name)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(AppDesignSystem.Colors.error)
                    }
                }
                
                HStack {
                    // Type indicator
                    HStack(spacing: 6) {
                        Image(systemName: isNegative ? "minus.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                        
                        Text(isNegative ? "Negative" : "Positive")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                    }
                    
                    Spacer()
                    
                    // Amount
                    Text("\(currencySymbol)\(String(format: "%.2f", abs(amount)))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                }
                
                // Description
                Text(eventDescription)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppDesignSystem.Colors.accent.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppDesignSystem.Colors.accent.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        
        private var eventDescription: String {
            let amountString = String(format: "%.2f", abs(amount))
            return isNegative ?
            "Players WITH this event pay \(currencySymbol)\(amountString)" :
            "Players WITHOUT this event pay \(currencySymbol)\(amountString)"
        }
    }
    
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
                    
                    // Team-specific select buttons
                    let teamGroups = Dictionary(grouping: startingXIPlayers, by: { $0.team.id })
                    
                    if teamGroups.count > 1 {
                        Menu {
                            ForEach(Array(teamGroups.keys).sorted(), id: \.self) { teamId in
                                if let teamPlayers = teamGroups[teamId], let team = teamPlayers.first?.team {
                                    Button(action: {
                                        selectTeamStartingXIPlayers(teamId: teamId)
                                    }) {
                                        HStack {
                                            Text("Select \(team.name)")
                                            Spacer()
                                            Text("(\(teamPlayers.count))")
                                        }
                                    }
                                }
                            }
                            
                            Divider()
                            
                            Button(action: {
                                deselectAllPlayers()
                            }) {
                                HStack {
                                    Image(systemName: "xmark.circle")
                                    Text("Clear All")
                                }
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "person.3.sequence.fill")
                                Text("By Team")
                                    .font(AppDesignSystem.Typography.captionFont)
                            }
                            .foregroundColor(AppDesignSystem.Colors.primary)
                        }
                    }
                }
            }
            
            // Dummy players warning (existing code)
            let hasDummyPlayers = gameSession.availablePlayers.contains { $0.name.contains("Player ") }
            if hasDummyPlayers {
                dummyPlayersWarningView
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
    
    // MARK: - Starting XI Helper Methods

    private func getStartingXIPlayers() -> [Player] {
        // First check if we have lineup data
        if !gameSession.matchLineups.isEmpty {
            return gameSession.availablePlayers.filter { player in
                // Check if this player is in starting XI based on lineup data
                for lineup in gameSession.matchLineups.values {
                    if lineup.homeTeam.startingXI.contains(where: { $0.id == player.id }) ||
                       lineup.awayTeam.startingXI.contains(where: { $0.id == player.id }) {
                        return true
                    }
                }
                return false
            }
        } else {
            // If no lineup data (using full squad), treat all players as selectable
            // You can either return all players or create a mock starting XI
            print("🔍 No lineup data available, treating all players as selectable")
            return gameSession.availablePlayers
        }
    }

    private func getSubstitutePlayers() -> [Player] {
        // First check if we have lineup data
        if !gameSession.matchLineups.isEmpty {
            return gameSession.availablePlayers.filter { player in
                // Check if this player is a substitute based on lineup data
                for lineup in gameSession.matchLineups.values {
                    if lineup.homeTeam.substitutes.contains(where: { $0.id == player.id }) ||
                       lineup.awayTeam.substitutes.contains(where: { $0.id == player.id }) {
                        return true
                    }
                }
                return false
            }
        } else {
            // If no lineup data (using full squad), return empty array
            // since we're treating all players as selectable starting XI
            print("🔍 No lineup data available, no substitutes to show")
            return []
        }
    }

    private func selectAllStartingXIPlayers() {
        let startingXIPlayers = getStartingXIPlayers()
        selectedPlayerIds = Set(startingXIPlayers.map { $0.id })
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Clear any existing error
        error = nil
    }

    private func selectTeamStartingXIPlayers(teamId: UUID) {
        let startingXIPlayers = getStartingXIPlayers()
        let teamStartingXIPlayerIds = startingXIPlayers
            .filter { $0.team.id == teamId }
            .map { $0.id }
        
        // Add team starting XI players to selection
        selectedPlayerIds.formUnion(teamStartingXIPlayerIds)
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Clear any existing error
        error = nil
    }


    // Add these helper methods to LiveGameSetupView

    private func selectAllPlayers() {
        selectedPlayerIds = Set(gameSession.availablePlayers.map { $0.id })
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Clear any existing error
        error = nil
    }

    private func deselectAllPlayers() {
        selectedPlayerIds.removeAll()
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }

    private func selectTeamPlayers(teamId: UUID) {
        let teamPlayerIds = gameSession.availablePlayers
            .filter { $0.team.id == teamId }
            .map { $0.id }
        
        // Add team players to selection (don't replace existing selection)
        selectedPlayerIds.formUnion(teamPlayerIds)
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Clear any existing error
        error = nil
    }

    // Enhanced player selection with keyboard shortcuts and better UX
    private func togglePlayerSelection(_ player: Player) {
        if selectedPlayerIds.contains(player.id) {
            selectedPlayerIds.remove(player.id)
        } else {
            selectedPlayerIds.insert(player.id)
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        // Clear error when user makes selection
        if !selectedPlayerIds.isEmpty {
            error = nil
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
    
    private var organizedPlayersListView: some View {
        let startingXIPlayers = getStartingXIPlayers()
        let substitutePlayers = getSubstitutePlayers()
        
        return VStack(spacing: 16) {
            // Check if we have lineup data
            if gameSession.matchLineups.isEmpty {
                // No lineup data - show all players as selectable with a note
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
                    
                    // Group all players by team
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
                // Starting XI Section
                if !startingXIPlayers.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Starting XI Players")
                            .font(AppDesignSystem.Typography.headingFont)
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        // Group starting XI by team
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
                
                // Divider
                if !startingXIPlayers.isEmpty && !substitutePlayers.isEmpty {
                    Divider()
                        .padding(.vertical, 8)
                }
                
                // Substitutes Section
                if !substitutePlayers.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Substitutes")
                            .font(AppDesignSystem.Typography.headingFont)
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("These players will automatically replace starting XI players if substitutions occur during the match.")
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .padding(.bottom, 8)
                        
                        // Group substitutes by team
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
    
    private struct FullSquadTeamSection: View {
        let team: Team
        let players: [Player]
        @Binding var selectedPlayerIds: Set<UUID>
        let onSelectTeam: () -> Void
        let onTogglePlayer: (Player) -> Void
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Team header
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
                
                // Players
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
    
    private struct FullSquadPlayerCard: View {
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
                            
                            // Full squad indicator
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

    // Helper method to group players by team and return sorted teams
    private func getPlayersByTeam(_ players: [Player]) -> [TeamPlayersData] {
        let groupedDict = Dictionary(grouping: players, by: { $0.team })
        
        return groupedDict.map { (team, players) in
            TeamPlayersData(team: team, players: players)
        }.sorted { $0.team.name < $1.team.name }
    }

    // Data structure for team-players pairing
    private struct TeamPlayersData {
        let team: Team
        let players: [Player]
    }

    // Starting XI Team Section Component
    private struct StartingXITeamSection: View {
        let team: Team
        let players: [Player]
        @Binding var selectedPlayerIds: Set<UUID>
        let onSelectTeam: () -> Void
        let onTogglePlayer: (Player) -> Void
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Team header
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
                
                // Players
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

    // Substitute Team Section Component
    private struct SubstituteTeamSection: View {
        let team: Team
        let players: [Player]
        
        var body: some View {
            VStack(alignment: .leading, spacing: 12) {
                // Team header
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
                
                // Players
                VStack(spacing: 8) {
                    ForEach(players, id: \.id) { player in
                        SubstitutePlayerCard(player: player)
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
        showingRateLimit = false
        
        Task {
            do {
                try await gameSession.fetchAvailableMatches()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    
                    // Enhanced error handling
                    let errorMessage = error.localizedDescription.lowercased()
                    if errorMessage.contains("network") || errorMessage.contains("connection") {
                        self.error = "No internet connection. Please check your network and try again."
                    } else if errorMessage.contains("rate") || errorMessage.contains("limit") {
                        self.showingRateLimit = true
                        self.error = "Too many requests. Please wait a moment before trying again."
                    } else if errorMessage.contains("timeout") {
                        self.error = "Request timed out. Please try again."
                    } else if errorMessage.contains("unauthorized") || errorMessage.contains("403") {
                        self.error = "Service temporarily unavailable. Please try again later."
                    } else {
                        self.error = "Unable to load matches. Please try again in a few moments."
                    }
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
                error = "Please select at least one starting XI player to continue."
                return
            }
            
            // Only add selected starting XI players to gameSession.selectedPlayers
            let startingXIPlayers = getStartingXIPlayers()
            let selectedStartingXI = startingXIPlayers.filter { selectedPlayerIds.contains($0.id) }
            
            // Add all substitutes automatically
            let substitutePlayers = getSubstitutePlayers()
            
            // Combine: selected starting XI + all substitutes
            let allPlayersToAdd = selectedStartingXI + substitutePlayers
            
            // Remove duplicates and update available players
            var uniquePlayersToAdd: [Player] = []
            var seenIds: Set<UUID> = []

            for player in allPlayersToAdd {
                if !seenIds.contains(player.id) {
                    uniquePlayersToAdd.append(player)
                    seenIds.insert(player.id)
                }
            }
            
            // Update gameSession with all players (starting XI + substitutes)
            for player in uniquePlayersToAdd {
                if !gameSession.availablePlayers.contains(where: { $0.id == player.id }) {
                    gameSession.availablePlayers.append(player)
                }
            }
            
            // Only selected starting XI players are initially "selected"
            gameSession.selectedPlayers = selectedStartingXI
            
            print("✅ Added \(selectedStartingXI.count) starting XI players and \(substitutePlayers.count) substitutes")
            
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
                : Array(self.selectedMatchIds.prefix(1))
                
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
                
                print("🔄 Loading players for \(matchIdsToLoad.count) matches...")
                
                for (index, matchId) in matchIdsToLoad.enumerated() {
                    guard let match = gameSession.availableMatches.first(where: { $0.id == matchId }) else {
                        print("⚠️ Match with ID \(matchId) not found in available matches")
                        continue
                    }
                    
                    print("📥 Loading players for match \(index + 1)/\(matchIdsToLoad.count): \(match.homeTeam.name) vs \(match.awayTeam.name)")
                    
                    do {
                        // Try lineup first
                        try await gameSession.fetchMatchLineup(for: matchId)
                        if let lineup = gameSession.matchLineups[matchId] {
                            let lineupPlayers = extractPlayersFromLineup(lineup)
                            allPlayers.append(contentsOf: lineupPlayers)
                            print("✅ Loaded \(lineupPlayers.count) real players from lineup")
                        }
                    } catch LineupError.notAvailableYet {
                        // Show choice alert instead of automatically falling back
                        await MainActor.run {
                            self.isLoading = false
                            self.pendingMatchId = matchId
                            self.pendingMatchName = "\(match.homeTeam.name) vs \(match.awayTeam.name)"
                            self.showingLineupChoiceAlert = true
                        }
                        return
                    } catch {
                        print("❌ Error loading players for \(match.homeTeam.name) vs \(match.awayTeam.name): \(error)")
                        // For other errors, continue to next match
                    }
                    
                    // Rate limiting between requests
                    if index < matchIdsToLoad.count - 1 {
                        try await Task.sleep(nanoseconds: 2_000_000_000)
                    }
                }
                
                await MainActor.run {
                    self.isLoading = false
                    gameSession.availablePlayers = allPlayers
                    
                    if !allPlayers.isEmpty {
                        print("✅ Successfully loaded \(allPlayers.count) real players")
                        if self.currentStep < self.steps.count - 1 {
                            self.currentStep += 1
                        }
                    } else {
                        self.error = "No player data available for selected matches."
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
    
    private func loadFullSquadForMatch(_ matchId: String) {
        isLoading = true
        
        Task {
            do {
                if let footballService = gameSession.matchService as? FootballDataMatchService {
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
    
    private func extractPlayersFromLineup(_ lineup: Lineup) -> [Player] {
        var players: [Player] = []
        players.append(contentsOf: lineup.homeTeam.startingXI)
        players.append(contentsOf: lineup.homeTeam.substitutes)
        players.append(contentsOf: lineup.awayTeam.startingXI)
        players.append(contentsOf: lineup.awayTeam.substitutes)
        return players
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
        if AppPurchaseManager.shared.currentTier == .free {
            if !AppPurchaseManager.shared.canUseLiveFeatures {
                showNoMoreMatchesDialog()
                return
            }
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

        // *** FIX: Set the selected match ***
        if let firstSelectedMatchId = selectedMatchIds.first,
           let selectedMatch = gameSession.availableMatches.first(where: { $0.id == firstSelectedMatchId }) {
            gameSession.selectedMatch = selectedMatch
            print("✅ Selected match set: \(selectedMatch.homeTeam.name) vs \(selectedMatch.awayTeam.name)")
        } else {
            print("❌ Warning: No match selected for live mode")
        }
        
        if gameSession.isLiveMode {
            gameSession.startMatch()
            print("⏱️ Match timer started for live game")
        }

        // Randomly assign players to participants
        gameSession.assignPlayersRandomly()

        // Set up event-driven mode for live games
        if gameSession.isLiveMode {
            gameSession.setupEventDrivenMode()
        }

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
                .fill(AppDesignSystem.Colors.cardBackground)
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
                .fill(AppDesignSystem.Colors.cardBackground)
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
                        
                        // Starting XI indicator
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
                    
                    // Substitute indicator
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

// MARK: - Error handling

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

class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    private let monitor = NWPathMonitor()
    
    init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: DispatchQueue.global())
    }
}
