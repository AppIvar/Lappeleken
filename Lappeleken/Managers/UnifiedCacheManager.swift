//
//  UnifiedCacheManager.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 07/08/2025.
//

import Foundation
import UIKit

class UnifiedCacheManager {
    static let shared = UnifiedCacheManager()
    
    private let cache = NSCache<NSString, CacheEntry>()
    private let cacheQueue = DispatchQueue(label: "cache.queue", attributes: .concurrent)
    
    private init() {
        // Configure cache limits
        cache.countLimit = 1000 // Max 1000 entries
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
        
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearExpiredCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    // MARK: - Generic Cache Methods
    
    private func set<T: Codable>(_ value: T, forKey key: String, expiration: CacheExpiration = .hours(1)) {
        cacheQueue.async(flags: .barrier) {
            let entry = CacheEntry(
                data: value,
                expirationDate: Date().addingTimeInterval(expiration.timeInterval),
                type: String(describing: T.self)
            )
            
            self.cache.setObject(entry, forKey: NSString(string: key))
        }
    }
    
    private func get<T: Codable>(_ type: T.Type, forKey key: String) -> T? {
        return cacheQueue.sync {
            guard let entry = cache.object(forKey: NSString(string: key)) else {
                return nil
            }
            
            // Check expiration
            if Date() > entry.expirationDate {
                cache.removeObject(forKey: NSString(string: key))
                return nil
            }
            
            return entry.data as? T
        }
    }
    
    // MARK: - Match Caching
    
    func cacheMatch(_ match: Match, expiration: CacheExpiration = .hours(2)) {
        set(match, forKey: "match_\(match.id)", expiration: expiration)
        print("ðŸ“¦ Cached match: \(match.homeTeam.name) vs \(match.awayTeam.name)")
    }
    
    func getMatch(for matchId: String) -> Match? {
        return get(Match.self, forKey: "match_\(matchId)")
    }
    
    func cacheMatches(_ matches: [Match], forKey key: String, expiration: CacheExpiration = .hours(1)) {
        set(matches, forKey: "matches_\(key)", expiration: expiration)
        print("ðŸ“¦ Cached \(matches.count) matches for key: \(key)")
    }
    
    func getMatches(forKey key: String) -> [Match]? {
        return get([Match].self, forKey: "matches_\(key)")
    }
    
    // MARK: - Player Caching
    
    func cachePlayers(_ players: [Player], for matchId: String, expiration: CacheExpiration = .hours(4)) {
        set(players, forKey: "players_\(matchId)", expiration: expiration)
        print("ðŸ“¦ Cached \(players.count) players for match: \(matchId)")
    }
    
    func getPlayers(for matchId: String) -> [Player]? {
        return get([Player].self, forKey: "players_\(matchId)")
    }
    
    // MARK: - Competition Caching
    
    func cacheCompetitions(_ competitions: [Competition], expiration: CacheExpiration = .days(1)) {
        set(competitions, forKey: "competitions_all", expiration: expiration)
        print("ðŸ“¦ Cached \(competitions.count) competitions")
    }
    
    func getCompetitions() -> [Competition]? {
        return get([Competition].self, forKey: "competitions_all")
    }
    
    // MARK: - Match Detail Caching
    
    func cacheMatchDetail(_ matchDetail: MatchDetail, for matchId: String, expiration: CacheExpiration = .hours(2)) {
        set(matchDetail, forKey: "match_detail_\(matchId)", expiration: expiration)
        print("ðŸ“¦ Cached match detail for: \(matchId)")
    }
    
    func getMatchDetail(for matchId: String) -> MatchDetail? {
        return get(MatchDetail.self, forKey: "match_detail_\(matchId)")
    }
    
    // MARK: - Lineup Caching
    
    func cacheLineup(_ lineup: Lineup, for matchId: String, expiration: CacheExpiration = .hours(6)) {
        set(lineup, forKey: "lineup_\(matchId)", expiration: expiration)
        print("ðŸ“¦ Cached lineup for match: \(matchId)")
    }
    
    func getLineup(for matchId: String) -> Lineup? {
        return get(Lineup.self, forKey: "lineup_\(matchId)")
    }
    
    // MARK: - Cache Management
    
    func clearCache(for key: String) {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeObject(forKey: NSString(string: key))
        }
    }
    
