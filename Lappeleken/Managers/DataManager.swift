//
//  DataManager.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 07/08/2025.
//

import Foundation

/// Clean DataManager focused on Live mode only
/// Uses real APIs and caching - no mock data or sample fallbacks
class DataManager {
    static let shared = DataManager()
    
    private let footballDataService: FootballDataMatchService
    private let liveService: LiveGameDataService
    private let cacheManager: UnifiedCacheManager
    
    private init() {
        // Initialize live services only
        let footballDataAPIClient = APIClient(baseURL: "https://api.football-data.org/v4")
        self.footballDataService = FootballDataMatchService(
            apiClient: footballDataAPIClient,
            apiKey: AppConfig.footballDataAPIKey
        )
        
        let apiClient = APIClient(baseURL: AppConfig.apiBaseURL)
        self.liveService = LiveGameDataService(apiClient: apiClient)
        self.cacheManager = UnifiedCacheManager.shared
    }
    
    // MARK: - Public Data Interface
    
    /// Fetch live matches (live + upcoming + recent finished)
    func fetchMatches(mode: DataMode? = nil) async throws -> [Match] {
        print("ðŸ“Š DataManager.fetchMatches() - Live mode")
        
        do {
            let matches = try await fetchLiveMatches()
            print("âœ… DataManager returned \(matches.count) matches")
            return matches
        } catch {
            print("âŒ DataManager.fetchMatches() failed: \(error)")
            throw DataError.fetchFailed("matches", underlying: error)
        }
    }
    
    /// Fetch players for a specific match
    func fetchPlayers(for matchId: String, mode: DataMode? = nil) async throws -> [Player] {
        print("ðŸ‘¥ DataManager.fetchPlayers() for match: \(matchId)")
        
        // Check cache first
        if let cachedPlayers = cacheManager.getPlayers(for: matchId) {
            print("ðŸ“¦ Using cached players for match \(matchId) (\(cachedPlayers.count) players)")
            return cachedPlayers
        }
        
        do {
            let players = try await footballDataService.fetchMatchPlayers(matchId: matchId)
            print("ðŸŒ Fetched \(players.count) live players")
            
            // Cache the results
            cacheManager.cachePlayers(players, for: matchId, expiration: .hours(4))
            
            return players
            
        } catch {
            print("âŒ DataManager.fetchPlayers() failed: \(error)")
            throw DataError.fetchFailed("players for match \(matchId)", underlying: error)
        }
    }
    
    /// Fetch available competitions
    func fetchCompetitions(mode: DataMode? = nil) async throws -> [Competition] {
        // Check cache first
        if let cachedCompetitions = cacheManager.getCompetitions() {
            print("ðŸ“¦ Using cached competitions")
            return cachedCompetitions
        }
        
        do {
            let competitions = try await footballDataService.fetchCompetitions()
            
            // Cache with longer expiration for competitions
            cacheManager.cacheCompetitions(competitions, expiration: .hours(24))
            return competitions
            
        } catch {
            throw DataError.fetchFailed("competitions", underlying: error)
        }
    }
    
    /// Fetch match details with lineup information
    func fetchMatchDetails(_ matchId: String, mode: DataMode? = nil) async throws -> MatchDetail {
        // Check cache first
        if let cachedDetail = cacheManager.getMatchDetail(for: matchId) {
            print("ðŸ“¦ Using cached match detail for \(matchId)")
            return cachedDetail
        }
        
        do {
            let matchDetail = try await footballDataService.fetchMatchDetails(matchId: matchId)
            
            // Cache the result
            cacheManager.cacheMatchDetail(matchDetail, for: matchId, expiration: .hours(2))
            
            return matchDetail
            
        } catch {
            throw DataError.fetchFailed("match details for \(matchId)", underlying: error)
        }
    }
    
    /// Save game using existing GameSession method
    func saveGame(_ gameSession: GameSession, name: String) async throws {
        print("ðŸ’¾ DataManager.saveGame() - Name: \(name)")
        
        do {
            // Update save tracking
            await MainActor.run {
                gameSession.currentSaveName = name
                gameSession.hasBeenSaved = true
            }
            
            // Use existing save method from GameSession
            gameSession.saveGame(name: name)
            
            print("âœ… Game saved successfully via DataManager")
            
        } catch {
            print("âŒ DataManager.saveGame() failed: \(error)")
            throw DataError.saveFailed("game '\(name)'", underlying: error)
        }
    }
    
