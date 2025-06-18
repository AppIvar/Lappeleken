//
//  TeamLineupView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 22/05/2025.
//

import SwiftUI

struct TeamLineupView: View {
    let team: Team
    let playersWithOwners: [(player: Player, participant: Participant?)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Team header
            HStack {
                Text(team.name)
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
                
                Spacer()
                
                Text("\(playersWithOwners.count) players")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            // Formation (placeholder - will be updated with API data)
            Text("Formation: 4-3-3")
                .font(AppDesignSystem.Typography.captionFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            // Players grouped by position
            let playersByPosition = Dictionary(grouping: playersWithOwners) { $0.player.position }
            
            VStack(alignment: .leading, spacing: 12) {
                // Goalkeepers
                if let goalkeepers = playersByPosition[.goalkeeper], !goalkeepers.isEmpty {
                    PositionSection(title: "Goalkeepers", players: goalkeepers)
                }
                
                // Defenders
                if let defenders = playersByPosition[.defender], !defenders.isEmpty {
                    PositionSection(title: "Defenders", players: defenders)
                }
                
                // Midfielders
                if let midfielders = playersByPosition[.midfielder], !midfielders.isEmpty {
                    PositionSection(title: "Midfielders", players: midfielders)
                }
                
                // Forwards
                if let forwards = playersByPosition[.forward], !forwards.isEmpty {
                    PositionSection(title: "Forwards", players: forwards)
                }
            }
        }
        .padding()
        .background(AppDesignSystem.Colors.cardBackground)
        .cornerRadius(AppDesignSystem.Layout.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        
        .withSmartBanner()
    }
}

struct PositionSection: View {
    let title: String
    let players: [(player: Player, participant: Participant?)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppDesignSystem.Typography.bodyFont.bold())
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            ForEach(players, id: \.player.id) { playerWithOwner in
                PlayerLineupCard(
                    player: playerWithOwner.player,
                    participant: playerWithOwner.participant
                )
            }
        }
    }
}

struct PlayerLineupCard: View {
    let player: Player
    let participant: Participant?
    
    var body: some View {
        HStack {
            // Player info
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(player.position.rawValue.capitalized)
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Stats
            HStack(spacing: 12) {
                if player.goals > 0 {
                    StatBadge(icon: "soccerball", value: player.goals, color: AppDesignSystem.Colors.success)
                }
                
                if player.assists > 0 {
                    StatBadge(icon: "arrow.up.forward", value: player.assists, color: AppDesignSystem.Colors.primary)
                }
                
                if player.yellowCards > 0 {
                    StatBadge(icon: "square.fill", value: player.yellowCards, color: Color.yellow)
                }
                
                if player.redCards > 0 {
                    StatBadge(icon: "square.fill", value: player.redCards, color: AppDesignSystem.Colors.error)
                }
            }
            
            // Owner info
            if let participant = participant {
                Text(participant.name)
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppDesignSystem.Colors.primary.opacity(0.1))
                    .cornerRadius(12)
            } else {
                Text("Unowned")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .italic()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

struct StatBadge: View {
    let icon: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
            
            Text("\(value)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(
            color: color.opacity(0.3),
            radius: 2,
            x: 0,
            y: 1
        )
    }
}
