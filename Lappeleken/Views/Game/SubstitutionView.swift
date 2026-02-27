//
//  SubstitutionView.swift
//  Lucky Football Slip
//
//  Player substitution - Football themed
//

import SwiftUI

struct SubstitutionView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedPlayerOff: Player? = nil
    @State private var newPlayerName: String = ""
    @State private var selectedTeam: Team? = nil
    @State private var newPlayerPosition = Player.Position.midfielder
    @State private var activeSheet: ActiveSheet?
    @State private var useExistingPlayer = false
    @State private var selectedExistingPlayer: Player? = nil
    @State private var newTeamName = ""
    @State private var newTeamShortName = ""

    enum ActiveSheet: Identifiable {
        case teamPicker, createTeam, existingPlayerPicker
        var id: String { String(describing: self) }
    }
    
    private var availableTeams: [Team] {
        let assignedTeams = Set(gameSession.participants.flatMap { $0.selectedPlayers + $0.substitutedPlayers }.map { $0.team })
        let allAvailableTeams = Set(gameSession.availablePlayers.map { $0.team })
        let sampleTeams = Set(SampleData.allTeams)
        return Array(assignedTeams.union(allAvailableTeams).union(sampleTeams)).sorted { $0.name < $1.name }
    }
    
    private var availableUnassignedPlayers: [Player] {
        let assignedPlayerIds = Set(gameSession.participants.flatMap { $0.selectedPlayers + $0.substitutedPlayers }.map { $0.id })
        return gameSession.availablePlayers.filter { !assignedPlayerIds.contains($0.id) }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                footballBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerIcon
                        playerOffSection
                        
                        if selectedPlayerOff != nil {
                            newPlayerSection
                            substituteButton
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Substitution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .teamPicker: teamPickerSheet
                case .createTeam: createTeamSheet
                case .existingPlayerPicker: existingPlayerPickerSheet
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            VStack {
                LinearGradient(colors: [AppDesignSystem.Colors.warning.opacity(colorScheme == .dark ? 0.15 : 0.08), Color.clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 150)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(AppDesignSystem.Colors.warning.opacity(0.15))
                .frame(width: 64, height: 64)
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: 28))
                .foregroundColor(AppDesignSystem.Colors.warning)
        }
    }
    
    // MARK: - Player Off Section
    
    private var playerOffSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .foregroundColor(AppDesignSystem.Colors.error)
                Text("Player Going Off")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            
            let allPlayers = gameSession.participants.flatMap { $0.selectedPlayers }
            
            if allPlayers.isEmpty {
                emptyStateCard(icon: "person.slash", message: "No players assigned yet")
            } else {
                VStack(spacing: 8) {
                    ForEach(gameSession.participants) { participant in
                        if !participant.selectedPlayers.isEmpty {
                            SubParticipantSection(
                                participant: participant,
                                selectedPlayerOff: $selectedPlayerOff,
                                onSelect: { player in
                                    selectedPlayerOff = player
                                    selectedTeam = player.team
                                }
                            )
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - New Player Section
    
    private var newPlayerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                Text("Player Coming On")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            
            // Toggle
            Picker("", selection: $useExistingPlayer) {
                Text("New Player").tag(false)
                Text("Existing").tag(true)
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: useExistingPlayer) { _ in
                selectedExistingPlayer = nil
                newPlayerName = ""
            }
            
            if useExistingPlayer {
                existingPlayerContent
            } else {
                newPlayerContent
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.15) : Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - Existing Player Content
    
    private var existingPlayerContent: some View {
        VStack(spacing: 10) {
            if availableUnassignedPlayers.isEmpty {
                Text("No unassigned players available")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .padding(.vertical, 8)
            } else {
                Button(action: { activeSheet = .existingPlayerPicker }) {
                    HStack {
                        if let player = selectedExistingPlayer {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                                .frame(width: 4, height: 24)
                            Text(player.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            Spacer()
                            Text(player.team.shortName)
                                .font(.system(size: 12))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        } else {
                            Image(systemName: "person.badge.plus")
                                .foregroundColor(AppDesignSystem.Colors.grassGreen)
                            Text("Select Player")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.grassGreen)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    // MARK: - New Player Content
    
    private var newPlayerContent: some View {
        VStack(spacing: 12) {
            // Name
            HStack {
                Image(systemName: "person")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                TextField("Player Name", text: $newPlayerName)
                    .font(.system(size: 14))
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02)))
            
            // Team
            Button(action: { activeSheet = .teamPicker }) {
                HStack {
                    if let team = selectedTeam {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppDesignSystem.TeamColors.getColor(for: team))
                            .frame(width: 4, height: 24)
                        Text(team.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                    } else {
                        Image(systemName: "flag")
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        Text("Select Team")
                            .font(.system(size: 14))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02)))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Position
            Picker("Position", selection: $newPlayerPosition) {
                ForEach(Player.Position.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    // MARK: - Substitute Button
    
    private var substituteButton: some View {
        Button(action: performSubstitution) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right")
                Text("Confirm Substitution")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canPerformSubstitution ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.4))
            )
        }
        .disabled(!canPerformSubstitution)
    }
    
    // MARK: - Sheets
    
    private var teamPickerSheet: some View {
        NavigationView {
            List {
                Button("+ Create New Team") { activeSheet = .createTeam }
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                
                ForEach(availableTeams, id: \.id) { team in
                    Button(action: { selectedTeam = team; activeSheet = nil }) {
                        HStack {
                            RoundedRectangle(cornerRadius: 2).fill(AppDesignSystem.TeamColors.getColor(for: team)).frame(width: 4, height: 20)
                            Text(team.name).foregroundColor(AppDesignSystem.Colors.primaryText)
                            Spacer()
                            if selectedTeam?.id == team.id {
                                Image(systemName: "checkmark").foregroundColor(AppDesignSystem.Colors.grassGreen)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { activeSheet = nil }.foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
    }
    
    private var createTeamSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Team Info")) {
                    TextField("Team Name", text: $newTeamName)
                        .onChange(of: newTeamName) { newTeamShortName = generateShortName(from: $0) }
                    TextField("Short Name", text: $newTeamShortName)
                }
                
                Section {
                    Button("Create Team") { createNewTeam() }
                        .disabled(newTeamName.isEmpty || newTeamShortName.isEmpty)
                }
            }
            .navigationTitle("New Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { resetNewTeamForm(); activeSheet = .teamPicker }
                }
            }
        }
    }
    
    private var existingPlayerPickerSheet: some View {
        NavigationView {
            List {
                ForEach(availableUnassignedPlayers, id: \.id) { player in
                    Button(action: { selectedExistingPlayer = player; activeSheet = nil }) {
                        HStack {
                            RoundedRectangle(cornerRadius: 2).fill(AppDesignSystem.TeamColors.getColor(for: player.team)).frame(width: 4, height: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(player.name).font(.system(size: 14, weight: .medium)).foregroundColor(AppDesignSystem.Colors.primaryText)
                                Text("\(player.team.shortName) • \(player.position.rawValue)").font(.system(size: 11)).foregroundColor(AppDesignSystem.Colors.secondaryText)
                            }
                            Spacer()
                            if selectedExistingPlayer?.id == player.id {
                                Image(systemName: "checkmark").foregroundColor(AppDesignSystem.Colors.grassGreen)
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .navigationTitle("Select Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { activeSheet = nil }.foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func emptyStateCard(icon: String, message: String) -> some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 24)).foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
                Text(message).font(.system(size: 13)).foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding(.vertical, 20)
            Spacer()
        }
        .background(RoundedRectangle(cornerRadius: 10).fill(AppDesignSystem.Colors.cardBackground))
    }
    
    private var canPerformSubstitution: Bool {
        guard selectedPlayerOff != nil else { return false }
        return useExistingPlayer ? selectedExistingPlayer != nil : (!newPlayerName.trimmingCharacters(in: .whitespaces).isEmpty && selectedTeam != nil)
    }
    
    private func performSubstitution() {
        guard let playerOff = selectedPlayerOff else { return }
        let playerOn: Player
        if useExistingPlayer, let existing = selectedExistingPlayer {
            playerOn = existing
        } else {
            guard let team = selectedTeam else { return }
            playerOn = Player(name: newPlayerName.trimmingCharacters(in: .whitespaces), team: team, position: newPlayerPosition)
            if !gameSession.availablePlayers.contains(where: { $0.id == playerOn.id }) {
                gameSession.availablePlayers.append(playerOn)
            }
        }
        gameSession.substitutePlayer(playerOff: playerOff, playerOn: playerOn)
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        presentationMode.wrappedValue.dismiss()
    }
    
    private func generateShortName(from name: String) -> String {
        let words = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if words.count >= 2 { return words.prefix(2).map { String($0.prefix(1).uppercased()) }.joined() + String(words[0].dropFirst().prefix(1).uppercased()) }
        return String(words.first?.prefix(3).uppercased() ?? "")
    }
    
    private func createNewTeam() {
        let team = Team(name: newTeamName.trimmingCharacters(in: .whitespaces), shortName: newTeamShortName.uppercased(), logoName: "team_logo", primaryColor: "#1a73e8")
        selectedTeam = team
        resetNewTeamForm()
        activeSheet = nil
    }
    
    private func resetNewTeamForm() { newTeamName = ""; newTeamShortName = "" }
}

// MARK: - Sub Participant Section

struct SubParticipantSection: View {
    let participant: Participant
    @Binding var selectedPlayerOff: Player?
    let onSelect: (Player) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(participant.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.grassGreen)
                .padding(.leading, 4)
            
            VStack(spacing: 4) {
                ForEach(participant.selectedPlayers, id: \.id) { player in
                    SubPlayerRow(player: player, isSelected: selectedPlayerOff?.id == player.id) {
                        onSelect(player)
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.15) : Color.black.opacity(0.04), radius: 3, x: 0, y: 2)
        )
    }
}

struct SubPlayerRow: View {
    let player: Player
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                    .frame(width: 3, height: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(player.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    Text("\(player.team.shortName) • \(player.position.rawValue)")
                        .font(.system(size: 11))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.4))
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? AppDesignSystem.Colors.grassGreen.opacity(0.08) : colorScheme == .dark ? Color.white.opacity(0.02) : Color.black.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? AppDesignSystem.Colors.grassGreen.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
