//
//  SubstitutionView.swift
//  Lucky Football Slip
//
//  Enhanced version with team dropdown and better UX
//

import SwiftUI

struct SubstitutionView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPlayerOff: Player? = nil
    @State private var newPlayerName: String = ""
    @State private var selectedTeam: Team? = nil
    @State private var newPlayerPosition = Player.Position.midfielder
    @State private var showTeamPicker = false
    
    // For existing player selection
    @State private var useExistingPlayer = false
    @State private var selectedExistingPlayer: Player? = nil
    @State private var showExistingPlayerPicker = false
    
    // Get all teams that exist in the game (from assigned players)
    private var availableTeams: [Team] {
        let assignedTeams = Set(gameSession.participants.flatMap { $0.selectedPlayers + $0.substitutedPlayers }.map { $0.team })
        let sampleTeams = Set(SampleData.allTeams)
        return Array(assignedTeams.union(sampleTeams)).sorted { $0.name < $1.name }
    }
    
    // Get available players not currently assigned to any participant
    private var availableUnassignedPlayers: [Player] {
        let assignedPlayerIds = Set(gameSession.participants.flatMap { $0.selectedPlayers + $0.substitutedPlayers }.map { $0.id })
        return gameSession.availablePlayers.filter { !assignedPlayerIds.contains($0.id) }
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Player to substitute off
                playerOffSection
                
                // New player selection
                if selectedPlayerOff != nil {
                    newPlayerSection
                    
                    // Action button
                    actionSection
                }
            }
            .navigationTitle("Player Substitution")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .sheet(isPresented: $showTeamPicker) {
                teamPickerSheet
            }
            .sheet(isPresented: $showExistingPlayerPicker) {
                existingPlayerPickerSheet
            }
        }
        .withBannerAd(placement: .bottom)
    }
    
    // MARK: - Player Off Section
    
    private var playerOffSection: some View {
        Section(header: Text("Select Player to Substitute")) {
            if gameSession.participants.flatMap({ $0.selectedPlayers }).isEmpty {
                Text("No players assigned yet")
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .italic()
            } else {
                ForEach(gameSession.participants) { participant in
                    if !participant.selectedPlayers.isEmpty {
                        participantSection(participant: participant)
                    }
                }
            }
        }
    }
    
    private func participantSection(participant: Participant) -> some View {
        Section(header:
            Text(participant.name)
                .font(.subheadline)
                .foregroundColor(.primary)
        ) {
            ForEach(participant.selectedPlayers) { player in
                playerOffRow(player: player)
            }
        }
    }
    
    private func playerOffRow(player: Player) -> some View {
        Button(action: {
            selectedPlayerOff = player
            // Auto-select the same team for the new player
            selectedTeam = player.team
        }) {
            HStack {
                // Team color indicator
                Circle()
                    .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                    .frame(width: 12, height: 12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 4) {
                        Text(player.team.shortName)
                            .font(.caption)
                            .foregroundColor(AppDesignSystem.TeamColors.getColor(for: player.team))
                        
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(player.position.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if selectedPlayerOff?.id == player.id {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppDesignSystem.Colors.success)
                        .font(.title3)
                }
            }
            .padding(.vertical, 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - New Player Section
    
    private var newPlayerSection: some View {
        Section(header: Text("New Player")) {
            // Toggle between existing and new player
            Picker("Player Type", selection: $useExistingPlayer) {
                Text("Create New Player").tag(false)
                Text("Use Existing Player").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: useExistingPlayer) { _ in
                // Reset selections when switching modes
                selectedExistingPlayer = nil
                newPlayerName = ""
            }
            
            if useExistingPlayer {
                existingPlayerSection
            } else {
                newPlayerCreationSection
            }
        }
    }
    
    private var existingPlayerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if availableUnassignedPlayers.isEmpty {
                Text("No available unassigned players")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                Button(selectedExistingPlayer?.name ?? "Select Existing Player") {
                    showExistingPlayerPicker = true
                }
                .foregroundColor(selectedExistingPlayer == nil ? .blue : .primary)
                
                if let player = selectedExistingPlayer {
                    HStack {
                        Circle()
                            .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                            .frame(width: 10, height: 10)
                        
                        Text("\(player.team.shortName) • \(player.position.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
    
    private var newPlayerCreationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Player name
            TextField("Player Name", text: $newPlayerName)
                .autocapitalization(.words)
                .autocorrectionDisabled()
            
            // Team selection
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Team")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if selectedTeam != nil {
                        Button("Change") {
                            showTeamPicker = true
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }
                }
                
                if let team = selectedTeam {
                    selectedTeamView(team: team)
                } else {
                    Button("Select Team") {
                        showTeamPicker = true
                    }
                    .foregroundColor(.blue)
                }
            }
            
            // Position selection
            Picker("Position", selection: $newPlayerPosition) {
                ForEach(Player.Position.allCases, id: \.self) { position in
                    Text(position.rawValue).tag(position)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    private func selectedTeamView(team: Team) -> some View {
        HStack {
            Circle()
                .fill(AppDesignSystem.TeamColors.getColor(for: team))
                .frame(width: 12, height: 12)
            
            Text(team.name)
                .font(.subheadline)
            
            Text("(\(team.shortName))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            showTeamPicker = true
        }
    }
    
    // MARK: - Action Section
    
    private var actionSection: some View {
        Section {
            Button(action: performSubstitution) {
                HStack {
                    if useExistingPlayer {
                        Text("Substitute with \(selectedExistingPlayer?.name ?? "Selected Player")")
                    } else {
                        Text("Complete Substitution")
                    }
                    
                    Spacer()
                    
                    Image(systemName: "arrow.left.arrow.right")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(
                    canPerformSubstitution ? AppDesignSystem.Colors.primary : Color.gray
                )
                .cornerRadius(8)
            }
            .disabled(!canPerformSubstitution)
        }
        .listRowBackground(Color.clear)
    }
    
    // MARK: - Team Picker Sheet
    
    private var teamPickerSheet: some View {
        NavigationView {
            List {
                ForEach(availableTeams, id: \.id) { team in
                    Button(action: {
                        selectedTeam = team
                        showTeamPicker = false
                    }) {
                        HStack {
                            Circle()
                                .fill(AppDesignSystem.TeamColors.getColor(for: team))
                                .frame(width: 16, height: 16)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(team.name)
                                    .foregroundColor(.primary)
                                
                                Text(team.shortName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if selectedTeam?.id == team.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Team")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    showTeamPicker = false
                }
            )
        }
    }
    
    // MARK: - Existing Player Picker Sheet
    
    private var existingPlayerPickerSheet: some View {
        NavigationView {
            List {
                ForEach(availableUnassignedPlayers, id: \.id) { player in
                    Button(action: {
                        selectedExistingPlayer = player
                        showExistingPlayerPicker = false
                    }) {
                        HStack {
                            Circle()
                                .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                                .frame(width: 16, height: 16)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 4) {
                                    Text(player.team.shortName)
                                        .font(.caption)
                                        .foregroundColor(AppDesignSystem.TeamColors.getColor(for: player.team))
                                    
                                    Text("•")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(player.position.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedExistingPlayer?.id == player.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Player")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    showExistingPlayerPicker = false
                }
            )
        }
    }
    
    // MARK: - Helper Properties and Methods
    
    private var canPerformSubstitution: Bool {
        guard selectedPlayerOff != nil else { return false }
        
        if useExistingPlayer {
            return selectedExistingPlayer != nil
        } else {
            return !newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   selectedTeam != nil
        }
    }
    
    private func performSubstitution() {
        guard let playerOff = selectedPlayerOff else { return }
        
        let playerOn: Player
        
        if useExistingPlayer {
            guard let existingPlayer = selectedExistingPlayer else { return }
            playerOn = existingPlayer
        } else {
            guard let team = selectedTeam,
                  !newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            
            // Create new player
            playerOn = Player(
                name: newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines),
                team: team,
                position: newPlayerPosition
            )
            
            // Add to available players if not already there
            if !gameSession.availablePlayers.contains(where: { $0.id == playerOn.id }) {
                gameSession.availablePlayers.append(playerOn)
            }
        }
        
        // Perform the substitution
        gameSession.substitutePlayer(playerOff: playerOff, playerOn: playerOn)
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Close the view
        presentationMode.wrappedValue.dismiss()
        
        print("✅ Substitution completed: \(playerOff.name) → \(playerOn.name)")
    }
}
