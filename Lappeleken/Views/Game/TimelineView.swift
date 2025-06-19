//
//  Enhanced TimelineView.swift
//  Lucky Football Slip
//
//  Timeline with editable/deletable events
//

import SwiftUI

struct TimelineView: View {
    @ObservedObject var gameSession: GameSession
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
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    Text("Match Timeline")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    if !gameSession.events.isEmpty {
                        Text("\(gameSession.events.count) events")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
                
                if gameSession.events.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 60))
                            .foregroundColor(AppDesignSystem.Colors.secondary.opacity(0.6))
                        
                        Text("No Events Yet")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Events will appear here as the game progresses")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .padding(.horizontal, 20)
                } else {
                    let sortedEvents = gameSession.events.sorted(by: { $0.timestamp > $1.timestamp })
                    
                    ForEach(Array(sortedEvents.enumerated()), id: \.element.id) { index, event in
                        EditableTimelineEventRow(
                            event: event,
                            gameSession: gameSession,
                            index: index,
                            isFirst: index == 0,
                            onEventTap: { selectedEvent in
                                self.selectedEvent = selectedEvent
                                showingEventActions = true
                            }
                        )
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 100)
            }
            .padding(.top, 20)
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
        .actionSheet(isPresented: $showingEventActions) {
            ActionSheet(
                title: Text("Event Options"),
                message: Text("What would you like to do with this event?"),
                buttons: [
                    .default(Text("Edit Event")) {
                        showingEditEvent = true
                    },
                    .destructive(Text("Delete Event")) {
                        showingDeleteConfirmation = true
                    },
                    .cancel()
                ]
            )
        }
        .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let event = selectedEvent {
                    deleteEvent(event)
                }
            }
        } message: {
            if let event = selectedEvent {
                Text("Are you sure you want to delete '\(gameSession.getEventDisplayName(for: event))' for \(event.player.name)? This will reverse all balance changes.")
            }
        }
        .sheet(isPresented: $showingEditEvent) {
            if let event = selectedEvent {
                EditEventView(
                    gameSession: gameSession,
                    event: event,
                    onSave: { editedEvent in
                        updateEvent(original: event, edited: editedEvent)
                    }
                )
            }
        }
    }
    
    // MARK: - Event Management
    
    private func deleteEvent(_ event: GameEvent) {
        // Remove the event and reverse its effects
        if let index = gameSession.events.firstIndex(where: { $0.id == event.id }) {
            gameSession.events.remove(at: index)
            
            // Reverse the balance changes
            reverseEventEffects(event)
            
            // Update UI
            gameSession.objectWillChange.send()
        }
        
        selectedEvent = nil
    }
    
    private func updateEvent(original: GameEvent, edited: GameEvent) {
        // First reverse the original event effects
        reverseEventEffects(original)
        
        // Update the event in the array
        if let index = gameSession.events.firstIndex(where: { $0.id == original.id }) {
            gameSession.events[index] = edited
        }
        
        // Apply the new event effects using the same logic as GameSession.recordEvent
        applyEventEffects(edited)
        
        // Update UI
        gameSession.objectWillChange.send()
        selectedEvent = nil
    }
    
    private func reverseEventEffects(_ event: GameEvent) {
        // Find the bet for this event type
        guard let bet = gameSession.bets.first(where: { $0.eventType == event.eventType }) else { return }
        
        // Find participants who have the player (include both active and substituted players)
        let participantsWithPlayer = gameSession.participants.filter { participant in
            participant.selectedPlayers.contains { $0.id == event.player.id } ||
            participant.substitutedPlayers.contains { $0.id == event.player.id }
        }
        
        // Find participants who don't have the player
        let participantsWithoutPlayer = gameSession.participants.filter { participant in
            !participant.selectedPlayers.contains { $0.id == event.player.id } &&
            !participant.substitutedPlayers.contains { $0.id == event.player.id }
        }
        
        if participantsWithPlayer.isEmpty || participantsWithoutPlayer.isEmpty {
            return
        }
        
        // Reverse the balance changes - EXACT OPPOSITE of applyEventEffects using GameSession logic
        if bet.amount >= 0 {
            // REVERSE positive bet: participants WITHOUT player had paid those WITH player
            let totalAmount = Double(participantsWithoutPlayer.count) * bet.amount
            let amountPerWinner = totalAmount / Double(participantsWithPlayer.count)
            
            for i in 0..<gameSession.participants.count {
                let hasPlayer = gameSession.participants[i].selectedPlayers.contains { $0.id == event.player.id } ||
                gameSession.participants[i].substitutedPlayers.contains { $0.id == event.player.id }
                
                if hasPlayer {
                    gameSession.participants[i].balance -= amountPerWinner  // REVERSE: was +=
                } else {
                    gameSession.participants[i].balance += bet.amount        // REVERSE: was -=
                }
            }
        } else {
            // REVERSE negative bet: participants WITH player had paid those WITHOUT player
            let payAmount = abs(bet.amount)
            
            for i in 0..<gameSession.participants.count {
                let hasPlayer = gameSession.participants[i].selectedPlayers.contains { $0.id == event.player.id } ||
                gameSession.participants[i].substitutedPlayers.contains { $0.id == event.player.id }
                
                if hasPlayer {
                    // REVERSE: Player owner had paid payAmount to EACH other participant
                    gameSession.participants[i].balance += payAmount * Double(participantsWithoutPlayer.count)  // REVERSE: was -=
                } else {
                    // REVERSE: Each other participant had received payAmount from EACH player owner
                    gameSession.participants[i].balance -= payAmount * Double(participantsWithPlayer.count)     // REVERSE: was +=
                }
            }
        }
        
        // Reverse player stats
        if let playerIndex = gameSession.participants.firstIndex(where: { participant in
            participant.selectedPlayers.contains { $0.id == event.player.id } ||
            participant.substitutedPlayers.contains { $0.id == event.player.id }
        }) {
            let participant = gameSession.participants[playerIndex]
            
            // Update in selected players
            if let selectedPlayerIndex = participant.selectedPlayers.firstIndex(where: { $0.id == event.player.id }) {
                switch event.eventType {
                case .goal:
                    gameSession.participants[playerIndex].selectedPlayers[selectedPlayerIndex].goals = max(0, gameSession.participants[playerIndex].selectedPlayers[selectedPlayerIndex].goals - 1)
                case .assist:
                    gameSession.participants[playerIndex].selectedPlayers[selectedPlayerIndex].assists = max(0, gameSession.participants[playerIndex].selectedPlayers[selectedPlayerIndex].assists - 1)
                case .yellowCard:
                    gameSession.participants[playerIndex].selectedPlayers[selectedPlayerIndex].yellowCards = max(0, gameSession.participants[playerIndex].selectedPlayers[selectedPlayerIndex].yellowCards - 1)
                case .redCard:
                    gameSession.participants[playerIndex].selectedPlayers[selectedPlayerIndex].redCards = max(0, gameSession.participants[playerIndex].selectedPlayers[selectedPlayerIndex].redCards - 1)
                default:
                    break
                }
            }
            
            // Update in substituted players
            if let substitutedPlayerIndex = participant.substitutedPlayers.firstIndex(where: { $0.id == event.player.id }) {
                switch event.eventType {
                case .goal:
                    gameSession.participants[playerIndex].substitutedPlayers[substitutedPlayerIndex].goals = max(0, gameSession.participants[playerIndex].substitutedPlayers[substitutedPlayerIndex].goals - 1)
                case .assist:
                    gameSession.participants[playerIndex].substitutedPlayers[substitutedPlayerIndex].assists = max(0, gameSession.participants[playerIndex].substitutedPlayers[substitutedPlayerIndex].assists - 1)
                case .yellowCard:
                    gameSession.participants[playerIndex].substitutedPlayers[substitutedPlayerIndex].yellowCards = max(0, gameSession.participants[playerIndex].substitutedPlayers[substitutedPlayerIndex].yellowCards - 1)
                case .redCard:
                    gameSession.participants[playerIndex].substitutedPlayers[substitutedPlayerIndex].redCards = max(0, gameSession.participants[playerIndex].substitutedPlayers[substitutedPlayerIndex].redCards - 1)
                default:
                    break
                }
            }
        }
    }
    
    private func applyEventEffects(_ event: GameEvent) {
        // Find the bet for this event type
        guard let bet = gameSession.bets.first(where: { $0.eventType == event.eventType }) else { return }
        
        // Find participants who have the player (include both active and substituted players)
        let participantsWithPlayer = gameSession.participants.filter { participant in
            participant.selectedPlayers.contains { $0.id == event.player.id } ||
            participant.substitutedPlayers.contains { $0.id == event.player.id }
        }
        
        // Find participants who don't have the player
        let participantsWithoutPlayer = gameSession.participants.filter { participant in
            !participant.selectedPlayers.contains { $0.id == event.player.id } &&
            !participant.substitutedPlayers.contains { $0.id == event.player.id }
        }
        
        if participantsWithPlayer.isEmpty || participantsWithoutPlayer.isEmpty {
            return
        }
        
        // Apply balance changes using EXACT GameSession logic
        if bet.amount >= 0 {
            // Positive bet: participants WITHOUT player pay those WITH player
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
            // Negative bet: participants WITH player pay those WITHOUT player
            let payAmount = abs(bet.amount)
            
            for i in 0..<gameSession.participants.count {
                let hasPlayer = gameSession.participants[i].selectedPlayers.contains { $0.id == event.player.id } ||
                gameSession.participants[i].substitutedPlayers.contains { $0.id == event.player.id }
                
                if hasPlayer {
                    // Player owner pays payAmount to EACH other participant
                    gameSession.participants[i].balance -= payAmount * Double(participantsWithoutPlayer.count)
                } else {
                    // Each other participant receives payAmount from EACH player owner
                    gameSession.participants[i].balance += payAmount * Double(participantsWithPlayer.count)
                }
            }
        }
        
        // Apply player stats using the same logic as GameSession.recordEvent
        if let playerIndex = gameSession.participants.firstIndex(where: { participant in
            participant.selectedPlayers.contains { $0.id == event.player.id } ||
            participant.substitutedPlayers.contains { $0.id == event.player.id }
        }) {
            let participant = gameSession.participants[playerIndex]
            
            // Update in selected players
            if let selectedPlayerIndex = participant.selectedPlayers.firstIndex(where: { $0.id == event.player.id }) {
                switch event.eventType {
                case .goal:
                    gameSession.participants[playerIndex].selectedPlayers[selectedPlayerIndex].goals += 1
                case .assist:
                    gameSession.participants[playerIndex].selectedPlayers[selectedPlayerIndex].assists += 1
                case .yellowCard:
                    gameSession.participants[playerIndex].selectedPlayers[selectedPlayerIndex].yellowCards += 1
                case .redCard:
                    gameSession.participants[playerIndex].selectedPlayers[selectedPlayerIndex].redCards += 1
                default:
                    break
                }
            }
            
            // Update in substituted players
            if let substitutedPlayerIndex = participant.substitutedPlayers.firstIndex(where: { $0.id == event.player.id }) {
                switch event.eventType {
                case .goal:
                    gameSession.participants[playerIndex].substitutedPlayers[substitutedPlayerIndex].goals += 1
                case .assist:
                    gameSession.participants[playerIndex].substitutedPlayers[substitutedPlayerIndex].assists += 1
                case .yellowCard:
                    gameSession.participants[playerIndex].substitutedPlayers[substitutedPlayerIndex].yellowCards += 1
                case .redCard:
                    gameSession.participants[playerIndex].substitutedPlayers[substitutedPlayerIndex].redCards += 1
                default:
                    break
                }
            }
        }
    }
}

