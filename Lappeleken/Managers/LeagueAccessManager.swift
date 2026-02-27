//
//  LeagueAccessManager.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 04/02/2026.
//

import Foundation

@MainActor
class LeagueAccessManager: ObservableObject {
    static let shared = LeagueAccessManager()
    
    // MARK: - League Categories
    
    enum LeagueCategory {
        case free           // Unlimited with ads, 1 match/day
        case bigLeague      // 3 free matches, then subscription
        case championsLeague // Subscription only
        case worldCup       // One-time purchase
    }
    
    // MARK: - League Definitions
    
    static let freeLeagues: Set<String> = ["DED", "PPL", "ELC", "EL"]  // Eredivisie, Primeira, Championship, Eliteserien
    static let bigLeagues: Set<String> = ["PL", "PD", "BL1", "SA"]     // Premier League, La Liga, Bundesliga, Serie A
    static let championsLeague: Set<String> = ["CL"]
    static let worldCup: Set<String> = ["WC"]
    
    // Big league to product mapping
    static let leagueToProductID: [String: AppPurchaseManager.ProductID] = [
        "PL": .leaguePL,
        "PD": .leagueLaLiga,
        "BL1": .leagueBundesliga,
        "SA": .leagueSerieA
    ]
    
    // MARK: - Free Match Tracking (3 per big league)
    
    private let freeMatchesPerBigLeague = 3
    
    func getFreeMatchesUsed(for leagueCode: String) -> Int {
        UserDefaults.standard.integer(forKey: "freeMatchesUsed_\(leagueCode)")
    }
    
    func getRemainingFreeMatches(for leagueCode: String) -> Int {
        guard Self.bigLeagues.contains(leagueCode) else { return Int.max }
        return max(0, freeMatchesPerBigLeague - getFreeMatchesUsed(for: leagueCode))
    }
    
    func useFreeMatch(for leagueCode: String) {
        guard Self.bigLeagues.contains(leagueCode) else { return }
        let current = getFreeMatchesUsed(for: leagueCode)
        UserDefaults.standard.set(current + 1, forKey: "freeMatchesUsed_\(leagueCode)")
        objectWillChange.send()
        print("📊 Used free match for \(leagueCode). Remaining: \(getRemainingFreeMatches(for: leagueCode))")
    }
    
    // MARK: - League Category Detection
    
    func getCategory(for leagueCode: String) -> LeagueCategory {
        if Self.freeLeagues.contains(leagueCode) {
            return .free
        } else if Self.bigLeagues.contains(leagueCode) {
            return .bigLeague
        } else if Self.championsLeague.contains(leagueCode) {
            return .championsLeague
        } else if Self.worldCup.contains(leagueCode) {
            return .worldCup
        }
        // Default unknown leagues to free
        return .free
    }
    
    // MARK: - Access Control
    
    func canAccessLeague(_ leagueCode: String) -> Bool {
        // Feature flag bypass for testing
        if !AppConfig.PurchaseConfig.purchasesEnabled {
            return true
        }
        
        // Premium users have access to everything
        if AppPurchaseManager.shared.hasPremium {
            return true
        }
        
        let category = getCategory(for: leagueCode)
        
        switch category {
        case .free:
            return true
            
        case .bigLeague:
            // Check if user has this specific league subscription
            if let productID = Self.leagueToProductID[leagueCode],
               AppPurchaseManager.shared.hasAccess(to: productID) {
                return true
            }
            // Otherwise check free matches remaining
            return getRemainingFreeMatches(for: leagueCode) > 0
            
        case .championsLeague:
            return AppPurchaseManager.shared.hasAccess(to: .leagueCL)
            
        case .worldCup:
            return AppPurchaseManager.shared.hasAccess(to: .worldCup2026)
        }
    }
    
    func getAccessStatus(for leagueCode: String) -> LeagueAccessStatus {
        let category = getCategory(for: leagueCode)
        
        // Feature flag bypass
        if !AppConfig.PurchaseConfig.purchasesEnabled {
            return .unlocked(reason: .testingMode)
        }
        
        // Premium always unlocked
        if AppPurchaseManager.shared.hasPremium {
            return .unlocked(reason: .premium)
        }
        
        switch category {
        case .free:
            return .unlocked(reason: .freeLeague)
            
        case .bigLeague:
            if let productID = Self.leagueToProductID[leagueCode],
               AppPurchaseManager.shared.hasAccess(to: productID) {
                return .unlocked(reason: .leagueSubscription)
            }
            let remaining = getRemainingFreeMatches(for: leagueCode)
            if remaining > 0 {
                return .limitedFree(remaining: remaining)
            }
            return .locked(requiredPurchase: Self.leagueToProductID[leagueCode] ?? .premium)
            
        case .championsLeague:
            if AppPurchaseManager.shared.hasAccess(to: .leagueCL) {
                return .unlocked(reason: .leagueSubscription)
            }
            return .locked(requiredPurchase: .leagueCL)
            
        case .worldCup:
            if AppPurchaseManager.shared.hasAccess(to: .worldCup2026) {
                return .unlocked(reason: .worldCupPurchase)
            }
            return .locked(requiredPurchase: .worldCup2026)
        }
    }
    
