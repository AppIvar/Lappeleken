//
//  MatcCacheManager.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 03/06/2025.
//

import Foundation

class MatchCacheManager {
    static let shared = MatchCacheManager()
    
    private struct CachedMatch {
        let data: Match
        let timestamp: Date
        let status: MatchStatus
        
        var isExpired: Bool {
            let now = Date()
            let cacheLifetime: TimeInterval
            
            switch status {
            case .completed:
                cacheLifetime = 3600 // 1 hour for completed matches
            case .inProgress, .halftime:
                cacheLifetime = 60   // 1 minute for live matches
            case .upcoming:
                cacheLifetime = 900  // 15 minutes for upcoming
            case .unknown:
                cacheLifetime = 300  // 5 minutes for unknown
            }
            
            return now.timeIntervalSince(timestamp) > cacheLifetime
        }
    }
    
    private struct CachedMatchList {
        let matches: [Match]
        let timestamp: Date
        let query: String
        
        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 300 // 5 minutes for match lists
        }
    }
    
    private var matchCache: [String: CachedMatch] = [:]
    private var matchListCache: [String: CachedMatchList] = [:]
    private var playerCache: [String: (players: [Player], timestamp: Date)] = [:]
    
    private let queue = DispatchQueue(label: "match.cache", qos: .utility, attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Match Caching
    
    func cacheMatch(_ match: Match) {
        queue.async(flags: .barrier) {
            self.matchCache[match.id] = CachedMatch(
                data: match,
                timestamp: Date(),
                status: match.status
            )
        }
    }
    
    func getCachedMatch(_ matchId: String) -> Match? {
        return queue.sync {
            guard let cached = matchCache[matchId], !cached.isExpired else {
                matchCache.removeValue(forKey: matchId)
                return nil
            }
            return cached.data
        }
    }
    
    // MARK: - Match List Caching
    
    func cacheMatchList(_ matches: [Match], for query: String) {
        queue.async(flags: .barrier) {
            self.matchListCache[query] = CachedMatchList(
                matches: matches,
                timestamp: Date(),
                query: query
            )
            
            // Also cache individual matches
            for match in matches {
                self.matchCache[match.id] = CachedMatch(
                    data: match,
                    timestamp: Date(),
                    status: match.status
                )
            }
        }
    }
    
    func getCachedMatchList(for query: String) -> [Match]? {
        return queue.sync {
            guard let cached = matchListCache[query], !cached.isExpired else {
                matchListCache.removeValue(forKey: query)
                return nil
            }
            return cached.matches
        }
    }
    
    // MARK: - Player Caching
    
    func cachePlayers(_ players: [Player], for matchId: String) {
        queue.async(flags: .barrier) {
            self.playerCache[matchId] = (players, Date())
        }
    }
    
    func getCachedPlayers(for matchId: String) -> [Player]? {
        return queue.sync {
            guard let cached = playerCache[matchId] else { return nil }
            
            // Players cache for 30 minutes (lineups don't change often)
            let cacheLifetime: TimeInterval = 1800
            if Date().timeIntervalSince(cached.timestamp) > cacheLifetime {
                playerCache.removeValue(forKey: matchId)
                return nil
            }
            
            return cached.players
        }
    }
    
    // MARK: - Cache Management
    
    func clearExpiredCache() {
        queue.async(flags: .barrier) {
            // Clear expired matches
            self.matchCache = self.matchCache.filter { !$1.isExpired }
            
            // Clear expired match lists
            self.matchListCache = self.matchListCache.filter { !$1.isExpired }
            
            // Clear expired players
            let now = Date()
            self.playerCache = self.playerCache.filter { _, cached in
                now.timeIntervalSince(cached.timestamp) <= 1800 // 30 minutes
            }
        }
    }
    
    func clearAllCache() {
        queue.async(flags: .barrier) {
            self.matchCache.removeAll()
            self.matchListCache.removeAll()
            self.playerCache.removeAll()
        }
    }
    
    // MARK: - Debug Info
    
    func getCacheStats() -> (matches: Int, lists: Int, players: Int) {
        return queue.sync {
            return (matchCache.count, matchListCache.count, playerCache.count)
        }
    }
}

// Enhanced FootballDataMatchService with caching
extension FootballDataMatchService {
    
    func fetchLiveMatchesWithCache(competitionCode: String? = nil) async throws -> [Match] {
        let cacheKey = "live_\(competitionCode ?? "all")"
        
        // Check cache first
        if let cachedMatches = MatchCacheManager.shared.getCachedMatchList(for: cacheKey) {
            print("📦 Using cached live matches (\(cachedMatches.count) matches)")
            return cachedMatches
        }
        
        print("🌐 Fetching fresh live matches from API")
        let matches = try await fetchLiveMatches(competitionCode: competitionCode)
        
        // Cache the results
        MatchCacheManager.shared.cacheMatchList(matches, for: cacheKey)
        
        return matches
    }
    
    func fetchMatchDetailsWithCache(matchId: String) async throws -> MatchDetail {
        // Check cache first
        if let cachedMatch = MatchCacheManager.shared.getCachedMatch(matchId) {
            print("📦 Using cached match details for \(matchId)")
            // Convert to MatchDetail - you might need to adjust this based on your models
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
        let matchDetail = try await fetchMatchDetails(matchId: matchId)
        
        // Cache the match
        MatchCacheManager.shared.cacheMatch(matchDetail.match)
        
        return matchDetail
    }
    
    func fetchMatchPlayersWithCache(matchId: String) async throws -> [Player] {
        // Check cache first
        if let cachedPlayers = MatchCacheManager.shared.getCachedPlayers(for: matchId) {
            print("📦 Using cached players for match \(matchId) (\(cachedPlayers.count) players)")
            return cachedPlayers
        }
        
        print("🌐 Fetching fresh players from API for match \(matchId)")
        let players = try await fetchMatchPlayers(matchId: matchId)
        
        // Cache the players
        MatchCacheManager.shared.cachePlayers(players, for: matchId)
        
        return players
    }
}
