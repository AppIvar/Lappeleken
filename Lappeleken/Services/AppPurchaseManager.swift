//
//  AppPurchaseManager.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 16/05/2025.
//

import Foundation
import StoreKit

@MainActor
class AppPurchaseManager: ObservableObject {
    static let shared = AppPurchaseManager()
    
    @Published var currentTier: PurchaseTier = .free
    @Published var purchasedCompetitions: Set<String> = []
    @Published var ownedCompetitions: Set<ProductID> = []
    @Published var isLoading = false
    @Published var availableProducts: [Product] = []
    @Published var purchaseError: String?
    
    enum PurchaseTier: String, CaseIterable {
        case free = "free"
        case premium = "premium"
        
        var displayName: String {
            switch self {
            case .free: return "Free"
            case .premium: return "Premium"
            }
        }
        
        var features: [String] {
            switch self {
            case .free:
                return [
                    "Manual mode games",
                    "3 free live matches",
                    "Basic leagues (PL, BL1, SA, PD)",
                    "Watch ads for extra matches"
                ]
            case .premium:
                return [
                    "Unlimited live matches",
                    "All basic leagues",
                    "Multiple match tracking",
                    "No ads",
                    "Premium support",
                    "Export game summaries"
                ]
            }
        }
    }

    enum ProductID: String, CaseIterable {
        case premium = "HovlandGames.Lucky_Football_Slip.premium"
        case championsLeague = "HovlandGames.Lucky_Football_Slip.champions_league"
        case worldCup = "HovlandGames.Lucky_Football_Slip.world_cup"
        case euroChampionship = "HovlandGames.Lucky_Football_Slip.euro_championship"
        case nationsCup = "HovlandGames.Lucky_Football_Slip.nations_cup"
        
        var displayName: String {
            switch self {
            case .premium: return "Premium Upgrade"
            case .championsLeague: return "Champions League"
            case .worldCup: return "World Cup 2026"
            case .euroChampionship: return "Euro 2028"
            case .nationsCup: return "Nations Cup"
            }
        }
        
        var description: String {
            switch self {
            case .premium: return "Unlock unlimited live matches and remove ads"
            case .championsLeague: return "Follow Champions League matches live"
            case .worldCup: return "Follow World Cup 2026 matches live"
            case .euroChampionship: return "Follow Euro 2028 matches live"
            case .nationsCup: return "Follow Nations Cup matches live"
            }
        }
        
        // Control availability of future tournaments
        var isCurrentlyAvailable: Bool {
            switch self {
            case .premium, .championsLeague:
                return true // Always available
            case .worldCup:
                return AppPurchaseManager.isWorldCupSeason()
            case .euroChampionship:
                return AppPurchaseManager.isEuroChampionshipSeason()
            case .nationsCup:
                return AppPurchaseManager.isNationsCupSeason()
            }
        }
        
        var availabilityMessage: String? {
            if !isCurrentlyAvailable {
                switch self {
                case .worldCup:
                    return "Available during World Cup 2026"
                case .euroChampionship:
                    return "Available during Euro 2028"
                case .nationsCup:
                    return "Available during Nations Cup season"
                default:
                    return nil
                }
            }
            return nil
        }
    }
    
    private var transactionListener: Task<Void, Error>?
    
    init() {
        transactionListener = listenForTransactions()
        loadPurchaseState()
        Task {
            await loadProducts()
            await updateEntitlements()
        }
    }
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Tournament Availability Logic
    
