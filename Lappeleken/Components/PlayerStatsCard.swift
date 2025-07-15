//
//  PlayerStatsCard.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import SwiftUI

// Fixed PlayerStatsCard to correctly display player stats
struct PlayerStatsCard: View {
    // Pass the gameSession to be able to look up the latest player data
    let gameSession: GameSession
    let player: Player
    var isSubstituted: Bool = false
    
    @State private var showDetails = false
    
    // Get the latest player stats from the gameSession
    private var currentPlayerStats: (goals: Int, assists: Int, yellowCards: Int, redCards: Int) {
        // First check in available players (source of truth)
        if let updatedPlayer = gameSession.availablePlayers.first(where: { $0.id == player.id }) {
            return (updatedPlayer.goals, updatedPlayer.assists, updatedPlayer.yellowCards, updatedPlayer.redCards)
        }
        // Fall back to the provided player
        return (player.goals, player.assists, player.yellowCards, player.redCards)
    }
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppDesignSystem.Layout.smallPadding) {
                // Header with player name and substitution status
                Button(action: {
                    withAnimation(.spring()) {
                        showDetails.toggle()
                    }
                }) {
                    HStack {
                        Text(player.name)
                            .font(AppDesignSystem.Typography.subheadingFont)
                        
                        // Show substitution status if applicable
                        if isSubstituted {
                            Spacer()
                            
                            Text("Subbed Off")
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(AppDesignSystem.Colors.error)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppDesignSystem.Colors.error.opacity(0.1))
                                .cornerRadius(4)
                        } else if case .substitutedOn = player.substitutionStatus {
                            Spacer()
                            
                            Text("Subbed On")
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(AppDesignSystem.Colors.success)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppDesignSystem.Colors.success.opacity(0.1))
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        // Expand/collapse indicator
                        Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .font(.caption)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                // Expanded details section
                if showDetails {
                    VStack {
                        HStack {
                            // Team color indicator
                            Rectangle()
                                .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                                .frame(width: 4, height: 16)
                                .cornerRadius(2)
                            
                            // Team name and position
                            Text(player.team.name)
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            
                            Text("•")
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            
                            Text(player.position.rawValue)
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                        .padding(.vertical, 4)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                Divider()
                
                // Stats display - graphical UI with the latest stats
                let stats = currentPlayerStats
                HStack(spacing: AppDesignSystem.Layout.largePadding) {
                    statItem(label: "Goals", value: stats.goals, team: player.team)
                    statItem(label: "Assists", value: stats.assists, team: player.team)
                    statItem(label: "Yellow", value: stats.yellowCards, team: player.team)
                    statItem(label: "Red", value: stats.redCards, team: player.team)
                }
            }
            .padding(.vertical, 6)
            .background(
                Rectangle()
                    .fill(AppDesignSystem.TeamColors.getAccentColor(for: player.team))
                    .opacity(0.5)
            )
            .opacity(isSubstituted ? 0.7 : 1.0)
        }
        // Force the view to update when the stats change
        .id("\(player.id.uuidString)-\(currentPlayerStats.goals)-\(currentPlayerStats.assists)-\(currentPlayerStats.yellowCards)-\(currentPlayerStats.redCards)")
    }
    
    private func statItem(label: String, value: Int, team: Team) -> some View {
        VStack {
            Text("\(value)")
                .font(AppDesignSystem.Typography.bodyFont.bold())
                .foregroundColor(value > 0 ? AppDesignSystem.TeamColors.getColor(for: team) : AppDesignSystem.Colors.secondaryText)
            
            Text(label)
                .font(AppDesignSystem.Typography.captionFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
    }
}
