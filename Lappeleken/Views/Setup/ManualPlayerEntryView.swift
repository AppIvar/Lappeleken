//
//  ManualPlayerEntryView.swift
//  Lucky Football Slip
//
//  Add players manually - Football themed
//

import SwiftUI

struct ManualPlayerEntryView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var playerName = ""
    @State private var selectedTeam: Team?
    @State private var selectedPosition = Player.Position.midfielder
    @State private var showTeamPicker = false
    @State private var showCreateTeamSheet = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var searchText = ""
    @State private var newTeamName = ""
    @State private var newTeamShortName = ""
    @State private var selectedTeamColor = "#1a73e8"
    
    private let teamColors = ["#EF0107", "#034694", "#C8102E", "#6CABDD", "#DA020E", "#132257", "#DC052D", "#FEBE10", "#004D98", "#1a73e8"]
    
    private var availableTeams: [Team] {
        let existing = Set(gameSession.availablePlayers.map { $0.team })
        let sample = Set(SampleData.allTeams)
        let all = Array(existing.union(sample))
        return searchText.isEmpty ? all.sorted { $0.name < $1.name } : all.filter { $0.name.lowercased().contains(searchText.lowercased()) || $0.shortName.lowercased().contains(searchText.lowercased()) }.sorted { $0.name < $1.name }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                footballBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerIcon
                        playerDetailsCard
                        quickAddSection
                        addButton
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
            .alert(isPresented: $showError) {
                Alert(title: Text("Error"), message: Text(errorMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showTeamPicker) { teamPickerSheet }
            .sheet(isPresented: $showCreateTeamSheet) { createTeamSheet }
        }
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            VStack {
                LinearGradient(colors: [AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.15 : 0.08), Color.clear], startPoint: .top, endPoint: .bottom)
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
                .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                .frame(width: 64, height: 64)
            Image(systemName: "person.badge.plus")
                .font(.system(size: 28))
                .foregroundColor(AppDesignSystem.Colors.grassGreen)
        }
    }
    
    // MARK: - Player Details Card
    
    private var playerDetailsCard: some View {
        VStack(spacing: 16) {
            // Name field
            VStack(alignment: .leading, spacing: 6) {
                Text("Player Name")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                HStack {
                    Image(systemName: "person")
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    TextField("Enter player name", text: $playerName)
                        .font(.system(size: 14))
                        .autocapitalization(.words)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppDesignSystem.Colors.grassGreen.opacity(0.2), lineWidth: 1))
                )
            }
            
            // Team selection
            VStack(alignment: .leading, spacing: 6) {
                Text("Team")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                if let team = selectedTeam {
                    Button(action: { showTeamPicker = true }) {
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppDesignSystem.TeamColors.getColor(for: team))
                                .frame(width: 4, height: 28)
                            Text(team.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            Spacer()
                            Text("Change")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.grassGreen)
                        }
                        .padding(12)
                        .background(RoundedRectangle(cornerRadius: 8).fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03)))
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    HStack(spacing: 10) {
                        Button(action: { showTeamPicker = true }) {
                            HStack {
                                Image(systemName: "list.bullet")
                                Text("Select Team")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.grassGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(AppDesignSystem.Colors.grassGreen.opacity(0.1)))
                        }
                        
                        Button(action: { showCreateTeamSheet = true }) {
                            HStack {
                                Image(systemName: "plus.circle")
                                Text("New Team")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.accent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(RoundedRectangle(cornerRadius: 8).fill(AppDesignSystem.Colors.accent.opacity(0.1)))
                        }
                    }
                }
            }
            
            // Position
            VStack(alignment: .leading, spacing: 6) {
                Text("Position")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Picker("", selection: $selectedPosition) {
                    ForEach(Player.Position.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
    
    // MARK: - Quick Add
    
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Add")
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(popularPlayers, id: \.name) { player in
                        QuickAddChip(name: player.name, position: player.position.rawValue) {
                            playerName = player.name
                            selectedPosition = player.position
                        }
                    }
                }
            }
        }
    }
    
    private var popularPlayers: [Player] {
        let existing = Set(gameSession.availablePlayers.map { $0.name.lowercased() })
        let sample: [Player] = [
            Player(name: "Erling Haaland", team: SampleData.allTeams.first!, position: .forward),
            Player(name: "Kevin De Bruyne", team: SampleData.allTeams.first!, position: .midfielder),
            Player(name: "Mohamed Salah", team: SampleData.allTeams.first!, position: .forward),
            Player(name: "Bukayo Saka", team: SampleData.allTeams.first!, position: .forward),
            Player(name: "Virgil van Dijk", team: SampleData.allTeams.first!, position: .defender)
        ]
        return sample.filter { !existing.contains($0.name.lowercased()) }
    }
    
    // MARK: - Add Button
    
    private var addButton: some View {
        Button(action: addPlayer) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Add Player")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(canAddPlayer ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.4))
            )
        }
        .disabled(!canAddPlayer)
    }
    
    private var canAddPlayer: Bool {
        !playerName.trimmingCharacters(in: .whitespaces).isEmpty && selectedTeam != nil
    }
    
    // MARK: - Sheets
    
    private var teamPickerSheet: some View {
        NavigationView {
            List {
                Section {
                    TextField("Search teams", text: $searchText)
                }
                
                ForEach(availableTeams, id: \.id) { team in
                    Button(action: { selectedTeam = team; showTeamPicker = false }) {
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
                    Button("Done") { showTeamPicker = false }.foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
    }
    
    private var createTeamSheet: some View {
        NavigationView {
            ZStack {
                footballBackground
                createTeamContent
            }
            .navigationTitle("New Team")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { resetNewTeamForm(); showCreateTeamSheet = false }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
    }
    
    private var createTeamContent: some View {
        VStack(spacing: 20) {
            createTeamNameField
            createTeamShortNameField
            createTeamColorPicker
            createTeamButton
            Spacer()
        }
        .padding(20)
    }
    
    private var createTeamNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Team Name")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            TextField("Enter team name", text: $newTeamName)
                .font(.system(size: 14))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                )
                .onChange(of: newTeamName) { newValue in
                    newTeamShortName = generateShortName(from: newValue)
                }
        }
    }
    
    private var createTeamShortNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Short Name")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            TextField("ABC", text: $newTeamShortName)
                .font(.system(size: 14))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                )
        }
    }
    
    private var createTeamColorPicker: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Team Color")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 10) {
                ForEach(teamColors, id: \.self) { hex in
                    TeamColorCircle(hex: hex, isSelected: selectedTeamColor == hex) {
                        selectedTeamColor = hex
                    }
                }
            }
        }
    }
    
    private var createTeamButton: some View {
        Button(action: createNewTeam) {
            Text("Create Team")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(newTeamName.isEmpty ? AppDesignSystem.Colors.secondaryText.opacity(0.4) : AppDesignSystem.Colors.grassGreen)
                )
        }
        .disabled(newTeamName.isEmpty || newTeamShortName.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func addPlayer() {
        let name = playerName.trimmingCharacters(in: .whitespaces)
        guard let team = selectedTeam else { errorMessage = "Please select a team"; showError = true; return }
        if gameSession.availablePlayers.contains(where: { $0.name.lowercased() == name.lowercased() && $0.team.id == team.id }) {
            errorMessage = "Player already exists in \(team.name)"; showError = true; return
        }
        let player = Player(name: name, team: team, position: selectedPosition)
        gameSession.availablePlayers.append(player)
        gameSession.saveCustomPlayers()
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        playerName = ""
        selectedTeam = nil
        selectedPosition = .midfielder
    }
    
    private func generateShortName(from name: String) -> String {
        let words = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if words.count >= 2 { return words.prefix(3).map { String($0.prefix(1).uppercased()) }.joined() }
        return String(words.first?.prefix(3).uppercased() ?? "")
    }
    
    private func createNewTeam() {
        let team = Team(name: newTeamName.trimmingCharacters(in: .whitespaces), shortName: newTeamShortName.uppercased(), logoName: "team_logo", primaryColor: selectedTeamColor)
        selectedTeam = team
        resetNewTeamForm()
        showCreateTeamSheet = false
    }
    
    private func resetNewTeamForm() { newTeamName = ""; newTeamShortName = ""; selectedTeamColor = "#1a73e8" }
}

// MARK: - Quick Add Chip

struct QuickAddChip: View {
    let name: String
    let position: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                Text(position)
                    .font(.system(size: 10))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(AppDesignSystem.Colors.grassGreen.opacity(0.1)))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Team Color Circle

struct TeamColorCircle: View {
    let hex: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Circle()
            .fill(Color(hex))
            .frame(width: 36, height: 36)
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .onTapGesture { action() }
    }
}
