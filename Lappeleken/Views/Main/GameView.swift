//
//  Enhanced GameView.swift
//  Lucky Football Slip
//
//  Vibrant game interface with enhanced design system
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
    @State private var animateGradient = false

    
    var body: some View {
        ZStack {
            // Enhanced background
            backgroundView
            
            TabView {
                participantsView
                    .tabItem {
                        Label("Participants", systemImage: "person.3.fill")
                    }
                
                playersView
                    .tabItem {
                        Label("Players", systemImage: "sportscourt.fill")
                    }
                
                eventsView
                    .tabItem {
                        Label("Events", systemImage: "list.bullet.circle.fill")
                    }
                
                TimelineView(gameSession: gameSession)
                    .tabItem {
                        Label("Timeline", systemImage: "clock.arrow.circlepath")
                    }
                
                StatsView(gameSession: gameSession)
                    .tabItem {
                        Label("Stats", systemImage: "chart.bar.xaxis")
                    }
                
                SettingsView()
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
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
        }
    }
    
    // MARK: - Enhanced Background
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 1.0),
                Color(red: 0.98, green: 0.96, blue: 1.0),
                Color(red: 0.96, green: 0.97, blue: 1.0)
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Enhanced Auto Save Prompt
    
    private var autoSaveGamePrompt: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Enhanced icon with glow
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppDesignSystem.Colors.primary.opacity(0.3),
                                    AppDesignSystem.Colors.primary.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 20,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.primary,
                                    AppDesignSystem.Colors.secondary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 16) {
                    Text("Save Your Game?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("Give your game a name so you don't lose your progress. You can always save it later from the game summary.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                }
                
                // Enhanced text field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Game Name (optional)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    TextField("Enter a name for your game", text: $autoSaveGameName)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.05),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                }
                
                // Enhanced buttons
                HStack(spacing: 16) {
                    Button("Skip") {
                        showingAutoSavePrompt = false
                        autoSaveGameName = ""
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.1))
                    )
                    
                    Button("Save & Continue") {
                        let finalGameName = autoSaveGameName.isEmpty ?
                            "Game \(Date().formatted(date: .abbreviated, time: .shortened))" :
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
            }
            .padding(24)
            .background(AppDesignSystem.Colors.background)
            .navigationTitle("Quick Save")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Enhanced Tab Views
    
    private var participantsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Enhanced action bar
                HStack(spacing: 12) {
                    EnhancedActionButton(
                        title: "Substitute",
                        icon: "arrow.left.arrow.right",
                        color: AppDesignSystem.Colors.warning,
                        style: .secondary
                    ) {
                        showingSubstitutionSheet = true
                    }
                    
                    EnhancedActionButton(
                        title: "Record Event",
                        icon: "plus.circle.fill",
                        color: AppDesignSystem.Colors.primary,
                        style: .primary
                    ) {
                        showingEventSheet = true
                    }
                }
                .padding(.horizontal, 20)
                
                // Enhanced participant cards
                ForEach(gameSession.participants) { participant in
                    ParticipantCard(participant: participant)
                        .padding(.horizontal, 20)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
    }
    
    private var playersView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Enhanced header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Assigned Players")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Track your team's performance")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    EnhancedActionButton(
                        title: "Event",
                        icon: "plus.circle.fill",
                        color: AppDesignSystem.Colors.primary,
                        style: .compact
                    ) {
                        showingEventSheet = true
                    }
                }
                .padding(.horizontal, 20)
                
                if gameSession.participants.flatMap({ $0.selectedPlayers + $0.substitutedPlayers }).isEmpty {
                    // Enhanced empty state
                    VStack(spacing: 16) {
                        Image(systemName: "person.3.sequence.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppDesignSystem.Colors.secondary.opacity(0.6))
                        
                        Text("No Players Assigned")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Players will appear here once they're assigned to participants")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    ForEach(gameSession.participants) { participant in
                        EnhancedPlayerSection(
                            participant: participant,
                            gameSession: gameSession
                        )
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
        .id("players-view-\(gameSession.events.count)-\(gameSession.substitutions.count)")
    }
    
    private var eventsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Enhanced header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Game Events")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("\(gameSession.events.count) events recorded")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    EnhancedActionButton(
                        title: "Record",
                        icon: "plus.circle.fill",
                        color: AppDesignSystem.Colors.primary,
                        style: .compact
                    ) {
                        showingEventSheet = true
                    }
                }
                .padding(.horizontal, 20)
                
                if gameSession.events.isEmpty {
                    // Enhanced empty state
                    VStack(spacing: 16) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(AppDesignSystem.Colors.secondary.opacity(0.6))
                        
                        Text("No Events Yet")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Start recording goals, cards, and other match events")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                } else {
                    ForEach(gameSession.events.sorted(by: { $0.timestamp > $1.timestamp })) { event in
                        EnhancedEventCard(event: event, gameSession: gameSession)
                            .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
    }
    
    // MARK: - Record Event Sheet (Enhanced)
    
    private var recordEventView: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if gameSession.participants.flatMap({ $0.selectedPlayers + $0.substitutedPlayers }).isEmpty {
                        // Enhanced empty state
                        VStack(spacing: 16) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppDesignSystem.Colors.warning)
                            
                            Text("No Players Available")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Text("You need to assign players to participants first")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 60)
                    } else {
                        // Player selection section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Select Player")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            ForEach(gameSession.participants) { participant in
                                VStack(alignment: .leading, spacing: 12) {
                                    Text(participant.name)
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(AppDesignSystem.Colors.primary)
                                    
                                    // Active players
                                    ForEach(participant.selectedPlayers) { player in
                                        EnhancedPlayerSelectionCard(
                                            player: player,
                                            isSelected: selectedPlayer?.id == player.id,
                                            isSubstituted: false
                                        ) {
                                            selectedPlayer = player
                                        }
                                    }
                                    
                                    // Substituted players
                                    ForEach(participant.substitutedPlayers) { player in
                                        EnhancedPlayerSelectionCard(
                                            player: player,
                                            isSelected: selectedPlayer?.id == player.id,
                                            isSubstituted: true
                                        ) {
                                            selectedPlayer = player
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
                                    ForEach(Bet.EventType.allCases, id: \.self) { eventType in
                                        EnhancedEventTypeCard(
                                            eventType: eventType,
                                            isSelected: selectedEventType == eventType
                                        ) {
                                            selectedEventType = eventType
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Record button
                        if let player = selectedPlayer, let eventType = selectedEventType {
                            Button {
                                gameSession.recordEvent(player: player, eventType: eventType)
                                showingEventSheet = false
                                selectedPlayer = nil
                                selectedEventType = nil
                            } label: {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                    
                                    Text("Record \(eventType.rawValue) for \(player.name)")
                                        .font(.system(size: 16, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    AppDesignSystem.Colors.success,
                                                    AppDesignSystem.Colors.success.opacity(0.8)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .vibrantButton(color: AppDesignSystem.Colors.success)
                            }
                        }
                    }
                }
                .padding(20)
            }
            .background(AppDesignSystem.Colors.background)
            .navigationTitle("Record Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingEventSheet = false
                        selectedPlayer = nil
                        selectedEventType = nil
                    }
                    .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Enhanced Components

struct EnhancedActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let style: Style
    let action: () -> Void
    
    enum Style {
        case primary, secondary, compact
    }
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(AppDesignSystem.Animations.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppDesignSystem.Animations.quick) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: style == .compact ? 6 : 8) {
                Image(systemName: icon)
                    .font(.system(size: style == .compact ? 16 : 18, weight: .medium))
                
                Text(title)
                    .font(.system(size: style == .compact ? 14 : 16, weight: .semibold, design: .rounded))
            }
            .foregroundColor(style == .primary ? .white : color)
            .padding(.vertical, style == .compact ? 8 : 12)
            .padding(.horizontal, style == .compact ? 12 : 16)
            .background(
                RoundedRectangle(cornerRadius: style == .compact ? 8 : 12)
                    .fill(
                        style == .primary ?
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [color.opacity(0.1), color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: style == .compact ? 8 : 12)
                            .stroke(
                                style == .secondary ? color.opacity(0.3) : Color.clear,
                                lineWidth: 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .if(style == .primary) { view in
            view.vibrantButton(color: color)
        }
    }
}


struct EnhancedPlayerSection: View {
    let participant: Participant
    let gameSession: GameSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            HStack {
                Text(participant.name)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                VibrantStatusBadge(
                    "\(participant.selectedPlayers.count + participant.substitutedPlayers.count) players",
                    color: AppDesignSystem.Colors.info
                )
            }
            
            // Active players
            if !participant.selectedPlayers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active Players")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.success)
                    
                    ForEach(participant.selectedPlayers) { player in
                        EnhancedPlayerStatsCard(gameSession: gameSession, player: player)
                    }
                }
            }
            
            // Substituted players
            if !participant.substitutedPlayers.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Substituted Players")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.warning)
                    
                    ForEach(participant.substitutedPlayers) { player in
                        EnhancedPlayerStatsCard(gameSession: gameSession, player: player, isSubstituted: true)
                    }
                }
            }
            
            if participant.selectedPlayers.isEmpty && participant.substitutedPlayers.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "person.slash")
                        .font(.system(size: 24))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
                    
                    Text("No players assigned")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
        }
        .enhancedCard()
    }
}

