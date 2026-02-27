//
//  MatchStatsView.swift
//  Lucky Football Slip
//
//  Football themed match statistics view
//

import SwiftUI

struct MatchStatsView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Participant standings
                standingsSection
                
                // Top performers
                topPerformersSection
                
                // Event summary
                eventSummarySection
            }
            .padding(16)
        }
        .background(footballBackground)
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            
            VStack {
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.08 : 0.04),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Standings Section
    
    private var standingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatsSectionHeader(title: "Standings", icon: "trophy.fill", color: AppDesignSystem.Colors.goalYellow)
            
            let sortedParticipants = gameSession.participants.sorted { $0.balance > $1.balance }
            
            VStack(spacing: 0) {
                ForEach(Array(sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                    StandingRow(participant: participant, position: index + 1)
                    
                    if index < sortedParticipants.count - 1 {
                        Divider()
                            .padding(.horizontal, 12)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppDesignSystem.Colors.cardBackground)
            )
        }
    }
    
    // MARK: - Top Performers
    
    private var topPerformersSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatsSectionHeader(title: "Top Performers", icon: "star.fill", color: AppDesignSystem.Colors.accent)
            
            let hasStats = gameSession.availablePlayers.contains { $0.goals > 0 || $0.assists > 0 || $0.yellowCards > 0 || $0.redCards > 0 }
            
            if hasStats {
                VStack(spacing: 8) {
                    if let topScorer = gameSession.availablePlayers.max(by: { $0.goals < $1.goals }), topScorer.goals > 0 {
                        PerformerRow(
                            title: "Top Scorer",
                            player: topScorer,
                            stat: "\(topScorer.goals) goal\(topScorer.goals == 1 ? "" : "s")",
                            icon: "soccerball",
                            color: AppDesignSystem.Colors.grassGreen
                        )
                    }
                    
                    if let topAssister = gameSession.availablePlayers.max(by: { $0.assists < $1.assists }), topAssister.assists > 0 {
                        PerformerRow(
                            title: "Most Assists",
                            player: topAssister,
                            stat: "\(topAssister.assists) assist\(topAssister.assists == 1 ? "" : "s")",
                            icon: "arrow.up.forward",
                            color: AppDesignSystem.Colors.info
                        )
                    }
                    
                    let mostCarded = gameSession.availablePlayers.max { ($0.yellowCards + $0.redCards) < ($1.yellowCards + $1.redCards) }
                    if let cardedPlayer = mostCarded, (cardedPlayer.yellowCards + cardedPlayer.redCards) > 0 {
                        PerformerRow(
                            title: "Most Cards",
                            player: cardedPlayer,
                            stat: "\(cardedPlayer.yellowCards + cardedPlayer.redCards) card\((cardedPlayer.yellowCards + cardedPlayer.redCards) == 1 ? "" : "s")",
                            icon: "square.fill",
                            color: AppDesignSystem.Colors.goalYellow
                        )
                    }
                }
            } else {
                emptyPerformersView
            }
        }
    }
    
    private var emptyPerformersView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 24))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
                
                Text("No stats yet")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding(.vertical, 20)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
    }
    
    // MARK: - Event Summary
    
    private var eventSummarySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            StatsSectionHeader(title: "Event Summary", icon: "list.bullet.clipboard", color: AppDesignSystem.Colors.grassGreen)
            
            if gameSession.events.isEmpty {
                emptyEventsView
            } else {
                let eventCounts = Dictionary(grouping: gameSession.events, by: { $0.eventType })
                    .mapValues { $0.count }
                
                VStack(spacing: 0) {
                    ForEach(Bet.EventType.allCases, id: \.self) { eventType in
                        if let count = eventCounts[eventType], count > 0 {
                            EventCountRow(eventType: eventType, count: count)
                            
                            if eventType != Bet.EventType.allCases.filter({ eventCounts[$0] ?? 0 > 0 }).last {
                                Divider()
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppDesignSystem.Colors.cardBackground)
                )
            }
        }
    }
    
    private var emptyEventsView: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "clock")
                    .font(.system(size: 24))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
                
                Text("No events recorded yet")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding(.vertical, 20)
            Spacer()
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
    }
}

// MARK: - Stats Section Header

struct StatsSectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
        }
    }
}

// MARK: - Standing Row

struct StandingRow: View {
    let participant: Participant
    let position: Int
    
    private var positionColor: Color {
        switch position {
        case 1: return AppDesignSystem.Colors.goalYellow
        case 2: return AppDesignSystem.Colors.secondaryText
        case 3: return AppDesignSystem.Colors.accent
        default: return AppDesignSystem.Colors.secondaryText.opacity(0.6)
        }
    }
    
    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Position badge
            ZStack {
                Circle()
                    .fill(positionColor.opacity(position <= 3 ? 0.15 : 0.08))
                    .frame(width: 28, height: 28)
                
                Text("\(position)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(positionColor)
            }
            
            Text(participant.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Text("\(participant.balance >= 0 ? "+" : "")\(currencySymbol)\(String(format: "%.2f", participant.balance))")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.error)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

// MARK: - Performer Row

struct PerformerRow: View {
    let title: String
    let player: Player
    let stat: String
    let icon: String
    let color: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Text(player.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            
            Spacer()
            
            Text(stat)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
    }
}

// MARK: - Event Count Row

struct EventCountRow: View {
    let eventType: Bet.EventType
    let count: Int
    
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
    
    private var eventColor: Color {
        switch eventType {
        case .goal, .assist: return AppDesignSystem.Colors.grassGreen
        case .yellowCard: return AppDesignSystem.Colors.goalYellow
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.warning
        case .penalty: return AppDesignSystem.Colors.info
        case .cleanSheet: return AppDesignSystem.Colors.info
        case .custom: return AppDesignSystem.Colors.accent
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: eventIcon)
                .font(.system(size: 14))
                .foregroundColor(eventColor)
                .frame(width: 20)
            
            Text(eventType.rawValue.capitalized)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(eventColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
