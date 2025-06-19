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
    
    // Keep existing cache for backward compatibility
    private var matchCache: [String: Match] = [:]
    private var playerCache: [String: [Player]] = [:]
    
    init(apiClient: APIClient, apiKey: String) {
        self.apiClient = apiClient
        self.apiKey = apiKey
    }
    
    // MARK: - Competition Methods
    
    func fetchCompetitions() async throws -> [Competition] {
        let response: CompetitionsResponse = try await apiClient.footballDataRequest(endpoint: "competitions")
        return response.competitions
            .filter { ["PL", "BL1", "SA", "PD", "CL", "EL"].contains($0.code) }
            .map { $0.toAppModel() }
    }
    
    // MARK: - Enhanced Match Fetching Methods with Caching and Rate Limiting
    
    func fetchTodaysMatches() async throws -> [Match] {
        let cacheKey = "today_matches"
        
        // Check cache first
        if let cachedMatches = MatchCacheManager.shared.getCachedMatchList(for: cacheKey) {
            print("📦 Using cached today's matches (\(cachedMatches.count) matches)")
            return cachedMatches
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let endpoint = "matches?dateFrom=\(today)&dateTo=\(today)"
        print("🗓️ Fetching today's matches with endpoint: \(endpoint)")
        
        let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        let matches = response.matches.map { $0.toAppModel() }
        
        // Cache the results
        MatchCacheManager.shared.cacheMatchList(matches, for: cacheKey)
        
        print("📊 Found \(matches.count) matches for today")
        for match in matches {
            print("  • \(match.homeTeam.name) vs \(match.awayTeam.name) (\(match.competition.name)) - \(match.status)")
        }
        
        return matches
    }

    func fetchMatchesInDateRange(days: Int = 7) async throws -> [Match] {
        let cacheKey = "daterange_\(days)"
        
        // Check cache first
        if let cachedMatches = MatchCacheManager.shared.getCachedMatchList(for: cacheKey) {
            print("📦 Using cached date range matches (\(cachedMatches.count) matches)")
            return cachedMatches
        }
        
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
        
        // Cache the results
        MatchCacheManager.shared.cacheMatchList(matches, for: cacheKey)
        
        print("📊 Found \(matches.count) matches in date range")
        
        let matchesByCompetition = Dictionary(grouping: matches) { $0.competition.code }
        for (competition, competitionMatches) in matchesByCompetition {
            print("  \(competition): \(competitionMatches.count) matches")
        }
        
        return matches
    }
    
    // MARK: - Main Match Service Protocol Methods with Robust Error Handling
    
    func fetchLiveMatches(competitionCode: String? = nil) async throws -> [Match] {
        return try await fetchLiveMatchesWithFallback(competitionCode: competitionCode)
    }
    
    func fetchLiveMatchesWithFallback(competitionCode: String? = nil) async throws -> [Match] {
        var lastError: Error?
        let maxRetries = 3
        
        for attempt in 1...maxRetries {
            do {
                print("🔄 Fetching live matches (attempt \(attempt)/\(maxRetries))")
                
                // Try with cache first
                let matches = try await fetchLiveMatchesFromCache(competitionCode: competitionCode)
                
                if !matches.isEmpty {
                    return matches
                }
                
                print("⚪ No live matches found, trying upcoming...")
                
                // Fallback to upcoming matches
                let upcomingMatches = try await fetchUpcomingMatchesFromCache(competitionCode: competitionCode)
                if !upcomingMatches.isEmpty {
                    return upcomingMatches
                }
                
                print("⚪ No upcoming matches, trying broader search...")
                
                // Final fallback - get any matches in next 7 days
                return try await fetchMatchesInDateRange(days: 7)
                
            } catch let error as APIError {
                lastError = error
                
                switch error {
                case .rateLimited:
                    print("🚨 Rate limited, waiting before retry...")
                    let waitTime = APIRateLimiter.shared.timeUntilNextCall()
                    if waitTime > 0 {
                        try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                    }
                    
                case .networkError:
                    print("📶 Network error, waiting \(attempt * 2) seconds before retry...")
                    try await Task.sleep(nanoseconds: UInt64(attempt * 2 * 1_000_000_000))
                    
                case .serverError(let code, let message):
                    print("🖥️ Server error \(code): \(message)")
                    if code >= 500 {
                        // Server error - retry after delay
                        try await Task.sleep(nanoseconds: UInt64(attempt * 3 * 1_000_000_000))
                    } else {
                        // Client error - don't retry
                        throw error
                    }
                    
                default:
                    print("❌ API error: \(error)")
                    try await Task.sleep(nanoseconds: UInt64(attempt * 1_000_000_000))
                }
            } catch {
                lastError = error
                print("❌ Unexpected error: \(error)")
                try await Task.sleep(nanoseconds: UInt64(attempt * 1_000_000_000))
            }
        }
        
        // If all retries failed, throw the last error
        throw lastError ?? NSError(domain: "MatchService", code: -1, userInfo: [
            NSLocalizedDescriptionKey: "Failed to fetch matches after \(maxRetries) attempts"
        ])
    }
    
    private func fetchLiveMatchesFromCache(competitionCode: String? = nil) async throws -> [Match] {
        let cacheKey = "live_\(competitionCode ?? "all")"
        
        // Check cache first
        if let cachedMatches = MatchCacheManager.shared.getCachedMatchList(for: cacheKey) {
            print("📦 Using cached live matches (\(cachedMatches.count) matches)")
            return cachedMatches
        }
        
        print("🌐 Fetching fresh live matches from API")
        
        var endpoint = "matches?status=LIVE,IN_PLAY"
        if let code = competitionCode {
            endpoint += "&competitions=\(code)"
        }
        
        print("🎯 Live matches endpoint: \(endpoint)")
        let response: MatchesResponse = try await apiClient.footballDataRequest(endpoint: endpoint)
        let matches = response.matches.map { $0.toAppModel() }
        
        // Cache the results
        MatchCacheManager.shared.cacheMatchList(matches, for: cacheKey)
        
        if !matches.isEmpty {
            print("✅ Found \(matches.count) live matches")
            return matches
        }
        
        print("⚪ No live matches found")
        return []
    }

    func fetchUpcomingMatches(competitionCode: String? = nil) async throws -> [Match] {
        return try await fetchUpcomingMatchesFromCache(competitionCode: competitionCode)
    }
    
    private func fetchUpcomingMatchesFromCache(competitionCode: String? = nil) async throws -> [Match] {
        let cacheKey = "upcoming_\(competitionCode ?? "all")"
        
        if let cachedMatches = MatchCacheManager.shared.getCachedMatchList(for: cacheKey) {
            print("📦 Using cached upcoming matches (\(cachedMatches.count) matches)")
            return cachedMatches
        }
        
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
                return response.matches.map { $0.toAppModel() }
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
            }
        ]
        
        for (index, strategy) in strategies.enumerated() {
            do {
                let matches = try await strategy()
                if !matches.isEmpty {
                    print("✅ Strategy \(index + 1) found \(matches.count) matches")
                    
                    // Cache the results
                    MatchCacheManager.shared.cacheMatchList(matches, for: cacheKey)
                    
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
    
    // MARK: - Match Details and Players with Caching
    
    func fetchMatchDetails(matchId: String) async throws -> MatchDetail {
        return try await fetchMatchDetailsFromCache(matchId: matchId)
    }
    
    private func fetchMatchDetailsFromCache(matchId: String) async throws -> MatchDetail {
        // Check cache first
        if let cachedMatch = MatchCacheManager.shared.getCachedMatch(matchId) {
            print("📦 Using cached match details for \(matchId)")
            return MatchDetail(
                match: cachedMatch,
                venue: nil,
                attendance: nil,
                referee: nil,
                homeScore: 0,
                awayScore: 0
            )
        }
        
        print("🌐 Fetching fresh match details from API for \(matchId)")
        let endpoint = "matches/\(matchId)"
        let response: APIMatchDetail = try await apiClient.footballDataRequest(endpoint: endpoint)
        let matchDetail = response.toAppModel()
        
        // Cache the match
        MatchCacheManager.shared.cacheMatch(matchDetail.match)
        
        return matchDetail
    }
    
    func fetchMatchPlayers(matchId: String) async throws -> [Player] {
        return try await fetchMatchPlayersFromCache(matchId: matchId)
    }
    
    private func fetchMatchPlayersFromCache(matchId: String) async throws -> [Player] {
        // Check cache first
        if let cachedPlayers = MatchCacheManager.shared.getCachedPlayers(for: matchId) {
            print("📦 Using cached players for match \(matchId) (\(cachedPlayers.count) players)")
            return cachedPlayers
        }
        
        print("🌐 Fetching fresh players from API for match \(matchId)")
        
        let endpoint = "matches/\(matchId)"
        let response: APIMatchDetail = try await apiClient.footballDataRequest(endpoint: endpoint)
        
        var players: [Player] = []
        
        // Add home team players - handle optional squad
        if let squad = response.homeTeam.squad, !squad.isEmpty {
            for player in squad {
                players.append(player.toAppModel(team: response.homeTeam.toAppModel()))
            }
        } else {
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
            print("No squad data available for away team, generating dummy players")
            let awayTeam = response.awayTeam.toAppModel()
            players.append(contentsOf: generateDummyPlayers(for: awayTeam))
        }
        
        if players.isEmpty {
            print("No players available from API, using backup data")
            players = createDummyPlayers()
        }
        
        // Cache the players
        MatchCacheManager.shared.cachePlayers(players, for: matchId)
        
        return players
    }
    
    // MARK: - Smart Match Monitoring
    
    func startMonitoringMatch(matchId: String, updateInterval: TimeInterval = 60, onUpdate: @escaping (MatchUpdate) -> Void) -> Task<Void, Never> {
        return smartMatchMonitoring(matchId: matchId, onUpdate: onUpdate)
    }
    
    func smartMatchMonitoring(matchId: String, onUpdate: @escaping (MatchUpdate) -> Void) -> Task<Void, Never> {
        return Task {
            var previousEvents: [MatchEvent] = []
            var consecutiveFailures = 0
            var lastSuccessfulUpdate = Date()
            
            while !Task.isCancelled {
                do {
                    // Check rate limit before making call
                    guard APIRateLimiter.shared.canMakeCall() else {
                        let waitTime = APIRateLimiter.shared.timeUntilNextCall()
                        print("⏳ Rate limited, waiting \(waitTime) seconds")
                        try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                        continue
                    }
                    
                    // Get match details
                    let matchDetails = try await fetchMatchDetails(matchId: matchId)
                    let currentTime = Date()
                    
                    // Smart interval based on match status and time
                    let pollInterval = calculateSmartInterval(
                        matchStatus: matchDetails.match.status,
                        lastUpdate: lastSuccessfulUpdate,
                        currentTime: currentTime
                    )
                    
                    // Try to get events (this might not always be available)
                    var newEvents: [MatchEvent] = []
                    do {
                        let events = try await fetchMatchEvents(matchId: matchId)
                        newEvents = events.filter { event in
                            !previousEvents.contains { $0.id == event.id }
                        }
                        
                        if !newEvents.isEmpty {
                            previousEvents.append(contentsOf: newEvents)
                            print("🔔 Found \(newEvents.count) new events")
                        }
                    } catch {
                        print("⚠️ Could not fetch events (this is normal for some matches): \(error)")
                        // Continue without events - many matches don't provide live events
                    }
                    
                    // Create update even if no new events (for match status changes)
                    let update = MatchUpdate(
                        match: matchDetails.match,
                        newEvents: newEvents
                    )
                    
                    await MainActor.run {
                        onUpdate(update)
                    }
                    
                    lastSuccessfulUpdate = currentTime
                    consecutiveFailures = 0
                    
                    print("📊 Next poll in \(pollInterval) seconds (Status: \(matchDetails.match.status))")
                    try await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                    
                } catch {
                    consecutiveFailures += 1
                    let backoffDelay = min(300, 30 * consecutiveFailures) // Max 5 minutes
                    
                    print("❌ Monitoring error (attempt \(consecutiveFailures)): \(error)")
                    print("⏳ Backing off for \(backoffDelay) seconds")
                    
                    do {
                        try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                    } catch {
                        // If sleep is cancelled, break the loop
                        break
                    }
                }
            }
        }
    }
    
    private func calculateSmartInterval(matchStatus: MatchStatus, lastUpdate: Date, currentTime: Date) -> TimeInterval {
        let timeSinceLastUpdate = currentTime.timeIntervalSince(lastUpdate)
        
        switch matchStatus {
        case .inProgress:
            // During active play - more frequent updates but respect rate limits
            if timeSinceLastUpdate < 120 { // Less than 2 minutes since last update
                return 90  // 1.5 minutes
            } else {
                return 60  // 1 minute if it's been a while
            }
            
        case .halftime:
            // Less frequent during halftime
            return 300 // 5 minutes
            
        case .upcoming:
            // Very infrequent for upcoming matches
            return 600 // 10 minutes
            
        case .completed:
            // Stop monitoring completed matches
            return 0
            
        case .unknown:
            // Conservative interval for unknown status
            return 180 // 3 minutes
        }
    }
    
    // MARK: - Legacy Methods (keeping for backward compatibility)
    
    func enhancedMatchMonitoring(matchId: String, updateInterval: TimeInterval = 60, onUpdate: @escaping (MatchUpdate) -> Void) -> Task<Void, Never> {
        return smartMatchMonitoring(matchId: matchId, onUpdate: onUpdate)
    }
    
    func fetchMatchEvents(matchId: String) async throws -> [MatchEvent] {
        // For now, return empty events as most matches don't provide real-time events
        // This would be enhanced with actual event endpoints when available
        return []
    }
    
    // MARK: - Premium Features
    
    func fetchMatchLineup(matchId: String) async throws -> Lineup {
        let endpoints = [
            "matches/\(matchId)/lineups",
            "matches/\(matchId)"
        ]
        
        for (index, endpoint) in endpoints.enumerated() {
            do {
                print("🎯 Lineup attempt \(index + 1): \(endpoint)")
                
                if index == 0 {
                    let response: APILineup = try await apiClient.footballDataRequest(endpoint: endpoint)
                    return response.toAppModel()
                } else {
                    let response: APIMatchDetail = try await apiClient.footballDataRequest(endpoint: endpoint)
                    
                    let homeLineup = TeamLineup(
                        team: response.homeTeam.toAppModel(),
                        formation: nil,
                        startingXI: response.homeTeam.squad?.prefix(11).map { $0.toAppModel(team: response.homeTeam.toAppModel()) } ?? [],
                        substitutes: response.homeTeam.squad?.dropFirst(11).map { $0.toAppModel(team: response.homeTeam.toAppModel()) } ?? [],
                        coach: nil
                    )
                    
                    let awayLineup = TeamLineup(
                        team: response.awayTeam.toAppModel(),
                        formation: nil,
                        startingXI: response.awayTeam.squad?.prefix(11).map { $0.toAppModel(team: response.awayTeam.toAppModel()) } ?? [],
                        substitutes: response.awayTeam.squad?.dropFirst(11).map { $0.toAppModel(team: response.awayTeam.toAppModel()) } ?? [],
                        coach: nil
                    )
                    
                    return Lineup(homeTeam: homeLineup, awayTeam: awayLineup)
                }
            } catch {
                print("❌ Lineup attempt \(index + 1) failed: \(error)")
                if index == endpoints.count - 1 {
                    throw error
                }
            }
        }
        
        throw NSError(domain: "LineupError", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "All lineup fetch attempts failed"
        ])
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
    
    // MARK: - Helper Methods
    
    private func createDummyPlayers() -> [Player] {
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