struct EnhancedPlayerStatsCard: View {
    let gameSession: GameSession
    let player: Player
    var isSubstituted: Bool = false
    
    @State private var showDetails = false
    
    private var currentPlayerStats: (goals: Int, assists: Int, yellowCards: Int, redCards: Int) {
        if let updatedPlayer = gameSession.availablePlayers.first(where: { $0.id == player.id }) {
            return (updatedPlayer.goals, updatedPlayer.assists, updatedPlayer.yellowCards, updatedPlayer.redCards)
        }
        return (player.goals, player.assists, player.yellowCards, player.redCards)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(AppDesignSystem.Animations.bouncy) {
                    showDetails.toggle()
                }
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.name)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        HStack(spacing: 8) {
                            Text(player.team.name)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppDesignSystem.TeamColors.getColor(for: player.team))
                            
                            Text("•")
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            
                            Text(player.position.rawValue)
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Substitution status
                    if isSubstituted {
                        VibrantStatusBadge("Subbed Off", color: AppDesignSystem.Colors.warning)
                    } else if case .substitutedOn = player.substitutionStatus {
                        VibrantStatusBadge("Subbed On", color: AppDesignSystem.Colors.success)
                    }
                    
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Stats display
            let stats = currentPlayerStats
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                EnhancedStatItem(label: "Goals", value: stats.goals, color: AppDesignSystem.Colors.success)
                EnhancedStatItem(label: "Assists", value: stats.assists, color: AppDesignSystem.Colors.info)
                EnhancedStatItem(label: "Yellow", value: stats.yellowCards, color: AppDesignSystem.Colors.warning)
                EnhancedStatItem(label: "Red", value: stats.redCards, color: AppDesignSystem.Colors.error)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )
        .opacity(isSubstituted ? 0.8 : 1.0)
    }
}

