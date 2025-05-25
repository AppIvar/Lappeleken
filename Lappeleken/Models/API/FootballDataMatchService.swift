//
//  FootballDataMatchService.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//


import Foundation

class FootballDataMatchService: MatchService {
    private let apiClient: APIClient
    private let apiKey: String
    
    // Cache to reduce API calls
    private var matchCache: [String: Match] = [:]
    private var playerCache: [String: [Player]] = [:]
    
    init(apiClient: APIClient, apiKey: String) {
        self.apiClient = apiClient
        self.apiKey = apiKey
    }
    
    // MARK: - Competition Methods
    
    func fetchCompetitions() async throws -> [Competition] {
        let response: CompetitionsResponse = try await apiClient.footballDataRequest(endpoint: "competitions")
        // Filter for major leagues you're interested in
        return response.competitions
            .filter { ["PL", "BL1", "SA", "PD", "CL", "EL"].contains($0.code) }
            .map { $0.toAppModel() }
    }
    
    // MARK: - Enhanced Match Fetching Methods
    
    func fetchTodaysMatches() async throws -> [Match] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let endpoint = "matches?dateFrom=\(today)&dateTo=\(today)"
        print("🗓️ Fetching today's matches with endpoint: \(endpoint)")
        
        let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        let matches = response.matches.map { $0.toAppModel() }
        
        print("📊 Found \(matches.count) matches for today")
        for match in matches {
            print("  • \(match.homeTeam.name) vs \(match.awayTeam.name) (\(match.competition.name)) - \(match.status)")
        }
        
