//
//  EnhancedPlayerSelectionView.swift
//  Lucky Football Slip
//
//  Football themed player selection for live mode
//

import SwiftUI

struct PlayerSelectionView: View {
    @ObservedObject var gameSession: GameSession
    @Binding var selectedPlayerIds: Set<UUID>
    @State private var showingManualEntry = false
    @State private var searchText = ""
    @State private var selectedTeamFilter: Team?
    @State private var showingTeamPicker = false
    
    @Environment(\.colorScheme) var colorScheme
    
    private var filteredPlayers: [Player] {
        var players = gameSession.availablePlayers
        
        if let team = selectedTeamFilter {
            players = players.filter { $0.team.id == team.id }
        }
        
        if !searchText.isEmpty {
            let searchTerm = searchText.lowercased()
            players = players.filter {
                $0.name.lowercased().contains(searchTerm) ||
                $0.team.name.lowercased().contains(searchTerm)
            }
        }
        
        return players
    }
    
    private var availableTeams: [Team] {
        let uniqueTeams = Set(gameSession.availablePlayers.map { $0.team })
        return Array(uniqueTeams).sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            headerSection
            statsSection
            filtersSection
            playersListSection
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualPlayerEntryView(gameSession: gameSession)
        }
        .sheet(isPresented: $showingTeamPicker) {
            teamPickerSheet
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Select Players")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("\(filteredPlayers.count) available")
                    .font(.system(size: 12))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Button(action: { showingManualEntry = true }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Add")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(AppDesignSystem.Colors.grassGreen)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppDesignSystem.Colors.grassGreen.opacity(0.12))
                )
            }
        }
    }
    
    // MARK: - Stats
    
    private var statsSection: some View {
        VStack(spacing: 8) {
            // Selection count
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                    
                    Text("\(selectedPlayerIds.count) selected")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                }
                
                Spacer()
                
                // Quick actions
                HStack(spacing: 8) {
                    if !selectedPlayerIds.isEmpty {
                        Button("Clear") {
                            withAnimation { selectedPlayerIds.removeAll() }
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.error)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppDesignSystem.Colors.error.opacity(0.1))
                        .cornerRadius(4)
                    }
                    
                    if selectedPlayerIds.count < filteredPlayers.count && !filteredPlayers.isEmpty {
                        Button("Select All") {
                            withAnimation {
                                filteredPlayers.forEach { selectedPlayerIds.insert($0.id) }
                            }
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppDesignSystem.Colors.grassGreen.opacity(0.1))
                        .cornerRadius(4)
                    }
                }
            }
            
            // Validation
            if selectedPlayerIds.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.goalYellow)
                    
                    Text("Select at least one player")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.goalYellow)
                    
                    Spacer()
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppDesignSystem.Colors.grassGreen.opacity(0.06))
        )
    }
    
    // MARK: - Filters
    
    private var filtersSection: some View {
        HStack(spacing: 10) {
            // Search field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                TextField("Search players", text: $searchText)
                    .font(.system(size: 14))
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04))
            )
            
            // Team filter
            Button(action: { showingTeamPicker = true }) {
                HStack(spacing: 4) {
                    Text(selectedTeamFilter?.shortName ?? "All")
                        .font(.system(size: 12, weight: .medium))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundColor(selectedTeamFilter != nil ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.primaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(selectedTeamFilter != nil ? AppDesignSystem.Colors.grassGreen.opacity(0.12) : colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.04))
                )
            }
        }
    }
    
    // MARK: - Players List
    
    private var playersListSection: some View {
        Group {
            if gameSession.availablePlayers.isEmpty {
                emptyStateView
            } else if filteredPlayers.isEmpty {
                noMatchesView
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(filteredPlayers, id: \.id) { player in
                            UnifiedPlayerCard(
                                player: player,
                                isSelected: selectedPlayerIds.contains(player.id)
                            ) {
                                togglePlayer(player)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyStateView: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(0.1))
                    .frame(width: 56, height: 56)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen.opacity(0.5))
            }
            
            Text("No Players Available")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("Add players manually to get started")
                .font(.system(size: 13))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Button(action: { showingManualEntry = true }) {
                Text("Add First Player")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(AppDesignSystem.Colors.grassGreen)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private var noMatchesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("No matches found")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Button("Clear Filters") {
                searchText = ""
                selectedTeamFilter = nil
            }
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(AppDesignSystem.Colors.grassGreen)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Team Picker Sheet
    
    private var teamPickerSheet: some View {
        NavigationView {
            List {
                Button("All Teams") {
                    selectedTeamFilter = nil
                    showingTeamPicker = false
                }
                .foregroundColor(selectedTeamFilter == nil ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.primaryText)
                
                ForEach(availableTeams, id: \.id) { team in
                    Button(action: {
                        selectedTeamFilter = team
                        showingTeamPicker = false
                    }) {
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppDesignSystem.TeamColors.getColor(for: team))
                                .frame(width: 4, height: 20)
                            
                            Text(team.name)
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Spacer()
                            
                            Text(team.shortName)
                                .font(.system(size: 12))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            
                            if selectedTeamFilter?.id == team.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Filter by Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showingTeamPicker = false }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func togglePlayer(_ player: Player) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
            if selectedPlayerIds.contains(player.id) {
                selectedPlayerIds.remove(player.id)
            } else {
                selectedPlayerIds.insert(player.id)
            }
        }
    }
}

// MARK: - Unified Player Card

struct UnifiedPlayerCard: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    @Environment(\.colorScheme) var colorScheme
    
    private var teamColor: Color {
        AppDesignSystem.TeamColors.getColor(for: player.team)
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
                action()
            }
        }) {
            HStack(spacing: 10) {
                // Team color indicator
                RoundedRectangle(cornerRadius: 2)
                    .fill(teamColor)
                    .frame(width: 4, height: 32)
                
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
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppDesignSystem.Colors.grassGreen.opacity(0.08) : AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? AppDesignSystem.Colors.grassGreen.opacity(0.3) : colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.05), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
