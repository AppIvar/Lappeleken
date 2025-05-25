//
//  MatchStatsView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 22/05/2025.
//

import SwiftUI

struct MatchStatsView: View {
    @ObservedObject var gameSession: GameSession
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Participant standings
                ParticipantStandingsView(gameSession: gameSession)
                
                // Player performance stats
                PlayerPerformanceView(gameSession: gameSession)
                
                // Event summary
                EventSummaryView(gameSession: gameSession)
            }
            .padding()
        }
    }
}

struct ParticipantStandingsView: View {
    @ObservedObject var gameSession: GameSession
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Participant Standings")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                ForEach(gameSession.participants.sorted(by: { $0.balance > $1.balance })) { participant in
                    HStack {
                        // Position indicator
                        let position = gameSession.participants.sorted(by: { $0.balance > $1.balance }).firstIndex(where: { $0.id == participant.id })! + 1
                        
                        Text("\(position).")
                            .font(AppDesignSystem.Typography.bodyFont.bold())
                            .foregroundColor(positionColor(position))
                            .frame(width: 24, alignment: .leading)
                        
                        Text(participant.name)
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        Text(formatCurrency(participant.balance))
                            .font(AppDesignSystem.Typography.bodyFont.bold())
                            .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    private func positionColor(_ position: Int) -> Color {
        switch position {
        case 1: return AppDesignSystem.Colors.success
        case 2: return AppDesignSystem.Colors.primary
        case 3: return AppDesignSystem.Colors.secondary
        default: return AppDesignSystem.Colors.secondaryText
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}

struct PlayerPerformanceView: View {
    @ObservedObject var gameSession: GameSession
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Top Performers")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                // Top scorers
                if let topScorer = gameSession.availablePlayers.max(by: { $0.goals < $1.goals }), topScorer.goals > 0 {
                    PerformanceRow(
                        title: "Top Scorer",
                        player: topScorer,
                        stat: "\(topScorer.goals) goals",
                        icon: "soccerball",
                        color: AppDesignSystem.Colors.success
                    )
                }
                
                // Top assists
                if let topAssister = gameSession.availablePlayers.max(by: { $0.assists < $1.assists }), topAssister.assists > 0 {
                    PerformanceRow(
                        title: "Most Assists",
                        player: topAssister,
                        stat: "\(topAssister.assists) assists",
                        icon: "arrow.up.forward",
                        color: AppDesignSystem.Colors.primary
                    )
                }
                
                // Most carded
                let mostCarded = gameSession.availablePlayers.max { (player1, player2) in
                    let cards1 = player1.yellowCards + player1.redCards
                    let cards2 = player2.yellowCards + player2.redCards
                    return cards1 < cards2
                }
                
                if let cardedPlayer = mostCarded, (cardedPlayer.yellowCards + cardedPlayer.redCards) > 0 {
                    PerformanceRow(
                        title: "Most Cards",
                        player: cardedPlayer,
                        stat: "\(cardedPlayer.yellowCards + cardedPlayer.redCards) cards",
                        icon: "square.fill",
                        color: AppDesignSystem.Colors.warning
                    )
                }
                
                if gameSession.availablePlayers.allSatisfy({ $0.goals == 0 && $0.assists == 0 && $0.yellowCards == 0 && $0.redCards == 0 }) {
                    Text("No player statistics yet")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .italic()
                }
            }
        }
    }
}

struct PerformanceRow: View {
    let title: String
    let player: Player
    let stat: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Text(player.name)
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            
            Spacer()
            
            Text(stat)
                .font(AppDesignSystem.Typography.bodyFont.bold())
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

struct EventSummaryView: View {
    @ObservedObject var gameSession: GameSession
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Event Summary")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                if gameSession.events.isEmpty {
                    Text("No events recorded yet")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .italic()
                } else {
                    let eventCounts = Dictionary(grouping: gameSession.events, by: { $0.eventType })
                        .mapValues { $0.count }
                    
                    ForEach(Bet.EventType.allCases, id: \.self) { eventType in
                        if let count = eventCounts[eventType], count > 0 {
                            HStack {
                                Image(systemName: iconForEvent(eventType))
                                    .font(.system(size: 16))
                                    .foregroundColor(colorForEvent(eventType))
                                    .frame(width: 20)
                                
                                Text(eventType.rawValue)
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                
                                Spacer()
                                
                                Text("\(count)")
                                    .font(AppDesignSystem.Typography.bodyFont.bold())
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
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
}
