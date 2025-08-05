//
//  FootballDataMatchService.swift
//  Lucky Football Slip
//
//  Clean implementation based on football-data.org v4 API
//

import Foundation

class FootballDataMatchService: MatchService {
    private let apiClient: APIClient
    private let apiKey: String
    
    init(apiClient: APIClient, apiKey: String) {
        self.apiClient = apiClient
        self.apiKey = apiKey
    }
    
    // MARK: - MatchService Protocol Methods
    
    func fetchCompetitions() async throws -> [Competition] {
        let response: CompetitionsResponse = try await apiClient.footballDataRequest(endpoint: "competitions")
        return response.competitions.map { $0.toAppModel() }
    }
    
    func fetchLiveMatches(competitionCode: String? = nil) async throws -> [Match] {
        return try await fetchAllRelevantMatches(competitionCode: competitionCode)
    }
    
    func fetchUpcomingMatches(competitionCode: String? = nil) async throws -> [Match] {
        let cacheKey = "upcoming_\(competitionCode ?? "all")"
        
        if let cachedMatches = MatchCacheManager.shared.getCachedMatchList(for: cacheKey) {
            return cachedMatches
        }
        
        var endpoint = "matches?status=SCHEDULED,TIMED"
        if let code = competitionCode {
            endpoint += "&competitions=\(code)"
        }
        
        let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        let matches = response.matches.map { $0.toAppModel() }
        
        MatchCacheManager.shared.cacheMatchList(matches, for: cacheKey)
        return matches
    }
    
    func fetchMatchDetails(matchId: String) async throws -> MatchDetail {
        if let cachedMatch = MatchCacheManager.shared.getCachedMatch(matchId) {
            return MatchDetail(
                match: cachedMatch,
                venue: nil,
                attendance: nil,
                referee: nil,
                homeScore: 0,
                awayScore: 0
            )
        }
        
        let endpoint = "matches/\(matchId)"
        
        // Make custom request to get full match data
        let url = URL(string: "https://api.football-data.org/v4/\(endpoint)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 500
            throw APIError.serverError(statusCode, "Failed to fetch match details")
        }
        
        let apiMatch = try JSONDecoder().decode(APIMatch.self, from: data)
        let match = apiMatch.toAppModel()
        
        MatchCacheManager.shared.cacheMatch(match)
        
        return MatchDetail(
            match: match,
            venue: nil,
            attendance: nil,
            referee: nil,
            homeScore: 0,
            awayScore: 0
        )
    }
    
    func fetchMatchPlayers(matchId: String) async throws -> [Player] {
        if let cachedPlayers = MatchCacheManager.shared.getCachedPlayers(for: matchId) {
            return cachedPlayers
        }
        
        do {
            let lineup = try await fetchMatchLineup(matchId: matchId)
            let players = lineup.homeTeam.startingXI + lineup.homeTeam.substitutes +
                         lineup.awayTeam.startingXI + lineup.awayTeam.substitutes
            
            MatchCacheManager.shared.cachePlayers(players, for: matchId)
            return players
        } catch {
            print("❌ Failed to get players from lineup, trying team squads: \(error)")
            
            // Fallback: get teams from match and fetch their squads
            let matchDetails = try await fetchMatchDetails(matchId: matchId)
            
            async let homeSquadTask = fetchTeamSquad(teamId: "\(matchDetails.match.homeTeam.id)")
            async let awaySquadTask = fetchTeamSquad(teamId: "\(matchDetails.match.awayTeam.id)")
            
            let homeSquad = try await homeSquadTask
            let awaySquad = try await awaySquadTask
            
            let players = homeSquad.players + awaySquad.players
            MatchCacheManager.shared.cachePlayers(players, for: matchId)
            return players
        }
    }
    
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
                            type: "ASSIST", // Custom type for assists
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
                // Add comprehensive validation
                guard let minute = sub["minute"] as? Int,
                      let playerOut = sub["playerOut"] as? [String: Any],
                      let playerOutId = playerOut["id"] as? Int,
                      let playerOutName = playerOut["name"] as? String,
                      let playerIn = sub["playerIn"] as? [String: Any],
                      let playerInId = playerIn["id"] as? Int,
                      let team = sub["team"] as? [String: Any],
                      let teamId = team["id"] as? Int else {
                    print("⚠️ Skipping malformed substitution data: missing required fields")
                    continue // Skip this substitution and continue with the next one
                }
                
