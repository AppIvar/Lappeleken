//
//  CacheMaintenanceManager.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 03/06/2025.
//

import Foundation

class CacheMaintenanceManager {
    static let shared = CacheMaintenanceManager()
    private var cleanupTimer: Timer?
    
    private init() {}
    
    func startPeriodicCleanup() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            MatchCacheManager.shared.optimizeCache()
            
            let stats = MatchCacheManager.shared.getCacheStats()
            print("🧹 Cache cleanup: \(stats.matches) matches, \(stats.matchLists) lists, \(stats.players) players")
        }
    }
    
    func stopPeriodicCleanup() {
        cleanupTimer?.invalidate()
        cleanupTimer = nil
    }
}
