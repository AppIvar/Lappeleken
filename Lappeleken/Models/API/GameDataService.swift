//
//  GameDataService.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

protocol GameDataService {
    func fetchPlayers() async throws -> [Player]
    func fetchTeams() async throws -> [Team]
    func recordEvent(playerId: UUID, eventType: Bet.EventType) async throws
    func fetchLiveGames() async throws -> [GameSession]
    func saveGame(gameSession: GameSession, name: String) async throws
}
