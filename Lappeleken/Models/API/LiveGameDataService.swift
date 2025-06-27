//
//  LiveGameDataService.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

class LiveGameDataService: GameDataService {
    private let apiClient: APIClient
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
    }
    
    func fetchPlayers() async throws -> [Player] {
        // Use API when available, fallback to sample data
        do {
            return try await apiClient.get(endpoint: "players")
        } catch {
            print("⚠️ API unavailable, using sample data: \(error)")
            return SampleData.samplePlayers
        }
    }
    
    func fetchTeams() async throws -> [Team] {
        do {
            return try await apiClient.get(endpoint: "teams")
        } catch {
            print("⚠️ API unavailable, using sample teams: \(error)")
            return SampleData.premierLeagueTeams
        }
    }
    
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
            print("✅ Event recorded via API: \(eventType.rawValue) for player \(playerId)")
        } catch {
            print("⚠️ Failed to record event via API: \(error)")
            // Continue without throwing - allow offline play
        }
    }
    
    func fetchLiveGames() async throws -> [GameSession] {
        do {
            return try await apiClient.get(endpoint: "games/live")
        } catch {
            print("⚠️ No live games available from API: \(error)")
            return []
        }
    }
    
    func saveGame(gameSession: GameSession, name: String) async throws {
        do {
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
            print("✅ Game saved to cloud: \(name)")
        } catch {
            print("⚠️ Cloud save failed, using local save: \(error)")
            GameHistoryManager.shared.saveGame(gameSession, name: name)
        }
    }
    
    // Enhanced live matches with proper fallback
    func fetchLiveMatches(competitionCode: String? = nil) async throws -> [Match] {
        do {
            let endpoint = competitionCode != nil ?
                "matches?status=LIVE,IN_PLAY&competitions=\(competitionCode!)" :
                "matches?status=LIVE,IN_PLAY"
            
            let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
            let matches = response.matches.map { $0.toAppModel() }
            
            if matches.isEmpty {
                print("⚪ No live matches from API, using mock data for demo")
                return createDemoMatches()
            }
            
            return matches
        } catch {
            print("⚠️ Live matches API failed, using demo matches: \(error)")
            return createDemoMatches()
        }
    }
    
    // Create realistic demo matches
    private func createDemoMatches() -> [Match] {
        let now = Date()
        let calendar = Calendar.current
        
        // Create matches at different realistic times
        let matches = [
            createMatch(
                home: "Arsenal", homeShort: "ARS", homeColor: "#EF0107",
                away: "Chelsea", awayShort: "CHE", awayColor: "#034694",
                startTime: calendar.date(byAdding: .minute, value: -30, to: now)!,
                status: .inProgress
            ),
            createMatch(
                home: "Manchester City", homeShort: "MCI", homeColor: "#6CABDD",
                away: "Liverpool", awayShort: "LIV", awayColor: "#C8102E",
                startTime: calendar.date(byAdding: .hour, value: 2, to: now)!,
                status: .upcoming
            ),
            createMatch(
                home: "Manchester United", homeShort: "MUN", homeColor: "#DA020E",
                away: "Tottenham", awayShort: "TOT", awayColor: "#132257",
                startTime: calendar.date(byAdding: .minute, value: 15, to: now)!,
                status: .upcoming
            )
        ]
        
        return matches
    }
    
    private func createMatch(home: String, homeShort: String, homeColor: String,
                           away: String, awayShort: String, awayColor: String,
                           startTime: Date, status: MatchStatus) -> Match {
        let homeTeam = Team(
            name: home,
            shortName: homeShort,
            logoName: homeShort.lowercased(),
            primaryColor: homeColor
        )
        
        let awayTeam = Team(
            name: away,
            shortName: awayShort,
            logoName: awayShort.lowercased(),
            primaryColor: awayColor
        )
        
        let competition = Competition(
            id: "PL",
            name: "Premier League",
            code: "PL"
        )
        
        return Match(
            id: "demo_\(homeShort)_vs_\(awayShort)",
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            startTime: startTime,
            status: status,
            competition: competition
        )
    }
}

// Helper type for endpoints that return no content
struct EmptyResponse: Decodable {}
