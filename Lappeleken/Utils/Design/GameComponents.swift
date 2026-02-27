//
//  GameComponents.swift
//  Lucky Football Slip
//
//  Apple Sports-inspired components for the game view
//

import SwiftUI

// MARK: - Game Stat Card (Apple Sports Style)
// Note: This replaces the existing GameStatCard - delete old one from GameView.swift

struct AppleStyleStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(color)
            
            // Value
            Text(value)
                .font(AppDesignSystem.Typography.scoreMedium)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            // Title
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppDesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium))
    }
}

// MARK: - Participant Standing Row (Apple Sports Style)

struct ParticipantStandingRow: View {
    let participant: Participant
    let position: Int
    let currencySymbol: String
    
    init(participant: Participant, position: Int, currencySymbol: String = "$") {
        self.participant = participant
        self.position = position
        self.currencySymbol = currencySymbol
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Position badge
            positionBadge
            
            // Avatar
            participantAvatar
            
            // Name & players count
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("\(participant.selectedPlayers.count) players")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Balance
            balanceView
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .fill(position == 1 ? AppDesignSystem.Colors.success.opacity(0.08) : Color.clear)
        )
    }
    
    // MARK: - Position Badge
    
    private var positionBadge: some View {
        ZStack {
            if position <= 3 {
                Circle()
                    .fill(positionColor)
                    .frame(width: 28, height: 28)
                
                Text("\(position)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            } else {
                Text("\(position)")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .frame(width: 28, height: 28)
            }
        }
    }
    
    private var positionColor: Color {
        switch position {
        case 1: return AppDesignSystem.Colors.success
        case 2: return AppDesignSystem.Colors.primary
        case 3: return AppDesignSystem.Colors.warning
        default: return AppDesignSystem.Colors.disabled
        }
    }
    
    // MARK: - Avatar
    
    private var participantAvatar: some View {
        ZStack {
            Circle()
                .fill(AppDesignSystem.Colors.primary.opacity(0.15))
                .frame(width: 40, height: 40)
            
            if let first = participant.name.first {
                Text(String(first).uppercased())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primary)
            }
        }
    }
    
    // MARK: - Balance
    
    private var balanceView: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(formatCurrency(participant.balance))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(balanceColor)
            
            if participant.balance != 0 {
                Text(participant.balance > 0 ? "Winning" : "Losing")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(balanceColor)
            }
        }
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

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let style: Style
    let action: () -> Void
    
    enum Style {
        case primary   // Filled background
        case secondary // Tinted background
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(style == .primary ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall)
                    .fill(style == .primary ? color : color.opacity(0.12))
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Event Row (Compact) - Named differently to avoid conflict with existing

struct GameEventRow: View {
    let event: GameEvent
    let gameSession: GameSession
    
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
    
    var body: some View {
        HStack(spacing: 12) {
            // Event icon
            ZStack {
                Circle()
                    .fill(eventColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: eventIcon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(eventColor)
            }
            
            // Event info
            VStack(alignment: .leading, spacing: 2) {
                Text(gameSession.getEventDisplayName(for: event))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(event.player.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Time
            Text(formatTime(event.timestamp))
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .foregroundColor(AppDesignSystem.Colors.tertiaryText)
        }
        .padding(.vertical, 8)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Player Game Card (Simplified)

struct PlayerGameCard: View {
    let player: Player
    let isActive: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Team color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                    .frame(width: 4, height: 44)
                
                // Player info
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(isActive ? AppDesignSystem.Colors.primaryText : AppDesignSystem.Colors.tertiaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(player.team.shortName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppDesignSystem.TeamColors.getColor(for: player.team))
                        
                        Text("•")
                            .foregroundColor(AppDesignSystem.Colors.tertiaryText)
                        
                        Text(player.position.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Stats (if any)
                if hasStats {
                    statsView
                }
                
                // Status indicator
                if !isActive {
                    StatusBadge("SUB", color: AppDesignSystem.Colors.warning, style: .soft)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall)
                    .fill(isActive ? AppDesignSystem.Colors.cardBackground : AppDesignSystem.Colors.disabled.opacity(0.1))
            )
            .opacity(isActive ? 1.0 : 0.7)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isActive)
    }
    
    private var hasStats: Bool {
        player.goals > 0 || player.assists > 0 || player.yellowCards > 0 || player.redCards > 0
    }
    
    private var statsView: some View {
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
}

// Note: StatPill is defined in PlayerCard.swift
// Note: StatBadge is defined in TeamLineupView.swift

// MARK: - Section Header

struct GameSectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    
    init(_ title: String, subtitle: String? = nil, icon: String? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primary)
            }
            
            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
}

// MARK: - Participant Players Section

struct ParticipantPlayersSection: View {
    let participant: Participant
    let gameSession: GameSession
    let onPlayerTap: (Player) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                // Avatar
                ZStack {
                    Circle()
                        .fill(AppDesignSystem.Colors.primary.opacity(0.15))
                        .frame(width: 32, height: 32)
                    
                    if let first = participant.name.first {
                        Text(String(first).uppercased())
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppDesignSystem.Colors.primary)
                    }
                }
                
                Text(participant.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                // Balance
                Text(formatCurrency(participant.balance))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(
                        participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error
                    )
            }
            .padding(.horizontal, 16)
            
            // Players
            VStack(spacing: 4) {
                ForEach(participant.selectedPlayers) { player in
                    PlayerGameCard(
                        player: player,
                        isActive: SubstitutionManager.shared.isPlayerActive(player),
                        onTap: { onPlayerTap(player) }
                    )
                }
                
                // Substituted players
                if !participant.substitutedPlayers.isEmpty {
                    ForEach(participant.substitutedPlayers) { player in
                        PlayerGameCard(
                            player: player,
                            isActive: false,
                            onTap: {}
                        )
                    }
                }
            }
        }
        .padding(.vertical, 16)
        .background(AppDesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium))
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "selectedCurrencySymbol") ?? "$"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$0"
    }
}

// Note: MissedEventsBanner is already defined in GameView.swift