                // Additional validation checks
                guard minute >= 0 && minute <= 120 else { // Allow for extra time
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
                
                // Optional: Get player in name for better logging (but don't require it)
                let playerInName = (playerIn["name"] as? String) ?? "Unknown Player"
                
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
                
                print("✅ Processed substitution: \(playerOutName) → \(playerInName) at \(minute)'")
            }
        }
        
        return events.sorted { $0.minute < $1.minute }
    }
    
    func startMonitoringMatch(matchId: String, updateInterval: TimeInterval, onUpdate: @escaping (MatchUpdate) -> Void) -> Task<Void, any Error> {
        return smartMatchMonitoring(matchId: matchId, onUpdate: onUpdate)
    }
    
    func fetchMatchLineup(matchId: String) async throws -> Lineup {
        print("🎯 Fetching lineup for match \(matchId)")
        
        // Get match data using standard API call (lineup data is included automatically)
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
        
        // Parse the full match response
        guard let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingError(NSError(domain: "JSON", code: 1, userInfo: nil))
        }
        
        guard let homeTeamData = jsonData["homeTeam"] as? [String: Any],
              let awayTeamData = jsonData["awayTeam"] as? [String: Any] else {
            throw APIError.decodingError(NSError(domain: "Teams", code: 1, userInfo: nil))
        }
        
        // Check if lineup data exists
        let homeLineup = homeTeamData["lineup"] as? [[String: Any]] ?? []
        let awayLineup = awayTeamData["lineup"] as? [[String: Any]] ?? []
        
        if !homeLineup.isEmpty && !awayLineup.isEmpty {
            print("✅ Real lineup data found!")
            return try convertMatchDataToLineup(homeTeamData: homeTeamData, awayTeamData: awayTeamData)
        } else {
            print("⚠️ No lineup data available")
            // Throw the specific error
            throw LineupError.notAvailableYet
        }
    }
    
    
    func fetchMatchSquad(matchId: String) async throws -> [Player] {
        print("👥 Fetching full squad for match \(matchId)")
        
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
        
        // Get team IDs and fetch their full squads
        let homeTeamId = homeTeamData["id"] as? Int ?? 0
        let awayTeamId = awayTeamData["id"] as? Int ?? 0
        
        async let homeSquadTask = fetchTeamSquad(teamId: String(homeTeamId))
        async let awaySquadTask = fetchTeamSquad(teamId: String(awayTeamId))
        
        let homeSquad = try await homeSquadTask
        let awaySquad = try await awaySquadTask
        
        let allPlayers = homeSquad.players + awaySquad.players
        print("✅ Fetched full squad: \(allPlayers.count) players")
        
        return allPlayers
    }
    


    func fetchLiveMatchDetails(matchId: String) async throws -> MatchWithEvents {
        let url = URL(string: "https://api.football-data.org/v4/matches/\(matchId)")!
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let apiMatch = try JSONDecoder().decode(APIMatch.self, from: data)
        
        return apiMatch.toMatchWithEvents()
    }
    
    func fetchTeamSquad(teamId: String) async throws -> TeamSquad {
        let endpoint = "teams/\(teamId)"
        let response: TeamResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        return response.toTeamSquad()
    }
    
    func enhancedMatchMonitoring(matchId: String, updateInterval: TimeInterval, onUpdate: @escaping (MatchUpdate) -> Void) -> Task<Void, any Error> {
        return smartMatchMonitoring(matchId: matchId, onUpdate: onUpdate)
    }
    
    // MARK: - Additional Methods
    
    func fetchMatchesInDateRange(days: Int = 7) async throws -> [Match] {
        let cacheKey = "daterange_\(days)"
        
        if let cachedMatches = MatchCacheManager.shared.getCachedMatchList(for: cacheKey) {
            return cachedMatches
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
        
        let fromDate = dateFormatter.string(from: today)
        let toDate = dateFormatter.string(from: futureDate)
        
        let endpoint = "matches?dateFrom=\(fromDate)&dateTo=\(toDate)"
        
        let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        let matches = response.matches.map { $0.toAppModel() }
        
        MatchCacheManager.shared.cacheMatchList(matches, for: cacheKey)
        return matches
    }
    
    func smartMatchMonitoring(matchId: String, onUpdate: @escaping (MatchUpdate) -> Void) -> Task<Void, any Error> {
        return Task<Void, any Error> {
            var previousEvents: [MatchEvent] = []
            var consecutiveFailures = 0
            
            while !Task.isCancelled {
                do {
                    guard APIRateLimiter.shared.canMakeCall() else {
                        let waitTime = APIRateLimiter.shared.timeUntilNextCall()
                        try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                        continue
                    }
                    
                    let matchDetails = try await fetchMatchDetails(matchId: matchId)
                    let currentEvents = try await fetchMatchEvents(matchId: matchId)
                    
                    let newEvents = currentEvents.filter { event in
                        !previousEvents.contains { $0.id == event.id }
                    }
                    
                    if !newEvents.isEmpty {
                        previousEvents.append(contentsOf: newEvents)
                        print("🔔 Found \(newEvents.count) new events")
                    }
                    
                    let update = MatchUpdate(match: matchDetails.match, newEvents: newEvents)
                    onUpdate(update)
                    
                    consecutiveFailures = 0
                    
                    let pollInterval = calculateSmartInterval(status: matchDetails.match.status)
                    try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                    
                } catch {
                    consecutiveFailures += 1
                    print("❌ Monitoring error (attempt \(consecutiveFailures)): \(error)")
                    
                    if consecutiveFailures >= 5 {
                        print("🛑 Too many consecutive failures, stopping monitoring")
                        break
                    }
                    
                    try await Task.sleep(nanoseconds: 30_000_000_000) // 30 seconds
                }
            }
        }
    }
    
    // MARK: - Debug Methods
    
    func debugAPIAccess() async {
        print("🔧 Testing API access...")
        do {
            let competitions = try await fetchCompetitions()
            print("✅ API working: \(competitions.count) competitions available")
        } catch {
            print("❌ API failed: \(error)")
        }
    }
    
    func debugRecentFinishedMatches() async {
        print("🔧 === RECENT FINISHED MATCHES LINEUP DEBUG ===")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: today)!
        
        let fromDate = dateFormatter.string(from: threeDaysAgo)
        let toDate = dateFormatter.string(from: today)
        
        do {
            // Get recent finished matches (most likely to have lineup data)
            let endpoint = "matches?status=FINISHED&dateFrom=\(fromDate)&dateTo=\(toDate)&competitions=PL,CL,BL1,FL1,PD,TIP,ELC,BSA"
            print("🔍 Fetching recent finished matches: \(endpoint)")
            
            let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
            print("✅ Found \(response.matches.count) finished matches in last 3 days")
            
            for match in response.matches.prefix(5) {
                print("\n📋 Testing match: \(match.homeTeam.name) vs \(match.awayTeam.name)")
                print("   ID: \(match.id), Competition: \(match.competition.name)")
                print("   Status: \(match.status), Date: \(match.utcDate)")
                
                await testMatchForLineupData(matchId: "\(match.id)")
            }
            
        } catch {
            print("❌ Failed to fetch recent matches: \(error)")
        }
        
        print("\n🔧 === END RECENT FINISHED MATCHES DEBUG ===")
    }
    
    func debugUpcomingMatches() async {
        print("🔧 === UPCOMING MATCHES LINEUP DEBUG ===")
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = Date()
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: today)!
        
        let fromDate = dateFormatter.string(from: today)
        let toDate = dateFormatter.string(from: nextWeek)
        
        do {
            // Get upcoming matches
            let endpoint = "matches?status=SCHEDULED,TIMED&dateFrom=\(fromDate)&dateTo=\(toDate)&competitions=PL,CL,BL1,FL1,PD,TIP,ELC,BSA"
            print("🔍 Fetching upcoming matches: \(endpoint)")
            
            let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
            print("✅ Found \(response.matches.count) upcoming matches in next 7 days")
            
            for match in response.matches.prefix(5) {
                print("\n📋 Testing match: \(match.homeTeam.name) vs \(match.awayTeam.name)")
                print("   ID: \(match.id), Competition: \(match.competition.name)")
                print("   Status: \(match.status), Date: \(match.utcDate)")
                
                await testMatchForLineupData(matchId: "\(match.id)")
            }
            
        } catch {
            print("❌ Failed to fetch upcoming matches: \(error)")
        }
        
        print("\n🔧 === END UPCOMING MATCHES DEBUG ===")
    }
    
    // MARK: - Supporting Methods for Lineup Search
    
    func fetchTodaysMatchesForLineupSearch() async throws -> [Match] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let endpoint = "matches?dateFrom=\(today)&dateTo=\(today)"
        let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        return response.matches.map { $0.toAppModel() }
    }
    
    func fetchMatchLineupForSearch(matchId: String) async throws -> Lineup {
        return try await fetchMatchLineup(matchId: matchId)
    }
    
    // MARK: - Private Helper Methods
    
    private func fetchAllRelevantMatches(competitionCode: String? = nil) async throws -> [Match] {
        let cacheKey = "all_relevant_\(competitionCode ?? "all")"
        
        if let cachedMatches = MatchCacheManager.shared.getCachedMatchList(for: cacheKey) {
            return cachedMatches
        }
        
        var endpoint = "matches?status=LIVE,IN_PLAY,SCHEDULED,TIMED,FINISHED"
        if let code = competitionCode {
            endpoint += "&competitions=\(code)"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let nextWeek = Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        
        let fromDate = dateFormatter.string(from: yesterday)
        let toDate = dateFormatter.string(from: nextWeek)
        
        endpoint += "&dateFrom=\(fromDate)&dateTo=\(toDate)"
        
        let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        let matches = response.matches.map { $0.toAppModel() }
        
        let sortedMatches = matches.sorted { match1, match2 in
            if match1.status == .inProgress && match2.status != .inProgress {
                return true
            }
            if match2.status == .inProgress && match1.status != .inProgress {
                return false
            }
            return match1.startTime < match2.startTime
        }
        
        MatchCacheManager.shared.cacheMatchList(sortedMatches, for: cacheKey)
        return sortedMatches
    }
    
    private func testMatchForLineupData(matchId: String) async {
        do {
            // Make raw API call to see actual response structure
            let url = URL(string: "https://api.football-data.org/v4/matches/\(matchId)")!
            var request = URLRequest(url: url)
            request.setValue(apiKey, forHTTPHeaderField: "X-Auth-Token")
            request.setValue("application/json", forHTTPHeaderField: "Accept")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("   ❌ API call failed: \(response)")
                return
            }
            
            guard let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("   ❌ Failed to parse JSON")
                return
            }
            
            // Check for lineup data
            if let homeTeam = jsonData["homeTeam"] as? [String: Any],
               let awayTeam = jsonData["awayTeam"] as? [String: Any] {
                
                let homeLineup = homeTeam["lineup"] as? [[String: Any]] ?? []
                let awayLineup = awayTeam["lineup"] as? [[String: Any]] ?? []
                let homeBench = homeTeam["bench"] as? [[String: Any]] ?? []
                let awayBench = awayTeam["bench"] as? [[String: Any]] ?? []
                
                if !homeLineup.isEmpty && !awayLineup.isEmpty {
                    print("   ✅ ✅ LINEUP DATA FOUND!")
                    print("      🏠 Home: \(homeLineup.count) starters, \(homeBench.count) bench")
                    print("      🏃 Away: \(awayLineup.count) starters, \(awayBench.count) bench")
                    
                    // Show formation if available
                    if let homeFormation = homeTeam["formation"] as? String {
                        print("      🏠 Home formation: \(homeFormation)")
                    }
                    if let awayFormation = awayTeam["formation"] as? String {
                        print("      🏃 Away formation: \(awayFormation)")
                    }
                    
                    // Show sample players
                    if let firstPlayer = homeLineup.first,
                       let playerName = firstPlayer["name"] as? String,
                       let position = firstPlayer["position"] as? String {
                        print("      👤 Sample player: \(playerName) (\(position))")
                    }
                    
                } else {
                    print("   ⚠️ No lineup data available")
                    print("      🏠 Home lineup: \(homeLineup.count) players")
                    print("      🏃 Away lineup: \(awayLineup.count) players")
                    
                    // Check if squad data is available instead
                    if let homeSquad = homeTeam["squad"] as? [[String: Any]],
                       let awaySquad = awayTeam["squad"] as? [[String: Any]] {
                        print("      📋 Squad data available: Home \(homeSquad.count), Away \(awaySquad.count)")
                    } else {
                        print("      ❌ No squad data either")
                    }
                }
                
                // Check for event data
                if let goals = jsonData["goals"] as? [[String: Any]] {
                    print("      ⚽ Goals: \(goals.count)")
                }
                if let bookings = jsonData["bookings"] as? [[String: Any]] {
                    print("      📋 Bookings: \(bookings.count)")
                }
                if let substitutions = jsonData["substitutions"] as? [[String: Any]] {
                    print("      🔄 Substitutions: \(substitutions.count)")
                }
            }
            
        } catch {
            print("   ❌ Error testing match: \(error)")
        }
    }
    
    private func convertMatchDataToLineup(homeTeamData: [String: Any], awayTeamData: [String: Any]) throws -> Lineup {
        print("🔄 Converting real match lineup data")
        
        let homeLineupData = homeTeamData["lineup"] as? [[String: Any]] ?? []
        let homeBenchData = homeTeamData["bench"] as? [[String: Any]] ?? []
        let homeFormation = homeTeamData["formation"] as? String ?? "4-4-2"
        
        let awayLineupData = awayTeamData["lineup"] as? [[String: Any]] ?? []
        let awayBenchData = awayTeamData["bench"] as? [[String: Any]] ?? []
        let awayFormation = awayTeamData["formation"] as? String ?? "4-4-2"
        
        let homeTeam = Team(
            id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", homeTeamData["id"] as? Int ?? 0))")!,
            name: homeTeamData["name"] as? String ?? "Home Team",
            shortName: homeTeamData["shortName"] as? String ?? "HOME",
            logoName: "team_logo",
            primaryColor: "#1a73e8"
        )
        
        let awayTeam = Team(
            id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", awayTeamData["id"] as? Int ?? 0))")!,
            name: awayTeamData["name"] as? String ?? "Away Team",
            shortName: awayTeamData["shortName"] as? String ?? "AWAY",
            logoName: "team_logo",
            primaryColor: "#e74c3c"
        )
        
        let homeStartingXI = homeLineupData.compactMap { playerData -> Player? in
            guard let id = playerData["id"] as? Int,
                  let name = playerData["name"] as? String else { return nil }
            
            let position = playerData["position"] as? String
            
            return Player(
                apiId: String(id),
                name: name,
                team: homeTeam,
                position: mapPosition(position)
            )
        }
        
        let homeBench = homeBenchData.compactMap { playerData -> Player? in
            guard let id = playerData["id"] as? Int,
                  let name = playerData["name"] as? String else { return nil }
            
            let position = playerData["position"] as? String
            
            return Player(
                apiId: String(id),
                name: name,
                team: homeTeam,
                position: mapPosition(position)
            )
        }
        
        let awayStartingXI = awayLineupData.compactMap { playerData -> Player? in
            guard let id = playerData["id"] as? Int,
                  let name = playerData["name"] as? String else { return nil }
            
            let position = playerData["position"] as? String
            
            return Player(
                apiId: String(id),
                name: name,
                team: awayTeam,
                position: mapPosition(position)
            )
        }
        
        let awayBench = awayBenchData.compactMap { playerData -> Player? in
            guard let id = playerData["id"] as? Int,
                  let name = playerData["name"] as? String else { return nil }
            
            let position = playerData["position"] as? String
            
            return Player(
                apiId: String(id),
                name: name,
                team: awayTeam,
                position: mapPosition(position)
            )
        }
        
        let homeLineup = TeamLineup(
            team: homeTeam,
            formation: homeFormation,
            startingXI: homeStartingXI,
            substitutes: homeBench,
            coach: nil
        )
        
        let awayLineup = TeamLineup(
            team: awayTeam,
            formation: awayFormation,
            startingXI: awayStartingXI,
            substitutes: awayBench,
            coach: nil
        )
        
        print("✅ Converted real lineup data: Home \(homeStartingXI.count) starters, Away \(awayStartingXI.count) starters")
        
        return Lineup(homeTeam: homeLineup, awayTeam: awayLineup)
    }
    
    private func createLineupFromTeamSquads(homeTeamId: String, awayTeamId: String, homeTeamData: [String: Any], awayTeamData: [String: Any]) async throws -> Lineup {
        print("🔄 Creating lineup from team squads")
        
        async let homeSquadTask = fetchTeamSquad(teamId: homeTeamId)
        async let awaySquadTask = fetchTeamSquad(teamId: awayTeamId)
        
        let homeSquad = try await homeSquadTask
        let awaySquad = try await awaySquadTask
        
        // Create team objects with correct names from match data
        let homeTeam = Team(
            id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", homeTeamData["id"] as? Int ?? 0))")!,
            name: homeTeamData["name"] as? String ?? homeSquad.team.name,
            shortName: homeTeamData["shortName"] as? String ?? homeSquad.team.shortName,
            logoName: "team_logo",
            primaryColor: "#1a73e8"
        )
        
        let awayTeam = Team(
            id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", awayTeamData["id"] as? Int ?? 0))")!,
            name: awayTeamData["name"] as? String ?? awaySquad.team.name,
            shortName: awayTeamData["shortName"] as? String ?? awaySquad.team.shortName,
            logoName: "team_logo",
            primaryColor: "#e74c3c"
        )
        
        // Create mock lineups from squad data
        let homeLineup = createMockLineupFromSquad(squad: homeSquad.players, team: homeTeam)
        let awayLineup = createMockLineupFromSquad(squad: awaySquad.players, team: awayTeam)
        
        print("✅ Created lineup from squads: Home \(homeLineup.startingXI.count) starters, Away \(awayLineup.startingXI.count) starters")
        
        return Lineup(homeTeam: homeLineup, awayTeam: awayLineup)
    }
    
    private func createMockLineupFromSquad(squad: [Player], team: Team) -> TeamLineup {
        // Group players by position
        let goalkeepers = squad.filter { $0.position == .goalkeeper }
        let defenders = squad.filter { $0.position == .defender }
        let midfielders = squad.filter { $0.position == .midfielder }
        let forwards = squad.filter { $0.position == .forward }
        
        var startingXI: [Player] = []
        
        // Build a 4-3-3 formation
        if let gk = goalkeepers.first {
            startingXI.append(gk)
        }
        
        startingXI.append(contentsOf: Array(defenders.prefix(4)))
        startingXI.append(contentsOf: Array(midfielders.prefix(3)))
        startingXI.append(contentsOf: Array(forwards.prefix(3)))
        
        // Fill remaining spots if needed
        let remainingPlayers = squad.filter { !startingXI.contains($0) }
        let needed = 11 - startingXI.count
        startingXI.append(contentsOf: Array(remainingPlayers.prefix(needed)))
        
        // Rest go to bench
        let substitutes = squad.filter { !startingXI.contains($0) }
        
        return TeamLineup(
            team: team,
            formation: "4-3-3",
            startingXI: startingXI,
            substitutes: Array(substitutes.prefix(12)),
            coach: nil
        )
    }
    
    private func mapPosition(_ positionString: String?) -> Player.Position {
        guard let position = positionString?.lowercased() else { return .midfielder }
        
        switch position {
        case "goalkeeper":
            return .goalkeeper
        case "centre-back", "center-back", "right-back", "left-back", "defence":
            return .defender
        case "central midfield", "defensive midfield", "attacking midfield", "midfield", "right winger", "left winger":
            return .midfielder
        case "centre-forward", "offence":
            return .forward
        default:
            return .midfielder
        }
    }
    
    private func calculateSmartInterval(status: MatchStatus) -> TimeInterval {
        switch status {
        case .inProgress: return 30
        case .halftime: return 300
        case .upcoming: return 600
        case .completed, .finished, .postponed, .cancelled: return 0
        case .paused, .suspended: return 300
        case .unknown: return 180
        }
    }
}


