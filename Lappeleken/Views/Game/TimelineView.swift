//
//  TimelineView.swift
//  Lucky Football Slip
//
//  Event timeline - Football themed
//

import SwiftUI

struct TimelineView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedEvent: GameEvent?
    @State private var showingEventActions = false
    @State private var showingEditEvent = false
    @State private var showingDeleteConfirmation = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ZStack {
            footballBackground
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    headerSection
                    
                    if gameSession.events.isEmpty {
                        emptyStateView
                    } else {
                        eventsListView
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 16)
            }
        }
        .actionSheet(isPresented: $showingEventActions) {
            ActionSheet(
                title: Text("Event Options"),
                message: Text("What would you like to do?"),
                buttons: [
                    .default(Text("Edit Event")) { showingEditEvent = true },
                    .destructive(Text("Delete Event")) { showingDeleteConfirmation = true },
                    .cancel()
                ]
            )
        }
        .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let event = selectedEvent { deleteEvent(event) }
            }
        } message: {
            if let event = selectedEvent {
                Text("Delete '\(gameSession.getEventDisplayName(for: event))' for \(event.player.name)?")
            }
        }
        .sheet(isPresented: $showingEditEvent) {
            if let event = selectedEvent {
                EditEventView(gameSession: gameSession, event: event) { edited in
                    updateEvent(original: event, edited: edited)
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            
            VStack {
                LinearGradient(
                    colors: [AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.08 : 0.04), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                
                Text("Match Timeline")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            
            Spacer()
            
            if !gameSession.events.isEmpty {
                Text("\(gameSession.events.count) events")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(AppDesignSystem.Colors.grassGreen))
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.secondaryText.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 36))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
            }
            
            VStack(spacing: 6) {
                Text("No Events Yet")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Events will appear here as the game progresses")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 200)
        .padding(.horizontal, 20)
    }
    
    // MARK: - Events List
    
    private var eventsListView: some View {
        let sortedEvents = gameSession.events.sorted { $0.timestamp > $1.timestamp }
        
        return VStack(spacing: 0) {
            ForEach(Array(sortedEvents.enumerated()), id: \.element.id) { index, event in
                TimelineEventRow(
                    event: event,
                    gameSession: gameSession,
                    isFirst: index == 0,
                    onTap: {
                        selectedEvent = event
                        showingEventActions = true
                    }
                )
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Event Management
    
    private func deleteEvent(_ event: GameEvent) {
        if let index = gameSession.events.firstIndex(where: { $0.id == event.id }) {
            gameSession.events.remove(at: index)
            reverseEventEffects(event)
            gameSession.objectWillChange.send()
        }
        selectedEvent = nil
    }
    
    private func updateEvent(original: GameEvent, edited: GameEvent) {
        reverseEventEffects(original)
        if let index = gameSession.events.firstIndex(where: { $0.id == original.id }) {
            gameSession.events[index] = edited
        }
        applyEventEffects(edited)
        gameSession.objectWillChange.send()
        selectedEvent = nil
    }
    
    private func reverseEventEffects(_ event: GameEvent) {
        guard let bet = gameSession.bets.first(where: { $0.eventType == event.eventType }) else { return }
        
        let participantsWithPlayer = gameSession.participants.filter { p in
            p.selectedPlayers.contains { $0.id == event.player.id } ||
            p.substitutedPlayers.contains { $0.id == event.player.id }
        }
        let participantsWithoutPlayer = gameSession.participants.filter { p in
            !p.selectedPlayers.contains { $0.id == event.player.id } &&
            !p.substitutedPlayers.contains { $0.id == event.player.id }
        }
        
        guard !participantsWithPlayer.isEmpty && !participantsWithoutPlayer.isEmpty else { return }
        
        if bet.amount >= 0 {
            let totalAmount = Double(participantsWithoutPlayer.count) * bet.amount
            let amountPerWinner = totalAmount / Double(participantsWithPlayer.count)
            
            for i in 0..<gameSession.participants.count {
                let hasPlayer = gameSession.participants[i].selectedPlayers.contains { $0.id == event.player.id } ||
                                gameSession.participants[i].substitutedPlayers.contains { $0.id == event.player.id }
                if hasPlayer {
                    gameSession.participants[i].balance -= amountPerWinner
                } else {
                    gameSession.participants[i].balance += bet.amount
                }
            }
        } else {
            let totalPenalty = Double(participantsWithPlayer.count) * abs(bet.amount)
            let amountPerOther = totalPenalty / Double(participantsWithoutPlayer.count)
            
            for i in 0..<gameSession.participants.count {
                let hasPlayer = gameSession.participants[i].selectedPlayers.contains { $0.id == event.player.id } ||
                                gameSession.participants[i].substitutedPlayers.contains { $0.id == event.player.id }
                if hasPlayer {
                    gameSession.participants[i].balance -= bet.amount
                } else {
                    gameSession.participants[i].balance -= amountPerOther
                }
            }
        }
    }
    
    private func applyEventEffects(_ event: GameEvent) {
        guard let bet = gameSession.bets.first(where: { $0.eventType == event.eventType }) else { return }
        
        let participantsWithPlayer = gameSession.participants.filter { p in
            p.selectedPlayers.contains { $0.id == event.player.id } ||
            p.substitutedPlayers.contains { $0.id == event.player.id }
        }
        let participantsWithoutPlayer = gameSession.participants.filter { p in
            !p.selectedPlayers.contains { $0.id == event.player.id } &&
            !p.substitutedPlayers.contains { $0.id == event.player.id }
        }
        
        guard !participantsWithPlayer.isEmpty && !participantsWithoutPlayer.isEmpty else { return }
        
        if bet.amount >= 0 {
            let totalAmount = Double(participantsWithoutPlayer.count) * bet.amount
            let amountPerWinner = totalAmount / Double(participantsWithPlayer.count)
            
            for i in 0..<gameSession.participants.count {
                let hasPlayer = gameSession.participants[i].selectedPlayers.contains { $0.id == event.player.id } ||
                                gameSession.participants[i].substitutedPlayers.contains { $0.id == event.player.id }
                if hasPlayer {
                    gameSession.participants[i].balance += amountPerWinner
                } else {
                    gameSession.participants[i].balance -= bet.amount
                }
            }
        } else {
            let totalPenalty = Double(participantsWithPlayer.count) * abs(bet.amount)
            let amountPerOther = totalPenalty / Double(participantsWithoutPlayer.count)
            
            for i in 0..<gameSession.participants.count {
                let hasPlayer = gameSession.participants[i].selectedPlayers.contains { $0.id == event.player.id } ||
                                gameSession.participants[i].substitutedPlayers.contains { $0.id == event.player.id }
                if hasPlayer {
                    gameSession.participants[i].balance += bet.amount
                } else {
                    gameSession.participants[i].balance += amountPerOther
                }
            }
        }
    }
}

// MARK: - Timeline Event Row

struct TimelineEventRow: View {
    let event: GameEvent
    let gameSession: GameSession
    let isFirst: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var eventIcon: String {
        if event.eventType == .custom && event.customEventName?.contains("Substitution") == true {
            return "arrow.left.arrow.right"
        }
        switch event.eventType {
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
    
    private var eventColor: Color {
        if event.eventType == .custom && event.customEventName?.contains("Substitution") == true {
            return AppDesignSystem.Colors.warning
        }
        switch event.eventType {
        case .goal: return AppDesignSystem.Colors.grassGreen
        case .assist: return AppDesignSystem.Colors.info
        case .yellowCard: return AppDesignSystem.Colors.goalYellow
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal: return AppDesignSystem.Colors.warning
        case .penalty: return AppDesignSystem.Colors.grassGreen
        case .penaltyMissed: return AppDesignSystem.Colors.error
        case .cleanSheet: return AppDesignSystem.Colors.info
        case .custom: return AppDesignSystem.Colors.accent
        }
    }
    
    private var participant: Participant? {
        gameSession.participants.first { p in
            p.selectedPlayers.contains { $0.id == event.player.id } ||
            p.substitutedPlayers.contains { $0.id == event.player.id }
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Timeline line and icon
                VStack(spacing: 0) {
                    ZStack {
                        Circle()
                            .fill(eventColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: eventIcon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(eventColor)
                    }
                    
                    if !isFirst {
                        Rectangle()
                            .fill(AppDesignSystem.Colors.secondaryText.opacity(0.2))
                            .frame(width: 2)
                            .frame(maxHeight: .infinity)
                    }
                }
                .frame(width: 36)
                
                // Event content
                VStack(alignment: .leading, spacing: 8) {
                    // Event type header
                    HStack {
                        Text(gameSession.getEventDisplayName(for: event))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(eventColor)
                        
                        Spacer()
                        
                        if let minute = event.minute {
                            Text("\(minute)'")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(eventColor))
                        }
                    }
                    
                    // Player info
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppDesignSystem.TeamColors.getColor(for: event.player.team))
                            .frame(width: 3, height: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.player.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Text(event.player.team.shortName)
                                .font(.system(size: 11))
                                .foregroundColor(AppDesignSystem.TeamColors.getColor(for: event.player.team))
                        }
                        
                        Spacer()
                        
                        if let participant = participant {
                            Text(participant.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.grassGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(AppDesignSystem.Colors.grassGreen.opacity(0.12))
                                )
                        }
                    }
                    
                    // Timestamp
                    let formatter = DateFormatter()
                    let _ = formatter.timeStyle = .short
                    Text(formatter.string(from: event.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppDesignSystem.Colors.cardBackground)
                        .shadow(color: colorScheme == .dark ? Color.black.opacity(0.15) : Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
                )
            }
            .padding(.bottom, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Event View

struct EditEventView: View {
    @ObservedObject var gameSession: GameSession
    let event: GameEvent
    let onSave: (GameEvent) -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedEventType: Bet.EventType
    @State private var selectedPlayer: Player
    
    init(gameSession: GameSession, event: GameEvent, onSave: @escaping (GameEvent) -> Void) {
        self.gameSession = gameSession
        self.event = event
        self.onSave = onSave
        self._selectedEventType = State(initialValue: event.eventType)
        self._selectedPlayer = State(initialValue: event.player)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        playerSelectionSection
                        eventTypeSelectionSection
                        saveButton
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
    }
    
    private var playerSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Player")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            ForEach(gameSession.participants) { participant in
                if !participant.selectedPlayers.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(participant.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.grassGreen)
                        
                        ForEach(participant.selectedPlayers) { player in
                            EditPlayerRow(player: player, isSelected: selectedPlayer.id == player.id) {
                                selectedPlayer = player
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var eventTypeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Type")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Bet.EventType.allCases, id: \.self) { eventType in
                    EditEventTypeCard(eventType: eventType, isSelected: selectedEventType == eventType) {
                        selectedEventType = eventType
                    }
                }
            }
        }
    }
    
    private var saveButton: some View {
        Button(action: {
            let edited = GameEvent(player: selectedPlayer, eventType: selectedEventType, timestamp: event.timestamp)
            onSave(edited)
            presentationMode.wrappedValue.dismiss()
        }) {
            Text("Save Changes")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(hasChanges ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.3))
                )
        }
        .disabled(!hasChanges)
    }
    
    private var hasChanges: Bool {
        selectedPlayer.id != event.player.id || selectedEventType != event.eventType
    }
}

// MARK: - Edit Player Row

struct EditPlayerRow: View {
    let player: Player
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                    .frame(width: 3, height: 28)
                
                Text(player.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.4))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppDesignSystem.Colors.grassGreen.opacity(0.08) : colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? AppDesignSystem.Colors.grassGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Edit Event Type Card

struct EditEventTypeCard: View {
    let eventType: Bet.EventType
    let isSelected: Bool
    let onTap: () -> Void
    
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
    
    private var color: Color {
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
        Button(action: onTap) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(eventType.rawValue.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(color)
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? color.opacity(0.12) : colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? color.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

