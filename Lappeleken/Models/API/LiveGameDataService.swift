//
//  LiveGameDataService.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

// LiveGameDataService.swift
class LiveGameDataService: GameDataService {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func fetchPlayers() async throws -> [Player] {
        if AppConfig.useStubData {
            // During development, return sample data
            return SampleData.samplePlayers
        }
        
        // Real implementation would be:
        return try await apiClient.get(endpoint: "players")
    }
    
    func fetchTeams() async throws -> [Team] {
        if AppConfig.useStubData {
            return SampleData.premierLeagueTeams
        }
        
        return try await apiClient.get(endpoint: "teams")
    }
    
    func recordEvent(playerId: UUID, eventType: Bet.EventType) async throws {
        // Structure your request data
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
        
        if !AppConfig.useStubData {
            // Send the actual API request
            let _: EmptyResponse = try await apiClient.post(endpoint: "events", body: request)
        }
    }
    
    func fetchLiveGames() async throws -> [GameSession] {
        if AppConfig.useStubData {
            return []
        }
        
        return try await apiClient.get(endpoint: "games/live")
    }
    
    func saveGame(gameSession: GameSession, name: String) async throws {
        if AppConfig.useStubData {
            GameHistoryManager.shared.saveGame(gameSession, name: name)
            return
        }
        
        // Real implementation would serialize and send the game
        struct SaveGameRequest: Encodable {
            let name: String
            let gameData: Data
            
            init(name: String, gameSession: GameSession) throws {
                self.name = name
                let encoder = JSONEncoder()
                self.gameData = try encoder.encode(gameSession)
            }
        }
        
        let request = try SaveGameRequest(name: name, gameSession: gameSession)
        let _: EmptyResponse = try await apiClient.post(endpoint: "games", body: request)
    }
    
    // Helper methods for the Live Match functionality
    func fetchLiveMatches(competitionCode: String? = nil) async throws -> [Match] {
        if AppConfig.useStubData || UserDefaults.standard.bool(forKey: "useBackupData") {
            // Use the same mock matches that EventDrivenManager uses
            return await EventDrivenManager.createMockMatches()
        }
        
        do {
            let endpoint = competitionCode != nil ?
                "matches?status=LIVE,IN_PLAY&competitions=\(competitionCode!)" :
                "matches?status=LIVE,IN_PLAY"
            
            let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
            return response.matches.map { $0.toAppModel() }
        } catch {
            print("⚠️ API failed, using mock data for testing")
            return await EventDrivenManager.createMockMatches()
        }
    }
    
    private func createDummyMatches() -> [Match] {
        // Create a few dummy matches for testing
        let arsenalTeam = Team(
            name: "Arsenal FC",
            shortName: "ARS",
            logoName: "arsenal_logo",
            primaryColor: "#EF0107"
        )
        
        let manchesterCity = Team(
            name: "Manchester City",
            shortName: "MCI",
            logoName: "mancity_logo",
            primaryColor: "#6CABDD"
        )
        
        let liverpool = Team(
            name: "Liverpool",
            shortName: "LIV",
            logoName: "liverpool_logo",
            primaryColor: "#C8102E"
        )
        
        let chelsea = Team(
            name: "Chelsea",
            shortName: "CHE",
            logoName: "chelsea_logo",
            primaryColor: "#034694"
        )
        
        let premierLeague = Competition(
            id: "PL",
            name: "Premier League",
            code: "PL"
        )
        
        let championsLeague = Competition(
            id: "CL",
            name: "UEFA Champions League",
            code: "CL"
        )
        
        // Create some matches at different times and statuses
        return [
            Match(
                id: "1",
                homeTeam: arsenalTeam,
                awayTeam: manchesterCity,
                startTime: Date().addingTimeInterval(3600), // in 1 hour
                status: .upcoming,
                competition: premierLeague
            ),
            Match(
                id: "2",
                homeTeam: liverpool,
                awayTeam: chelsea,
                startTime: Date().addingTimeInterval(-1800), // started 30 min ago
                status: .inProgress,
                competition: premierLeague
            ),
            Match(
                id: "3",
                homeTeam: manchesterCity,
                awayTeam: chelsea,
                startTime: Date().addingTimeInterval(86400), // tomorrow
                status: .upcoming,
                competition: championsLeague
            )
        ]
    }
}

// Helper type for endpoints that return no content
struct EmptyResponse: Decodable {}