#if DEBUG
extension FootballDataMatchService {
    
    /// Create a mock live match for testing
    func createMockLiveMatch() -> Match {
        let homeTeam = Team(
            name: "Bayern Munich",
            shortName: "BAY",
            logoName: "bayern_logo",
            primaryColor: "#DC052D"
        )
        
        let awayTeam = Team(
            name: "Borussia Dortmund",
            shortName: "BVB",
            logoName: "dortmund_logo",
            primaryColor: "#FDE100"
        )
        
        let bundesliga = Competition(
            id: "BL1",
            name: "Bundesliga",
            code: "BL1"
        )
        
        return Match(
            id: "mock_live_\(UUID().uuidString)",
            homeTeam: homeTeam,
            awayTeam: awayTeam,
            startTime: Date().addingTimeInterval(-1800),
            status: .inProgress,
            competition: bundesliga
        )
    }
    
    /// Comprehensive match simulation for testing the entire live mode flow
    func simulateCompleteMatch(duration: TimeInterval = 300) async throws -> String {
        print("🎮 Starting Complete Match Simulation...")
        let startTime = Date()
        
        // 1. Create mock match
        let mockMatch = createMockLiveMatch()
        print("⚽ Created mock match: \(mockMatch.homeTeam.name) vs \(mockMatch.awayTeam.name)")
        
        // 2. Generate mock players
        let mockPlayers = generateMockPlayers()
        print("👥 Generated \(mockPlayers.count) mock players")
        
        // 3. Create mock lineup
        let mockLineup = createMockLineup(players: mockPlayers, match: mockMatch)
        print("📋 Created mock lineup")
        
        // 4. Simulate match events over time
        var simulatedEvents: [MatchEvent] = []
        let eventCount = Int(duration / 30) // One event every 30 seconds
        
        for i in 0..<eventCount {
            let eventTime = startTime.addingTimeInterval(TimeInterval(i * 30))
            let mockEvent = generateRandomMatchEvent(
                minute: min(i * 2, 90),
                players: mockPlayers,
                match: mockMatch
            )
            simulatedEvents.append(mockEvent)
            
            print("🔔 Generated event \(i+1): \(mockEvent.type) by \(mockEvent.playerName ?? "Unknown") at \(mockEvent.minute)'")
        }
        
        // 5. Test event processing
        print("\n🧪 Testing Event Processing:")
        for event in simulatedEvents {
            let betEventType = mapEventTypeToBet(event.type)
            print("  \(event.type) → \(betEventType.rawValue)")
        }
        
        // 6. Test rate limiting
        print("\n⏱️ Testing Rate Limiting:")
        await testRateLimiting()
        
        // 7. Test caching
        print("\n💾 Testing Caching:")
        await testCaching(match: mockMatch, players: mockPlayers)
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        return """
        ✅ Complete Match Simulation Finished
        Duration: \(String(format: "%.2f", duration))s
        Events Generated: \(simulatedEvents.count)
        Players: \(mockPlayers.count)
        Status: Success
        """
    }
    
