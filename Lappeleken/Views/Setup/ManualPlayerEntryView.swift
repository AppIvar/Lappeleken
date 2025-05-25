//
//  ManualPlayerEntryView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 09/05/2025.
//

import SwiftUI

struct ManualPlayerEntryView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @State private var playerName = ""
    @State private var teamName = ""
    @State private var selectedPosition = Player.Position.midfielder
    @State private var showTeamPicker = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    // Get existing team names for autocomplete
    private var existingTeams: [String] {
        let teams = gameSession.availablePlayers.map { $0.team.name }
        return Array(Set(teams)).sorted()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Player Details")) {
                    TextField("Player Name", text: $playerName)
                        .autocapitalization(.words)
                    
                    VStack(alignment: .leading) {
                        if showTeamPicker {
                            Picker("Select Existing Team", selection: $teamName) {
                                ForEach(existingTeams, id: \.self) { team in
                                    Text(team).tag(team)
                                }
                            }
                            .pickerStyle(WheelPickerStyle())
                            
                            Button("Enter Custom Team") {
                                showTeamPicker = false
                            }
                            .font(.caption)
                            .padding(.top, 5)
                        } else {
                            HStack {
                                TextField("Team Name", text: $teamName)
                                    .autocapitalization(.words)
                                
                                if !existingTeams.isEmpty {
                                    Button("Pick Team") {
                                        showTeamPicker = true
                                    }
                                    .font(.caption)
                                }
                            }
                        }
                    }
                    
                    Picker("Position", selection: $selectedPosition) {
                        ForEach(Player.Position.allCases, id: \.self) { position in
                            Text(position.rawValue).tag(position)
                        }
                    }
                }
                
                Section {
                    Button("Add Player") {
                        addPlayer()
                    }
                    .disabled(playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                              teamName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Add Player Manually")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Cannot Add Player"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }

    
    private func addPlayer() {
        // Trim whitespace
        let cleanPlayerName = playerName.trimmingCharacters(in: .whitespaces)
        let cleanTeamName = teamName.trimmingCharacters(in: .whitespaces)
        
        // Check if player already exists
        if gameSession.availablePlayers.contains(where: {
            $0.name.lowercased() == cleanPlayerName.lowercased() &&
            $0.team.name.lowercased() == cleanTeamName.lowercased()
        }) {
            errorMessage = "This player already exists in the database."
            showError = true
            return
        }
        
        // Look for existing team with the same name
        let existingTeam = gameSession.availablePlayers
            .map { $0.team }
            .first { $0.name.lowercased() == cleanTeamName.lowercased() }
        
        // Use existing team or create new one
        let team: Team
        if let existingTeam = existingTeam {
            team = existingTeam
        } else {
            // Create a new team
            team = Team(
                name: cleanTeamName,
                shortName: String(cleanTeamName.prefix(3)).uppercased(),
                logoName: "custom_team_logo",
                primaryColor: "#777777"
            )
        }
        
        // Create a player
        let player = Player(
            name: cleanPlayerName,
            team: team,
            position: selectedPosition
        )
        
        // Add player to available players
        gameSession.availablePlayers.append(player)
        
        // Debug log
        print("Added new player: \(player.name) (\(player.team.name))")
        
        // Clear the form
        playerName = ""
        teamName = ""
        selectedPosition = .midfielder
    }
}