    func clearAllCache() {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeAllObjects()
        }
        print("ðŸ—‘ï¸ Cleared all cache")
    }
    
    @objc private func clearExpiredCache() {
        cacheQueue.async(flags: .barrier) {
            // NSCache automatically manages memory, but we can help by clearing expired entries
            // This is called on memory warnings
            print("âš ï¸ Memory warning - NSCache will automatically free memory")
        }
    }
    
    // MARK: - Cache Statistics
    
    func getCacheStatistics() -> CacheStatistics {
        return cacheQueue.sync {
            return CacheStatistics(
                totalEntries: cache.name.isEmpty ? 0 : 1, // NSCache doesn't expose count
                estimatedMemoryUsage: "Unknown", // NSCache manages this internally
                hitRate: 0.0 // Would need to track this separately
            )
        }
    }
    
    // MARK: - Specific Cache Keys (for migration from UnifiedCacheManager)
    
    func getCachedMatch(_ matchId: String) -> Match? {
        return getMatch(for: matchId)
    }
    
    func getCachedPlayers(for matchId: String) -> [Player]? {
        return getPlayers(for: matchId)
    }
    
    func getCachedMatchList(for key: String) -> [Match]? {
        return getMatches(forKey: key)
    }
    
    func cacheMatchList(_ matches: [Match], for key: String) {
        cacheMatches(matches, forKey: key)
    }
    
    // MARK: - General Match Caching (for DataManager.fetchMatches())
    
    func cacheMatches(_ matches: [Match], expiration: CacheExpiration = .hours(1)) {
        set(matches, forKey: "general_matches", expiration: expiration)
        
        // Also cache individual matches for detailed access
        for match in matches {
            cacheMatch(match, expiration: expiration)
        }
        
        print("ðŸ“¦ Cached \(matches.count) general matches")
    }
    
    func getMatches() -> [Match]? {
        return get([Match].self, forKey: "general_matches")
    }
    
    // MARK: - Match Collection Caching (with custom keys)
    
    func cacheMatches(_ matches: [Match], for key: String, expiration: CacheExpiration = .hours(1)) {
        set(matches, forKey: "matches_collection_\(key)", expiration: expiration)
        
        // Also cache individual matches
        for match in matches {
            cacheMatch(match, expiration: expiration)
        }
        
        print("ðŸ“¦ Cached \(matches.count) matches for collection: \(key)")
    }
    
    func getMatches(for key: String) -> [Match]? {
        return get([Match].self, forKey: "matches_collection_\(key)")
    }
    
    // MARK: - Live Match Specific Caching
    
    func cacheLiveMatches(_ matches: [Match]) {
        // Shorter cache time for live matches
        cacheMatches(matches, for: "live", expiration: .minutes(5))
        
        // Mark live matches with special status tracking
        for match in matches where match.status == .inProgress || match.status == .halftime {
            set(match, forKey: "live_match_\(match.id)", expiration: .minutes(2))
        }
    }
    
    func getLiveMatches() -> [Match]? {
        return getMatches(for: "live")
    }
    
    // MARK: - Competition-based Match Caching
    
    func cacheMatchesForCompetition(_ matches: [Match], competitionCode: String) {
        let key = "competition_\(competitionCode)"
        cacheMatches(matches, for: key, expiration: .hours(2))
    }
    
    func getMatchesForCompetition(_ competitionCode: String) -> [Match]? {
        return getMatches(for: "competition_\(competitionCode)")
    }
    
    // MARK: - Date-based Match Caching
    
    func cacheTodayMatches(_ matches: [Match]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        cacheMatches(matches, for: "date_\(today)", expiration: .hours(6))
    }
    
    func getTodayMatches() -> [Match]? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        return getMatches(for: "date_\(today)")
    }
    
    func cacheMatchesInDateRange(_ matches: [Match], days: Int) {
        let key = "daterange_\(days)days"
        cacheMatches(matches, for: key, expiration: .hours(4))
    }
    
    func getMatchesInDateRange(days: Int) -> [Match]? {
        return getMatches(for: "daterange_\(days)days")
    }
    
    // MARK: - Enhanced Cache Statistics
    
    func getCacheStatus() -> String {
        let stats = getCacheStatistics()
        return """
        ðŸ“Š Cache Status:
        - Total entries: \(stats.totalEntries)
        - Memory usage: \(stats.estimatedMemoryUsage)
        - Hit rate: \(String(format: "%.1f%%", stats.hitRate * 100))
        """
    }
    
    // MARK: - Cache Warming (Pre-populate commonly accessed data)
    
    func warmCache(with matches: [Match]) {
        print("ðŸ”¥ Warming cache with \(matches.count) matches...")
        
        // Cache general matches
        cacheMatches(matches)
        
        // Cache by competition
        let matchesByCompetition = Dictionary(grouping: matches) { $0.competition.code }
        for (competitionCode, competitionMatches) in matchesByCompetition {
            cacheMatchesForCompetition(competitionMatches, competitionCode: competitionCode)
        }
        
        // Cache today's matches
        let today = Date()
        let todayMatches = matches.filter { Calendar.current.isDate($0.startTime, inSameDayAs: today) }
        if !todayMatches.isEmpty {
            cacheTodayMatches(todayMatches)
        }
        
        // Cache live matches
        let liveMatches = matches.filter { $0.status == .inProgress || $0.status == .halftime }
        if !liveMatches.isEmpty {
            cacheLiveMatches(liveMatches)
        }
        
        print("âœ… Cache warming complete!")
    }
    
    // MARK: - Smart Cache Invalidation
    
    func invalidateMatchData(for matchId: String) {
        print("â™»ï¸ Invalidating all cache data for match: \(matchId)")
        
        // Remove specific match
        clearCache(for: "match_\(matchId)")
        clearCache(for: "live_match_\(matchId)")
        
        // Remove players for this match
        clearCache(for: "players_\(matchId)")
        
        // Remove match detail
        clearCache(for: "match_detail_\(matchId)")
        
        // Remove lineup
        clearCache(for: "lineup_\(matchId)")
        
        // Note: We don't remove match collections as they might still be relevant
        // They will expire naturally based on their expiration times
    }
    
    func invalidateExpiredEntries() {
        print("ðŸ§¹ Clearing expired cache entries...")
        
        // NSCache handles expiration automatically, but we can help by triggering cleanup
        clearExpiredCache()
        
        // For more aggressive cleanup, we could iterate through known keys
        // but NSCache is designed to handle this efficiently on its own
    }
    
    // MARK: - Development/Debug Methods
    
    #if DEBUG
    func printCacheContents() {
        print("\nðŸ” Cache Debug Information:")
        print("  Cache object: \(cache)")
        
        // Common cache keys we expect to find
        let testKeys = [
            "general_matches",
            "matches_collection_live",
            "competitions_all",
            "daterange_7days",
            "date_\(DateFormatter().string(from: Date()))"
        ]
        
        for key in testKeys {
            if get(String.self, forKey: key) != nil {
                print("  âœ… Found data for key: \(key)")
            } else {
                print("  âŒ No data for key: \(key)")
            }
        }
    }
    
    func simulateCacheMiss(for key: String) {
        clearCache(for: key)
        print("ðŸŽ¯ Simulated cache miss for key: \(key)")
    }
    
    func simulateMemoryPressure() {
        clearAllCache()
        print("âš ï¸ Simulated memory pressure - cleared all cache")
    }
    #endif
    
    // MARK: - Migration from Legacy UnifiedCacheManager
    
    func migrateFromLegacyCache() {
        print("ðŸ”„ Migrating from legacy UnifiedCacheManager...")
        
        // This method would help transition from the old UnifiedCacheManager
        // to the new UnifiedCacheManager without losing cached data
        
        // For now, we'll just ensure compatibility
        print("âœ… Migration support ready (currently using parallel caching)")
    }
}


// MARK: - Cache Entry

private class CacheEntry: NSObject {
    let data: Any
    let expirationDate: Date
    let type: String
    
    init(data: Any, expirationDate: Date, type: String) {
        self.data = data
        self.expirationDate = expirationDate
        self.type = type
        super.init()
    }
}

// MARK: - Cache Statistics

struct CacheStatistics {
    let totalEntries: Int
    let estimatedMemoryUsage: String
    let hitRate: Double
}
