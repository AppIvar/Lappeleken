//
//  GameViewComponents.swift
//  Lucky Football Slip
//
//  Extracted components from GameView to help compiler type-checking
//

import SwiftUI

// MARK: - Record Event Sheet (Extracted)

struct RecordEventSheet: View {
    @ObservedObject var gameSession: GameSession
    @Binding var selectedPlayer: Player?
    @Binding var selectedEventType: Bet.EventType?
    @Binding var selectedCustomEventName: String?
    @Binding var isPresented: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    if gameSession.participants.flatMap({ $0.selectedPlayers + $0.substitutedPlayers }).isEmpty {
                        emptyStateView
                    } else {
                        playerSelectionSection
                        
                        if selectedPlayer != nil {
                            eventTypeSelectionSection
                        }
                        
                        recordButtonSection
                    }
                }
                .padding(24)
            }
            .background(GameViewBackground())
            .navigationTitle("Record Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        closeSheet()
                    }
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.warning.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(AppDesignSystem.Colors.warning)
            }
            
            Text("No Players Available")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("Assign players to participants before recording events")
                .font(.system(size: 14))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    // MARK: - Player Selection
    
    private var playerSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Player")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            ForEach(gameSession.participants) { participant in
                if !participant.selectedPlayers.isEmpty {
                    ParticipantPlayersGroup(
                        participant: participant,
                        selectedPlayer: $selectedPlayer
                    )
                }
            }
        }
    }
    
    // MARK: - Event Type Selection
    
    private var eventTypeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Event Type")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            // Standard events grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(Bet.EventType.allCases.filter { $0 != .custom }, id: \.self) { eventType in
                    EventTypeCard(
                        eventType: eventType,
                        isSelected: selectedEventType == eventType && selectedCustomEventName == nil,
                        onTap: {
                            selectedEventType = eventType
                            selectedCustomEventName = nil
                        }
                    )
                }
            }
            
            // Custom events
            customEventsSection
        }
    }
    
    private var customEventsSection: some View {
        let customEvents = gameSession.getCustomEvents()
        
        return VStack(alignment: .leading, spacing: 12) {
            Text("Custom Events")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.accent)
                .padding(.top, 12)
            
            if customEvents.isEmpty {
                Text("No custom events available")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            } else {
                ForEach(customEvents, id: \.id) { customEvent in
                    CustomEventCard(
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
    
    // MARK: - Record Button
    
    private var recordButtonSection: some View {
        Group {
            if let player = selectedPlayer, canRecord {
                Button(action: recordEvent) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20))
                        
                        Text("Record \(eventDisplayName) for \(player.name)")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(AppDesignSystem.Colors.grassGreen)
                    .cornerRadius(12)
                    .shadow(color: AppDesignSystem.Colors.grassGreen.opacity(0.4), radius: 8, x: 0, y: 4)
                }
                .padding(.top, 8)
            }
        }
    }
    
    // MARK: - Helpers
    
    private var canRecord: Bool {
        (selectedEventType != nil && selectedEventType != .custom) ||
        (selectedEventType == .custom && selectedCustomEventName != nil)
    }
    
    private var eventDisplayName: String {
        if selectedEventType == .custom {
            return selectedCustomEventName ?? "Custom Event"
        }
        return selectedEventType?.rawValue ?? "Event"
    }
    
    private func recordEvent() {
        guard let player = selectedPlayer else { return }
        
        if selectedEventType == .custom, let customEventName = selectedCustomEventName {
            gameSession.recordCustomEvent(player: player, eventName: customEventName)
        } else if let eventType = selectedEventType {
            gameSession.recordEvent(player: player, eventType: eventType)
        }
        
        closeSheet()
    }
    
    private func closeSheet() {
        isPresented = false
        selectedPlayer = nil
        selectedEventType = nil
        selectedCustomEventName = nil
    }
}

// MARK: - Participant Players Group

struct ParticipantPlayersGroup: View {
    let participant: Participant
    @Binding var selectedPlayer: Player?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(participant.name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.grassGreen)
            