    nonisolated static func isWorldCupSeason() -> Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "debugWorldCupAvailable")
        #else
        let calendar = Calendar.current
        let now = Date()
        
        // World Cup 2026: June 11 - July 19, 2026
        let worldCupStart = calendar.date(from: DateComponents(year: 2026, month: 6, day: 1))!
        let worldCupEnd = calendar.date(from: DateComponents(year: 2026, month: 8, day: 1))!
        
        return now >= worldCupStart && now <= worldCupEnd
        #endif
    }

    nonisolated static func isEuroChampionshipSeason() -> Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "debugEuroAvailable")
        #else
        let calendar = Calendar.current
        let now = Date()
        
        // Euro 2028: June-July 2028 (exact dates TBD)
        let euroStart = calendar.date(from: DateComponents(year: 2028, month: 6, day: 1))!
        let euroEnd = calendar.date(from: DateComponents(year: 2028, month: 8, day: 1))!
        
        return now >= euroStart && now <= euroEnd
        #endif
    }

    nonisolated static func isNationsCupSeason() -> Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "debugNationsCupAvailable")
        #else
        // Nations League runs every 2 years, next one is 2024-2025
        let calendar = Calendar.current
        let now = Date()
        let year = calendar.component(.year, from: now)
        
        // Available during Nations League years (even years + following year)
        return year % 2 == 0 || (year - 1) % 2 == 0
        #endif
    }

    // MARK: - Debug Methods for Testing Tournament Availability

    func enableWorldCupForTesting(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "debugWorldCupAvailable")
        objectWillChange.send()
        print("🌍 World Cup availability set to: \(enabled)")
    }
    
    func enableEuroForTesting(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "debugEuroAvailable")
        objectWillChange.send()
        print("🇪🇺 Euro Championship availability set to: \(enabled)")
    }
    
    func enableNationsCupForTesting(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: "debugNationsCupAvailable")
        objectWillChange.send()
        print("🏆 Nations Cup availability set to: \(enabled)")
    }
    
    // Get only currently available products
    var availableCompetitionProducts: [ProductID] {
        return ProductID.allCases.filter { $0.isCurrentlyAvailable }
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        print("🛒 Loading products...")
        print("🔍 Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        print("🔍 Environment: \(AppConfig.environment)")
        
        isLoading = true
        purchaseError = nil
        
        do {
            let productIds = ProductID.allCases.map { $0.rawValue }
            print("🔍 Requested Product IDs:")
            for (index, id) in productIds.enumerated() {
                print("  \(index + 1). \(id)")
            }
            
            // Add more specific error handling
            let products = try await Product.products(for: productIds)
            
            print("🔍 StoreKit Response:")
            print("  - Products returned: \(products.count)")
            print("  - Expected products: \(productIds.count)")
            
            if products.isEmpty {
                print("⚠️ No products returned from StoreKit")
                print("🔍 Debugging checklist:")
                print("  - App Store Connect product status: Ready to Submit ✓")
                print("  - Bundle ID matches: \(Bundle.main.bundleIdentifier == "HovlandGames.Lucky-Football-Slip" ? "✓" : "❌")")
                print("  - Product ID format: \(productIds.first?.hasPrefix("HovlandGames.Lucky_Football_Slip.") == true ? "✓" : "❌")")
                print("  - Signed in to App Store: Check device settings")
                print("  - Network connection: \(checkNetworkConnection() ? "✓" : "❌")")
            } else {
                availableProducts = products
                print("✅ Products loaded successfully:")
                for product in products {
                    print("  • \(product.id): \(product.displayName) - \(product.displayPrice)")
                }
            }
        } catch {
            print("❌ Failed to load products: \(error)")
            
            // More specific error handling
            if let storeKitError = error as? StoreKitError {
                switch storeKitError {
                case .notAvailableInStorefront:
                    purchaseError = "Products not available in your region"
                case .networkError:
                    purchaseError = "Network error. Please check your connection and try again."
                case .systemError:
                    purchaseError = "System error. Please restart the app and try again."
                default:
                    purchaseError = "Store error: \(storeKitError.localizedDescription)"
                }
            } else {
                purchaseError = "Failed to load products: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }

    // Add this helper method to check network
    private func checkNetworkConnection() -> Bool {
        // Simple network check
        guard let url = URL(string: "https://www.apple.com") else { return false }
        
        var result = false
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: url) { _, response, _ in
            result = (response as? HTTPURLResponse)?.statusCode == 200
            semaphore.signal()
        }
        
        task.resume()
        semaphore.wait()
        
        return result
    }

    // Add this method to test specific product loading
    func testSpecificProduct() async {
        print("🧪 Testing specific premium product...")
        
        do {
            let products = try await Product.products(for: ["HovlandGames.Lucky_Football_Slip.premium"])
            
            if let product = products.first {
                print("✅ Premium product found:")
                print("  - ID: \(product.id)")
                print("  - Display Name: \(product.displayName)")
                print("  - Description: \(product.description)")
                print("  - Price: \(product.displayPrice)")
                print("  - Type: \(product.type)")
            } else {
                print("❌ Premium product not found")
            }
        } catch {
            print("❌ Error testing premium product: \(error)")
        }
    }
    
    func debugProductLoading() async {
        print("🔍 Debug: Attempting to load products...")
        print("🔍 Product IDs being requested:")
        
        let productIds = ProductID.allCases.map { $0.rawValue }
        for (index, id) in productIds.enumerated() {
            print("  \(index + 1). \(id)")
        }
        
        do {
            let products = try await Product.products(for: productIds)
            print("🔍 Products returned from App Store: \(products.count)")
            
            if products.isEmpty {
                print("⚠️ No products returned - Check:")
                print("  • Are products created in App Store Connect?")
                print("  • Are they in 'Ready to Submit' or 'Approved' status?")
                print("  • Is your app's bundle ID correct?")
                print("  • Are you using the correct Apple ID/team?")
            } else {
                print("✅ Products found:")
                for product in products {
                    print("  • \(product.id): \(product.displayName)")
                }
            }
        } catch {
            print("❌ Error loading products: \(error)")
            if let storeKitError = error as? StoreKitError {
                print("StoreKit Error: \(storeKitError.localizedDescription)")
            }
        }
    }
    
    // MARK: - Purchase Methods
    
    func purchase(_ productID: ProductID) async throws -> Bool {
        print("🛒 Attempting to purchase: \(productID.displayName)")
        
        #if DEBUG
        // For testing without actual purchases
        print("⚠️ Debug mode - simulating purchase")
        await simulatePurchase(productID)
        return true
        #endif
        
        guard let product = availableProducts.first(where: { $0.id == productID.rawValue }) else {
            throw PurchaseError.productNotFound
        }
        
        isLoading = true
        purchaseError = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchaseState(for: transaction)
                await transaction.finish()
                isLoading = false
                return true
                
            case .userCancelled:
                isLoading = false
                return false
                
            case .pending:
                isLoading = false
                return false
                
            @unknown default:
                isLoading = false
                return false
            }
        } catch {
            isLoading = false
            purchaseError = error.localizedDescription
            throw error
        }
    }
    
    // Debug helper for testing
    private func simulatePurchase(_ productID: ProductID) async {
        isLoading = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Update purchase state
        switch productID {
        case .premium:
            currentTier = .premium
        case .championsLeague:
            purchasedCompetitions.insert(productID.rawValue)
            ownedCompetitions.insert(.championsLeague)
        case .worldCup:
            purchasedCompetitions.insert(productID.rawValue)
            ownedCompetitions.insert(.worldCup)
        case .euroChampionship:
            purchasedCompetitions.insert(productID.rawValue)
            ownedCompetitions.insert(.euroChampionship)
        case .nationsCup:
            purchasedCompetitions.insert(productID.rawValue)
            ownedCompetitions.insert(.nationsCup)
        }
        
        savePurchaseState()
        isLoading = false
        
        print("✅ Simulated purchase completed: \(productID.displayName)")
    }
    
    func debugPurchaseState() {
        print("🔍 Debug Purchase State:")
        print("  - Current Tier: \(currentTier.rawValue)")
        print("  - Available Products: \(availableProducts.count)")
        
        for product in availableProducts {
            print("    • \(product.id): \(product.displayName) - \(product.displayPrice)")
        }
        
        print("  - Purchased Competitions: \(purchasedCompetitions)")
        print("  - Owned Competitions: \(ownedCompetitions)")
        
        // Check if premium product exists
        if let premiumProduct = availableProducts.first(where: { $0.id == ProductID.premium.rawValue }) {
            print("  ✅ Premium product found: \(premiumProduct.displayName)")
        } else {
            print("  ❌ Premium product NOT found")
            print("  Looking for product ID: \(ProductID.premium.rawValue)")
        }
    }

    // Also add this method to test the purchase flow
    func testPremiumPurchase() async {
        print("🧪 Testing premium purchase flow...")
        
        guard let premiumProduct = availableProducts.first(where: { $0.id == ProductID.premium.rawValue }) else {
            print("❌ Cannot test - premium product not found")
            return
        }
        
        print("✅ Found premium product, attempting purchase...")
        
        do {
            let success = try await purchase(.premium)
            print("Purchase result: \(success)")
        } catch {
            print("❌ Purchase failed: \(error)")
        }
    }
    
    
    
    // MARK: - New Methods Required by UI
    
    func purchaseProduct(_ productId: String) async throws {
        guard let productID = ProductID(rawValue: productId) else {
            throw PurchaseError.productNotFound
        }
        
        let success = try await purchase(productID)
        if !success {
            throw PurchaseError.userCancelled
        }
    }
    
    func hasAccess(to productID: ProductID) -> Bool {
        switch productID {
        case .premium:
            return currentTier == .premium
        case .championsLeague:
            return currentTier == .premium || ownedCompetitions.contains(.championsLeague)
        case .worldCup:
            return currentTier == .premium || ownedCompetitions.contains(.worldCup)
        case .euroChampionship:
            return currentTier == .premium || ownedCompetitions.contains(.euroChampionship)
        case .nationsCup:
            return currentTier == .premium || ownedCompetitions.contains(.nationsCup)
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        print("🔄 Restoring purchases...")
        isLoading = true
        purchaseError = nil
        
        do {
            try await AppStore.sync()
            await updateEntitlements()
            print("✅ Purchases restored successfully")
        } catch {
            print("❌ Failed to restore purchases: \(error)")
            purchaseError = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Free Live Matches Logic
    
    var remainingFreeMatches: Int {
        let used = UserDefaults.standard.integer(forKey: "usedLiveMatchCount")
        let adRewarded = UserDefaults.standard.integer(forKey: "adRewardedLiveMatches")
        let total = 3 + adRewarded // 3 free + ad rewarded
        return max(0, total - used)
    }
    
    var canUseLiveFeatures: Bool {
        return currentTier == .premium || remainingFreeMatches > 0
    }
    
    func canAccessCompetition(_ competitionCode: String) -> Bool {
        // Basic leagues included in premium
        let basicLeagues = ["PL", "BL1", "SA", "PD", "EL"]
        
        if basicLeagues.contains(competitionCode) {
            return canUseLiveFeatures
        }
        
        // Special competitions require separate purchase
        switch competitionCode {
        case "CL":
            return purchasedCompetitions.contains(ProductID.championsLeague.rawValue)
        case "WC":
            return purchasedCompetitions.contains(ProductID.worldCup.rawValue)
        case "EC":
            return purchasedCompetitions.contains(ProductID.euroChampionship.rawValue)
        case "NC":
            return purchasedCompetitions.contains(ProductID.nationsCup.rawValue)
        default:
            return false
        }
    }
    
    func useFreeLiveMatch() {
        let current = UserDefaults.standard.integer(forKey: "usedLiveMatchCount")
        UserDefaults.standard.set(current + 1, forKey: "usedLiveMatchCount")
    }
    
    // MARK: - Private Methods
    
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    let transaction = try await self.checkVerified(result)
                    await self.updatePurchaseState(for: transaction)
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw PurchaseError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
    
    private func updateEntitlements() async {
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                await updatePurchaseState(for: transaction)
            } catch {
                print("❌ Failed to update entitlements: \(error)")
            }
        }
    }
    
    private func updatePurchaseState(for transaction: Transaction) async {
        switch transaction.productID {
        case ProductID.premium.rawValue:
            currentTier = .premium
            savePurchaseState()
            
        case ProductID.championsLeague.rawValue:
            purchasedCompetitions.insert(ProductID.championsLeague.rawValue)
            ownedCompetitions.insert(.championsLeague)
            savePurchaseState()
            
        case ProductID.worldCup.rawValue:
            purchasedCompetitions.insert(ProductID.worldCup.rawValue)
            ownedCompetitions.insert(.worldCup)
            savePurchaseState()
            
        case ProductID.euroChampionship.rawValue:
            purchasedCompetitions.insert(ProductID.euroChampionship.rawValue)
            ownedCompetitions.insert(.euroChampionship)
            savePurchaseState()
            
        case ProductID.nationsCup.rawValue:
            purchasedCompetitions.insert(ProductID.nationsCup.rawValue)
            ownedCompetitions.insert(.nationsCup)
            savePurchaseState()
            
        default:
            break
        }
    }
    
    private func loadPurchaseState() {
        // Load tier
        if let tierString = UserDefaults.standard.string(forKey: "purchaseTier"),
           let tier = PurchaseTier(rawValue: tierString) {
            currentTier = tier
        }
        
        // Load purchased competitions
        if let competitionsData = UserDefaults.standard.data(forKey: "purchasedCompetitions"),
           let competitions = try? JSONDecoder().decode(Set<String>.self, from: competitionsData) {
            purchasedCompetitions = competitions
            
            // Convert to ownedCompetitions enum set
            ownedCompetitions = Set(competitions.compactMap { ProductID(rawValue: $0) })
        }
    }
    
    private func savePurchaseState() {
        UserDefaults.standard.set(currentTier.rawValue, forKey: "purchaseTier")
        
        if let competitionsData = try? JSONEncoder().encode(purchasedCompetitions) {
            UserDefaults.standard.set(competitionsData, forKey: "purchasedCompetitions")
        }
        
        print("💾 Purchase state saved - Tier: \(currentTier.displayName)")
    }
}

enum PurchaseError: Error, LocalizedError {
    case productNotFound
    case failedVerification
    case userCancelled
    case purchasePending
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .productNotFound:
            return "Product not found"
        case .failedVerification:
            return "Purchase verification failed"
        case .userCancelled:
            return "Purchase was cancelled"
        case .purchasePending:
            return "Purchase is pending approval"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

extension AppPurchaseManager {
    
    // Add the missing property
    var freeLiveMatchesUsed: Int {
        get {
            return UserDefaults.standard.integer(forKey: "usedLiveMatchCount")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "usedLiveMatchCount")
        }
    }
    
    #if DEBUG
    /// Reset all purchase state for debugging
    func debugResetPurchaseState() {
        UserDefaults.standard.removeObject(forKey: "usedLiveMatchCount")  // Fixed key name
        UserDefaults.standard.removeObject(forKey: "adRewardedLiveMatches")
        UserDefaults.standard.removeObject(forKey: "purchaseTier")
        UserDefaults.standard.removeObject(forKey: "purchasedCompetitions")
        
        // Reset to default state
        currentTier = .free
        purchasedCompetitions = []
        ownedCompetitions = []
        
        print("🔄 DEBUG: Purchase state reset")
        print("  - Free matches used: \(freeLiveMatchesUsed)")
        print("  - Can use live features: \(canUseLiveFeatures)")
        print("  - Remaining free matches: \(remainingFreeMatches)")
        
        objectWillChange.send()
    }
    
    /// Grant additional free matches for testing
    func debugGrantFreeMatches(count: Int = 3) {
        let currentUsed = freeLiveMatchesUsed
        freeLiveMatchesUsed = max(0, currentUsed - count)
        
        print("🎁 DEBUG: Granted \(count) free matches")
        print("  - Previously used: \(currentUsed)")
        print("  - Now used: \(freeLiveMatchesUsed)")
        print("  - Remaining: \(remainingFreeMatches)")
        
        objectWillChange.send()
    }
    #endif
}