// MARK: - Editable Timeline Event Row

struct EditableTimelineEventRow: View {
    let event: GameEvent
    @ObservedObject var gameSession: GameSession
    let index: Int
    let isFirst: Bool
    let onEventTap: (GameEvent) -> Void
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Button(action: {
            onEventTap(event)
        }) {
            HStack(spacing: 16) {
                // Timeline indicator
                VStack {
                    if !isFirst {
                        Rectangle()
                            .fill(AppDesignSystem.Colors.primary.opacity(0.3))
                            .frame(width: 2, height: 20)
                    }
                    
                    Circle()
                        .fill(eventColor)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                    
                    Rectangle()
                        .fill(AppDesignSystem.Colors.primary.opacity(0.3))
                        .frame(width: 2, height: 30)
                }
                
                // Event content
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        // Event icon and type
                        HStack(spacing: 8) {
                            Image(systemName: eventIcon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(eventColor)
                            
                            // FIXED: Use proper display name instead of rawValue
                            Text(gameSession.getEventDisplayName(for: event))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                        }
                        
                        Spacer()
                        
                        // Time and edit indicator
                        HStack(spacing: 8) {
                            Text(timeFormatter.string(from: event.timestamp))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            
                            Image(systemName: "pencil.circle")
                                .font(.system(size: 16))
                                .foregroundColor(AppDesignSystem.Colors.primary)
                        }
                    }
                    
                    // Player info
                    HStack(spacing: 12) {
                        // Team color indicator
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppDesignSystem.TeamColors.getColor(for: event.player.team))
                            .frame(width: 4, height: 20)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.player.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Text("\(event.player.team.shortName) • \(event.player.position.rawValue)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        // Participant who owns this player
                        if let participant = participantForPlayer(event.player) {
                            Text(participant.name)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.primary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppDesignSystem.Colors.primary.opacity(0.1))
                                .cornerRadius(6)
                        }
                    }
                    
                    // Impact indicator
                    if let bet = gameSession.bets.first(where: { $0.eventType == event.eventType }) {
                        HStack(spacing: 4) {
                            Image(systemName: bet.amount > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(bet.amount > 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                            
                            Text(formatCurrency(abs(bet.amount)))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(bet.amount > 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                        }
                    }
                }
                .padding(.vertical, 12)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(eventColor.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.bottom, 8)
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
    
    private func participantForPlayer(_ player: Player) -> Participant? {
        return gameSession.participants.first { participant in
            participant.selectedPlayers.contains { $0.id == player.id } ||
            participant.substitutedPlayers.contains { $0.id == player.id }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}

// MARK: - Edit Event View

struct EditEventView: View {
    @ObservedObject var gameSession: GameSession
    let event: GameEvent
    let onSave: (GameEvent) -> Void
    
    @State private var selectedEventType: Bet.EventType
    @State private var selectedPlayer: Player
    @Environment(\.presentationMode) var presentationMode
    
    init(gameSession: GameSession, event: GameEvent, onSave: @escaping (GameEvent) -> Void) {
        self.gameSession = gameSession
        self.event = event
        self.onSave = onSave
        self._selectedEventType = State(initialValue: event.eventType)
        self._selectedPlayer = State(initialValue: event.player)
    }
    
    // MARK: - Player Selection Section
    private var playerSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Player")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            participantPlayersList
        }
    }
    
    private var participantPlayersList: some View {
        ForEach(gameSession.participants) { participant in
            if !participant.selectedPlayers.isEmpty {
                participantPlayersGroup(participant)
            }
        }
    }
    
    private func participantPlayersGroup(_ participant: Participant) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(participant.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.primary)
            
            playerGridForParticipant(participant)
        }
    }
    
    private func playerGridForParticipant(_ participant: Participant) -> some View {
        LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
            ForEach(participant.selectedPlayers) { player in
                PlayerSelectionCard(
                    player: player,
                    isSelected: selectedPlayer.id == player.id
                ) {
                    selectedPlayer = player
                }
            }
        }
    }
    