    // MARK: - Display Helpers
    
    func getLeagueDisplayName(for code: String) -> String {
        switch code {
        case "PL": return "Premier League"
        case "PD": return "La Liga"
        case "BL1": return "Bundesliga"
        case "SA": return "Serie A"
        case "CL": return "Champions League"
        case "WC": return "World Cup"
        case "DED": return "Eredivisie"
        case "PPL": return "Primeira Liga"
        case "ELC": return "Championship"
        case "EL": return "Eliteserien"
        default: return code
        }
    }
    
    func getCategoryDisplayName(_ category: LeagueCategory) -> String {
        switch category {
        case .free: return "Free League"
        case .bigLeague: return "Big League"
        case .championsLeague: return "Champions League"
        case .worldCup: return "World Cup"
        }
    }
    
    // MARK: - Debug/Testing
    
    #if DEBUG
    func resetAllFreeMatches() {
        for league in Self.bigLeagues {
            UserDefaults.standard.removeObject(forKey: "freeMatchesUsed_\(league)")
        }
        objectWillChange.send()
        print("🧪 Reset all free match counts")
    }
    
    func setFreeMatchesUsed(for leagueCode: String, count: Int) {
        UserDefaults.standard.set(count, forKey: "freeMatchesUsed_\(leagueCode)")
        objectWillChange.send()
        print("🧪 Set \(leagueCode) free matches used to \(count)")
    }
    
    func simulateAllFreeMatchesUsed() {
        for league in Self.bigLeagues {
            UserDefaults.standard.set(freeMatchesPerBigLeague, forKey: "freeMatchesUsed_\(league)")
        }
        objectWillChange.send()
        print("🧪 Simulated all free matches used for big leagues")
    }
    
    func getDebugStatus() -> [String: Any] {
        var status: [String: Any] = [:]
        
        status["purchasesEnabled"] = AppConfig.PurchaseConfig.purchasesEnabled
        status["hasPremium"] = AppPurchaseManager.shared.hasPremium
        status["hasRemovedAds"] = AppPurchaseManager.shared.hasRemovedAds
        status["hasWorldCup2026"] = AppPurchaseManager.shared.hasWorldCup2026
        status["isAdFree"] = AppPurchaseManager.shared.isAdFree
        
        var leagueStatus: [String: String] = [:]
        for league in Self.bigLeagues {
            let remaining = getRemainingFreeMatches(for: league)
            let used = getFreeMatchesUsed(for: league)
            leagueStatus[league] = "used: \(used), remaining: \(remaining)"
        }
        status["bigLeagues"] = leagueStatus
        
        var subscriptions: [String] = []
        for productID in AppPurchaseManager.ProductID.allCases where productID.isLeagueSubscription {
            if AppPurchaseManager.shared.hasAccess(to: productID) {
                subscriptions.append(productID.displayName)
            }
        }
        status["activeLeagueSubscriptions"] = subscriptions
        
        return status
    }
    
    func printDebugStatus() {
        print("========== LEAGUE ACCESS DEBUG STATUS ==========")
        let status = getDebugStatus()
        for (key, value) in status.sorted(by: { $0.key < $1.key }) {
            print("  \(key): \(value)")
        }
        print("=================================================")
    }
    #endif
}

// MARK: - Access Status Enum

enum LeagueAccessStatus {
    case unlocked(reason: UnlockReason)
    case limitedFree(remaining: Int)
    case locked(requiredPurchase: AppPurchaseManager.ProductID)
    
    enum UnlockReason {
        case premium
        case leagueSubscription
        case worldCupPurchase
        case freeLeague
        case testingMode
        case freeMatch
    }
    
    var isAccessible: Bool {
        switch self {
        case .unlocked, .limitedFree:
            return true
        case .locked:
            return false
        }
    }
    
    var displayMessage: String {
        switch self {
        case .unlocked(let reason):
            switch reason {
            case .premium: return "Premium Access"
            case .leagueSubscription: return "Subscribed"
            case .worldCupPurchase: return "Purchased"
            case .freeLeague: return "Free"
            case .testingMode: return "Testing Mode"
            case .freeMatch: return "Free"
            }
        case .limitedFree(let remaining):
            return "\(remaining) free match\(remaining == 1 ? "" : "es") left"
        case .locked(let product):
            return "Unlock with \(product.displayName)"
        }
    }
}
