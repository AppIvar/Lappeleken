//
//  LiveGameDataService.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

class LiveGameDataService: GameDataService {
    private let apiClient: APIClient
    
    init (apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    // MARK: - Event Recording
    
    /// Record a game event to backend
    /// - Parameters:
    ///   - playerId: UUID of the player
    ///   - eventType: Type of event (goal, card, etc.)
    func recordEvent(playerId: UUID, eventType: Bet.EventType) async throws {
        struct EventRequest: Encodable {
            let playerId: UUID
            let eventType: String
            let timestamp: Date
        }
        
        let request = EventRequest(
            playerId: playerId,
            eventType: eventType.rawValue,
            timestamp: Date()
        )
        
        do {
            let _: EmptyResponse = try await apiClient.post(endpoint: "events", body: request)
            print("✅ Event recorded: \(eventType.rawValue) for player \(playerId)")
        } catch {
            print("⚠️ Failed to record event: \(error)")
            // Don't throw - allow offline play
        }
    }
    
    // MARK: - Game Management
    
    /// Fetch active live games from backend
    func fetchLiveGames() async throws -> [GameSession] {
        do {
            return try await apiClient.get(endpoint: "games/live")
        } catch {
            print("⚠️ No live games available: \(error)")
            return []
        }
    }
    
    /// Save game to backend
    ///  - Parameters
    ///    - gameSession: The game session to save
    ///    - name: Name for the saved game
    func saveGame(gameSession: GameSession, name: String) async throws {
        struct SaveGameRequest: Encodable {
            let name: String
            let gameData: Data
            
            init(name: String, gameSession: GameSession) throws {
                self.name = name
                let encoder = JSONEncoder()
                self.gameData = try encoder.encode(gameSession)
            }
        }
        
        do {
            let request = try SaveGameRequest(name: name, gameSession: gameSession)
            let _: EmptyResponse = try await apiClient.post(endpoint: "games", body: request)
            print("✅ Game saved to cloud: \(name)")
        } catch {
            print("⚠️ Cloud save failed, using local save: \(error)")
            // Fallback to local save
            GameHistoryManager.shared.saveGame(gameSession, name: name)
        }
    }
    
    // MARK: - Legacy/Fallback Methods
    // These were used for demo/offline mode - can be removed
    
    func fetchPlayers() async throws -> [Player] {
        // This seems to be unused - remove if not needed
        do {
            return try await apiClient.get(endpoint: "players")
        } catch {
            print("⚠️ API unavailable, using sample data: \(error)")
            return SampleData.samplePlayers
        }
    }
    
    func fetchTeams() async throws -> [Team] {
        // This seems to be unused - remove if not needed
        do {
            return try await apiClient.get(endpoint: "teams")
        } catch {
            print("⚠️ API unavailable, using sample teams: \(error)")
            return SampleData.premierLeagueTeams
        }
    }
}

struct EmptyResponse: Decodable {}

