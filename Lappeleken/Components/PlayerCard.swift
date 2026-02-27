//
//  PlayerCard.swift
//  Lucky Football Slip
//
//  Apple Sports-inspired clean player card
//

import SwiftUI

// MARK: - Player Selection Card (for setup flows)

struct PlayerCard: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Team color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                    .frame(width: 4, height: 50)
                
                // Player avatar
                ZStack {
                    Circle()
                        .fill(AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    if let firstLetter = player.name.first {
                        Text(String(firstLetter).uppercased())
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.TeamColors.getColor(for: player.team))
                    }
                }
                
                // Player info
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(player.team.shortName)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(AppDesignSystem.TeamColors.getColor(for: player.team))
                        
                        Text("•")
                            .foregroundColor(AppDesignSystem.Colors.tertiaryText)
                        
                        Text(player.position.rawValue)
                            .font(.system(size: 13))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    // Stats row (if any)
                    if hasStats {
                        statsRow
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppDesignSystem.Colors.success)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .fill(isSelected ? AppDesignSystem.Colors.selected : AppDesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .stroke(
                        isSelected ? AppDesignSystem.Colors.primary : Color.clear,
                        lineWidth: 2
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var hasStats: Bool {
        player.goals > 0 || player.assists > 0 || player.yellowCards > 0 || player.redCards > 0
    }
    
    private var statsRow: some View {
        HStack(spacing: 8) {
            if player.goals > 0 {
                StatPill(icon: "soccerball", count: player.goals, color: AppDesignSystem.Colors.success)
            }
            if player.assists > 0 {
                StatPill(icon: "arrow.up.forward", count: player.assists, color: AppDesignSystem.Colors.info)
            }
            if player.yellowCards > 0 {
                StatPill(icon: "square.fill", count: player.yellowCards, color: AppDesignSystem.Colors.warning)
            }
            if player.redCards > 0 {
                StatPill(icon: "square.fill", count: player.redCards, color: AppDesignSystem.Colors.error)
            }
        }
    }
    
    private func positionIcon(for position: Player.Position) -> String {
        switch position {
        case .goalkeeper: return "hand.raised.fill"
        case .defender: return "shield.fill"
        case .midfielder: return "circle.hexagongrid.fill"
        case .forward: return "star.fill"
        }
    }
}

// MARK: - Compact Player Row (for lists)

struct CompactPlayerCard: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                // Team color indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                    .frame(width: 3, height: 36)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .lineLimit(1)
                    
                    Text("\(player.team.shortName) • \(player.position.rawValue)")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppDesignSystem.Colors.success)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 20))
                        .foregroundColor(AppDesignSystem.Colors.tertiaryText)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall)
                    .fill(isSelected ? AppDesignSystem.Colors.selected : AppDesignSystem.Colors.cardBackground)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Participant Card (for game setup)

struct ParticipantCard: View {
    let participant: Participant
    let currencySymbol: String
    
    init(participant: Participant, currencySymbol: String = "$") {
        self.participant = participant
        self.currencySymbol = currencySymbol
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                if let firstLetter = participant.name.first {
                    Text(String(firstLetter).uppercased())
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(participant.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                HStack(spacing: 8) {
                    Label("\(participant.selectedPlayers.count) players", systemImage: "person.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    if !participant.substitutedPlayers.isEmpty {
                        Label("\(participant.substitutedPlayers.count) subbed", systemImage: "arrow.left.arrow.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.warning)
                    }
                }
            }
            
            Spacer()
            
            // Balance
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(participant.balance))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(balanceColor)
                
                if participant.balance != 0 {
                    Text(participant.balance > 0 ? "Winning" : "Losing")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(balanceColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
    }
    
    private var balanceColor: Color {
        if participant.balance > 0 { return AppDesignSystem.Colors.success }
        if participant.balance < 0 { return AppDesignSystem.Colors.error }
        return AppDesignSystem.Colors.secondaryText
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currencySymbol
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "\(currencySymbol)0"
    }
}

// MARK: - Event Card

struct EventCard: View {
    let event: GameEvent
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        HStack(spacing: 12) {
            // Event icon
            ZStack {
                Circle()
                    .fill(eventColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: eventIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(eventColor)
            }
            
            // Event info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.eventType.rawValue)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    if let minute = event.minute {
                        Text("\(minute)'")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(eventColor)
                            .clipShape(Capsule())
                    }
                }
                
                Text(event.player.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: event.player.team))
                
                Text("\(event.player.team.shortName) • \(event.player.position.rawValue)")
                    .font(.system(size: 12))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
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
        case .yellowCard, .redCard: return "square.fill"
        case .ownGoal: return "arrow.uturn.backward"
        case .penalty: return "p.circle"
        case .penaltyMissed: return "p.circle.fill"
        case .cleanSheet: return "lock.shield"
        case .custom: return "star"
        }
    }
}

// MARK: - Stat Pill (shared component)

struct StatPill: View {
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
            Text("\(count)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }
}

// MARK: - Legacy Support

// Alias for backward compatibility
typealias StatBadge = StatPill
