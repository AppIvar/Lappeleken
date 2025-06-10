//
//  MockFootballDataService.swift
//  Lucky Football Slip
//
//  Mock service for testing live mode functionality
//

import Foundation

class MockFootballDataService: MatchService {
    private var mockMatches: [Match] = []
    private var mockPlayers: [String: [Player]] = [:]
    private var currentMatch: Match?
    private var mockEvents: [MatchEvent] = []
    private var eventIndex = 0
    
    // Mock match states for testing different scenarios
    enum MockMatchState {
        case upcoming
        case justStarted
        case firstHalf
        case halftime
        case secondHalf
        case finished
    }
    
    private var currentState: MockMatchState = .upcoming
    private var matchMinute = 0
    
    init() {
        setupMockData()
    }
    
    // MARK: - MatchService Protocol Implementation
    
    func fetchCompetitions() async throws -> [Competition] {
        return [
            Competition(id: "PL", name: "Premier League", code: "PL"),
            Competition(id: "CL", name: "UEFA Champions League", code: "CL")
        ]
    }
    
    func fetchLiveMatches(competitionCode: String? = nil) async throws -> [Match] {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        return mockMatches.filter { match in
            match.status == .inProgress || match.status == .upcoming
        }
    }
    
    func fetchUpcomingMatches(competitionCode: String? = nil) async throws -> [Match] {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        return mockMatches.filter { $0.status == .upcoming }
    }
    
    func fetchMatchDetails(matchId: String) async throws -> MatchDetail {
        guard let match = mockMatches.first(where: { $0.id == matchId }) else {
            throw APIError.serverError(404, "Match not found")
        }
        
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        return MatchDetail(
            match: match,
            venue: "Mock Stadium",
            attendance: 50000,
            referee: "Test Referee",
            homeScore: getCurrentScore().home,
            awayScore: getCurrentScore().away
        )
    }
    
    func fetchMatchPlayers(matchId: String) async throws -> [Player] {
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        if let players = mockPlayers[matchId] {
            return players
        }
        
        // Generate players for this match if not already created
        guard let match = mockMatches.first(where: { $0.id == matchId }) else {
            throw APIError.serverError(404, "Match not found")
        }
        
        let players = generatePlayersForMatch(match)
        mockPlayers[matchId] = players
        return players
    }
    
    func startMonitoringMatch(matchId: String, updateInterval: TimeInterval = 30, onUpdate: @escaping (MatchUpdate) -> Void) -> Task<Void, Never> {
        return Task {
            guard let match = mockMatches.first(where: { $0.id == matchId }) else {
                return
            }
            
            currentMatch = match
            
            while !Task.isCancelled {
                // Simulate match progression
                await simulateMatchProgression()
                
                // Create update with new events
                let newEvents = getNewEvents()
                let updatedMatch = getCurrentMatch()
                
                let update = MatchUpdate(
                    match: updatedMatch,
                    newEvents: newEvents
                )
                
                await MainActor.run {
                    onUpdate(update)
                }
                
                // Wait for next update
                try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
            }
        }
    }
    
    func fetchMatchEvents(matchId: String) async throws -> [MatchEvent] {
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        return mockEvents
    }
    
    func fetchMatchLineup(matchId: String) async throws -> Lineup {
        guard let match = mockMatches.first(where: { $0.id == matchId }) else {
            throw APIError.serverError(404, "Match not found")
        }
        
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let players = try await fetchMatchPlayers(matchId: matchId)
        let homePlayers = players.filter { $0.team.id == match.homeTeam.id }
        let awayPlayers = players.filter { $0.team.id == match.awayTeam.id }
        
        let homeLineup = TeamLineup(
            team: match.homeTeam,
            formation: "4-3-3",
            startingXI: Array(homePlayers.prefix(11)),
            substitutes: Array(homePlayers.dropFirst(11)),
            coach: Coach(id: "1", name: "Home Coach", nationality: "England")
        )
        
        let awayLineup = TeamLineup(
            team: match.awayTeam,
            formation: "4-2-3-1",
            startingXI: Array(awayPlayers.prefix(11)),
            substitutes: Array(awayPlayers.dropFirst(11)),
            coach: Coach(id: "2", name: "Away Coach", nationality: "Spain")
        )
        
        return Lineup(homeTeam: homeLineup, awayTeam: awayLineup)
    }
    
