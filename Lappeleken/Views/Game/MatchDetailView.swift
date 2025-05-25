//
//  MatchDetailView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 22/05/2025.
//

import SwiftUI

struct MatchDetailView: View {
    @ObservedObject var gameSession: GameSession
    @State private var selectedTab = 0
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            // Match header with score
            if let match = gameSession.selectedMatch {
                MatchHeaderView(match: match)
            }
            
            // Tab selector
            Picker("", selection: $selectedTab) {
                Text("Lineups").tag(0)
                Text("Events").tag(1)
                Text("Stats").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Tab content
            TabView(selection: $selectedTab) {
                LineupView(gameSession: gameSession)
                    .tag(0)
                
                EventsTimelineView(gameSession: gameSession)
                    .tag(1)
                
                MatchStatsView(gameSession: gameSession)
                    .tag(2)
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        }
    }
}

// Lineup view with formation display
struct LineupView: View {
    @ObservedObject var gameSession: GameSession
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Home team lineup
                if let match = gameSession.selectedMatch {
                    TeamLineupView(team: match.homeTeam, playersWithOwners: getPlayersWithOwners(team: match.homeTeam))
                    
                    Divider()
                    
                    TeamLineupView(team: match.awayTeam, playersWithOwners: getPlayersWithOwners(team: match.awayTeam))
                }
            }
            .padding()
        }
    }
    
    // Helper to get players with their owners (participants)
    private func getPlayersWithOwners(team: Team) -> [(player: Player, participant: Participant?)] {
        let teamPlayers = gameSession.availablePlayers.filter { $0.team.id == team.id }
        return teamPlayers.map { player in
            let owner = gameSession.participants.first { participant in
                participant.selectedPlayers.contains { $0.id == player.id } ||
                participant.substitutedPlayers.contains { $0.id == player.id }
            }
            return (player, owner)
        }
    }
}
