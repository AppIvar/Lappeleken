//
//  FootballDataMatchService.swift
//  Lucky Football Slip
//
//  Clean implementation based on football-data.org v4 API
//

import Foundation

// MARK: - MatchService Protocol

protocol MatchService {
    func fetchCompetitions() async throws -> [Competition]
    func fetchUpcomingMatches(competitionCode: String?) async throws -> [Match]
    func fetchLiveMatches(competitionCode: String?) async throws -> [Match]
    func fetchMatchDetails(matchId: String) async throws -> MatchDetail
    func fetchMatchPlayers(matchId: String) async throws -> [Player]
    func fetchMatchEvents(matchId: String) async throws -> [MatchEvent]
    
    func monitorMatch(
        matchId: String,
        onUpdate: @escaping (MatchUpdate) -> Void
    ) -> Task<Void, Error>
    
    // Premium features
    func fetchMatchLineup(matchId: String) async throws -> Lineup
    func fetchLiveMatchDetails(matchId: String) async throws -> MatchWithEvents
    func fetchTeamSquad(teamId: String) async throws -> TeamSquad
}

struct MatchUpdate {
    let match: Match
    let newEvents: [MatchEvent]
}

// MARK: - FootballDataMatchService Implementation

class FootballDataMatchService: MatchService {
    private let apiClient: APIClient
    private let apiKey: String
    
    // Track monitoring tasks for each match
    private var monitoringTasks: [String: Task<Void, Error>] = [:]
    
    init(apiClient: APIClient, apiKey: String) {
        self.apiClient = apiClient
        self.apiKey = apiKey
    }
    
    // MARK: - Competition Resource
    // https://api.football-data.org/v4/competitions
    
    /// Fetch all available competitions
    /// Filtered to major leagues: PL, BL1, SA, PD, CL, EL
    func fetchCompetitions() async throws -> [Competition] {
        let response: CompetitionsResponse = try await apiClient.footballDataRequest(
            endpoint: "competitions"
        )
        return response.competitions
            .filter { ["PL", "BL1", "SA", "PD", "CL", "EL"].contains($0.code) }
            .map { $0.toAppModel() }
    }
    
    // MARK: - Match Resource
    // https://api.football-data.org/v4/matches
    
    /// Fetch live/in-play matches
    /// Optional filter by competition code
    func fetchLiveMatches(competitionCode: String? = nil) async throws -> [Match] {
        // Include PAUSED for halftime matches
        var endpoint = "matches?status=LIVE,IN_PLAY,PAUSED"
        if let code = competitionCode {
            endpoint += "&competitions=\(code)"
        }
        
        let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        return response.matches.map { $0.toAppModel() }
    }
    
    /// Fetch scheduled (upcoming) matches
    /// Optional filter by competition code
    func fetchUpcomingMatches(competitionCode: String? = nil) async throws -> [Match] {
        var endpoint = "matches?status=SCHEDULED,TIMED"
        if let code = competitionCode {
            endpoint += "&competitions=\(code)"
        }
        
        let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        return response.matches.map { $0.toAppModel() }
    }
    
