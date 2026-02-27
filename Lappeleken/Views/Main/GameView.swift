//
//  GameView.swift
//  Lucky Football Slip
//
//  Clean 4-tab interface with integrated stats - Football themed
//  Note: Component structs are in GameViewComponents.swift
//

import SwiftUI

struct GameView: View {
    @ObservedObject var gameSession: GameSession
    @Binding var shouldShowSummary: Bool
    @State private var selectedPlayer: Player? = nil
    @State private var selectedEventType: Bet.EventType? = nil
    @State private var showingEventSheet = false
    @State private var showingSubstitutionSheet = false
    @State private var showingAutoSavePrompt = false
    @State private var selectedCustomEventName: String? = nil
    @State private var showMissedEventsBanner = false
    @State private var missedEventsInfo: (count: Int, matchName: String) = (0, "")
    @State private var showingSaveGameSheet = false
    @State private var showingEndGameConfirmation = false
    @State private var shouldEndGameAfterSave = false
    
    @Environment(\.colorScheme) var colorScheme
    
    init(gameSession: GameSession, shouldShowSummary: Binding<Bool>) {
        self.gameSession = gameSession
        self._shouldShowSummary = shouldShowSummary
    }

    var body: some View {
        VStack(spacing: 0) {
            customNavigationHeader
            
            // Missed events banner
            if showMissedEventsBanner {
                MissedEventsBanner(
                    eventCount: missedEventsInfo.count,
                    matchName: missedEventsInfo.matchName
                ) {
                    showMissedEventsBanner = false
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            
            // TabView content
            ZStack {
                // Football themed background
                GameViewBackground()
                
                TabView {
                    // Tab 1: Participants with integrated stats
                    participantsWithStatsView
                        .tabItem {
                            Label("Participants", systemImage: "person.3.fill")
                        }
                    
                    // Tab 2: Players with quick actions
                    enhancedPlayersView
                        .tabItem {
                            Label("Players", systemImage: "sportscourt.fill")
                        }
                    
                    // Tab 3: Timeline
                    TimelineView(gameSession: gameSession)
                        .tabItem {
                            Label("Timeline", systemImage: "clock.arrow.circlepath")
                        }
                    
                    // Tab 4: Match Score
                    MatchScoreView(gameSession: gameSession)
                        .tabItem {
                            Label("Match", systemImage: "soccerball")
                        }
                    
                    // Tab 5: Settings
                    SettingsView()
                        .environmentObject(gameSession)
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
                .accentColor(AppDesignSystem.Colors.grassGreen)
            }
        }
        .navigationBarHidden(true)
        
        .sheet(isPresented: $showingEventSheet) {
            RecordEventSheet(
                gameSession: gameSession,
                selectedPlayer: $selectedPlayer,
                selectedEventType: $selectedEventType,
                selectedCustomEventName: $selectedCustomEventName,
                isPresented: $showingEventSheet
            )
        }
        .sheet(isPresented: $showingSubstitutionSheet) {
            SubstitutionView(gameSession: gameSession)
        }
        .sheet(isPresented: $showingAutoSavePrompt) {
            UnifiedSaveGameSheet(gameSession: gameSession, isPresented: $showingAutoSavePrompt)
        }
        .sheet(isPresented: $showingSaveGameSheet) {
            UnifiedSaveGameSheet(gameSession: gameSession, isPresented: $showingSaveGameSheet)
                .onDisappear {
                    if shouldEndGameAfterSave {
                        shouldEndGameAfterSave = false
                        cleanupGame()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            shouldShowSummary = true
                        }
                    }
                }
        }
    
        .alert("End Game", isPresented: $showingEndGameConfirmation) {
            Button("End Without Saving", role: .destructive) {
                endGameWithoutSaving()
            }
            Button("Save & End") {
                showingEndGameConfirmation = false
                shouldEndGameAfterSave = true
                showingSaveGameSheet = true
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to quit the game? Any unsaved progress will be lost.\n\nYou can save your progress before ending the game.")
        }
        
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("MissedEventsFound"))) { notification in
            if let userInfo = notification.userInfo,
               let count = userInfo["eventCount"] as? Int,
               let matchName = userInfo["matchName"] as? String {
                
                DispatchQueue.main.async {
                    self.missedEventsInfo = (count, matchName)
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.showMissedEventsBanner = true
                    }
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 8) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        self.showMissedEventsBanner = false
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartGame"))) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if AppPurchaseManager.shared.currentTier == .free {
                    showingAutoSavePrompt = true
                }
            }
        }
        .onAppear {
            gameSession.autoFixCustomEventsOnGameStart()
        }
        .onReceive(gameSession.$events) { events in
            if let lastEvent = events.last {
                if lastEvent.eventType == .custom,
                   let customName = lastEvent.customEventName,
                   customName.contains("Substitution") {
                    print("🔄 GameView detected new substitution event: \(customName)")
                }
            }
        }
        .withMinimalBanner()
    }
    
    // MARK: - Navigation Header
    
    private var customNavigationHeader: some View {
        VStack(spacing: 0) {
            HStack {
                // Football icon
                ZStack {
                    Circle()
                        .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "sportscourt.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
                
                Text("Lucky Football Slip")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                // Live indicator if applicable
                if gameSession.isLiveMode {
                    LiveIndicator()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 10)
            .padding(.bottom, 14)
            .background(
                ZStack {
                    AppDesignSystem.Colors.cardBackground
                    
                    // Subtle green tint at top
                    VStack {
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.08 : 0.04),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 30)
                        Spacer()
                    }
                }
            )
            
            // Green accent line
            Rectangle()
                .fill(AppDesignSystem.Colors.grassGreen.opacity(0.3))
                .frame(height: 2)
        }
    }
    
    // MARK: - Participants With Stats View
    
    private var participantsWithStatsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                gameStatsOverview
                quickActionsBar
                participantsStandings
                
                if !gameSession.events.isEmpty {
                    recentActivity
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(GameViewBackground())
    }
    
    // MARK: - Game Stats Overview
    
    private var gameStatsOverview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Game Overview")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                if gameSession.isLiveMode {
                    LiveIndicator()
                }
            }
            
            // Save and end buttons row
            HStack(spacing: 12) {
                QuickActionButton(
                    title: "Save Game",
                    icon: "square.and.arrow.down",
                    color: AppDesignSystem.Colors.grassGreen,
                    style: .secondary
                ) {
                    showingSaveGameSheet = true
                }
                
                Spacer()
                
                QuickActionButton(
                    title: "End Game",
                    icon: "xmark.circle",
                    color: AppDesignSystem.Colors.error,
                    style: .secondary
                ) {
                    showingEndGameConfirmation = true
                }
            }
            
            // Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                GameStatCard(
                    title: "Total Events",
                    value: "\(gameSession.events.count)",
                    icon: "list.bullet.circle.fill",
                    color: AppDesignSystem.Colors.grassGreen
                )
                
                GameStatCard(
                    title: "Active Players",
                    value: "\(gameSession.participants.flatMap { $0.selectedPlayers }.count)",
                    icon: "person.3.fill",
                    color: AppDesignSystem.Colors.goalYellow
                )
                
                GameStatCard(
                    title: "Money in Play",
                    value: formatCurrency(totalMoneyInPlay),
                    icon: "dollarsign.circle.fill",
                    color: AppDesignSystem.Colors.accent
                )
            }
            
            // Event type breakdown
            if !gameSession.events.isEmpty {
                eventTypeBreakdown
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Event Type Breakdown
    
    private var eventTypeBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Breakdown")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            let eventCounts = Dictionary(grouping: gameSession.events) { event in
                gameSession.getEventDisplayName(for: event)
            }.mapValues { $0.count }
                .sorted {
                    if $0.value != $1.value {
                        return $0.value > $1.value
                    }
                    return $0.key < $1.key
                }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(eventCounts.prefix(4), id: \.key) { eventName, count in
                    if let sampleEvent = gameSession.events.first(where: {
                        gameSession.getEventDisplayName(for: $0) == eventName
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: eventIcon(sampleEvent.eventType))
                                .font(.system(size: 14))
                                .foregroundColor(eventColor(sampleEvent.eventType))
                                .frame(width: 20)
                            
                            Text(eventName)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Spacer()
                            
                            Text("\(count)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(eventColor(sampleEvent.eventType))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
    }
    
    // MARK: - Quick Actions Bar
    
    private var quickActionsBar: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                title: "Record Event",
                icon: "plus.circle.fill",
                color: AppDesignSystem.Colors.grassGreen,
                style: .primary
            ) {
                showingEventSheet = true
            }
            
            QuickActionButton(
                title: "Substitute",
                icon: "arrow.left.arrow.right",
                color: AppDesignSystem.Colors.warning,
                style: .secondary
            ) {
                showingSubstitutionSheet = true
            }
            
            if gameSession.canUndoLastEvent {
                QuickActionButton(
                    title: "Undo",
                    icon: "arrow.uturn.backward",
                    color: AppDesignSystem.Colors.error,
                    style: .secondary
                ) {
                    gameSession.undoLastEvent()
                }
            }
        }
    }
    
    // MARK: - Participants Standings
    
    private var participantsStandings: some View {
        VStack(alignment: .leading, spacing: 16) {
            GameSectionHeader("Standings", subtitle: "\(gameSession.participants.count) players")
            
            let sortedParticipants = gameSession.participants.sorted(by: { $0.balance > $1.balance })
            
            VStack(spacing: 0) {
                ForEach(Array(sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                    let freshParticipant = gameSession.participants.first(where: { $0.id == participant.id }) ?? participant
                    
                    ParticipantStandingRow(
                        participant: freshParticipant,
                        position: index + 1,
                        currencySymbol: currencySymbol
                    )
                    .id("\(participant.id)-\(freshParticipant.balance)")
                    
                    if index < sortedParticipants.count - 1 {
                        Divider()
                            .padding(.horizontal, 16)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
    }
    
    // MARK: - Recent Activity
    
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            GameSectionHeader("Recent Activity")
            
            VStack(spacing: 0) {
                ForEach(gameSession.events.suffix(3).reversed(), id: \.id) { event in
                    GameEventRow(event: event, gameSession: gameSession)
                    
                    if event.id != gameSession.events.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
    }
    
    // MARK: - Enhanced Players View
    
    private var enhancedPlayersView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header section
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Player Assignments")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        if gameSession.isLiveMode {
                            Text(SubstitutionManager.shared.getLiveSubstitutionStatusForUI(in: gameSession))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.info)
                        } else {
                            Text("Tap a player to record an event")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        QuickActionButton(
                            title: "Event",
                            icon: "plus.circle.fill",
                            color: AppDesignSystem.Colors.grassGreen,
                            style: .primary
                        ) {
                            showingEventSheet = true
                        }
                        
                        if !gameSession.isLiveMode {
                            QuickActionButton(
                                title: "Sub",
                                icon: "arrow.left.arrow.right",
                                color: AppDesignSystem.Colors.warning,
                                style: .secondary
                            ) {
                                showingSubstitutionSheet = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Enhanced participant sections
                ForEach(gameSession.participants) { participant in
                    ParticipantPlayersSection(
                        participant: participant,
                        gameSession: gameSession
                    ) { player in
                        selectedPlayer = player
                        showingEventSheet = true
                    }
                    .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
        .background(GameViewBackground())
    }
    
    // MARK: - Helper Properties
    
    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
    }
    
    private var totalMoneyInPlay: Double {
        let totalPositive = gameSession.participants.filter { $0.balance > 0 }.map { $0.balance }.reduce(0, +)
        let totalNegative = abs(gameSession.participants.filter { $0.balance < 0 }.map { $0.balance }.reduce(0, +))
        return max(totalPositive, totalNegative)
    }
    
    // MARK: - Helper Functions
    
    private func eventIcon(_ eventType: Bet.EventType) -> String {
        switch eventType {
        case .goal: return "soccerball"
        case .assist: return "arrow.up.forward"
        case .yellowCard: return "square.fill"
        case .redCard: return "square.fill"
        case .ownGoal: return "arrow.uturn.backward"
        case .penalty: return "p.circle"
        case .penaltyMissed: return "p.circle.fill"
        case .cleanSheet: return "lock.shield"
        case .custom: return "star"
        }
    }
    
    private func eventColor(_ eventType: Bet.EventType) -> Color {
        switch eventType {
        case .goal, .assist: return AppDesignSystem.Colors.grassGreen
        case .yellowCard: return AppDesignSystem.Colors.goalYellow
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.warning
        case .penalty: return AppDesignSystem.Colors.primary
        case .cleanSheet: return AppDesignSystem.Colors.info
        case .custom: return AppDesignSystem.Colors.accent
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
    
    private func cleanupGame() {
        if gameSession.isLiveMode {
            gameSession.cleanupEventDrivenMode()
        }
    }
    
    private func endGameWithoutSaving() {
        cleanupGame()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            shouldShowSummary = true
        }
    }
}

// MARK: - Missed Events Banner

struct MissedEventsBanner: View {
    let eventCount: Int
    let matchName: String
    let onDismiss: () -> Void
    
    @State private var isVisible = true
    
    var body: some View {
        if isVisible {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Caught up on \(eventCount) events!")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Events from \(matchName) while you were away")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isVisible = false
                    }
                    onDismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppDesignSystem.Colors.grassGreen)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Game Stat Card

struct GameStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - View Extensions

extension View {
    func withSubstitutionBadge(player: Player) -> some View {
        self.overlay(
            Group {
                if case .substitutedOff = player.substitutionStatus {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.trailing, 4)
                                .padding(.top, 4)
                        }
                        Spacer()
                    }
                } else if case .substitutedOn = player.substitutionStatus {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                                .padding(.trailing, 4)
                                .padding(.top, 4)
                        }
                        Spacer()
                    }
                }
            }
        )
    }
}

extension Participant {
    var activePlayersForUI: [Player] {
        return selectedPlayers.filter { SubstitutionManager.shared.isPlayerActive($0) }
    }
    
    var activePlayerCount: Int {
        return activePlayersForUI.count
    }
    
    func getSubstitutionSummaryForUI() -> String {
        if substitutedPlayers.isEmpty {
            return "No substitutions"
        } else {
            return "\(substitutedPlayers.count) substitution\(substitutedPlayers.count == 1 ? "" : "s")"
        }
    }
}