    /// Record event using live service
    func recordEvent(playerId: UUID, eventType: Bet.EventType, mode: DataMode? = nil) async throws {
        do {
            try await liveService.recordEvent(playerId: playerId, eventType: eventType)
        } catch {
            // Don't throw for event recording failures - just log them
            print("âš ï¸ Failed to record event: \(error)")
        }
    }
}

// MARK: - Private Implementation Methods

extension DataManager {
    
    // MARK: - Live Match Fetching
    
    private func fetchLiveMatches() async throws -> [Match] {
        // Check cache first
        if let cachedMatches = cacheManager.getLiveMatches() {
            print("ðŸ“¦ Using cached comprehensive matches (\(cachedMatches.count) matches)")
            return cachedMatches
        }
        
        print("ðŸ”„ Fetching comprehensive match data (live + upcoming + recent)")
        
        var allMatches: [Match] = []
        var errors: [String] = []
        
        // Fetch different match types concurrently
        async let liveTask = fetchWithErrorHandling {
            try await self.footballDataService.fetchLiveMatches(competitionCode: nil)
        }
        async let upcomingTask = fetchWithErrorHandling {
            try await self.footballDataService.fetchUpcomingMatches(competitionCode: nil)
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
            print("âœ… Found \(live.count) live matches")
        } else if let error = liveError {
            errors.append("Live: \(error)")
        }
        
        if let upcoming = upcomingMatches {
            allMatches.append(contentsOf: upcoming)
            print("âœ… Found \(upcoming.count) upcoming matches")
        } else if let error = upcomingError {
            errors.append("Upcoming: \(error)")
        }
        
        if let recent = allRecentMatches {
            let finishedMatches = recent.filter { $0.status == .completed || $0.status == .finished }
            allMatches.append(contentsOf: finishedMatches)
            print("âœ… Found \(finishedMatches.count) recent finished matches")
        } else if let error = recentError {
            errors.append("Recent: \(error)")
        }
        
        // Remove duplicates
        let uniqueMatches = removeDuplicateMatches(allMatches)
        
        if uniqueMatches.isEmpty {
            let combinedError = errors.joined(separator: "; ")
            throw DataError.fetchFailed("No live matches found. Errors: \(combinedError)", underlying: NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: combinedError]))
        }
        
        // Sort by relevance (live first, then upcoming, then recent)
        let sortedMatches = sortMatchesByRelevance(uniqueMatches)
        
        // Cache results
        cacheManager.cacheLiveMatches(sortedMatches)
        print("ðŸŽ¯ Total matches: \(sortedMatches.count)")
        
        return sortedMatches
    }
    
    // MARK: - Helper Methods
    
    /// Safe error handling wrapper for async operations
    private func fetchWithErrorHandling<T>(_ operation: () async throws -> T) async -> (T?, String?) {
        do {
            let result = try await operation()
            return (result, nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }
    
    /// Remove duplicate matches based on ID
    private func removeDuplicateMatches(_ matches: [Match]) -> [Match] {
        var uniqueMatches: [Match] = []
        var seenIds: Set<String> = []
        
        for match in matches {
            if !seenIds.contains(match.id) {
                uniqueMatches.append(match)
                seenIds.insert(match.id)
            }
        }
        
        return uniqueMatches
    }
    
    /// Sort matches by relevance: Live â†’ Upcoming â†’ Recent
    private func sortMatchesByRelevance(_ matches: [Match]) -> [Match] {
        return matches.sorted { match1, match2 in
            // Priority 1: Live matches first
            if (match1.status == .inProgress || match1.status == .halftime) &&
               !(match2.status == .inProgress || match2.status == .halftime) {
                return true
            }
            if !(match1.status == .inProgress || match1.status == .halftime) &&
               (match2.status == .inProgress || match2.status == .halftime) {
                return false
            }
            
            // Priority 2: Upcoming matches (earliest first)
            if match1.status == .upcoming && match2.status == .upcoming {
                return match1.startTime < match2.startTime
            }
            
            // Priority 3: Upcoming vs finished (upcoming first)
            if match1.status == .upcoming && (match2.status == .completed || match2.status == .finished) {
                return true
            }
            if (match1.status == .completed || match1.status == .finished) && match2.status == .upcoming {
                return false
            }
            
            // Priority 4: Recent finished matches (most recent first)
            if (match1.status == .completed || match1.status == .finished) &&
               (match2.status == .completed || match2.status == .finished) {
                return match1.startTime > match2.startTime
            }
            
            // Default: sort by start time
            return match1.startTime < match2.startTime
        }
    }
    
    // MARK: - Network Error Handling
    
    /// Check network connectivity and handle common API errors
    private func checkNetworkAndRetry<T>(_ operation: () async throws -> T) async throws -> T {
        if !NetworkMonitor.shared.isConnected {
            throw DataError.networkUnavailable
        }
        
        do {
            return try await operation()
        } catch {
            if let apiError = error as? APIError {
                switch apiError {
                case .networkError:
                    throw DataError.networkUnavailable
                case .rateLimited:
                    throw DataError.rateLimited(retryAfter: APIRateLimiter.shared.timeUntilNextCall())
                default:
                    throw error
                }
            }
            throw error
        }
    }
}

// MARK: - Data Modes (Simplified)

enum DataMode {
    case live       // Use real APIs only
    case manual     // For compatibility (not used in this clean version)
    case hybrid     // For compatibility (not used in this clean version)
    
    var description: String {
        switch self {
        case .live: return "Live API Data"
        case .manual: return "Manual Mode (Not Supported)"
        case .hybrid: return "Hybrid Mode (Not Supported)"
        }
    }
}

// MARK: - Data Errors

enum DataError: LocalizedError {
    case fetchFailed(String, underlying: Error)
    case saveFailed(String, underlying: Error)
    case cacheError(String)
    case networkUnavailable
    case rateLimited(retryAfter: TimeInterval)
    case invalidData(String)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let resource, let underlying):
            return "Failed to fetch \(resource): \(underlying.localizedDescription)"
        case .saveFailed(let resource, let underlying):
            return "Failed to save \(resource): \(underlying.localizedDescription)"
        case .cacheError(let message):
            return "Cache error: \(message)"
        case .networkUnavailable:
            return "Network connection is unavailable"
        case .rateLimited(let retryAfter):
            return "Rate limited. Try again in \(Int(retryAfter)) seconds"
        case .invalidData(let message):
            return "Invalid data: \(message)"
        }
    }
}