struct EnhancedStatItem: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(value > 0 ? color : AppDesignSystem.Colors.secondaryText.opacity(0.5))
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(value > 0 ? color.opacity(0.1) : Color.gray.opacity(0.05))
        )
    }
}

struct EnhancedEventCard: View {
    let event: GameEvent
    let gameSession: GameSession
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func getParticipantName(for player: Player) -> String {
        return gameSession.participants.first {
            $0.selectedPlayers.contains { $0.id == player.id } ||
            $0.substitutedPlayers.contains { $0.id == player.id }
        }?.name ?? "Unknown"
    }
    
    private func getEventColor(_ eventType: Bet.EventType) -> Color {
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
    
    private func getEventIcon(_ eventType: Bet.EventType) -> String {
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
        HStack(spacing: 16) {
            // Event icon with enhanced styling
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                getEventColor(event.eventType),
                                getEventColor(event.eventType).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: getEventIcon(event.eventType))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(
                color: getEventColor(event.eventType).opacity(0.3),
                radius: 6,
                x: 0,
                y: 3
            )
            
            VStack(alignment: .leading, spacing: 6) {
                Text(event.eventType.rawValue)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(event.player.name)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: event.player.team))
                
                HStack(spacing: 8) {
                    Text(event.player.team.name)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Text("•")
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Text("Owned by \(getParticipantName(for: event.player))")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(dateFormatter.string(from: event.timestamp))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                if let bet = gameSession.bets.first(where: { $0.eventType == event.eventType }) {
                    VibrantStatusBadge(
                        bet.amount >= 0 ? "+\(formatCurrency(bet.amount))" : "\(formatCurrency(bet.amount))",
                        color: bet.amount >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error
                    )
                }
            }
        }
        .enhancedCard()
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}

struct EnhancedPlayerSelectionCard: View {
    let player: Player
    let isSelected: Bool
    let isSubstituted: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(AppDesignSystem.Animations.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppDesignSystem.Animations.quick) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(player.name)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        if isSubstituted {
                            VibrantStatusBadge("Subbed Off", color: AppDesignSystem.Colors.warning)
                        }
                    }
                    
                    HStack(spacing: 8) {
                        Text(player.team.name)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.TeamColors.getColor(for: player.team))
                        
                        Text("•")
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Text(player.position.rawValue)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected ?
                        AppDesignSystem.Colors.primary.opacity(0.1) :
                        Color.white
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ?
                                AppDesignSystem.Colors.primary :
                                Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isSubstituted ? 0.7 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct EnhancedEventTypeCard: View {
    let eventType: Bet.EventType
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    private func getEventColor(_ eventType: Bet.EventType) -> Color {
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
    
    private func getEventIcon(_ eventType: Bet.EventType) -> String {
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
        Button(action: {
            withAnimation(AppDesignSystem.Animations.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppDesignSystem.Animations.quick) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(
                            isSelected ?
                            LinearGradient(
                                colors: [
                                    getEventColor(eventType),
                                    getEventColor(eventType).opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    getEventColor(eventType).opacity(0.2),
                                    getEventColor(eventType).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: getEventIcon(eventType))
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(
                            isSelected ? .white : getEventColor(eventType)
                        )
                }
                
                Text(eventType.rawValue)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(
                        isSelected ?
                        getEventColor(eventType) :
                        AppDesignSystem.Colors.primaryText
                    )
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        isSelected ?
                        getEventColor(eventType).opacity(0.1) :
                        Color.white
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isSelected ?
                                getEventColor(eventType) :
                                Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.02 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
        .if(isSelected) { view in
            view.shadow(
                color: getEventColor(eventType).opacity(0.3),
                radius: 6,
                x: 0,
                y: 3
            )
        }
    }
}

// MARK: - Helper Extensions

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
