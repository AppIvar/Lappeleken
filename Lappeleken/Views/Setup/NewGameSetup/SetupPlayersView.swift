//
//  SetupPlayersView.swift
//  Lucky Football Slip
//
//  Step 2: Select players
//

import SwiftUI

struct SetupPlayersView: View {
    @ObservedObject var gameSession: GameSession
    @Binding var selectedPlayerIds: Set<UUID>
    @Binding var showPlayerEntry: Bool
    @Binding var showLineupSearch: Bool
    let onDeletePlayer: (Player) -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            SetupStepHeader(
                icon: "sportscourt.fill",
                iconColor: AppDesignSystem.Colors.secondary,
                title: "Select Players",
                subtitle: "Choose the football players that will be available for selection during the game."
            )
            
            // Action buttons
            HStack(spacing: 12) {
                Button("Add Players") {
                    showPlayerEntry = true
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppDesignSystem.Colors.primary)
                .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                .vibrantButton()
                
                Button("Search Lineups") {
                    showLineupSearch = true
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.primary)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                        .stroke(AppDesignSystem.Colors.primary, lineWidth: 2)
                )
            }
            
            // Players by team
            if !gameSession.availablePlayers.isEmpty {
                playersGroupedByTeam
            } else {
                emptyPlayersView
            }
        }
    }
    
    private var emptyPlayersView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("No players added yet")
                .font(AppDesignSystem.Typography.subheadingFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("Add players manually or search for team lineups to get started")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.largeCornerRadius)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    private var playersGroupedByTeam: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Available Players")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                VibrantStatusBadge("\(gameSession.availablePlayers.count)", color: AppDesignSystem.Colors.info)
            }
            
            let teamGroups = Dictionary(grouping: gameSession.availablePlayers) { $0.team.id }
            
            LazyVStack(spacing: 12) {
                ForEach(Array(teamGroups.keys).sorted(by: { teamGroups[$0]!.first!.team.name < teamGroups[$1]!.first!.team.name }), id: \.self) { teamId in
                    if let players = teamGroups[teamId], let team = players.first?.team {
                        TeamPlayerGroup(
                            team: team,
                            players: players,
                            selectedPlayerIds: $selectedPlayerIds,
                            onDeletePlayer: onDeletePlayer
                        )
                    }
                }
            }
        }
    }
}