        return matches
    }

    func fetchMatchesInDateRange(days: Int = 7) async throws -> [Match] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
        
        let fromDate = dateFormatter.string(from: today)
        let toDate = dateFormatter.string(from: futureDate)
        
        let endpoint = "matches?dateFrom=\(fromDate)&dateTo=\(toDate)"
        print("📅 Fetching matches from \(fromDate) to \(toDate)")
        
        let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        let matches = response.matches.map { $0.toAppModel() }
        
        print("📊 Found \(matches.count) matches in date range")
        
        // Group by competition for debugging
        let matchesByCompetition = Dictionary(grouping: matches) { $0.competition.code }
        for (competition, competitionMatches) in matchesByCompetition {
            print("  \(competition): \(competitionMatches.count) matches")
        }
        
        return matches
    }
    
    // MARK: - Main Match Service Protocol Methods
    
    func fetchLiveMatches(competitionCode: String? = nil) async throws -> [Match] {
        print("🔴 Attempting to fetch live matches...")
        
        // First try to get live matches
        do {
            var endpoint = "matches?status=LIVE,IN_PLAY"
            if let code = competitionCode {
                endpoint += "&competitions=\(code)"
            }
            
            print("🎯 Live matches endpoint: \(endpoint)")
            let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
            let liveMatches = response.matches.map { $0.toAppModel() }
            
            // Update cache
            for match in liveMatches {
                matchCache[match.id] = match
            }
            
            if !liveMatches.isEmpty {
                print("✅ Found \(liveMatches.count) live matches")
                return liveMatches
            }
            
            print("⚪ No live matches found, checking today's matches...")
            
            // If no live matches, get today's matches
            let todaysMatches = try await fetchTodaysMatches()
            
            if !todaysMatches.isEmpty {
                print("📅 Returning \(todaysMatches.count) matches from today")
                return todaysMatches
            }
            
            print("📆 No matches today, getting upcoming matches...")
            
            // If no matches today, get upcoming matches in next week
            return try await fetchMatchesInDateRange(days: 7)
            
        } catch let error as APIError {
            print("❌ API Error in fetchLiveMatches: \(error)")
            
            if case .serverError(let code, let message) = error {
                print("Server error \(code): \(message)")
            }
            
            // Try fallback to today's matches
            do {
                print("🔄 Falling back to today's matches...")
                return try await fetchTodaysMatches()
            } catch {
                print("❌ Fallback also failed: \(error)")
                
                // Final fallback - try upcoming matches
                print("🔄 Final fallback to upcoming matches...")
                return try await fetchUpcomingMatches(competitionCode: competitionCode)
            }
        }
    }

    func fetchUpcomingMatches(competitionCode: String? = nil) async throws -> [Match] {
        print("⏭️ Fetching upcoming matches...")
        
        // Try multiple strategies
        let strategies: [() async throws -> [Match]] = [
            // Strategy 1: Standard upcoming matches
            { () async throws -> [Match] in
                var endpoint = "matches?status=SCHEDULED"
                if let code = competitionCode {
                    endpoint += "&competitions=\(code)"
                }
                print("🎯 Strategy 1 - Endpoint: \(endpoint)")
                let response: MatchesResponse = try await self.apiClient.footballDataRequest(endpoint: endpoint)
                let matches = response.matches.map { $0.toAppModel() }
                
                // Update cache
                for match in matches {
                    self.matchCache[match.id] = match
                }
                
                return matches
            },
            
            // Strategy 2: Today's matches
            { () async throws -> [Match] in
                print("🎯 Strategy 2 - Today's matches")
                return try await self.fetchTodaysMatches()
            },
            
            // Strategy 3: Next 7 days
            { () async throws -> [Match] in
                print("🎯 Strategy 3 - Next 7 days")
                return try await self.fetchMatchesInDateRange(days: 7)
            },
            
            // Strategy 4: Specific competition approach
            { () async throws -> [Match] in
                print("🎯 Strategy 4 - Competition-specific approach")
                if let code = competitionCode {
                    let endpoint = "competitions/\(code)/matches?status=SCHEDULED"
                    let response: MatchesResponse = try await self.apiClient.footballDataRequest(endpoint: endpoint)
                    return response.matches.map { $0.toAppModel() }
                }
                return []
            }
        ]
        
        for (index, strategy) in strategies.enumerated() {
            do {
                let matches = try await strategy()
                if !matches.isEmpty {
                    print("✅ Strategy \(index + 1) found \(matches.count) matches")
                    return matches
                }
                print("⚪ Strategy \(index + 1) returned no matches")
            } catch {
                print("❌ Strategy \(index + 1) failed: \(error)")
            }
        }
        
        print("❌ All strategies failed, returning empty array")
        return []
    }
    
    // MARK: - Match Details and Players
    
    func fetchMatchDetails(matchId: String) async throws -> MatchDetail {
        let endpoint = "matches/\(matchId)"
        let response: APIMatchDetail = try await apiClient.footballDataRequest(endpoint: endpoint)
        return response.toAppModel()
    }
    
    func fetchMatchPlayers(matchId: String) async throws -> [Player] {
        // Check cache first
        if let cachedPlayers = playerCache[matchId] {
            return cachedPlayers
        }
        
        let endpoint = "matches/\(matchId)"
        let response: APIMatchDetail = try await apiClient.footballDataRequest(endpoint: endpoint)
        
        // Convert API players to app model players
        var players: [Player] = []
        
        // Add home team players - handle optional squad
        if let squad = response.homeTeam.squad, !squad.isEmpty {
            for player in squad {
                players.append(player.toAppModel(team: response.homeTeam.toAppModel()))
            }
        } else {
            // Generate dummy players for this team if no squad data available
            print("No squad data available for home team, generating dummy players")
            let homeTeam = response.homeTeam.toAppModel()
            players.append(contentsOf: generateDummyPlayers(for: homeTeam))
        }
        
        // Add away team players - handle optional squad
        if let squad = response.awayTeam.squad, !squad.isEmpty {
            for player in squad {
                players.append(player.toAppModel(team: response.awayTeam.toAppModel()))
            }
        } else {
            // Generate dummy players for this team if no squad data available
            print("No squad data available for away team, generating dummy players")
            let awayTeam = response.awayTeam.toAppModel()
            players.append(contentsOf: generateDummyPlayers(for: awayTeam))
        }
        
        // If still no players found, something went wrong
        if players.isEmpty {
            print("No players available from API, using backup data")
            players = createDummyPlayers()
        }
        
        // Update cache
        playerCache[matchId] = players
        
        return players
    }
    
    // MARK: - Premium Features
    
    func fetchMatchLineup(matchId: String) async throws -> Lineup {
        let endpoint = "matches/\(matchId)/lineup"
        print("🏟️ Fetching lineup for match \(matchId) with premium endpoint: \(endpoint)")
        let response: APILineup = try await apiClient.footballDataRequest(endpoint: endpoint)
        return response.toAppModel()
    }
    
    func fetchLiveMatchDetails(matchId: String) async throws -> MatchWithEvents {
        let endpoint = "matches/\(matchId)"
        print("📊 Fetching live match details for match \(matchId)")
        let response: APIMatchWithEvents = try await apiClient.footballDataRequest(endpoint: endpoint)
        return response.toAppModel()
    }
    
    func fetchTeamSquad(teamId: String) async throws -> TeamSquad {
        let endpoint = "teams/\(teamId)"
        print("👥 Fetching team squad for team \(teamId)")
        let response: APITeamSquad = try await apiClient.footballDataRequest(endpoint: endpoint)
        return response.toAppModel()
    }
    
    func enhancedMatchMonitoring(matchId: String, updateInterval: TimeInterval = 60, onUpdate: @escaping (MatchUpdate) -> Void) -> Task<Void, Never> {
        return Task {
            var previousEvents: [MatchEvent] = []
            
            while !Task.isCancelled {
                do {
                    let matchWithEvents = try await fetchLiveMatchDetails(matchId: matchId)
                    
                    // Find new events by comparing with previous events
                    let newEvents = matchWithEvents.events.filter { event in
                        !previousEvents.contains { $0.id == event.id }
                    }
                    
                    if !newEvents.isEmpty {
                        previousEvents = matchWithEvents.events
                        
                        let update = MatchUpdate(
                            match: matchWithEvents.match,
                            newEvents: newEvents
                        )
                        
                        onUpdate(update)
                    }
                    
                    // Adjust polling frequency based on match status
                    let interval: TimeInterval
                    switch matchWithEvents.match.status {
                    case .inProgress: interval = 30  // Every 30 seconds during play
                    case .halftime: interval = 120   // Every 2 minutes during halftime
                    case .upcoming: interval = 300   // Every 5 minutes before match
                    case .completed: return          // Stop polling for completed matches
                    case .unknown: interval = 60     // Default to 1 minute
                    }
                    
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                } catch {
                    // Handle all errors the same way to avoid throwing
                    print("Error monitoring match: \(error)")
                    do {
                        try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                    } catch {
                        // If sleep fails, just continue the loop
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Match Events and Monitoring
    
    func fetchMatchEvents(matchId: String) async throws -> [MatchEvent] {
        // With premium subscription, we could potentially get more detailed events
        // For now, we'll keep the existing implementation
        _ = matchCache[matchId]
        let currentMatch = try await fetchMatchDetails(matchId: matchId)
        
        let events: [MatchEvent] = []
        
        // Cache the new state
        matchCache[matchId] = currentMatch.match
        
        return events
    }
    
    func startMonitoringMatch(matchId: String, updateInterval: TimeInterval = 60, onUpdate: @escaping (MatchUpdate) -> Void) -> Task<Void, Never> {
        return Task {
            while !Task.isCancelled {
                do {
                    let matchDetails = try await fetchMatchDetails(matchId: matchId)
                    let events = try await fetchMatchEvents(matchId: matchId)
                    
                    let update = MatchUpdate(
                        match: matchDetails.match,
                        newEvents: events
                    )
                    
                    onUpdate(update)
                    
                    // Adjust polling frequency based on match status
                    let interval: TimeInterval
                    switch matchDetails.match.status {
                    case .inProgress: interval = 30  // Every 30 seconds during play
                    case .halftime: interval = 120   // Every 2 minutes during halftime
                    case .upcoming: interval = 300   // Every 5 minutes before match
                    case .completed:
                        return  // Stop polling for completed matches
                    case .unknown:
                        interval = 60  // Default to 1 minute
                    }
                    
                    try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                } catch {
                    // Handle all errors the same way to avoid throwing
                    print("Error monitoring match: \(error)")
                    do {
                        try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                    } catch {
                        // If sleep fails, just continue the loop
                        break
                    }
                }
            }
        }
    }
    
    // MARK: - Testing and Debugging Methods
    
    func testBundesligaSpecifically() async {
        print("🇩🇪 Testing Bundesliga Specifically...")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let endpoints = [
            "competitions/BL1/matches?status=SCHEDULED",
            "competitions/BL1/matches?dateFrom=\(today)&dateTo=\(today)",
            "matches?competitions=BL1&dateFrom=\(today)&dateTo=\(today)",
            "matches?competitions=BL1&status=SCHEDULED",
            "matches?dateFrom=\(today)&dateTo=\(today)" // All matches today
        ]
        
        for (index, endpoint) in endpoints.enumerated() {
            do {
                print("\n\(index + 1)️⃣ Testing endpoint: \(endpoint)")
                let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
                print("✅ Success! Found \(response.matches.count) matches")
                
                let bundesligaMatches = response.matches.filter { $0.competition.code == "BL1" }
                print("   📊 Bundesliga matches: \(bundesligaMatches.count)")
                
                for match in bundesligaMatches {
                    print("  • \(match.homeTeam.name) vs \(match.awayTeam.name)")
                    print("    Date: \(match.utcDate)")
                    print("    Status: \(match.status)")
                }
            } catch {
                print("❌ Failed: \(error)")
            }
        }
    }
    
    // MARK: - Private Helper Methods
    
    private func createDummyPlayers() -> [Player] {
        // Create teams
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
        
        // Create players
        var players: [Player] = []
        
        // Arsenal players
        players.append(Player(name: "Bukayo Saka", team: arsenalTeam, position: .forward))
        players.append(Player(name: "Martin Ødegaard", team: arsenalTeam, position: .midfielder))
        players.append(Player(name: "Declan Rice", team: arsenalTeam, position: .midfielder))
        
        // Man City players
        players.append(Player(name: "Erling Haaland", team: manchesterCity, position: .forward))
        players.append(Player(name: "Kevin De Bruyne", team: manchesterCity, position: .midfielder))
        players.append(Player(name: "Phil Foden", team: manchesterCity, position: .midfielder))
        
        return players
    }

    private func generateDummyPlayers(for team: Team) -> [Player] {
        var players: [Player] = []
        
        let positions = [
            Player.Position.goalkeeper,
            Player.Position.defender, Player.Position.defender, Player.Position.defender, Player.Position.defender,
            Player.Position.midfielder, Player.Position.midfielder, Player.Position.midfielder,
            Player.Position.forward, Player.Position.forward, Player.Position.forward
        ]
        
        // Generate 11 players (standard team size)
        for i in 1...11 {
            let position = positions[i-1]
            let positionAbbr = String(position.rawValue.prefix(3)).uppercased()
            
            let player = Player(
                name: "\(team.name) Player \(i) (\(positionAbbr))",
                team: team,
                position: position
            )
            players.append(player)
        }
        
        return players
    }
}