    private func generateMockPlayers() -> [Player] {
        var players: [Player] = []
        
        let homeTeam = Team(
            name: "Bayern Munich",
            shortName: "BAY",
            logoName: "bayern_logo",
            primaryColor: "#DC052D"
        )
        
        let awayTeam = Team(
            name: "Borussia Dortmund",
            shortName: "BVB",
            logoName: "dortmund_logo",
            primaryColor: "#FDE100"
        )
        
        // Home team players
        let homePlayerNames = ["Manuel Neuer", "Joshua Kimmich", "Leon Goretzka", "Thomas Müller", "Robert Lewandowski", "Serge Gnabry", "Kingsley Coman", "Alphonso Davies", "Dayot Upamecano", "Matthijs de Ligt", "Jamal Musiala"]
        
        for (index, name) in homePlayerNames.enumerated() {
            players.append(Player(
                apiId: "home_\(index)",
                name: name,
                team: homeTeam,
                position: getPositionForIndex(index)
            ))
        }
        
        // Away team players
        let awayPlayerNames = ["Gregor Kobel", "Mats Hummels", "Jude Bellingham", "Marco Reus", "Erling Haaland", "Jadon Sancho", "Raphaël Guerreiro", "Emre Can", "Nico Schlotterbeck", "Donyell Malen", "Julian Brandt"]
        
        for (index, name) in awayPlayerNames.enumerated() {
            players.append(Player(
                apiId: "away_\(index)",
                name: name,
                team: awayTeam,
                position: getPositionForIndex(index)
            ))
        }
        
        return players
    }
    