// MARK: - Cache Expiration

enum CacheExpiration {
    case minutes(Int)
    case hours(Int)
    case days(Int)
    case never
    
    var timeInterval: TimeInterval {
        switch self {
        case .minutes(let m): return TimeInterval(m * 60)
        case .hours(let h): return TimeInterval(h * 60 * 60)
        case .days(let d): return TimeInterval(d * 24 * 60 * 60)
        case .never: return TimeInterval.greatestFiniteMagnitude
        }
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension DataManager {
    
    func debugDataFlow() async {
        print("\nðŸ§ª DataManager Debug Flow Test (Live Mode)")
        print("==========================================")
        
        do {
            // Test 1: Network Status
            print("1ï¸âƒ£ Testing Network Status:")
            print("  Network connected: \(NetworkMonitor.shared.isConnected)")
            print("  Can make API call: \(APIRateLimiter.shared.canMakeCall())")
            
            // Test 2: Cache Status
            print("\n2ï¸âƒ£ Testing Cache:")
            print(cacheManager.getCacheStatus())
            
            // Test 3: Live Match Fetch
            print("\n3ï¸âƒ£ Testing Live Match Fetch:")
            let matches = try await fetchMatches()
            print("  âœ… Fetched \(matches.count) live matches")
            
            if !matches.isEmpty {
                let liveCount = matches.filter { $0.status == .inProgress || $0.status == .halftime }.count
                let upcomingCount = matches.filter { $0.status == .upcoming }.count
                let finishedCount = matches.filter { $0.status == .completed || $0.status == .finished }.count
                
                print("    - Live: \(liveCount)")
                print("    - Upcoming: \(upcomingCount)")
                print("    - Recent finished: \(finishedCount)")
            }
            
        } catch {
            print("âŒ Debug test failed: \(error)")
        }
        
        print("\nâœ… DataManager Debug Test Complete!")
    }
    
    func testNetworkConditions() async {
        print("\nðŸ“¡ Testing Network Conditions")
        print("===============================")
        
        print("  Current network: \(NetworkMonitor.shared.isConnected ? "Connected" : "Disconnected")")
        print("  API rate limit: \(APIRateLimiter.shared.canMakeCall() ? "Available" : "Limited")")
        
        if APIRateLimiter.shared.canMakeCall() {
            let stats = APIRateLimiter.shared.getUsageStats()
            print("  API usage: \(stats.current)/\(stats.max) calls")
        }
    }
}
#endif
