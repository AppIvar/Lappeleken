//
//  LiveSetupComponents.swift
//  Lucky Football Slip
//
//  Apple Sports-inspired UI components for Live Game Setup
//

import SwiftUI

// MARK: - Data Structures

struct DateGroup {
    let date: Date
    let matches: [Match]
}


// MARK: - Match Selection Card
// Note: Use AppleSportsMatchCard from MatchComponents.swift instead
// This is kept for backward compatibility only
typealias MatchSelectionCard = AppleSportsMatchCard

// MARK: - Participant Card (Setup)

struct SetupParticipantCard: View {
    let participant: Participant
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.primary.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text(String(participant.name.prefix(1).uppercased()))
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primary)
            }
            
            // Name
            Text(participant.name)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(8)
                    .background(AppDesignSystem.Colors.error.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
    }
}

// Legacy alias
typealias EnhancedParticipantCard = SetupParticipantCard

// MARK: - Player Selection Components

struct FullSquadTeamSection: View {
    let team: Team
    let players: [Player]
    @Binding var selectedPlayerIds: Set<UUID>
    let onSelectTeam: () -> Void
    let onTogglePlayer: (Player) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppDesignSystem.TeamColors.getColor(for: team))
                    .frame(width: 4, height: 24)
                
                Text(team.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
                
                Text("Full Squad")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Text("(\(players.count))")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.tertiaryText)
                
                Spacer()
                
                Button(action: onSelectTeam) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("All")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppDesignSystem.Colors.primary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall))
            
            // Players
            VStack(spacing: 6) {
                ForEach(players, id: \.id) { player in
                    SelectablePlayerRow(
                        player: player,
                        isSelected: selectedPlayerIds.contains(player.id),
                        badge: "Squad",
                        badgeColor: AppDesignSystem.Colors.primary,
                        onToggle: { onTogglePlayer(player) }
                    )
                }
            }
        }
    }
}

struct StartingXITeamSection: View {
    let team: Team
    let players: [Player]
    @Binding var selectedPlayerIds: Set<UUID>
    let onSelectTeam: () -> Void
    let onTogglePlayer: (Player) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppDesignSystem.TeamColors.getColor(for: team))
                    .frame(width: 4, height: 24)
                
                Text(team.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
                
                Text("Starting XI")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.success)
                
                Text("(\(players.count))")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.tertiaryText)
                
                Spacer()
                
                Button(action: onSelectTeam) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("All")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(AppDesignSystem.Colors.success)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppDesignSystem.Colors.success.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall))
            
            // Players
            VStack(spacing: 6) {
                ForEach(players, id: \.id) { player in
                    SelectablePlayerRow(
                        player: player,
                        isSelected: selectedPlayerIds.contains(player.id),
                        badge: "XI",
                        badgeColor: AppDesignSystem.Colors.success,
                        onToggle: { onTogglePlayer(player) }
                    )
                }
            }
        }
    }
}

struct SubstituteTeamSection: View {
    let team: Team
    let players: [Player]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppDesignSystem.TeamColors.getColor(for: team))
                    .frame(width: 4, height: 24)
                
                Text(team.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
                
                Text("Substitutes")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.warning)
                
                Text("(\(players.count))")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.tertiaryText)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(AppDesignSystem.Colors.warning.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall))
            
            // Info
            Text("Substitutes are available for Live Mode automatic substitution tracking")
                .font(.system(size: 12))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .padding(.horizontal, 12)
            
            // Players (view only)
            VStack(spacing: 6) {
                ForEach(players, id: \.id) { player in
                    HStack(spacing: 10) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppDesignSystem.TeamColors.getColor(for: team).opacity(0.5))
                            .frame(width: 3, height: 32)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(player.name)
                                .font(.system(size: 14))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            Text(player.position.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(AppDesignSystem.Colors.tertiaryText)
                        }
                        
                        Spacer()
                        
                        Text("SUB")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.warning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(AppDesignSystem.Colors.warning.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(AppDesignSystem.Colors.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall))
                }
            }
        }
    }
}

// MARK: - Selectable Player Row

struct SelectablePlayerRow: View {
    let player: Player
    let isSelected: Bool
    let badge: String
    let badgeColor: Color
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                // Team color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                    .frame(width: 3, height: 40)
                
                // Player info
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    HStack(spacing: 6) {
                        Text(player.position.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Text(badge)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(badgeColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(badgeColor.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? badgeColor : AppDesignSystem.Colors.tertiaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall)
                    .fill(isSelected ? badgeColor.opacity(0.08) : AppDesignSystem.Colors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Legacy aliases
typealias FullSquadPlayerCard = SelectablePlayerRow
typealias StartingXIPlayerCard = SelectablePlayerRow

// MARK: - Helper Functions

func playerCardBackground(isSelected: Bool, color: Color) -> some View {
    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall)
        .fill(isSelected ? color.opacity(0.08) : AppDesignSystem.Colors.cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall)
                .stroke(isSelected ? color.opacity(0.3) : Color.clear, lineWidth: 1)
        )
}

// MARK: - Status Components (Required by LiveGameSetupView)

struct RateLimitWarning: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .foregroundColor(AppDesignSystem.Colors.warning)
            Text("Rate limit reached. Updates paused temporarily.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall)
                .fill(AppDesignSystem.Colors.warning.opacity(0.1))
        )
    }
}

struct LiveConnectionStatus: View {
    let isConnected: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                .frame(width: 8, height: 8)
            
            Text(isConnected ? "Connected" : "Disconnected")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(isConnected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
        }
    }
}

struct NextUpdateTimer: View {
    @State private var timeRemaining: Int = 90
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text("Next update in \(timeRemaining)s")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(AppDesignSystem.Colors.secondaryText)
            .onReceive(timer) { _ in
                if timeRemaining > 0 {
                    timeRemaining -= 1
                } else {
                    timeRemaining = 90
                }
            }
    }
}

// MARK: - League Access Badge Helper

@ViewBuilder
func leagueAccessBadge(for status: LeagueAccessStatus) -> some View {
    switch status {
    case .unlocked(let reason):
        switch reason {
        case .premium:
            accessBadgeView(text: "PRO", icon: "crown.fill", color: AppDesignSystem.Colors.goalYellow)
        case .leagueSubscription:
            accessBadgeView(text: "SUB", icon: "checkmark.seal.fill", color: AppDesignSystem.Colors.success)
        case .freeLeague:
            accessBadgeView(text: "FREE", icon: "gift.fill", color: AppDesignSystem.Colors.primary)
        case .testingMode:
            accessBadgeView(text: "TEST", icon: "hammer.fill", color: AppDesignSystem.Colors.accent)
        default:
            EmptyView()
        }
        
    case .limitedFree(let remaining):
        accessBadgeView(text: "\(remaining) left", icon: "ticket.fill", color: AppDesignSystem.Colors.warning)
        
    case .locked(_):
        accessBadgeView(text: "LOCKED", icon: "lock.fill", color: AppDesignSystem.Colors.error)
    }
}

private func accessBadgeView(text: String, icon: String, color: Color) -> some View {
    Label(text, systemImage: icon)
        .font(.system(size: 10, weight: .semibold))
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.15))
        .clipShape(Capsule())
}
