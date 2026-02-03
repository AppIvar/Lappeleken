//
//  DataManager.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 07/08/2025.
//

import Foundation

/// Central data management layer
/// Coordinates API calls, caching, and error handling
class DataManager {
    static let shared = DataManager()
    
    // Services
    private let footballDataService: FootballDataMatchService
    private let liveService: LiveGameDataService
    private let cacheManager: UnifiedCacheManager
    
    private init() {
        // Initialize football-data.org service
        let footballDataAPIClient = APIClient(baseURL: "https://api.football-data.org/v4")
        self.footballDataService = FootballDataMatchService(
            apiClient: footballDataAPIClient,
            apiKey: AppConfig.footballDataAPIKey
        )
        
        // Initialize your backend service
        let apiClient = APIClient(baseURL: AppConfig.apiBaseURL)
        self.liveService = LiveGameDataService(apiClient: apiClient)
        
        // Initialize cache
        self.cacheManager = UnifiedCacheManager.shared
    }
    
    // MARK: - Competition Data
    
    /// Fetch available competitions with caching
    func fetchCompetitions() async throws -> [Competition] {
        // Check cache first
        if let cached = cacheManager.getCompetitions() {
            print("📦 Using cached competitions")
            return cached
        }
        
        do {
            let competitions = try await footballDataService.fetchCompetitions()
            cacheManager.cacheCompetitions(competitions)
            return competitions
        } catch {
            throw DataError.fetchFailed("competitions", underlying: error)
        }
    }
    
    // MARK: - Match Data
    
    /// Fetch comprehensive match list (live + upcoming + recent)
    func fetchMatches() async throws -> [Match] {
        print("🔍 Fetching comprehensive match data")
        
        // Check cache first
        if let cached = cacheManager.getLiveMatches() {
            print("📦 Using cached matches (\(cached.count) matches)")
            return cached
        }
        
        var allMatches: [Match] = []
        var errors: [String] = []
        
        // Fetch different match types concurrently
        async let liveTask = fetchWithErrorHandling {
            try await self.footballDataService.fetchLiveMatches()
        }
        async let upcomingTask = fetchWithErrorHandling {
            try await self.footballDataService.fetchUpcomingMatches()
        }
        async let recentTask = fetchWithErrorHandling {
            try await self.footballDataService.fetchMatchesInDateRange(days: 1)
        }
        
        // Collect results
        let (liveMatches, liveError) = await liveTask
        let (upcomingMatches, upcomingError) = await upcomingTask
        let (allRecentMatches, recentError) = await recentTask
        
        // Add successful results
        if let live = liveMatches {
            allMatches.append(contentsOf: live)
            print("✅ Found \(live.count) live matches")
        } else if let error = liveError {
            errors.append("Live: \(error)")
        }
        
        if let upcoming = upcomingMatches {
            allMatches.append(contentsOf: upcoming)
            print("✅ Found \(upcoming.count) upcoming matches")
        } else if let error = upcomingError {
            errors.append( "Upcoming: \(error)")
        }
        
        if let recent = allRecentMatches {
            let finished = recent.filter { $0.status == .completed || $0.status == .finished }
            allMatches.append(contentsOf: finished)
            print("✅ Found \(finished.count) recent finished matches")
        } else if let error = recentError {
            errors.append("Recent: \(error)")
        }
        
        // Remove duplicates
        let uniqueMatches = removeDuplicateMatches(allMatches)
        
        if uniqueMatches.isEmpty {
            let combinedError = errors.joined(separator: "; ")
            throw DataError.fetchFailed("No matches found. Errors: \(combinedError)", underlying: nil)
        }
        
        print("✅ Returning \(uniqueMatches.count) unique matches")
        return uniqueMatches
    }
    
    /// Fetch today's matches specifically
    func fetchTodaysMatches() async throws -> [Match] {
        do {
            return try await footballDataService.fetchTodaysMatches()
        } catch {
            throw DataError.fetchFailed("todays matches", underlying: error)
        }
    }
    
    /// Fetch live matches only
    func fetchLiveMatches(competitionCode: String? = nil) async throws -> [Match] {
        do {
            return try await footballDataService.fetchLiveMatches(competitionCode: competitionCode)
        } catch {
            throw DataError.fetchFailed("live matches", underlying: error)
        }
    }
    
    /// Fetch match details with caching
    func fetchMatchDetails(_ matchId: String) async throws -> MatchDetail {
        // Check cache
        if let cached = cacheManager.getMatchDetail(for: matchId) {
            print("📦 Using cached match detail for \(matchId)")
            return cached
        }
        
        do {
            let detail = try await footballDataService.fetchMatchDetails(matchId: matchId)
            cacheManager.cacheMatchDetail(detail, for: matchId)
            return detail
        } catch {
            throw DataError.fetchFailed("match details for \(matchId)", underlying: error)
        }
    }
    
    // MARK: - Player Data
    
