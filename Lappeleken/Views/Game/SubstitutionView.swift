//
//  SubstitutionView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 12/05/2025.
//

import SwiftUI

struct SubstitutionView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedPlayerOff: Player? = nil
    @State private var newPlayerName: String = ""
    @State private var newPlayerTeam: Team? = nil
    @State private var newPlayerPosition = Player.Position.midfielder
    
    // For existing player selection
    @State private var useExistingPlayer = false
    @State private var selectedExistingPlayer: Player? = nil
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Select Player to Substitute")) {
                    if gameSession.participants.flatMap({ $0.selectedPlayers }).isEmpty {
                        Text("No players assigned yet")
                            .foregroundColor(AppDesignSystem.Colors.error)
                    } else {
                        ForEach(gameSession.participants) { participant in
                            Section(header: Text(participant.name)) {
                                ForEach(participant.selectedPlayers) { player in
                                    Button(action: {
                                        selectedPlayerOff = player
                                        // Set default team to same as player going off
                                        newPlayerTeam = player.team
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(player.name)
                                                    .font(.body)
                                                Text("\(player.team.name) · \(player.position.rawValue)")
                                                    .font(.caption)
                                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                            }
                                            
                                            Spacer()
                                            
                                            if selectedPlayerOff?.id == player.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(AppDesignSystem.Colors.primary)
                                            }
                                        }
                                    }
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                }
                            }
                        }
                    }
                }
                
                if selectedPlayerOff != nil {
                    Section(header: Text("New Player")) {
                        Toggle("Use Existing Player", isOn: $useExistingPlayer)
                        
                        if useExistingPlayer {
                            // Show list of available players not currently assigned
                            let availablePlayers = gameSession.availablePlayers.filter { player in
                                !gameSession.participants.flatMap({ $0.selectedPlayers }).contains(where: { $0.id == player.id })
                            }
                            
                            if availablePlayers.isEmpty {
                                Text("No available existing players")
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            } else {
                                ForEach(availablePlayers) { player in
                                    Button(action: {
                                        selectedExistingPlayer = player
                                    }) {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(player.name)
                                                    .font(.body)
                                                Text("\(player.team.name) · \(player.position.rawValue)")
                                                    .font(.caption)
                                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                            }
                                            
                                            Spacer()
                                            
                                            if selectedExistingPlayer?.id == player.id {
                                                Image(systemName: "checkmark")
                                                    .foregroundColor(AppDesignSystem.Colors.primary)
                                            }
                                        }
                                    }
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                }
                            }
                        } else {
                            // Create new player
                            TextField("Player Name", text: $newPlayerName)
                            
                            Picker("Team", selection: $newPlayerTeam) {
                                Text("Select Team").tag(nil as Team?)
                                ForEach(SampleData.premierLeagueTeams) { team in
                                    Text(team.name).tag(team as Team?)
                                }
                            }
                            
                            Picker("Position", selection: $newPlayerPosition) {
                                ForEach(Player.Position.allCases, id: \.self) { position in
                                    Text(position.rawValue).tag(position)
                                }
                            }
                        }
                    }
                    
                    if let playerOff = selectedPlayerOff {
                        Section {
                            Button(action: {
                                if useExistingPlayer {
                                    if let playerOn = selectedExistingPlayer {
                                        gameSession.substitutePlayer(playerOff: playerOff, playerOn: playerOn)
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                } else {
                                    if !newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                                       let team = newPlayerTeam {
                                        // Create new player
                                        let playerOn = Player(
                                            name: newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines),
                                            team: team,
                                            position: newPlayerPosition
                                        )
                                        
                                        gameSession.substitutePlayer(playerOff: playerOff, playerOn: playerOn)
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                }
                            }) {
                                Text("Complete Substitution")
                                    .bold()
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(AppDesignSystem.Colors.primary)
                                    .cornerRadius(8)
                            }
                            .disabled((useExistingPlayer && selectedExistingPlayer == nil) ||
                                     (!useExistingPlayer && (newPlayerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || newPlayerTeam == nil)))
                        }
                    }
                }
            }
            .navigationTitle("Player Substitution")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}
