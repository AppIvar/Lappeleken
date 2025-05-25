//
//  OfflineGameDataService.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

class OfflineGameDataService: GameDataService {
    func fetchPlayers() async throws -> [Player] {
        return SampleData.samplePlayers
    }
    
    func fetchTeams() async throws -> [Team] {
        return SampleData.premierLeagueTeams
    }
    
    func recordEvent(playerId: UUID, eventType: Bet.EventType) async throws {
        
    }
    
    func fetchLiveGames() async throws -> [GameSession] {
        return []
    }
    
    func saveGame(gameSession: GameSession, name: String) async throws {
        GameHistoryManager.shared.saveGame(gameSession, name: name)
    }
}