    private func getPositionForIndex(_ index: Int) -> Player.Position {
        switch index {
        case 0: return .goalkeeper
        case 1...4: return .defender
        case 5...8: return .midfielder
        default: return .forward
        }
    }
    
    private func createMockLineup(players: [Player], match: Match) -> Lineup {
        let homePlayers = players.filter { $0.team.name == match.homeTeam.name }
        let awayPlayers = players.filter { $0.team.name == match.awayTeam.name }
        
        let homeLineup = TeamLineup(
            team: match.homeTeam,
            formation: "4-3-3",
            startingXI: Array(homePlayers.prefix(11)),
            substitutes: Array(homePlayers.suffix(from: 11)),
            coach: nil
        )
        
        let awayLineup = TeamLineup(
            team: match.awayTeam,
            formation: "4-2-3-1",
            startingXI: Array(awayPlayers.prefix(11)),
            substitutes: Array(awayPlayers.suffix(from: 11)),
            coach: nil
        )
        
        return Lineup(homeTeam: homeLineup, awayTeam: awayLineup)
    }
    
    private func generateRandomMatchEvent(minute: Int, players: [Player], match: Match) -> MatchEvent {
        let eventTypes = ["REGULAR", "YELLOW", "RED", "SUBSTITUTION", "PENALTY", "OWN"]
        let randomType = eventTypes.randomElement()!
        let randomPlayer = players.randomElement()!
        
        return MatchEvent(
            id: "sim_\(UUID().uuidString)",
            type: randomType,
            playerId: randomPlayer.apiId ?? "unknown",  // FIX: Handle optional apiId
            playerName: randomPlayer.name,
            minute: minute,
            teamId: randomPlayer.team.id.uuidString
        )
    }
    
