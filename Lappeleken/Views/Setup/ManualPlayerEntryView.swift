//
//  ManualPlayerEntryView.swift
//  Lucky Football Slip
//
//  Enhanced version with team dropdown and NEW TEAM CREATION
//

import SwiftUI

struct ManualPlayerEntryView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @State private var playerName = ""
    @State private var selectedTeam: Team?
    @State private var selectedPosition = Player.Position.midfielder
    @State private var showTeamPicker = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var searchText = ""
    
    // NEW: States for creating new teams
    @State private var showCreateTeamSheet = false
    @State private var newTeamName = ""
    @State private var newTeamShortName = ""
    @State private var selectedTeamColor = "#1a73e8"
    
    // Available team colors
    private let teamColors = [
        "#EF0107", "#034694", "#C8102E", "#6CABDD", "#DA020E",
        "#132257", "#DC052D", "#FEBE10", "#004D98", "#000000",
        "#FB090B", "#0068A8", "#1a73e8", "#00C853", "#FF6F00"
    ]
    
    // Get existing teams from game session and reduced sample data combined
    private var availableTeams: [Team] {
        let existingTeams = Set(gameSession.availablePlayers.map { $0.team })
        let sampleTeams = Set(SampleData.allTeams)
        let allTeams = Array(existingTeams.union(sampleTeams))
        
        if searchText.isEmpty {
            return allTeams.sorted { $0.name < $1.name }
        } else {
            return allTeams.filter { team in
                team.name.lowercased().contains(searchText.lowercased()) ||
                team.shortName.lowercased().contains(searchText.lowercased())
            }.sorted { $0.name < $1.name }
        }
    }
    
    // Simple team grouping for reduced dataset
    private var teamsByLeague: [String: [Team]] {
        var result: [String: [Team]] = [:]
        
        // Group by major leagues (simplified)
        let premierLeagueTeams = availableTeams.filter { team in
            ["Arsenal", "Chelsea", "Liverpool", "Manchester City", "Manchester United", "Tottenham"].contains(team.name)
        }
        if !premierLeagueTeams.isEmpty {
            result["Premier League"] = premierLeagueTeams
        }
        
        let otherTeams = availableTeams.filter { team in
            !premierLeagueTeams.contains { $0.id == team.id }
        }
        if !otherTeams.isEmpty {
            result["Other Teams"] = otherTeams
        }
        
        return result.filter { !$0.value.isEmpty }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Details")) {
                    // Player Name
                    TextField("Player Name", text: $playerName)
                        .autocapitalization(.words)
                        .autocorrectionDisabled()
                    
                    // Team Selection (Enhanced)
                    teamSelectionSection
                    
                    // Position Selection
                    Picker("Position", selection: $selectedPosition) {
                        ForEach(Player.Position.allCases, id: \.self) { position in
                            Text(position.rawValue).tag(position)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // Quick Add Section
                quickAddSection
                
                Section {
                    Button("Add Player") {
                        addPlayer()
                    }
                    .disabled(playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              selectedTeam == nil)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(.white)
                    .padding()
                    .background(
                        (playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedTeam == nil)
                        ? Color.gray
                        : AppDesignSystem.Colors.primary
                    )
                    .cornerRadius(8)
                }
                .listRowBackground(Color.clear)
            }
            .navigationTitle("Add Player")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Cannot Add Player"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .withSmartBanner()
    }
    
    // MARK: - Enhanced Team Selection Section
    
    private var teamSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Team")
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // NEW: Create Team Button
                Button("Create New") {
                    showCreateTeamSheet = true
                }
                .font(.caption)
                .foregroundColor(.green)
                .padding(.trailing, 8)
                
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
                .padding(.vertical, 8)
            }
        }
        .sheet(isPresented: $showTeamPicker) {
            teamPickerSheet
        }
        .sheet(isPresented: $showCreateTeamSheet) {
            createTeamSheet
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
    
    // MARK: - NEW: Create Team Sheet
    
    private var createTeamSheet: some View {
        NavigationView {
            Form {
                Section(header: Text("Team Information")) {
                    TextField("Team Name", text: $newTeamName)
                        .autocapitalization(.words)
                        .onChange(of: newTeamName) { name in
                            // Auto-generate short name from team name
                            if newTeamShortName.isEmpty || newTeamShortName == generateShortName(from: name) {
                                newTeamShortName = generateShortName(from: name)
                            }
                        }
                    
                    TextField("Short Name (3 letters)", text: $newTeamShortName)
                        .autocapitalization(.allCharacters)
                        .onChange(of: newTeamShortName) { shortName in
                            // Limit to 3 characters
                            if shortName.count > 3 {
                                newTeamShortName = String(shortName.prefix(3))
                            }
                        }
                }
                
                Section(header: Text("Team Color")) {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                        ForEach(teamColors, id: \.self) { color in
                            Button(action: {
                                selectedTeamColor = color
                            }) {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(
                                                selectedTeamColor == color ? Color.black : Color.clear,
                                                lineWidth: 3
                                            )
                                    )
                                    .overlay(
                                        selectedTeamColor == color ?
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.white)
                                            .font(.system(size: 16, weight: .bold)) :
                                        nil
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.vertical, 8)
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
                        : Color.green
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
                    showCreateTeamSheet = false
                },
                trailing: Button("Save") {
                    createNewTeam()
                }
                .disabled(newTeamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                          newTeamShortName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            )
        }
    }
    
    // MARK: - Team Picker Sheet (Enhanced)
    
    private var teamPickerSheet: some View {
        NavigationView {
            VStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search teams...", text: $searchText)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .padding(.horizontal)
                
                List {
                    if searchText.isEmpty {
                        // Grouped by league
                        ForEach(teamsByLeague.keys.sorted(), id: \.self) { league in
                            Section(header: Text(league)) {
                                ForEach(teamsByLeague[league] ?? [], id: \.id) { team in
                                    teamRowView(team: team)
                                }
                            }
                        }
                    } else {
                        // Flat list when searching
                        ForEach(availableTeams, id: \.id) { team in
                            teamRowView(team: team)
                        }
                    }
                }
                .listStyle(PlainListStyle())
            }
            .navigationTitle("Select Team")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    showTeamPicker = false
                },
                trailing: Button("Create New") {
                    showTeamPicker = false
                    showCreateTeamSheet = true
                }
                .foregroundColor(.green)
            )
        }
    }
    
    private func teamRowView(team: Team) -> some View {
        Button(action: {
            selectedTeam = team
            showTeamPicker = false
            searchText = ""
        }) {
            HStack {
                Circle()
                    .fill(AppDesignSystem.TeamColors.getColor(for: team))
                    .frame(width: 16, height: 16)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(team.name)
                        .foregroundColor(.primary)
                        .font(.subheadline)
                    
                    Text(team.shortName)
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                Spacer()
                
                // Show player count for this team
                let playerCount = gameSession.availablePlayers.filter { $0.team.id == team.id }.count
                if playerCount > 0 {
                    Text("\(playerCount) players")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if selectedTeam?.id == team.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Quick Add Section (unchanged)
    
    private var quickAddSection: some View {
        Section(header: Text("Quick Add Popular Players")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(popularPlayers, id: \.name) { player in
                        quickAddPlayerButton(player: player)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    private var popularPlayers: [Player] {
        // Return a subset of popular players that aren't already added
        let existingPlayerNames = Set(gameSession.availablePlayers.map { $0.name.lowercased() })
        
        return [
            Player(name: "Cristiano Ronaldo", team: SampleData.allTeams.first!, position: .forward),
            Player(name: "Lionel Messi", team: SampleData.allTeams.first!, position: .forward),
            Player(name: "Kylian Mbappé", team: SampleData.allTeams.first!, position: .forward),
            Player(name: "Erling Haaland", team: SampleData.allTeams.first!, position: .forward),
            Player(name: "Kevin De Bruyne", team: SampleData.allTeams.first!, position: .midfielder),
            Player(name: "Mohamed Salah", team: SampleData.allTeams.first!, position: .forward)
        ].filter { !existingPlayerNames.contains($0.name.lowercased()) }
    }
    
    private func quickAddPlayerButton(player: Player) -> some View {
        VStack(spacing: 4) {
            Text(player.name)
                .font(.caption)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
            
            Text(player.position.rawValue)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(6)
        .onTapGesture {
            playerName = player.name
            selectedPosition = player.position
            // Don't auto-select team, let user choose
        }
    }
    
    // MARK: - NEW: Helper Methods for Team Creation
    
    private func generateShortName(from teamName: String) -> String {
        var separators = CharacterSet.whitespacesAndNewlines
        separators.insert(charactersIn: ".,!?;:-()[]{}\"'")
        
        let words = teamName.components(separatedBy: separators)
            .filter { !$0.isEmpty }
        
        
        if words.count >= 2 {
            // Take first letter of first two words + first letter of last word if exists
            let firstTwo = words.prefix(2).map { String($0.prefix(1).uppercased()) }
            if words.count > 2 {
                return (firstTwo + [String(words.last!.prefix(1).uppercased())]).joined()
            } else {
                return (firstTwo + [String(words[0].dropFirst().prefix(1).uppercased())]).joined()
            }
        } else if !words.isEmpty {
            // Single word - take first 3 letters
            return String(words[0].prefix(3).uppercased())
        }
        
        return ""
    }
    
    private func createNewTeam() {
        let cleanTeamName = newTeamName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanShortName = newTeamShortName.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !cleanTeamName.isEmpty && !cleanShortName.isEmpty else {
            errorMessage = "Please fill in all team details."
            showError = true
            return
        }
        
        // Check if team already exists
        if availableTeams.contains(where: { $0.name.lowercased() == cleanTeamName.lowercased() }) {
            errorMessage = "A team with this name already exists."
            showError = true
            return
        }
        
        // Create new team
        let newTeam = Team(
            name: cleanTeamName,
            shortName: cleanShortName,
            logoName: "team_logo",
            primaryColor: selectedTeamColor
        )
        
        // Select the new team and close sheet
        selectedTeam = newTeam
        resetNewTeamForm()
        showCreateTeamSheet = false
        
        print("✅ Created new team: \(newTeam.name) (\(newTeam.shortName))")
    }
    
    private func resetNewTeamForm() {
        newTeamName = ""
        newTeamShortName = ""
        selectedTeamColor = "#1a73e8"
    }
    
    // MARK: - Helper Methods (enhanced)
    
    private func addPlayer() {
        // Trim whitespace
        let cleanPlayerName = playerName.trimmingCharacters(in: .whitespaces)
        
        guard let team = selectedTeam else {
            errorMessage = "Please select a team for the player."
            showError = true
            return
        }
        
        // Check if player already exists
        if gameSession.availablePlayers.contains(where: {
            $0.name.lowercased() == cleanPlayerName.lowercased() &&
            $0.team.id == team.id
        }) {
            errorMessage = "This player already exists in \(team.name)."
            showError = true
            return
        }
        
        // Create the player with the selected team
        let player = Player(
            name: cleanPlayerName,
            team: team,
            position: selectedPosition
        )
        
        // Add player to available players
        gameSession.availablePlayers.append(player)
        
        // Provide haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Clear the form
        playerName = ""
        selectedTeam = nil
        selectedPosition = .midfielder
        
        // Show success message briefly
        withAnimation {
            // Could add a success state here
        }
        
        print("✅ Added new player: \(player.name) to \(player.team.name)")
    }
}


extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
