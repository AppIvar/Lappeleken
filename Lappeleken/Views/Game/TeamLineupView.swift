//
//  TeamLineupView.swift
//  Lucky Football Slip
//
//  Team lineup display - Football themed
//

import SwiftUI

struct TeamLineupView: View {
    let team: Team
    let playersWithOwners: [(player: Player, participant: Participant?)]
    
    @Environment(\.colorScheme) var colorScheme
    
    private var teamColor: Color {
        AppDesignSystem.TeamColors.getColor(for: team)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Team header
            teamHeader
            
            // Players by position
            let byPosition = Dictionary(grouping: playersWithOwners) { $0.player.position }
            
            VStack(spacing: 12) {
                if let gks = byPosition[.goalkeeper], !gks.isEmpty {
                    LineupPositionSection(title: "Goalkeepers", players: gks, teamColor: teamColor)
                }
                if let defs = byPosition[.defender], !defs.isEmpty {
                    LineupPositionSection(title: "Defenders", players: defs, teamColor: teamColor)
                }
                if let mids = byPosition[.midfielder], !mids.isEmpty {
                    LineupPositionSection(title: "Midfielders", players: mids, teamColor: teamColor)
                }
                if let fwds = byPosition[.forward], !fwds.isEmpty {
                    LineupPositionSection(title: "Forwards", players: fwds, teamColor: teamColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(teamColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                    radius: 6,
                    x: 0,
                    y: 3
                )
        )
    }
    
    // MARK: - Team Header
    
    private var teamHeader: some View {
        HStack(spacing: 12) {
            // Team color badge
            Circle()
                .fill(teamColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Text(team.shortName.prefix(2))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(team.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("\(playersWithOwners.count) players")
                    .font(.system(size: 12))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
        }
    }
}

// MARK: - Position Section

struct LineupPositionSection: View {
    let title: String
    let players: [(player: Player, participant: Participant?)]
    let teamColor: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(teamColor)
                .padding(.leading, 4)
            
            VStack(spacing: 4) {
                ForEach(players, id: \.player.id) { item in
                    LineupPlayerRow(player: item.player, participant: item.participant, teamColor: teamColor)
                }
            }
        }
    }
}

// MARK: - Player Row

struct LineupPlayerRow: View {
    let player: Player
    let participant: Participant?
    let teamColor: Color
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            // Team color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(teamColor)
                .frame(width: 3, height: 32)
            
            // Player info
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(player.position.rawValue)
                    .font(.system(size: 11))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Stats
            HStack(spacing: 8) {
                if player.goals > 0 {
                    StatBadge(icon: "soccerball", count: player.goals, color: AppDesignSystem.Colors.grassGreen)
                }
                if player.assists > 0 {
                    StatBadge(icon: "arrow.up.forward", count: player.assists, color: AppDesignSystem.Colors.info)
                }
                if player.yellowCards > 0 {
                    StatBadge(icon: "square.fill", count: player.yellowCards, color: AppDesignSystem.Colors.goalYellow)
                }
                if player.redCards > 0 {
                    StatBadge(icon: "square.fill", count: player.redCards, color: AppDesignSystem.Colors.error)
                }
            }
            
            // Owner
            if let participant = participant {
                Text(participant.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(AppDesignSystem.Colors.grassGreen.opacity(0.12))
                    )
            } else {
                Text("—")
                    .font(.system(size: 11))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.02))
        )
    }
}