    private func mapEventTypeToBet(_ eventType: String) -> Bet.EventType {
        switch eventType.uppercased() {
        case "REGULAR", "PENALTY": return .goal
        case "YELLOW": return .yellowCard
        case "RED": return .redCard
        case "OWN": return .ownGoal
        case "SUBSTITUTION": return .goal // Substitutions don't have direct bet mapping
        default: return .goal
        }
    }
    
    private func testRateLimiting() async {
        print("  Testing API rate limiter...")
        for i in 1...3 {
            let canCall = APIRateLimiter.shared.canMakeCall()
            print("    Call \(i): \(canCall ? "✅ Allowed" : "❌ Limited")")
            if canCall {
                APIRateLimiter.shared.recordCall()
            }
        }
    }
    
    private func testCaching(match: Match, players: [Player]) async {
        print("  Testing match caching...")
        
        // Test match caching
        MatchCacheManager.shared.cacheMatch(match)
        if let cachedMatch = MatchCacheManager.shared.getCachedMatch(match.id) {
            print("    ✅ Match caching working")
        } else {
            print("    ❌ Match caching failed")
        }
        
        // Test player caching
        MatchCacheManager.shared.cachePlayers(players, for: match.id)
        if let cachedPlayers = MatchCacheManager.shared.getCachedPlayers(for: match.id) {
            print("    ✅ Player caching working (\(cachedPlayers.count) players)")
        } else {
            print("    ❌ Player caching failed")
        }
    }
    
