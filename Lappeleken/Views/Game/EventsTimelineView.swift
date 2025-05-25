//
//  EventsTimelineView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 22/05/2025.
//

import SwiftUI

struct EventsTimelineView: View {
    @ObservedObject var gameSession: GameSession
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                if gameSession.events.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "clock")
                            .font(.system(size: 60))
                            .foregroundColor(AppDesignSystem.Colors.secondary)
                        
                        Text("No Events Yet")
                            .font(AppDesignSystem.Typography.headingFont)
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Match events will appear here as they happen during the game.")
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
                    let sortedEvents = gameSession.events.sorted(by: { $0.timestamp > $1.timestamp })
                    
                    ForEach(Array(sortedEvents.enumerated()), id: \.element.id) { index, event in
                        EventRow(event: event, gameSession: gameSession)
                        
                        if index < sortedEvents.count - 1 {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct EventRow: View {
    let event: GameEvent
    let gameSession: GameSession
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Event icon
            Image(systemName: iconForEvent(event.eventType))
                .font(.system(size: 20))
                .foregroundColor(colorForEvent(event.eventType))
                .frame(width: 30, height: 30)
                .background(colorForEvent(event.eventType).opacity(0.2))
                .cornerRadius(15)
            
            VStack(alignment: .leading, spacing: 4) {
                // Event title
                Text(titleForEvent(event))
                    .font(AppDesignSystem.Typography.bodyFont.bold())
                
                // Player name and team
                HStack {
                    Text(event.player.name)
                        .font(AppDesignSystem.Typography.bodyFont)
                    
                    Text("(\(event.player.team.shortName))")
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                // Show which participant owns this player
                if let participant = participantForPlayer(event.player) {
                    Text("Owned by: \(participant.name)")
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.primary)
                } else {
                    Text("Unowned player")
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .italic()
                }
                
                // Timestamp
                Text(formatTimestamp(event.timestamp))
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Points earned/lost (if applicable)
            if let bet = gameSession.bets.first(where: { $0.eventType == event.eventType }) {
                VStack {
                    Text(bet.amount >= 0 ? "+\(formatCurrency(bet.amount))" : "\(formatCurrency(bet.amount))")
                        .font(AppDesignSystem.Typography.captionFont.bold())
                        .foregroundColor(bet.amount >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    // Helper functions
    private func participantForPlayer(_ player: Player) -> Participant? {
        return gameSession.participants.first { participant in
            participant.selectedPlayers.contains { $0.id == player.id } ||
            participant.substitutedPlayers.contains { $0.id == player.id }
        }
    }
    
    private func iconForEvent(_ eventType: Bet.EventType) -> String {
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
    
    private func colorForEvent(_ eventType: Bet.EventType) -> Color {
        switch eventType {
        case .goal, .assist: return AppDesignSystem.Colors.success
        case .yellowCard: return Color.yellow
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.warning
        case .penalty: return AppDesignSystem.Colors.primary
        case .cleanSheet: return Color.blue
        case .custom: return AppDesignSystem.Colors.secondary
        }
    }
    
    private func titleForEvent(_ event: GameEvent) -> String {
        switch event.eventType {
        case .goal: return "Goal"
        case .assist: return "Assist"
        case .yellowCard: return "Yellow Card"
        case .redCard: return "Red Card"
        case .ownGoal: return "Own Goal"
        case .penalty: return "Penalty Scored"
        case .penaltyMissed: return "Penalty Missed"
        case .cleanSheet: return "Clean Sheet"
        case .custom:
            // Try to get custom bet name
            let customBetName = gameSession.customBetNames.values.first ?? "Custom Event"
            return customBetName
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}
