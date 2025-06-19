//
//  Streamlined GameView.swift
//  Lucky Football Slip
//
//  Clean 4-tab interface with integrated stats
//

import SwiftUI

struct GameView: View {
    @ObservedObject var gameSession: GameSession
    @State private var selectedPlayer: Player? = nil
    @State private var selectedEventType: Bet.EventType? = nil
    @State private var showingEventSheet = false
    @State private var showingSubstitutionSheet = false
    @State private var showingAutoSavePrompt = false
    @State private var autoSaveGameName = ""
    @State private var selectedCustomEventName: String? = nil
    
    var body: some View {
        ZStack {
            // Clean background
            backgroundView
            
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
                
                // Tab 3: Timeline (existing)
                TimelineView(gameSession: gameSession)
                    .tabItem {
                        Label("Timeline", systemImage: "clock.arrow.circlepath")
                    }
                
                // Tab 4: Settings
                SettingsView()
                    .environmentObject(gameSession)
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
            }
            .accentColor(AppDesignSystem.Colors.primary)
        }
        .navigationTitle("Lucky Football Slip")
        .sheet(isPresented: $showingEventSheet) {
            recordEventView
        }
        .sheet(isPresented: $showingSubstitutionSheet) {
            SubstitutionView(gameSession: gameSession)
        }
        .sheet(isPresented: $showingAutoSavePrompt) {
            autoSaveGamePrompt
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartGame"))) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if AppPurchaseManager.shared.currentTier == .free {
                    showingAutoSavePrompt = true
                }
            }
        }
        .onAppear {
            // Ensure custom events are properly mapped
            gameSession.autoFixCustomEventsOnGameStart()
        }
    }
    

    
    // MARK: - Background
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 1.0),
                Color(red: 0.98, green: 0.96, blue: 1.0),
                Color(red: 0.96, green: 0.97, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Enhanced Participants View with Stats
    
    private var participantsWithStatsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Game Stats Overview
                gameStatsOverview
                
                // Quick Actions Bar
                quickActionsBar
                
                // Participants Standings
                participantsStandings
                
                // Recent Activity (last 3 events)
                if !gameSession.events.isEmpty {
                    recentActivity
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
    }
    
    // MARK: - Game Stats Overview
    
    private var gameStatsOverview: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Game Overview")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                // Live indicator if it's a live game
                if gameSession.isLiveMode {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(AppDesignSystem.Colors.success)
                            .frame(width: 8, height: 8)
                        
                        Text("LIVE")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.success)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppDesignSystem.Colors.success.opacity(0.1))
                    .cornerRadius(8)
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
                    color: AppDesignSystem.Colors.primary
                )
                
                GameStatCard(
                    title: "Active Players",
                    value: "\(gameSession.participants.flatMap { $0.selectedPlayers }.count)",
                    icon: "person.3.fill",
                    color: AppDesignSystem.Colors.success
                )
                
                GameStatCard(
                    title: "Money in Play",
                    value: formatCurrency(totalMoneyInPlay),
                    icon: "dollarsign.circle.fill",
                    color: AppDesignSystem.Colors.warning
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
            
            // Group events by their display name (not just eventType)
            let eventCounts = Dictionary(grouping: gameSession.events) { event in
                gameSession.getEventDisplayName(for: event)
            }.mapValues { $0.count }
             .sorted { $0.value > $1.value }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(eventCounts.prefix(4), id: \.key) { eventName, count in
                    // Get the first event with this name to determine color/icon
                    let sampleEvent = gameSession.events.first {
                        gameSession.getEventDisplayName(for: $0) == eventName
                    }!
                    
                    HStack(spacing: 8) {
                        Image(systemName: eventIcon(sampleEvent.eventType))
                            .font(.system(size: 14))
                            .foregroundColor(eventColor(sampleEvent.eventType))
                            .frame(width: 20)
                        
                        Text(eventName)  // Use the display name instead of rawValue
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
    
    // MARK: - Quick Actions Bar
    
    private var quickActionsBar: some View {
        HStack(spacing: 12) {
            Button(action: {
                showingEventSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Record Event")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppDesignSystem.Colors.primary)
                .cornerRadius(10)
            }
            
            Button(action: {
                showingSubstitutionSheet = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 16))
                    Text("Substitute")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(AppDesignSystem.Colors.warning)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(AppDesignSystem.Colors.warning.opacity(0.1))
                .cornerRadius(10)
            }
            
            if gameSession.canUndoLastEvent {
                Button(action: {
                    gameSession.undoLastEvent()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.system(size: 16))
                        Text("Undo")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(AppDesignSystem.Colors.error.opacity(0.1))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    // MARK: - Participants Standings
    
    private var participantsStandings: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Standings")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text("\(gameSession.participants.count) players")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            ForEach(gameSession.participants.sorted(by: { $0.balance > $1.balance })) { participant in
                EnhancedParticipantStandingRow(
                    participant: participant,
                    position: gameSession.participants.sorted(by: { $0.balance > $1.balance })
                        .firstIndex(where: { $0.id == participant.id })! + 1,
                    gameSession: gameSession
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Recent Activity
    
    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            ForEach(gameSession.events.suffix(3).reversed(), id: \.id) { event in
                CompactEventRow(event: event, gameSession: gameSession) // Add gameSession parameter
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Enhanced Players View
    
    private var enhancedPlayersView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Header with quick event button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Player Assignments")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Tap a player to record an event")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingEventSheet = true
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Event")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppDesignSystem.Colors.primary)
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                
                if gameSession.participants.flatMap({ $0.selectedPlayers + $0.substitutedPlayers }).isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppDesignSystem.Colors.secondary.opacity(0.6))
                        
                        Text("No Players Assigned")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Players will appear here once the game starts")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding(.horizontal, 20)
                } else {
                    // Player assignments by participant
                    ForEach(gameSession.participants) { participant in
                        if !participant.selectedPlayers.isEmpty || !participant.substitutedPlayers.isEmpty {
                            ParticipantPlayersSection(
                                participant: participant,
                                onPlayerTap: { player in
                                    selectedPlayer = player
                                    showingEventSheet = true
                                }
                            )
                        }
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
    }
    
    // MARK: - Helper Properties
    
    private var totalMoneyInPlay: Double {
        let totalPositive = gameSession.participants.filter { $0.balance > 0 }.map { $0.balance }.reduce(0, +)
        let totalNegative = abs(gameSession.participants.filter { $0.balance < 0 }.map { $0.balance }.reduce(0, +))
        return max(totalPositive, totalNegative)
    }
    
    // MARK: - Record Event Sheet
    
    private var recordEventView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if gameSession.participants.flatMap({ $0.selectedPlayers + $0.substitutedPlayers }).isEmpty {
                        // Empty state
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppDesignSystem.Colors.warning)
                            
                            Text("No Players Available")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Text("You need to assign players to participants before recording events")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 80)
                    } else {
                        // Player selection
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Player")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            ForEach(gameSession.participants) { participant in
                                if !participant.selectedPlayers.isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text(participant.name)
                                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                                            .foregroundColor(AppDesignSystem.Colors.primary)
                                        
                                        LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                                            ForEach(participant.selectedPlayers) { player in
                                                PlayerSelectionCard(
                                                    player: player,
                                                    isSelected: selectedPlayer?.id == player.id
                                                ) {
                                                    selectedPlayer = player
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Event type selection
                        if selectedPlayer != nil {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Select Event Type")
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    // Standard event types (excluding custom)
                                    ForEach(Bet.EventType.allCases.filter { $0 != .custom }, id: \.self) { eventType in
                                        EventTypeSelectionCard(
                                            eventType: eventType,
                                            isSelected: selectedEventType == eventType
                                        ) {
                                            selectedEventType = eventType
                                        }
                                    }
                                }
                                
                                // Custom events section (within the same sheet)
                                if !gameSession.getCustomEvents().isEmpty {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Custom Events")
                                            .font(.system(size: 18, weight: .bold, design: .rounded))
                                            .foregroundColor(AppDesignSystem.Colors.accent)
                                            .padding(.top, 16)
                                        
                                        LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                                            ForEach(gameSession.getCustomEvents(), id: \.id) { customEvent in
                                                CustomEventInlineCard(
                                                    name: customEvent.name,
                                                    amount: customEvent.amount,
                                                    isSelected: selectedCustomEventName == customEvent.name,
                                                    onTap: {
                                                        selectedCustomEventName = customEvent.name
                                                        selectedEventType = .custom
                                                    }
                                                )
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Record button
                        if let player = selectedPlayer, let eventType = selectedEventType {
                            Button {
                                if eventType == .custom, let customEventName = selectedCustomEventName {
                                    gameSession.recordCustomEvent(player: player, eventName: customEventName)
                                } else {
                                    gameSession.recordEvent(player: player, eventType: eventType)
                                }
                                showingEventSheet = false
                                selectedPlayer = nil
                                selectedEventType = nil
                                selectedCustomEventName = nil
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                    
                                    let eventText = eventType == .custom ?
                                        (selectedCustomEventName ?? "Custom Event") :
                                        eventType.rawValue
                                    
                                    Text("Record \(eventText) for \(player.name)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.vertical, 16)
                                .frame(maxWidth: .infinity)
                                .background(AppDesignSystem.Colors.success)
                                .cornerRadius(12)
                            }
                        }
                    }
                }
                .padding(24)
            }
            .navigationTitle("Record Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        showingEventSheet = false
                        selectedPlayer = nil
                        selectedEventType = nil
                        selectedCustomEventName = nil
                    }
                }
            }
        }
    }
    
    struct CustomEventInlineCard: View {
        let name: String
        let amount: Double
        let isSelected: Bool
        let onTap: () -> Void
        
        private var currencySymbol: String {
            UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        }
        
        private var isNegative: Bool {
            amount < 0
        }
        
        var body: some View {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    // Custom event icon
                    Circle()
                        .fill(isSelected ? AppDesignSystem.Colors.accent : AppDesignSystem.Colors.accent.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "star.fill")
                                .font(.system(size: 16))
                                .foregroundColor(isSelected ? .white : AppDesignSystem.Colors.accent)
                        )
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            // Type indicator
                            Image(systemName: isNegative ? "minus.circle.fill" : "plus.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                            
                            Text("\(currencySymbol)\(String(format: "%.2f", abs(amount)))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(AppDesignSystem.Colors.success)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? AppDesignSystem.Colors.accent.opacity(0.1) : Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    isSelected ? AppDesignSystem.Colors.accent : AppDesignSystem.Colors.accent.opacity(0.3),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Auto Save Prompt
    
    private var autoSaveGamePrompt: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "externaldrive.badge.plus")
                    .font(.system(size: 60))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Quick Save Game")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Save your game progress so you can continue later or share with friends.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                
                TextField("Game name (optional)", text: $autoSaveGameName)
                    .font(.system(size: 16, weight: .medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
                
                Button("Save Game") {
                    let finalGameName = autoSaveGameName.isEmpty ?
                        "Game \\(Date().formatted(date: .abbreviated, time: .shortened))" :
                        autoSaveGameName
                    
                    GameHistoryManager.shared.saveGameSession(gameSession, name: finalGameName)
                    
                    showingAutoSavePrompt = false
                    autoSaveGameName = ""
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
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
                .vibrantButton()
            }
            .padding(24)
            .background(AppDesignSystem.Colors.background)
            .navigationTitle("Quick Save")
            .navigationBarTitleDisplayMode(.inline)
        }
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
        case .goal, .assist: return AppDesignSystem.Colors.success
        case .yellowCard: return AppDesignSystem.Colors.warning
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.warning
        case .penalty: return AppDesignSystem.Colors.primary
        case .cleanSheet: return AppDesignSystem.Colors.info
        case .custom: return AppDesignSystem.Colors.secondary
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}

// MARK: - Supporting Components

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

struct EnhancedParticipantStandingRow: View {
    let participant: Participant
    let position: Int
    let gameSession: GameSession
    
    private var positionColor: Color {
        switch position {
        case 1: return AppDesignSystem.Colors.warning
        case 2: return AppDesignSystem.Colors.secondaryText
        case 3: return AppDesignSystem.Colors.warning.opacity(0.7)
        default: return AppDesignSystem.Colors.secondaryText.opacity(0.6)
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Position indicator
            ZStack {
                Circle()
                    .fill(position <= 3 ? positionColor.opacity(0.2) : Color.clear)
                    .frame(width: 32, height: 32)
                
                Text("\(position)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(positionColor)
            }
            
            // Participant info
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppDesignSystem.Colors.primary.opacity(0.8))
                        .frame(width: 36, height: 36)
                    
                    if let firstLetter = participant.name.first {
                        Text(String(firstLetter).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("\(participant.selectedPlayers.count) players")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            // Balance
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(participant.balance))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                
                Text(participant.balance >= 0 ? "Winning" : "Losing")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}

struct CompactEventRow: View {
    let event: GameEvent
    @ObservedObject var gameSession: GameSession
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            // Event icon
            Circle()
                .fill(eventColor.opacity(0.2))
                .frame(width: 28, height: 28)
                .overlay(
                    Image(systemName: eventIcon)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(eventColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.player.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                // Use the proper event display name instead of rawValue
                Text(gameSession.getEventDisplayName(for: event))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Text(timeFormatter.string(from: event.timestamp))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(.vertical, 4)
    }
    
    private var eventColor: Color {
        switch event.eventType {
        case .goal, .assist: return AppDesignSystem.Colors.success
        case .yellowCard: return AppDesignSystem.Colors.warning
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.warning
        case .penalty: return AppDesignSystem.Colors.primary
        case .cleanSheet: return AppDesignSystem.Colors.info
        case .custom: return AppDesignSystem.Colors.secondary
        }
    }
    
    private var eventIcon: String {
        switch event.eventType {
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
}

struct ParticipantPlayersSection: View {
    let participant: Participant
    let onPlayerTap: (Player) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Participant header
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppDesignSystem.Colors.primary.opacity(0.8))
                        .frame(width: 32, height: 32)
                    
                    if let firstLetter = participant.name.first {
                        Text(String(firstLetter).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                Text(participant.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text(formatCurrency(participant.balance))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
            }
            
            // Active players
            if !participant.selectedPlayers.isEmpty {
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                    ForEach(participant.selectedPlayers) { player in
                        CompactPlayerRow(player: player, isActive: true) {
                            onPlayerTap(player)
                        }
                    }
                }
            }
            
            // Substituted players
            if !participant.substitutedPlayers.isEmpty {
                Text("Substituted")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .padding(.top, 8)
                
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                    ForEach(participant.substitutedPlayers) { player in
                        CompactPlayerRow(player: player, isActive: false) {
                            onPlayerTap(player)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppDesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
                )
        )
        .padding(.horizontal, 20)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}

struct CompactPlayerRow: View {
    let player: Player
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Team color indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                    .frame(width: 4, height: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(isActive ? AppDesignSystem.Colors.primaryText : AppDesignSystem.Colors.secondaryText)
                    
                    Text("\(player.team.shortName) • \(player.position.rawValue)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if !isActive {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.warning)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isActive ? Color.white : AppDesignSystem.Colors.secondaryText.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PlayerSelectionCard: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Team color indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                    .frame(width: 4, height: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("\(player.team.shortName) • \(player.position.rawValue)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppDesignSystem.Colors.success)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AppDesignSystem.Colors.success.opacity(0.1) : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? AppDesignSystem.Colors.success : Color.gray.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EventTypeSelectionCard: View {
    let eventType: Bet.EventType
    let isSelected: Bool
    let action: () -> Void
    
    private var eventColor: Color {
        switch eventType {
        case .goal, .assist: return AppDesignSystem.Colors.success
        case .yellowCard: return AppDesignSystem.Colors.warning
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.warning
        case .penalty: return AppDesignSystem.Colors.primary
        case .cleanSheet: return AppDesignSystem.Colors.info
        case .custom: return AppDesignSystem.Colors.secondary
        }
    }
    
    private var eventIcon: String {
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
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: eventIcon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .white : eventColor)
                
                Text(eventType.rawValue)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : AppDesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? eventColor : eventColor.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
