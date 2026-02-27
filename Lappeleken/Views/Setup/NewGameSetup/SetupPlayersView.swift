//
//  SetupPlayersView.swift
//  Lucky Football Slip
//
//  Step 2: Select players - Compact row design matching LiveGameSetupView
//

import SwiftUI

struct SetupPlayersView: View {
    @ObservedObject var gameSession: GameSession
    @Binding var selectedPlayerIds: Set<UUID>
    @Binding var showPlayerEntry: Bool
    @Binding var showLineupSearch: Bool
    let onDeletePlayer: (Player) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            SetupStepHeaderNew(
                icon: "sportscourt.fill",
                title: "Select Players",
                subtitle: "Choose players for the game"
            )
            
            // Action buttons
            HStack(spacing: 12) {
                SetupActionButton(
                    title: "Add Players",
                    icon: "person.badge.plus",
                    style: .primary
                ) {
                    showPlayerEntry = true
                }
                
                SetupActionButton(
                    title: "Search Lineups",
                    icon: "magnifyingglass",
                    style: .secondary
                ) {
                    showLineupSearch = true
                }
            }
            
            // Selection summary
            if !gameSession.availablePlayers.isEmpty {
                selectionSummaryBar
            }
            
            // Players by team
            if !gameSession.availablePlayers.isEmpty {
                playersGroupedByTeam
            } else {
                emptyPlayersView
            }
        }
    }
    
    // MARK: - Selection Summary Bar
    
    private var selectionSummaryBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                
                Text("\(selectedPlayerIds.count) selected")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            
            Spacer()
            
            if selectedPlayerIds.count > 0 {
                Button("Clear All") {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedPlayerIds.removeAll()
                    }
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.error)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppDesignSystem.Colors.grassGreen.opacity(0.08))
        )
    }
    
    // MARK: - Empty State
    
    private var emptyPlayersView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(0.1))
                    .frame(width: 64, height: 64)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen.opacity(0.5))
            }
            
            VStack(spacing: 6) {
                Text("No Players Yet")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Add players manually or search lineups")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
        .padding(.vertical, 32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
    }
    
    // MARK: - Players Grouped by Team
    
    private var playersGroupedByTeam: some View {
        VStack(spacing: 10) {
            let teamGroups = Dictionary(grouping: gameSession.availablePlayers) { $0.team.id }
            
            ForEach(Array(teamGroups.keys).sorted(by: {
                teamGroups[$0]!.first!.team.name < teamGroups[$1]!.first!.team.name
            }), id: \.self) { teamId in
                if let players = teamGroups[teamId], let team = players.first?.team {
                    CompactTeamSection(
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

// MARK: - Setup Action Button

struct SetupActionButton: View {
    enum Style { case primary, secondary }
    
    let title: String
    let icon: String
    let style: Style
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundColor(style == .primary ? .white : AppDesignSystem.Colors.grassGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                Group {
                    if style == .primary {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppDesignSystem.Colors.grassGreen)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(AppDesignSystem.Colors.grassGreen, lineWidth: 1.5)
                    }
                }
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Compact Team Section

struct CompactTeamSection: View {
    let team: Team
    let players: [Player]
    @Binding var selectedPlayerIds: Set<UUID>
    let onDeletePlayer: (Player) -> Void
    
    @State private var isExpanded = true
    @Environment(\.colorScheme) var colorScheme
    
    private var teamColor: Color {
        AppDesignSystem.TeamColors.getColor(for: team)
    }
    
    private var selectedCount: Int {
        players.filter { selectedPlayerIds.contains($0.id) }.count
    }
    
    private var allSelected: Bool {
        players.allSatisfy { selectedPlayerIds.contains($0.id) }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Team header
            teamHeader
            
            // Players list
            if isExpanded {
                VStack(spacing: 4) {
                    ForEach(players, id: \.id) { player in
                        CompactSetupPlayerRow(
                            player: player,
                            isSelected: selectedPlayerIds.contains(player.id),
                            onToggle: {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                    if selectedPlayerIds.contains(player.id) {
                                        selectedPlayerIds.remove(player.id)
                                    } else {
                                        selectedPlayerIds.insert(player.id)
                                    }
                                }
                            },
                            onDelete: { onDeletePlayer(player) }
                        )
                    }
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.15) : Color.black.opacity(0.04),
                    radius: 3,
                    x: 0,
                    y: 2
                )
        )
    }
    
    private var teamHeader: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 10) {
                // Team color bar
                RoundedRectangle(cornerRadius: 2)
                    .fill(teamColor)
                    .frame(width: 4, height: 28)
                
                // Team name and count
                VStack(alignment: .leading, spacing: 1) {
                    Text(team.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("\(selectedCount)/\(players.count) selected")
                        .font(.system(size: 11))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                // Select all / Deselect button
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                        if allSelected {
                            players.forEach { selectedPlayerIds.remove($0.id) }
                        } else {
                            players.forEach { selectedPlayerIds.insert($0.id) }
                        }
                    }
                }) {
                    Text(allSelected ? "Deselect" : "Select All")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(teamColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(teamColor.opacity(0.12))
                        )
                }
                .buttonStyle(PlainButtonStyle())
                
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Compact Setup Player Row (matches UnifiedPlayerCard style)

struct CompactSetupPlayerRow: View {
    let player: Player
    let isSelected: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    private var teamColor: Color {
        AppDesignSystem.TeamColors.getColor(for: player.team)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Main tap area for selection
            Button(action: {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                    onToggle()
                }
            }) {
                HStack(spacing: 10) {
                    // Team color indicator
                    RoundedRectangle(cornerRadius: 2)
                        .fill(teamColor)
                        .frame(width: 3, height: 32)
                    
                    // Player info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Text(player.team.shortName)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(teamColor)
                            
                            Text("•")
                                .font(.system(size: 10))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            
                            Text(player.position.rawValue)
                                .font(.system(size: 11))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.4))
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
                    .padding(5)
                    .background(
                        Circle()
                            .fill(AppDesignSystem.Colors.secondaryText.opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? AppDesignSystem.Colors.grassGreen.opacity(0.08) : colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.02))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? AppDesignSystem.Colors.grassGreen.opacity(0.25) : Color.clear, lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
    }
}
