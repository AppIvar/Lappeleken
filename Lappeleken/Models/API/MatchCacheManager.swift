//
//  MatchCacheManager.swift
//  Lucky Football Slip
//
//  Clean version without problematic event caching
//

import Foundation

class MatchCacheManager {
    static let shared = MatchCacheManager()
    
    // MARK: - Cache Structures
    
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
            case .finished:
                cacheLifetime = 3600
            case .postponed:
                cacheLifetime = 3600
            case .cancelled:
                cacheLifetime = 3600
            case .paused:
                cacheLifetime = 300
            case .suspended:
                cacheLifetime = 300
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
    
    // MARK: - Cache Storage
    
    private var matchCache: [String: CachedMatch] = [:]
    private var matchListCache: [String: CachedMatchList] = [:]
    private var playerCache: [String: (players: [Player], timestamp: Date)] = [:]
    
    private let queue = DispatchQueue(label: "match.cache", qos: .utility, attributes: .concurrent)
    
    private init() {}
    
    // MARK: - Match Caching Methods
    
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
    
    func cachePlayers(_ players: [Player], for matchId: String) {
        queue.async(flags: .barrier) {
            self.playerCache[matchId] = (players, Date())
        }
    }
    
    func getCachedPlayers(for matchId: String) -> [Player]? {
        return queue.sync {
            guard let cached = playerCache[matchId] else { return nil }
            
            let cacheAge = Date().timeIntervalSince(cached.timestamp)
            if cacheAge > 3600 { // 1 hour
                playerCache.removeValue(forKey: matchId)
                return nil
            }
            
            return cached.players
        }
    }
    
    // MARK: - Cache Management
    
    func clearAllCache() {
        queue.async(flags: .barrier) {
            self.matchCache.removeAll()
            self.matchListCache.removeAll()
            self.playerCache.removeAll()
            print("🧹 All caches cleared")
        }
    }
    
    func optimizeCache() {
        queue.async(flags: .barrier) {
            let now = Date()
            
            // Remove expired caches
            self.matchCache = self.matchCache.filter { !$1.isExpired }
            self.matchListCache = self.matchListCache.filter { !$1.isExpired }
            
            // Clean old player caches
            self.playerCache = self.playerCache.filter { (_, cached) in
                return now.timeIntervalSince(cached.timestamp) < 3600 // 1 hour
            }
            
            print("🔧 Optimized caches")
        }
    }
    
    // MARK: - Cache Statistics
    
    func getCacheStats() -> (matches: Int, matchLists: Int, players: Int) {
        return queue.sync {
            return (matchCache.count, matchListCache.count, playerCache.count)
        }
    }
    
    func printCacheStatus() {
        let stats = getCacheStats()
        print("""
        📊 Cache Status:
        - Matches: \(stats.matches)
        - Match Lists: \(stats.matchLists)
        - Players: \(stats.players)
        """)
    }
}
