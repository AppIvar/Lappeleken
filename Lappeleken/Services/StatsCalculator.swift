//
//  StatsCalculator.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 16/05/2025.
//
import Foundation

struct StatsCalculator {
    let gameSession: GameSession
    
    struct TeamStats: Identifiable {
        let id = UUID()
        let team: Team
        let goals: Int
        let assists: Int
        let yellowCards: Int
        let redCards: Int
        let players: Int
    }
    
    struct PlayerStats: Identifiable {
        let id = UUID()
        let player: Player
        let participant: String
        let eventsCount: Int
        let pointsGenerated: Double
        
        var efficiency: Double {
            if eventsCount == 0 {
                return 0.0
            }
            return pointsGenerated / Double(eventsCount)
        }
    }
    
    struct ParticipantStats: Identifiable {
        let id = UUID()
        let participant: Participant
        let totalEvents: Int
        let mostValuablePlayer: Player?
        let roi: Double // Return on investment
    }
    
    func calculateTeamStats() -> [TeamStats] {
        // Get all teams from available players
        let teams = Set(gameSession.availablePlayers.map { $0.team })
        
        var teamStats: [TeamStats] = []
        
        for team in teams {
            let teamPlayers = gameSession.availablePlayers.filter { $0.team.id == team.id }
            
            let goals = teamPlayers.reduce(0) { $0 + $1.goals }
            let assists = teamPlayers.reduce(0) { $0 + $1.assists }
            let yellowCards = teamPlayers.reduce(0) { $0 + $1.yellowCards }
            let redCards = teamPlayers.reduce(0) { $0 + $1.redCards }
            
            teamStats.append(TeamStats(
                team: team,
                goals: goals,
                assists: assists,
                yellowCards: yellowCards,
                redCards: redCards,
                players: teamPlayers.count
            ))
        }
        
        return teamStats.sorted { $0.goals > $1.goals }
    }
    
    func calculatePlayerStats() -> [PlayerStats] {
        var playerStats: [PlayerStats] = []
        
        // Function to calculate points generated by a player
        func calculatePoints(for player: Player) -> Double {
            let playerEvents = gameSession.events.filter { $0.player.id == player.id }
            var totalPoints = 0.0
            
            for event in playerEvents {
                if let bet = gameSession.bets.first(where: { $0.eventType == event.eventType }) {
                    // Calculate how many participants benefited from this event
                    let participantsWithPlayer = gameSession.participants.filter { participant in
                        participant.selectedPlayers.contains { $0.id == player.id } ||
                        participant.substitutedPlayers.contains { $0.id == player.id }
                    }
                    
                    let participantsWithoutPlayer = gameSession.participants.filter { participant in
                        !participant.selectedPlayers.contains { $0.id == player.id } &&
                        !participant.substitutedPlayers.contains { $0.id == player.id }
                    }
                    
                    if !participantsWithPlayer.isEmpty && !participantsWithoutPlayer.isEmpty {
                        let totalAmount = Double(participantsWithoutPlayer.count) * bet.amount
                        let amountPerWinner = totalAmount / Double(participantsWithPlayer.count)
                        totalPoints += amountPerWinner
                    }
                }
            }
            
            return totalPoints
        }
        
        // Get owner for each player
        for participant in gameSession.participants {
            // Active players
            for player in participant.selectedPlayers {
                let points = calculatePoints(for: player)
                let eventsCount = gameSession.events.filter { $0.player.id == player.id }.count
                
                playerStats.append(PlayerStats(
                    player: player,
                    participant: participant.name,
                    eventsCount: eventsCount,
                    pointsGenerated: points
                ))
            }
            
            // Substituted players
            for player in participant.substitutedPlayers {
                let points = calculatePoints(for: player)
                let eventsCount = gameSession.events.filter { $0.player.id == player.id }.count
                
                playerStats.append(PlayerStats(
                    player: player,
                    participant: participant.name + " (Subbed Off)",
                    eventsCount: eventsCount,
                    pointsGenerated: points
                ))
            }
        }
        
        return playerStats.sorted { $0.pointsGenerated > $1.pointsGenerated }
    }
    
    func calculateParticipantStats() -> [ParticipantStats] {
        var participantStats: [ParticipantStats] = []
        
        for participant in gameSession.participants {
            // All players (active and substituted)
            let allPlayers = participant.selectedPlayers + participant.substitutedPlayers
            
            // Count total events
            let events = gameSession.events.filter { event in
                allPlayers.contains { $0.id == event.player.id }
            }
            
            // Find most valuable player (player with most events)
            let playerEventCounts = allPlayers.map { player in
                (player, gameSession.events.filter { $0.player.id == player.id }.count)
            }
            
            let mvp = playerEventCounts
                .sorted { $0.1 > $1.1 }
                .first?
                .0
            
            // Calculate ROI (balance / total player count)
            let roi = participant.balance / Double(allPlayers.count)
            
            participantStats.append(ParticipantStats(
                participant: participant,
                totalEvents: events.count,
                mostValuablePlayer: mvp,
                roi: roi
            ))
        }
        
        return participantStats.sorted { $0.roi > $1.roi }
    }
}
