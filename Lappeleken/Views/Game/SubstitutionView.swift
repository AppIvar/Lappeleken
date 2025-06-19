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

    // Sheet management
    @State private var activeSheet: ActiveSheet?
    @State private var useExistingPlayer = false
    @State private var selectedExistingPlayer: Player? = nil

    // For creating new teams
    @State private var newTeamName = ""
    @State private var newTeamShortName = ""

    enum ActiveSheet: Identifiable {
        case teamPicker
        case createTeam
        case existingPlayerPicker
        
        var id: String {
            switch self {
            case .teamPicker:
                return "teamPicker"
            case .createTeam:
                return "createTeam"
            case .existingPlayerPicker:
                return "existingPlayerPicker"
            }
        }
    }
    
    // Get all teams that exist in the game (from assigned players)
    private var availableTeams: [Team] {
        let assignedTeams = Set(gameSession.participants.flatMap { $0.selectedPlayers + $0.substitutedPlayers }.map { $0.team })
        let allAvailableTeams = Set(gameSession.availablePlayers.map { $0.team }) // ADDED: Include all available players
        let sampleTeams = Set(SampleData.allTeams)
        return Array(assignedTeams.union(allAvailableTeams).union(sampleTeams)).sorted { $0.name < $1.name }
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
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .teamPicker:
                    teamPickerSheet
                case .createTeam:
                    createTeamSheet
                case .existingPlayerPicker:
                    existingPlayerPickerSheet
                }
            }
        }
        .withMinimalBanner()
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
                    activeSheet = .existingPlayerPicker
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
                Text("Team")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Buttons with explicit button styles and no form interference
                VStack(spacing: 8) {
                    Button(action: {
                        print("🔧 Create New button tapped")
                        activeSheet = .createTeam
                        print("🔧 activeSheet set to: \(activeSheet?.id ?? "nil")")
                    }) {
                        Text("Create New Team")
                            .font(.caption)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.green)
                            .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Rectangle())
                    
                    if selectedTeam != nil {
                        Button(action: {
                            print("🔧 Change button tapped")
                            activeSheet = .teamPicker
                            print("🔧 activeSheet set to: \(activeSheet?.id ?? "nil")")
                        }) {
                            Text("Change Team")
                                .font(.caption)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(6)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .contentShape(Rectangle())
                    }
                }
                
                if let team = selectedTeam {
                    selectedTeamView(team: team)
                } else {
                    Button(action: {
                        activeSheet = .teamPicker
                    }) {
                        Text("Select Existing Team")
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(PlainButtonStyle())
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
                        activeSheet = nil
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
                    activeSheet = nil
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
                        activeSheet = nil
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
                    activeSheet = nil
                }
            )
        }
    }
    
    // MARK: - Create Team Sheet

    private var createTeamSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Team Information")) {
                    TextField("Team Name", text: $newTeamName)
                        .autocapitalization(.words)
                        .onChange(of: newTeamName) { newValue in
                            if newTeamShortName.isEmpty {
                                newTeamShortName = generateShortName(from: newValue)
                            }
                        }
                    
                    TextField("Short Name (3-4 letters)", text: $newTeamShortName)
                        .autocapitalization(.allCharacters)
                        .onChange(of: newTeamShortName) { newValue in
                            newTeamShortName = String(newValue.prefix(4).uppercased())
                        }
                }
                
                Section {
                    Button("Create Team") {
                        createNewTeam()
                    }
                    .disabled(newTeamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              newTeamShortName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        (newTeamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                         newTeamShortName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        ? Color.gray
                        : AppDesignSystem.Colors.primary
                    )
                    .cornerRadius(8)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Create New Team")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    resetNewTeamForm()
                    activeSheet = nil
                },
                trailing: Button("Save") {
                    createNewTeam()
                }
                .disabled(newTeamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          newTeamShortName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }

    // MARK: - Helper Methods for Team Creation

    private func generateShortName(from teamName: String) -> String {
        let words = teamName.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        if words.count >= 2 {
            let firstTwo = words.prefix(2).map { String($0.prefix(1).uppercased()) }
            if words.count > 2 {
                return (firstTwo + [String(words.last!.prefix(1).uppercased())]).joined()
            } else {
                return (firstTwo + [String(words[0].dropFirst().prefix(1).uppercased())]).joined()
            }
        } else if !words.isEmpty {
            return String(words[0].prefix(3).uppercased())
        }
        
        return ""
    }

    private func createNewTeam() {
        let cleanTeamName = newTeamName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanShortName = newTeamShortName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !cleanTeamName.isEmpty && !cleanShortName.isEmpty else { return }
        
        // Check if team already exists
        if availableTeams.contains(where: { $0.name.lowercased() == cleanTeamName.lowercased() }) {
            return
        }
        
        // Create new team
        let newTeam = Team(
            name: cleanTeamName,
            shortName: cleanShortName,
            logoName: "team_logo",
            primaryColor: "#1a73e8"
        )
        
        // Select the new team and close sheet
        selectedTeam = newTeam
        resetNewTeamForm()
        activeSheet = nil
        
        print("✅ Created new team: \(newTeam.name) (\(newTeam.shortName))")
    }

    private func resetNewTeamForm() {
        newTeamName = ""
        newTeamShortName = ""
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