    func fetchLiveMatchDetails(matchId: String) async throws -> MatchWithEvents {
        let matchDetail = try await fetchMatchDetails(matchId: matchId)
        let events = try await fetchMatchEvents(matchId: matchId)
        
        return MatchWithEvents(
            match: matchDetail.match,
            events: events,
            homeLineup: nil,
            awayLineup: nil
        )
    }
    
    func fetchTeamSquad(teamId: String) async throws -> TeamSquad {
        // Find team from mock matches
        let allTeams = mockMatches.flatMap { [$0.homeTeam, $0.awayTeam] }
        guard let team = allTeams.first(where: { $0.id.uuidString == teamId }) else {
            throw APIError.serverError(404, "Team not found")
        }
        
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let players = generatePlayersForTeam(team)
        
        return TeamSquad(
            team: team,
            players: players,
            coach: Coach(id: teamId, name: "\(team.name) Coach", nationality: "Unknown")
        )
    }
    
    // MARK: - Additional MatchService Protocol Methods
    
    func fetchTodaysMatches() async throws -> [Match] {
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        return mockMatches.filter { match in
            match.startTime >= today && match.startTime < tomorrow
        }
    }
    
    func fetchMatchesInDateRange(days: Int = 7) async throws -> [Match] {
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        let today = Date()
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: today) ?? today
        