            ForEach(participant.selectedPlayers) { player in
                GamePlayerCard(
                    player: player,
                    isSelected: selectedPlayer?.id == player.id,
                    onTap: { selectedPlayer = player }
                )
            }
        }
    }
}

// MARK: - Game Player Card (for event recording)

struct GamePlayerCard: View {
    let player: Player
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Team color indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                    .frame(width: 4, height: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(player.position.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AppDesignSystem.Colors.grassGreen.opacity(0.1) : AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? AppDesignSystem.Colors.grassGreen : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Event Type Card

struct EventTypeCard: View {
    let eventType: Bet.EventType
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var eventIcon: String {
        switch eventType {
        case .goal: return "soccerball"
        case .assist: return "hand.point.right.fill"
        case .yellowCard: return "rectangle.portrait.fill"
        case .redCard: return "rectangle.portrait.fill"
        case .ownGoal: return "arrow.uturn.backward.circle"
        case .penaltyMissed: return "xmark.circle"
        case .custom: return "star.fill"
        default: return "circle"
        }
    }
    
    private var eventColor: Color {
        switch eventType {
        case .goal, .assist : return AppDesignSystem.Colors.grassGreen
        case .yellowCard: return AppDesignSystem.Colors.goalYellow
        case .redCard, .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.error
        default: return AppDesignSystem.Colors.primary
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? eventColor : eventColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: eventIcon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : eventColor)
                }
                
                Text(eventType.rawValue.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? eventColor : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(
                color: isSelected ? eventColor.opacity(0.3) : Color.clear,
                radius: 6,
                x: 0,
                y: 3
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Custom Event Card

struct CustomEventCard: View {
    let name: String
    let amount: Double
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppDesignSystem.Colors.accent : AppDesignSystem.Colors.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(isSelected ? .white : AppDesignSystem.Colors.accent)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    HStack(spacing: 4) {
                        Image(systemName: amount < 0 ? "minus.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(amount < 0 ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.grassGreen)
                        
                        Text("\(currencySymbol)\(String(format: "%.2f", abs(amount)))")
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? AppDesignSystem.Colors.accent : AppDesignSystem.Colors.accent.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Player Selection Card (for TimelineView edit mode)

struct PlayerSelectionCard: View {
    let player: Player
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var teamColor: Color {
        AppDesignSystem.TeamColors.getColor(for: player.team)
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Team color indicator
                RoundedRectangle(cornerRadius: 3)
                    .fill(teamColor)
                    .frame(width: 4, height: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(player.position.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AppDesignSystem.Colors.grassGreen.opacity(0.1) : AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? AppDesignSystem.Colors.grassGreen : teamColor.opacity(0.3),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Event Type Selection Card (for TimelineView)

struct EventTypeSelectionCard: View {
    let eventType: Bet.EventType
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    private var eventColor: Color {
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
    
    private var eventIcon: String {
        switch eventType {
        case .goal: return "soccerball"
        case .assist: return "hand.point.right.fill"
        case .yellowCard: return "rectangle.portrait.fill"
        case .redCard: return "rectangle.portrait.fill"
        case .ownGoal: return "arrow.uturn.backward.circle"
        case .penaltyMissed: return "xmark.circle"
        case .penalty: return "p.circle"
        case .cleanSheet: return "lock.shield"
        case .custom: return "star.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isSelected ? eventColor : eventColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: eventIcon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : eventColor)
                }
                
                Text(eventType.rawValue.capitalized)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? eventColor : Color.clear, lineWidth: 2)
                    )
            )
            .shadow(
                color: isSelected ? eventColor.opacity(0.3) : Color.clear,
                radius: 6,
                x: 0,
                y: 3
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Game View Background (Football themed)

struct GameViewBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    private var isDark: Bool { colorScheme == .dark }
    
    var body: some View {
        ZStack {
            // Base with green tint
            Color(isDark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            
            // Top green gradient
            VStack {
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.grassGreen.opacity(isDark ? 0.15 : 0.06),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
                
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
}