    /// Fetch players for a specific match with caching
    func fetchPlayers(for matchId: String) async throws -> [Player] {
        print("👥 Fetching players for match: \(matchId)")
        
        // Check cache first
        if let cached = cacheManager.getPlayers(for: matchId) {
            print("📦 Using cached players (\(cached.count) players)")
            return cached
        }
        
        do {
            let players = try await footballDataService.fetchMatchPlayers(matchId: matchId)
            print("✅ Fetched \(players.count) players")
            
            // Cache with 4-hour expiration
            cacheManager.cachePlayers(players, for: matchId)
            return players
            
        } catch {
            print("❌ Failed to fetch players: \(error)")
            throw DataError.fetchFailed("players for match \(matchId)", underlying: error)
        }
    }
    
    /// Fetch team squad (all players in team roster)
    func fetchTeamSquad(teamId: String) async throws -> TeamSquad {
        do {
            return try await footballDataService.fetchTeamSquad(teamId: teamId)
        } catch {
            throw DataError.fetchFailed("team squad for \(teamId)", underlying: error)
        }
    }
    
    /// Fetch squad players for a specific match (fallback when lineup not available)
    func fetchSquad(for matchId: String) async throws -> [Player] {
        print("📦 Fetching squad fallback for match: \(matchId)")
        
        do {
            // Get match details to know which teams are playing
            let matchDetail = try await fetchMatchDetails(matchId)
            
            // Fetch both team squads
            async let homeSquadTask = footballDataService.fetchTeamSquad(teamId: matchDetail.match.homeTeam.id.uuidString)
            async let awaySquadTask = footballDataService.fetchTeamSquad(teamId: matchDetail.match.awayTeam.id.uuidString)
            
            let (homeSquad, awaySquad) = try await (homeSquadTask, awaySquadTask)
            
            // Combine all players from both squads
            var allPlayers: [Player] = []
            allPlayers.append(contentsOf: homeSquad.players)
            allPlayers.append(contentsOf: awaySquad.players)
            
            print("✅ Fetched \(allPlayers.count) squad players")
            return allPlayers
            
        } catch {
            print("❌ Failed to fetch squad: \(error)")
            throw DataError.fetchFailed("squad for match \(matchId)", underlying: error)
        }
    }
    
    // MARK: - Event recording
    
    /// Record a player event to backend
    func recordEvent(playerId: UUID, eventType: Bet.EventType) async throws {
        do {
            try await liveService.recordEvent(playerId: playerId, eventType: eventType)
        } catch {
            // Don't throw - allow offline play
            print("⚠️ Failed to record event: \(error)")
        }
    }
    
    // MARK: - Game Management

    /// Save game to backend and locally
    func saveGame(_ gameSession: GameSession, name: String) async throws {
        print("💾 DataManager.saveGame() - Name: \(name)")
        
        // Update save tracking on main thread
        await MainActor.run {
            gameSession.currentSaveName = name
            gameSession.hasBeenSaved = true
        }
        
        // Try cloud save (will fallback to local internally)
        do {
            try await liveService.saveGame(gameSession: gameSession, name: name)
            print("✅ Game saved to cloud")
        } catch {
            print("⚠️ Cloud save failed, saving locally: \(error)")
            // Save locally directly - DO NOT call gameSession.saveGame (causes loop!)
            GameHistoryManager.shared.saveGame(gameSession, name: name)
        }
        
        print("✅ Game saved successfully")
    }
    
    /// Fetch live games from your backend
    func fetchLiveGames() async throws -> [GameSession] {
        do {
            return try await liveService.fetchLiveGames()
        } catch {
            print("⚠️ Failed to fetch live games: \(error)")
            return []
        }
    }
}

// MARK: - Helper Methods

extension DataManager {
    /// Helper to handle errors gracefully in async tasks
    private func fetchWithErrorHandling<T>(
        operation: @escaping () async throws -> T
    ) async -> (T?, String?) {
        do {
            let result = try await operation()
            return (result, nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }
    
    /// Remove duplicate matches based on ID
    private func removeDuplicateMatches(_ matches: [Match]) -> [Match] {
        var seen = Set<String>()
        return matches.filter { match in
            guard !seen.contains(match.id) else { return false }
            seen.insert(match.id)
            return true
        }
    }
}

enum DataError: Error {
    case fetchFailed(String, underlying: Error?)
    case saveFailed(String, underlying: Error?)
    case networkUnavailable
    case rateLimited(retryAfter: TimeInterval)
    case invalidData(String)
    
    var localizedDescription: String {
        switch self {
        case .fetchFailed(let resource, let error):
            if let error = error {
                return "Failed to fetch \(resource): \(error.localizedDescription)"
            }
            return "Failed to fetch \(resource)"
        case .saveFailed(let item, let error):
            if let error = error {
                return "Failed to save \(item): \(error.localizedDescription)"
            }
            return "Failed to save \(item)"
        case .networkUnavailable:
            return "Network connection is unavailable"
        case .rateLimited(let retryAfter):
            return "Rate limited. Try again in \(Int(retryAfter)) seconds"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}