    /// Fetch matches for today
    /// Using date shortcuts: TODAY, YESTERDAY, TOMORROW
    func fetchTodaysMatches() async throws -> [Match] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let endpoint = "matches?dateFrom=\(today)&dateTo=\(today)"
        let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        return response.matches.map { $0.toAppModel() }
    }
    
    /// Fetch matches in a date range
    /// - Parameter days: Number of days from today (default: 7)
    func fetchMatchesInDateRange(days: Int = 7) async throws -> [Match] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
        
        let dateFrom = dateFormatter.string(from: today)
        let dateTo = dateFormatter.string(from: futureDate)
        
        let endpoint = "matches?dateFrom=\(dateFrom)&dateTo=\(dateTo)"
        let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        return response.matches.map { $0.toAppModel() }
    }
    
    /// Fetch detailed match information including lineups
    /// - Parameter matchId: The match ID
    func fetchMatchDetails(matchId: String) async throws -> MatchDetail {
        let url = URL(string: "https://api.football-data.org/v4/matches/\(matchId)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw APIError.serverError(statusCode, "Failed to fetch match details")
        }
        
        let apiMatchDetail = try JSONDecoder().decode(APIMatchDetailResponse.self, from: data)

        // DEBUG: Print what we got
        print("📊 Match \(matchId) stats:")
        print("   Status: \(apiMatchDetail.status)")
        print("   Minute: \(apiMatchDetail.minute ?? -1)")
        print("   Home stats: \(apiMatchDetail.homeTeam.statistics != nil ? "YES" : "NO")")
        print("   Away stats: \(apiMatchDetail.awayTeam.statistics != nil ? "YES" : "NO")")
        if let homeStats = apiMatchDetail.homeTeam.statistics {
            print("   Home possession: \(homeStats.ballPossession ?? -1)")
            print("   Home shots: \(homeStats.shots ?? -1)")
        }
        
        let matchDetail = apiMatchDetail.toMatchDetail()
        
        // Cache the match
        UnifiedCacheManager.shared.cacheMatch(matchDetail.match)
        
        return matchDetail
    }
    
    // MARK: - Match Subresource: Players/Lineup
    // Extracted from match data
    
    /// Fetch players from match lineup data (REQUIRED BY MatchService PROTOCOL)
    /// - Parameter matchId: The match ID
    /// - Returns: Array of players from both teams
    /// - Throws: LineupError.notAvailableYet if lineup hasn't been announced
    func fetchMatchPlayers(matchId: String) async throws -> [Player] {
        let url = URL(string: "https://api.football-data.org/v4/matches/\(matchId)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw APIError.serverError(statusCode, "Failed to fetch match data")
        }
        
        guard let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let homeTeamData = jsonData["homeTeam"] as? [String: Any],
              let awayTeamData = jsonData["awayTeam"] as? [String: Any] else {
            throw APIError.decodingError(NSError(domain: "JSON", code: 1, userInfo: nil))
        }
        
        // Check if lineup data exists
        let homeLineup = homeTeamData["lineup"] as? [[String: Any]] ?? []
        let awayLineup = awayTeamData["lineup"] as? [[String: Any]] ?? []
        
        if homeLineup.isEmpty && awayLineup.isEmpty {
            throw LineupError.notAvailableYet
        }
        
        return try convertMatchDataToPlayers(homeTeamData: homeTeamData, awayTeamData: awayTeamData)
    }
    
    // MARK: - Team Resource
    // https://api.football-data.org/v4/teams/{id}
    
    /// Fetch team squad (all players in the team)
    /// - Parameter teamId: The team ID
    func fetchTeamSquad(teamId: String) async throws -> TeamSquad {
        do {
            let endpoint = "teams/\(teamId)"
            let response: TeamResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
            return response.toTeamSquad()
        } catch let apiError as APIError {
            switch apiError {
            case .serverError(let code, _) where code == 400:
                throw NSError(domain: "TeamSquadError", code: 400, userInfo: [
                    NSLocalizedDescriptionKey: "Team ID \(teamId) is not valid in the football API database."
                ])
            case .serverError(let code, _) where code == 404:
                throw NSError(domain: "TeamSquadError", code: 404, userInfo: [
                    NSLocalizedDescriptionKey: "Team \(teamId) not found in the football API database."
                ])
            default:
                throw apiError
            }
        }
    }
    
    // MARK: - Additional Match Methods
    
    /// Fetch live match details with events (REQUIRED BY MatchService PROTOCOL)
    func fetchLiveMatchDetails(matchId: String) async throws -> MatchWithEvents {
        let url = URL(string: "https://api.football-data.org/v4/matches/\(matchId)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let apiMatch = try JSONDecoder().decode(APIMatch.self, from: data)
        
        return apiMatch.toMatchWithEvents()
    }
    
    /// Fetch match events (REQUIRED BY MatchService PROTOCOL)
    func fetchMatchEvents(matchId: String) async throws -> [MatchEvent] {
        let url = URL(string: "https://api.football-data.org/v4/matches/\(matchId)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse the full match response
        guard let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingError(NSError(domain: "JSON", code: 1, userInfo: nil))
        }
        
        var events: [MatchEvent] = []
        
        // Process goals (including penalties and own goals)
        if let goals = jsonData["goals"] as? [[String: Any]] {
            for goal in goals {
                if let minute = goal["minute"] as? Int,
                   let type = goal["type"] as? String,
                   let scorer = goal["scorer"] as? [String: Any],
                   let scorerId = scorer["id"] as? Int,
                   let scorerName = scorer["name"] as? String,
                   let team = goal["team"] as? [String: Any],
                   let teamId = team["id"] as? Int {
                    
                    // Create goal event
                    events.append(MatchEvent(
                        id: "goal_\(minute)_\(scorerId)",
                        type: type, // "REGULAR", "PENALTY", or "OWN"
                        playerId: "\(scorerId)",
                        playerName: scorerName,
                        minute: minute,
                        teamId: "\(teamId)"
                    ))
                    
                    // Create assist event if present
                    if let assist = goal["assist"] as? [String: Any],
                       let assistId = assist["id"] as? Int,
                       let assistName = assist["name"] as? String {
                        
                        events.append(MatchEvent(
                            id: "assist_\(minute)_\(assistId)",
                            type: "ASSIST",
                            playerId: "\(assistId)",
                            playerName: assistName,
                            minute: minute,
                            teamId: "\(teamId)"
                        ))
                    }
                }
            }
        }
        
        // Process bookings (cards)
        if let bookings = jsonData["bookings"] as? [[String: Any]] {
            for booking in bookings {
                if let minute = booking["minute"] as? Int,
                   let card = booking["card"] as? String,
                   let player = booking["player"] as? [String: Any],
                   let playerId = player["id"] as? Int,
                   let playerName = player["name"] as? String,
                   let team = booking["team"] as? [String: Any],
                   let teamId = team["id"] as? Int {
                    
                    events.append(MatchEvent(
                        id: "card_\(minute)_\(playerId)",
                        type: card, // "YELLOW" or "RED"
                        playerId: "\(playerId)",
                        playerName: playerName,
                        minute: minute,
                        teamId: "\(teamId)"
                    ))
                }
            }
        }
        
        // Process substitutions
        if let substitutions = jsonData["substitutions"] as? [[String: Any]] {
            for sub in substitutions {
                guard let minute = sub["minute"] as? Int,
                      let playerOut = sub["playerOut"] as? [String: Any],
                      let playerOutId = playerOut["id"] as? Int,
                      let playerOutName = playerOut["name"] as? String,
                      let playerIn = sub["playerIn"] as? [String: Any],
                      let playerInId = playerIn["id"] as? Int,
                      let playerInName = playerIn["name"] as? String,
                      let team = sub["team"] as? [String: Any],
                      let teamId = team["id"] as? Int else {
                    print("⚠️ Skipping malformed substitution data")
                    continue
                }
                
                // Validation checks
                guard minute >= 0 && minute <= 120 else {
                    print("⚠️ Skipping substitution with invalid minute: \(minute)")
                    continue
                }
                
                guard playerOutId != playerInId else {
                    print("⚠️ Skipping substitution where player is substituting themselves: \(playerOutId)")
                    continue
                }
                
                guard !playerOutName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    print("⚠️ Skipping substitution with empty player out name")
                    continue
                }
                
                // Create the substitution event
                events.append(MatchEvent(
                    id: "sub_\(minute)_\(playerOutId)",
                    type: "SUBSTITUTION",
                    playerId: "\(playerOutId)",
                    playerName: playerOutName,
                    minute: minute,
                    teamId: "\(teamId)",
                    playerOffId: "\(playerOutId)",
                    playerOnId: "\(playerInId)"
                ))
                
                // Debug: Log parsed substitution (not a game event yet, just API data)
                if AppConfig.enableDetailedLogging {
                    print("📋 Parsed API substitution: \(playerOutName) → \(playerInName) at \(minute)'")
                }
            }
        }
        
        return events.sorted { $0.minute < $1.minute }
    }
    
    /// Monitor a match for live updates (REQUIRED BY MatchService PROTOCOL)
    func monitorMatch(matchId: String, onUpdate: @escaping (MatchUpdate) -> Void) -> Task<Void, Error> {
        // Cancel any existing monitoring for this match
        monitoringTasks[matchId]?.cancel()
        
        let task = Task<Void, Error> {
            var previousEvents: [MatchEvent] = []
            
            while !Task.isCancelled {
                do {
                    // Fetch current match state
                    let matchDetail = try await fetchMatchDetails(matchId: matchId)
                    let currentEvents = try await fetchMatchEvents(matchId: matchId)
                    
                    // Detect new events
                    let newEvents = currentEvents.filter { event in
                        !previousEvents.contains { $0.id == event.id }
                    }
                    
                    // Create update
                    let update = MatchUpdate(
                        match: matchDetail.match,
                        newEvents: newEvents
                    )
                    
                    // Notify callback
                    onUpdate(update)
                    
                    previousEvents = currentEvents
                    
                    // Wait before next poll (adjust based on match status)
                    let pollInterval = calculatePollInterval(for: matchDetail.match.status)
                    if pollInterval > 0 {
                        try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                    } else {
                        // Match finished, stop monitoring
                        break
                    }
                    
                } catch {
                    print("⚠️ Monitoring error for match \(matchId): \(error)")
                    // Wait a bit before retrying
                    try await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds
                }
            }
        }
        
        monitoringTasks[matchId] = task
        return task
    }
    
    /// Fetch match lineup (REQUIRED BY MatchService PROTOCOL)
    func fetchMatchLineup(matchId: String) async throws -> Lineup {
        let url = URL(string: "https://api.football-data.org/v4/matches/\(matchId)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw APIError.serverError(statusCode, "Failed to fetch match data")
        }
        
        guard let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let homeTeamData = jsonData["homeTeam"] as? [String: Any],
              let awayTeamData = jsonData["awayTeam"] as? [String: Any] else {
            throw APIError.decodingError(NSError(domain: "JSON", code: 1, userInfo: nil))
        }
        
        // Check if lineup data exists
        let homeLineup = homeTeamData["lineup"] as? [[String: Any]] ?? []
        let awayLineup = awayTeamData["lineup"] as? [[String: Any]] ?? []
        
        if homeLineup.isEmpty && awayLineup.isEmpty {
            throw LineupError.notAvailableYet
        }
        
        // Convert to Lineup structure
        let homeTeam = createTeamFromMatchData(homeTeamData)
        let awayTeam = createTeamFromMatchData(awayTeamData)
        
        let homeStartingXI = homeLineup.compactMap { createPlayerFromMatchData($0, team: homeTeam) }
        let awayStartingXI = awayLineup.compactMap { createPlayerFromMatchData($0, team: awayTeam) }
        
        let homeBench = (homeTeamData["bench"] as? [[String: Any]] ?? []).compactMap {
            createPlayerFromMatchData($0, team: homeTeam)
        }
        let awayBench = (awayTeamData["bench"] as? [[String: Any]] ?? []).compactMap {
            createPlayerFromMatchData($0, team: awayTeam)
        }
        
        let homeTeamLineup = TeamLineup(
            team: homeTeam,
            formation: homeTeamData["formation"] as? String,
            startingXI: homeStartingXI,
            substitutes: homeBench,
            coach: nil
        )
        
        let awayTeamLineup = TeamLineup(
            team: awayTeam,
            formation: awayTeamData["formation"] as? String,
            startingXI: awayStartingXI,
            substitutes: awayBench,
            coach: nil
        )
        
        return Lineup(homeTeam: homeTeamLineup, awayTeam: awayTeamLineup)
    }
    
    // MARK: - Competition Subresources (placeholders)
    // These can be implemented when needed
    
    /// Fetch standings for a competition (not yet implemented)
    func fetchStandings(competitionCode: String) async throws {
        throw NSError(domain: "NotImplemented", code: 501, userInfo: [
            NSLocalizedDescriptionKey: "Standings feature not yet implemented"
        ])
    }
    
    /// Fetch top scorers for a competition (not yet implemented)
    func fetchTopScorers(competitionCode: String) async throws {
        throw NSError(domain: "NotImplemented", code: 501, userInfo: [
            NSLocalizedDescriptionKey: "Top scorers feature not yet implemented"
        ])
    }
    
    // MARK: - Helper Methods
    
    private func convertMatchDataToPlayers(homeTeamData: [String: Any], awayTeamData: [String: Any]) throws -> [Player] {
        var allPlayers: [Player] = []
        
        let homeTeam = createTeamFromMatchData(homeTeamData)
        let awayTeam = createTeamFromMatchData(awayTeamData)
        
        // Extract home team players
        if let homeLineup = homeTeamData["lineup"] as? [[String: Any]] {
            for playerData in homeLineup {
                if let player = createPlayerFromMatchData(playerData, team: homeTeam) {
                    allPlayers.append(player)
                }
            }
        }
        
        if let homeBench = homeTeamData["bench"] as? [[String: Any]] {
            for playerData in homeBench {
                if let player = createPlayerFromMatchData(playerData, team: homeTeam) {
                    allPlayers.append(player)
                }
            }
        }
        
        // Extract away team players
        if let awayLineup = awayTeamData["lineup"] as? [[String: Any]] {
            for playerData in awayLineup {
                if let player = createPlayerFromMatchData(playerData, team: awayTeam) {
                    allPlayers.append(player)
                }
            }
        }
        
        if let awayBench = awayTeamData["bench"] as? [[String: Any]] {
            for playerData in awayBench {
                if let player = createPlayerFromMatchData(playerData, team: awayTeam) {
                    allPlayers.append(player)
                }
            }
        }
        
        return allPlayers
    }
    
    private func createTeamFromMatchData(_ teamData: [String: Any]) -> Team {
        let id = teamData["id"] as? Int ?? 0
        let name = teamData["name"] as? String ?? "Unknown Team"
        let shortName = teamData["shortName"] as? String ?? name.prefix(3).uppercased()
        
        return Team(
            id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", id))") ?? UUID(),
            name: name,
            shortName: String(shortName),
            logoName: "team_logo",
            primaryColor: "#1a73e8",
            apiId: String(id)  // Store the raw API ID
        )
    }
    
    private func createPlayerFromMatchData(_ playerData: [String: Any], team: Team) -> Player? {
        guard let id = playerData["id"] as? Int,
              let name = playerData["name"] as? String else {
            return nil
        }
        
        let position = playerData["position"] as? String
        let mappedPosition = mapPosition(position)
        
        return Player(
            apiId: String(id),
            name: name,
            team: team,
            position: mappedPosition
        )
    }
    
    private func mapPosition(_ apiPosition: String?) -> Player.Position {
        guard let position = apiPosition?.uppercased() else { return .midfielder }
        
        switch position {
        case "GOALKEEPER": return .goalkeeper
        case "DEFENCE", "DEFENDER", "CENTRE-BACK", "CENTER-BACK", "RIGHT-BACK", "LEFT-BACK": return .defender
        case "MIDFIELD", "MIDFIELDER", "CENTRAL MIDFIELD", "DEFENSIVE MIDFIELD", "ATTACKING MIDFIELD": return .midfielder
        case "OFFENCE", "OFFENSE", "FORWARD", "ATTACKER", "CENTRE-FORWARD": return .forward
        default: return .midfielder
        }
    }
    
    private func calculatePollInterval(for status: MatchStatus) -> TimeInterval {
        switch status {
        case .inProgress:
            return 30 // Poll every 30 seconds during match
        case .halftime:
            return 300 // Poll every 5 minutes during halftime
        case .upcoming:
            return 600 // Poll every 10 minutes before match starts
        case .completed, .finished, .cancelled, .postponed:
            return 0 // Stop polling
        case .paused, .suspended:
            return 180 // Poll every 3 minutes
        case .unknown:
            return 180 // Poll every 3 minutes for unknown status
        }
    }
}