    /// Quick test for betting flow with simulated events
    func testBettingFlow() async {
        print("💰 Testing Betting Flow...")
        
        // Create a mock game session
        let mockGameSession = GameSession()
        mockGameSession.isLiveMode = true
        
        // Add mock participants
        let participant1 = Participant(name: "Alice")
        let participant2 = Participant(name: "Bob")
        mockGameSession.participants = [participant1, participant2]
        
        // Add mock bets
        let goalBet = Bet(eventType: .goal, amount: 5.0)
        let cardBet = Bet(eventType: .yellowCard, amount: -2.0)
        mockGameSession.bets = [goalBet, cardBet]
        
        // Add mock players
        let mockPlayers = generateMockPlayers()
        mockGameSession.availablePlayers = mockPlayers
        mockGameSession.selectedPlayers = Array(mockPlayers.prefix(6))
        
        // FIX: Use GameSession's assignPlayersRandomly method instead of assignedParticipant
        mockGameSession.assignPlayersRandomly()
        
        // Simulate events
        print("  Simulating betting events...")
        for i in 1...3 {
            let randomPlayer = mockGameSession.selectedPlayers.randomElement()!
            let eventTypes: [Bet.EventType] = [.goal, .yellowCard, .assist]
            let randomEventType = eventTypes.randomElement()!
            
            // FIX: Use correct GameEvent constructor
            let gameEvent = GameEvent(
                player: randomPlayer,
                eventType: randomEventType,
                timestamp: Date()
            )
            
            mockGameSession.events.append(gameEvent)
            
            // FIX: Check participant assignment through GameSession logic
            if let participantWithPlayer = mockGameSession.participants.first(where: { participant in
                participant.selectedPlayers.contains { $0.id == randomPlayer.id }
            }),
               let bet = mockGameSession.bets.first(where: { $0.eventType == randomEventType }) {
                print("    Event \(i): \(randomPlayer.name) (\(randomEventType.rawValue)) → \(participantWithPlayer.name) \(bet.amount > 0 ? "wins" : "pays") $\(abs(bet.amount))")
            }
        }
        
        print("  ✅ Betting flow test complete")
    }
}
#endif