        return mockMatches.filter { match in
            match.startTime >= today && match.startTime <= futureDate
        }
    }
    
    func fetchLiveMatchesWithFallback(competitionCode: String? = nil) async throws -> [Match] {
        // Try live matches first
        let liveMatches = try await fetchLiveMatches(competitionCode: competitionCode)
        
        if !liveMatches.isEmpty {
            return liveMatches
        }
        
        // Fallback to upcoming matches
        print("🔄 No live matches, falling back to upcoming...")
        return try await fetchUpcomingMatches(competitionCode: competitionCode)
    }
    
    func enhancedMatchMonitoring(matchId: String, updateInterval: TimeInterval = 60, onUpdate: @escaping (MatchUpdate) -> Void) -> Task<Void, Never> {
        return startMonitoringMatch(matchId: matchId, updateInterval: updateInterval, onUpdate: onUpdate)
    }
    
    func smartMatchMonitoring(matchId: String, onUpdate: @escaping (MatchUpdate) -> Void) -> Task<Void, Never> {
        return startMonitoringMatch(matchId: matchId, updateInterval: 30, onUpdate: onUpdate)
    }
    
    func fetchLiveMatchesWithCache(competitionCode: String? = nil) async throws -> [Match] {
        // Mock service doesn't need caching, just return live matches
        return try await fetchLiveMatches(competitionCode: competitionCode)
    }
    
    func fetchMatchDetailsWithCache(matchId: String) async throws -> MatchDetail {
        // Mock service doesn't need caching, just return match details
        return try await fetchMatchDetails(matchId: matchId)
    }
    
    func fetchMatchPlayersWithCache(matchId: String) async throws -> [Player] {
        // Mock service doesn't need caching, just return players
        return try await fetchMatchPlayers(matchId: matchId)
    }
    
    func fetchMatchPlayersRobust(for matchId: String) async throws -> [Player]? {
        do {
            return try await fetchMatchPlayers(matchId: matchId)
        } catch {
            print("⚠️ Mock service: Error fetching players for \(matchId): \(error)")
            return nil
        }
    }
    
    // MARK: - Mock Data Setup
    
    private func setupMockData() {
        let premierLeague = Competition(id: "PL", name: "Premier League", code: "PL")
        let championsLeague = Competition(id: "CL", name: "UEFA Champions League", code: "CL")
        
        // Create teams
        let arsenal = Team(
            name: "Arsenal FC",
            shortName: "ARS",
            logoName: "arsenal_logo",
            primaryColor: "#EF0107"
        )
        
        let manchester = Team(
            name: "Manchester City",
            shortName: "MCI",
            logoName: "mancity_logo",
            primaryColor: "#6CABDD"
        )
        
        let liverpool = Team(
            name: "Liverpool FC",
            shortName: "LIV",
            logoName: "liverpool_logo",
            primaryColor: "#C8102E"
        )
        
        let chelsea = Team(
            name: "Chelsea FC",
            shortName: "CHE",
            logoName: "chelsea_logo",
            primaryColor: "#034694"
        )
        
        // Create test matches with different statuses
        mockMatches = [
            // Live match for testing
            Match(
                id: "test-live-1",
                homeTeam: arsenal,
                awayTeam: manchester,
                startTime: Date().addingTimeInterval(-1800), // Started 30 min ago
                status: .inProgress,
                competition: premierLeague
            ),
            
            // Another live match
            Match(
                id: "test-live-2",
                homeTeam: liverpool,
                awayTeam: chelsea,
                startTime: Date().addingTimeInterval(-900), // Started 15 min ago
                status: .inProgress,
                competition: premierLeague
            ),
            
            // Upcoming match
            Match(
                id: "test-upcoming-1",
                homeTeam: manchester,
                awayTeam: liverpool,
                startTime: Date().addingTimeInterval(3600), // In 1 hour
                status: .upcoming,
                competition: premierLeague
            ),
            
            // Champions League match
            Match(
                id: "test-cl-1",
                homeTeam: arsenal,
                awayTeam: chelsea,
                startTime: Date().addingTimeInterval(7200), // In 2 hours
                status: .upcoming,
                competition: championsLeague
            )
        ]
        
        print("🧪 MockFootballDataService initialized with \(mockMatches.count) test matches")
    }
    
    // MARK: - Public Test Access Methods
    
    func getCurrentTestMatch() -> Match? {
        return currentMatch ?? mockMatches.first
    }
    
    func getAllTestMatches() -> [Match] {
        return mockMatches
    }
    
    private func generatePlayersForMatch(_ match: Match) -> [Player] {
        var allPlayers: [Player] = []
        
        // Generate players for home team
        allPlayers.append(contentsOf: generatePlayersForTeam(match.homeTeam))
        
        // Generate players for away team
        allPlayers.append(contentsOf: generatePlayersForTeam(match.awayTeam))
        
        return allPlayers
    }
    
    private func generatePlayersForTeam(_ team: Team) -> [Player] {
        let positions: [Player.Position] = [
            .goalkeeper,
            .defender,
            .midfielder,
            .forward
        ]
        
        return positions.enumerated().map { index, position in
            let positionName = position.rawValue.capitalized
            let playerName = "\(team.shortName) \(positionName) \(index + 1)"
            
            return Player(
                name: playerName,
                team: team,
                position: position
            )
        }
    }
    
    // MARK: - Match Simulation
    
    private func simulateMatchProgression() async {
        guard let match = currentMatch else { return }
        
        // Update match minute and state
        matchMinute += Int.random(in: 1...3)
        
        switch currentState {
        case .upcoming:
            if Date() >= match.startTime {
                currentState = .justStarted
                matchMinute = 1
                addKickoffEvent()
            }
            
        case .justStarted:
            if matchMinute >= 5 {
                currentState = .firstHalf
            }
            
        case .firstHalf:
            if matchMinute >= 45 {
                currentState = .halftime
                addHalftimeEvent()
            } else {
                // Random events during first half
                if Int.random(in: 1...10) == 1 {
                    addRandomEvent()
                }
            }
            
        case .halftime:
            if matchMinute >= 50 {
                currentState = .secondHalf
                matchMinute = 46
                addSecondHalfEvent()
            }
            
        case .secondHalf:
            if matchMinute >= 90 {
                currentState = .finished
                addFullTimeEvent()
            } else {
                // Random events during second half
                if Int.random(in: 1...8) == 1 {
                    addRandomEvent()
                }
            }
            
        case .finished:
            // Match is over, no more events
            break
        }
        
        // Update match status
        updateMatchStatus()
    }
    
    private func updateMatchStatus() {
        guard let matchIndex = mockMatches.firstIndex(where: { $0.id == currentMatch?.id }) else {
            return
        }
        
        let newStatus: MatchStatus
        switch currentState {
        case .upcoming:
            newStatus = .upcoming
        case .justStarted, .firstHalf, .secondHalf:
            newStatus = .inProgress
        case .halftime:
            newStatus = .halftime
        case .finished:
            newStatus = .completed
        }
        
        mockMatches[matchIndex] = Match(
            id: mockMatches[matchIndex].id,
            homeTeam: mockMatches[matchIndex].homeTeam,
            awayTeam: mockMatches[matchIndex].awayTeam,
            startTime: mockMatches[matchIndex].startTime,
            status: newStatus,
            competition: mockMatches[matchIndex].competition
        )
        
        currentMatch = mockMatches[matchIndex]
    }
    
    private func addKickoffEvent() {
        let event = MatchEvent(
            id: "kickoff-\(Date().timeIntervalSince1970)",
            type: "kickoff",
            playerId: "",
            playerName: "Match Official",
            minute: 1,
            teamId: "",
            playerOffId: nil,
            playerOnId: nil
        )
        mockEvents.append(event)
    }
    
    private func addHalftimeEvent() {
        let event = MatchEvent(
            id: "halftime-\(Date().timeIntervalSince1970)",
            type: "halftime",
            playerId: "",
            playerName: "Match Official",
            minute: 45,
            teamId: "",
            playerOffId: nil,
            playerOnId: nil
        )
        mockEvents.append(event)
    }
    
    private func addSecondHalfEvent() {
        let event = MatchEvent(
            id: "secondhalf-\(Date().timeIntervalSince1970)",
            type: "second_half_start",
            playerId: "",
            playerName: "Match Official",
            minute: 46,
            teamId: "",
            playerOffId: nil,
            playerOnId: nil
        )
        mockEvents.append(event)
    }
    
    private func addFullTimeEvent() {
        let event = MatchEvent(
            id: "fulltime-\(Date().timeIntervalSince1970)",
            type: "full_time",
            playerId: "",
            playerName: "Match Official",
            minute: 90,
            teamId: "",
            playerOffId: nil,
            playerOnId: nil
        )
        mockEvents.append(event)
    }
    
    private func addRandomEvent() {
        guard let match = currentMatch,
              let matchId = match.id.split(separator: "-").first,
              let players = mockPlayers[String(matchId)] ?? mockPlayers[match.id] else {
            return
        }
        
        if players.isEmpty {
            // Generate players if they don't exist
            let generatedPlayers = generatePlayersForMatch(match)
            mockPlayers[match.id] = generatedPlayers
            addRandomEvent() // Retry with generated players
            return
        }
        
        let eventTypes = ["goal", "yellow_card", "substitution", "assist"]
        let eventType = eventTypes.randomElement()!
        let player = players.randomElement()!
        
        let event = MatchEvent(
            id: "event-\(Date().timeIntervalSince1970)",
            type: eventType,
            playerId: player.id.uuidString,
            playerName: player.name,
            minute: matchMinute,
            teamId: player.team.id.uuidString,
            playerOffId: eventType == "substitution" ? player.id.uuidString : nil,
            playerOnId: eventType == "substitution" ? players.randomElement()?.id.uuidString : nil
        )
        
        mockEvents.append(event)
        print("🎯 Mock event: \(eventType) by \(player.name) at minute \(matchMinute)")
    }
    
    private func getNewEvents() -> [MatchEvent] {
        let newEvents = Array(mockEvents.dropFirst(eventIndex))
        eventIndex = mockEvents.count
        return newEvents
    }
    
    private func getCurrentMatch() -> Match {
        return currentMatch ?? mockMatches[0]
    }
    
    private func getCurrentScore() -> (home: Int, away: Int) {
        let goals = mockEvents.filter { $0.type == "goal" }
        let homeGoals = goals.filter { event in
            guard let match = currentMatch else { return false }
            return event.teamId == match.homeTeam.id.uuidString
        }.count
        
        let awayGoals = goals.filter { event in
            guard let match = currentMatch else { return false }
            return event.teamId == match.awayTeam.id.uuidString
        }.count
        
        return (homeGoals, awayGoals)
    }
    
    // MARK: - Test Helpers
    
    func resetMatch() {
        currentState = .upcoming
        matchMinute = 0
        mockEvents.removeAll()
        eventIndex = 0
        
        // Reset match to upcoming
        if let matchIndex = mockMatches.firstIndex(where: { $0.id == currentMatch?.id }) {
            mockMatches[matchIndex] = Match(
                id: mockMatches[matchIndex].id,
                homeTeam: mockMatches[matchIndex].homeTeam,
                awayTeam: mockMatches[matchIndex].awayTeam,
                startTime: Date().addingTimeInterval(60), // Start in 1 minute
                status: .upcoming,
                competition: mockMatches[matchIndex].competition
            )
            currentMatch = mockMatches[matchIndex]
        }
    }
    
    func forceMatchState(_ state: MockMatchState) {
        currentState = state
        updateMatchStatus()
    }
    
    func addTestEvent(_ type: String) {
        guard let match = currentMatch,
              let players = mockPlayers[match.id],
              !players.isEmpty else {
            return
        }
        
        let player = players.randomElement()!
        let event = MatchEvent(
            id: "test-\(Date().timeIntervalSince1970)",
            type: type,
            playerId: player.id.uuidString,
            playerName: player.name,
            minute: matchMinute,
            teamId: player.team.id.uuidString,
            playerOffId: nil,
            playerOnId: nil
        )
        
        mockEvents.append(event)
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension MockFootballDataService {
    func getDebugInfo() -> String {
        var info = "🧪 Mock Service Debug Info:\n"
        info += "Current State: \(currentState)\n"
        info += "Match Minute: \(matchMinute)\n"
        info += "Total Events: \(mockEvents.count)\n"
        info += "Available Matches: \(mockMatches.count)\n"
        
        if let match = currentMatch {
            info += "Current Match: \(match.homeTeam.name) vs \(match.awayTeam.name)\n"
            info += "Match Status: \(match.status)\n"
            let score = getCurrentScore()
            info += "Score: \(score.home) - \(score.away)\n"
        }
        
        return info
    }
    
    func simulateGoal(for team: Team) {
        guard let match = currentMatch,
              let players = mockPlayers[match.id] else {
            return
        }
        
        let teamPlayers = players.filter { $0.team.id == team.id }
        guard let scorer = teamPlayers.randomElement() else { return }
        
        let event = MatchEvent(
            id: "test-goal-\(Date().timeIntervalSince1970)",
            type: "goal",
            playerId: scorer.id.uuidString,
            playerName: scorer.name,
            minute: matchMinute,
            teamId: team.id.uuidString,
            playerOffId: nil,
            playerOnId: nil
        )
        
        mockEvents.append(event)
        print("⚽ Test goal: \(scorer.name) for \(team.name)")
    }
}
#endif