    // MARK: - Event Type Selection Section
    private var eventTypeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Event Type")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            eventTypeGrid
        }
    }
    
    private var eventTypeGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            ForEach(Bet.EventType.allCases, id: \.self) { eventType in
                EventTypeSelectionCard(
                    eventType: eventType,
                    isSelected: selectedEventType == eventType
                ) {
                    selectedEventType = eventType
                }
            }
        }
    }
    
    // MARK: - Save Button Section
    private var saveButtonSection: some View {
        Button("Save Changes") {
            saveEditedEvent()
        }
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(.white)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity)
        .background(AppDesignSystem.Colors.primary)
        .cornerRadius(12)
        .disabled(isButtonDisabled)
    }
    
    private var isButtonDisabled: Bool {
        selectedPlayer.id == event.player.id && selectedEventType == event.eventType
    }
    
    private func saveEditedEvent() {
        let editedEvent = GameEvent(
            player: selectedPlayer,
            eventType: selectedEventType,
            timestamp: event.timestamp // Keep same timestamp
        )
        
        onSave(editedEvent)
        presentationMode.wrappedValue.dismiss()
    }
    
    // MARK: - Updated Main Body
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    playerSelectionSection
                    eventTypeSelectionSection
                    saveButtonSection
                }
                .padding(24)
            }
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
