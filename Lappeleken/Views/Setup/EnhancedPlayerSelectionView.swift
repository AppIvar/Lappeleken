//
//  FixedPlayerSelectionView.swift
//  Lucky Football Slip
//
//  Fixed version that properly displays players
//

import SwiftUI

struct PlayerSelectionView: View {
    @ObservedObject var gameSession: GameSession
    @Binding var selectedPlayerIds: Set<UUID>
    @State private var showingManualEntry = false
    @State private var searchText = ""
    @State private var selectedTeamFilter: Team?
    @State private var showingTeamPicker = false
    
    // Simple filtered players
    private var filteredPlayers: [Player] {
        var players = gameSession.availablePlayers
        
        // Apply team filter first
        if let team = selectedTeamFilter {
            players = players.filter { $0.team.id == team.id }
        }
        
        // Apply search filter
        if !searchText.isEmpty {
            let searchTerm = searchText.lowercased()
            players = players.filter {
                $0.name.lowercased().contains(searchTerm) ||
                $0.team.name.lowercased().contains(searchTerm)
            }
        }
        
        return players
    }
    
    // Get unique teams for filter
    private var availableTeams: [Team] {
        let uniqueTeams = Set(gameSession.availablePlayers.map { $0.team })
        return Array(uniqueTeams).sorted { $0.name < $1.name }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            headerView
            
            // Stats and validation
            statsView
            
            // Search and filters
            filtersView
            
            // Players list
            playersListView
        }
        .sheet(isPresented: $showingManualEntry) {
            ManualPlayerEntryView(gameSession: gameSession)
        }
        .sheet(isPresented: $showingTeamPicker) {
            teamPickerSheet
        }
        .withSmartBanner()
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("Select Players")
                .font(.title2)
                .fontWeight(.semibold)
            
            Spacer()
            
            Button("Add Player") {
                showingManualEntry = true
            }
            .font(.subheadline)
            .foregroundColor(.blue)
        }
    }
    
    // MARK: - Stats
    
    private var statsView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(filteredPlayers.count) available players")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(selectedPlayerIds.count) selected")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(selectedPlayerIds.isEmpty ? .secondary : .blue)
            }
            
            // Validation message
            if selectedPlayerIds.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                    Text("Select at least one player to continue")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Quick actions
            if !filteredPlayers.isEmpty {
                quickActionsView
            }
        }
    }
    
    // MARK: - Quick Actions
    
    private var quickActionsView: some View {
        HStack(spacing: 12) {
            if !selectedPlayerIds.isEmpty {
                Button("Clear All") {
                    selectedPlayerIds.removeAll()
                }
                .font(.caption)
                .foregroundColor(.red)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.red.opacity(0.1))
                .cornerRadius(4)
            }
            
            if selectedPlayerIds.count < filteredPlayers.count {
                Button("Select All") {
                    for player in filteredPlayers {
                        selectedPlayerIds.insert(player.id)
                    }
                }
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Filters
    
    private var filtersView: some View {
        HStack(spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                    .font(.caption)
                
                TextField("Search players", text: $searchText)
                    .font(.subheadline)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(6)
            
            // Team filter
            Button(selectedTeamFilter?.shortName ?? "All Teams") {
                showingTeamPicker = true
            }
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(selectedTeamFilter != nil ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
            .foregroundColor(selectedTeamFilter != nil ? .blue : .primary)
            .cornerRadius(6)
        }
    }
    
    // MARK: - Players List
    
    private var playersListView: some View {
        Group {
            if gameSession.availablePlayers.isEmpty {
                // No players at all
                emptyPlayersView
            } else if filteredPlayers.isEmpty {
                // No players match filter
                noMatchesView
            } else {
                // Show players
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(filteredPlayers, id: \.id) { player in
                            UnifiedPlayerCard(
                                player: player,
                                isSelected: selectedPlayerIds.contains(player.id)
                            ) {
                                togglePlayerSelection(player)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }
    
    // MARK: - Empty States
    
    private var emptyPlayersView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Players Available")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Add players manually to get started")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add First Player") {
                showingManualEntry = true
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
    
    private var noMatchesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.title)
                .foregroundColor(.secondary)
            
            Text("No matches found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try adjusting your search or filter")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Clear Filters") {
                searchText = ""
                selectedTeamFilter = nil
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    // MARK: - Team Picker Sheet
    
    private var teamPickerSheet: some View {
        NavigationView {
            List {
                // All teams option
                Button("All Teams") {
                    selectedTeamFilter = nil
                    showingTeamPicker = false
                }
                .foregroundColor(selectedTeamFilter == nil ? .blue : .primary)
                
                // Individual teams
                ForEach(availableTeams, id: \.id) { team in
                    Button(action: {
                        selectedTeamFilter = team
                        showingTeamPicker = false
                    }) {
                        HStack {
                            Text(team.name)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Text(team.shortName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if selectedTeamFilter?.id == team.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Filter by Team")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Done") {
                    showingTeamPicker = false
                }
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func togglePlayerSelection(_ player: Player) {
        withAnimation(.easeInOut(duration: 0.2)) {
            if selectedPlayerIds.contains(player.id) {
                selectedPlayerIds.remove(player.id)
            } else {
                selectedPlayerIds.insert(player.id)
            }
        }
    }
}

// MARK: - Unified Player Card (Single Component)

struct UnifiedPlayerCard: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Simple animation feedback
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
            HStack(spacing: 12) {
                // Team color indicator
                Rectangle()
                    .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                    .frame(width: 4, height: 36)
                    .cornerRadius(2)
                
                VStack(alignment: .leading, spacing: 3) {
                    Text(player.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Text(player.team.shortName)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppDesignSystem.TeamColors.getColor(for: player.team))
                        
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Text(player.position.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.secondaryText.opacity(0.5))
                    .font(.system(size: 20))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? 
                          AppDesignSystem.TeamColors.getAccentColor(for: player.team).opacity(0.2) :
                          Color.white)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isSelected ?
                        AppDesignSystem.TeamColors.getColor(for: player.team) :
                        Color.gray.opacity(0.2),
                        lineWidth: isSelected ? 1.5 : 0.5
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: isSelected ?
                AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.15) :
                Color.black.opacity(0.04),
                radius: isSelected ? 3 : 1,
                x: 0,
                y: 1
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Debug View for Testing

struct PlayerSelectionDebugView: View {
    @ObservedObject var gameSession: GameSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Debug Info")
                .font(.headline)
            
            Text("Available Players: \(gameSession.availablePlayers.count)")
            Text("Sample Players: \(SampleData.corePlayers.count)")
            
            if gameSession.availablePlayers.isEmpty {
                Button("Load Sample Data") {
                    gameSession.addPlayers(SampleData.corePlayers)
                }
                .buttonStyle(.borderedProminent)
            }
            
            Text("First 5 players:")
            ForEach(gameSession.availablePlayers.prefix(5), id: \.id) { player in
                Text("• \(player.name) (\(player.team.shortName))")
                    .font(.caption)
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
    }
}
