//
//  AppPurchaseManager.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 22/05/2025.
//

import Foundation
import StoreKit

@MainActor
class AppPurchaseManager: ObservableObject {
    static let shared = AppPurchaseManager()
    
    @Published var currentTier: PurchaseTier = .free
    @Published var isLoading = false
    @Published var availableProducts: [Product] = []
    @Published var purchaseError: String?
    
    private var transactionListener: Task<Void, Error>?
    
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
                    "Free leagues unlimited (with ads)",
                    "1 live match per day",
                    "3 free matches per big league",
                    "Banner ads throughout app"
                ]
            case .premium:
                return [
                    "All leagues & competitions",
                    "Unlimited live matches daily",
                    "Multiple match selection",
                    "Completely ad-free experience",
                    "World Cup 2026 included"
                ]
            }
        }
        
        var yearlyPrice: String {
            switch self {
            case .free: return "Free"
            case .premium: return "$19.99/year"
            }
        }
    }
    
    enum ProductID: String, CaseIterable {
        // One-time purchases
        case removeAds = "Lucky.Football.Slip.remove_ads"
        case worldCup2026 = "Lucky.Football.Slip.worldcup_2026"
        
        // Yearly subscriptions - Individual leagues
        case leaguePL = "Lucky.Football.Slip.league_pl"
        case leagueLaLiga = "Lucky.Football.Slip.league_laliga"
        case leagueBundesliga = "Lucky.Football.Slip.league_bundesliga"
        case leagueSerieA = "Lucky.Football.Slip.league_seriea"
        case leagueCL = "Lucky.Football.Slip.league_cl"
        
        // Yearly subscription - Premium (all access)
        case premium = "Lucky.Football.Slip.premium_yearly"
        
        var displayName: String {
            switch self {
            case .removeAds: return "Remove Ads"
            case .worldCup2026: return "World Cup 2026"
            case .leaguePL: return "Premier League"
            case .leagueLaLiga: return "La Liga"
            case .leagueBundesliga: return "Bundesliga"
            case .leagueSerieA: return "Serie A"
            case .leagueCL: return "Champions League"
            case .premium: return "Premium All-Access"
            }
        }
        
        var description: String {
            switch self {
            case .removeAds: return "Remove all banner and interstitial ads forever"
            case .worldCup2026: return "Access World Cup 2026 matches (June-July 2026)"
            case .leaguePL: return "Unlimited Premier League matches"
            case .leagueLaLiga: return "Unlimited La Liga matches"
            case .leagueBundesliga: return "Unlimited Bundesliga matches"
            case .leagueSerieA: return "Unlimited Serie A matches"
            case .leagueCL: return "Champions League access"
            case .premium: return "All leagues, no ads, unlimited matches"
            }
        }
        
        var price: String {
            switch self {
            case .removeAds: return "$2.99"
            case .worldCup2026: return "$4.99"
            case .leaguePL, .leagueLaLiga, .leagueBundesliga, .leagueSerieA: return "$6.99/year"
            case .leagueCL: return "$4.99/year"
            case .premium: return "$19.99/year"
            }
        }
        
        var isSubscription: Bool {
            switch self {
            case .removeAds, .worldCup2026:
                return false
            case .leaguePL, .leagueLaLiga, .leagueBundesliga, .leagueSerieA, .leagueCL, .premium:
                return true
            }
        }
        
        var isLeagueSubscription: Bool {
            switch self {
            case .leaguePL, .leagueLaLiga, .leagueBundesliga, .leagueSerieA, .leagueCL:
                return true
            default:
                return false
            }
        }
    }
    
    // MARK: - Feature Flag Integration
    
    var isSubscriptionEnabled: Bool {
        return AppConfig.PurchaseConfig.purchasesEnabled
    }
    
    // MARK: - One-Time Purchase Tracking
    
    var hasRemovedAds: Bool {
        get { UserDefaults.standard.bool(forKey: "purchase_removeAds") }
        set {
            UserDefaults.standard.set(newValue, forKey: "purchase_removeAds")
            objectWillChange.send()
        }
    }
    
    var hasWorldCup2026: Bool {
        get {
            // Check if purchased and not expired (Aug 1, 2026)
            guard UserDefaults.standard.bool(forKey: "purchase_worldCup2026") else { return false }
            let expiryDate = Calendar.current.date(from: DateComponents(year: 2026, month: 8, day: 1)) ?? Date()
            return Date() < expiryDate
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "purchase_worldCup2026")
            objectWillChange.send()
        }
    }
    
    // MARK: - Subscription Tracking
    
    @Published var activeSubscriptions: Set<String> = []
    
    var hasPremium: Bool {
        currentTier == .premium || activeSubscriptions.contains(ProductID.premium.rawValue)
    }
    
    var hasAnyLeagueSubscription: Bool {
        ProductID.allCases.filter { $0.isLeagueSubscription }.contains { hasAccess(to: $0) }
    }
    
    // MARK: - Ad-Free Check
    
    var isAdFree: Bool {
        // Feature flag bypass
        if !AppConfig.PurchaseConfig.purchasesEnabled && AppConfig.PremiumFeatures.adFreeExperience {
            return true
        }
        return hasRemovedAds || hasPremium
    }
    
    // MARK: - Initialization
    
    private init() {
        #if DEBUG
        debugProductConfiguration()
        #endif
        
        loadPurchaseState()
        transactionListener = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateEntitlements()
        }
    }

    #if DEBUG
    func debugProductConfiguration() {
        print("ðŸ› DEBUG: ProductID.premium.rawValue = '\(ProductID.premium.rawValue)'")
        print("ðŸ› DEBUG: All cases = \(ProductID.allCases.map { "'\($0.rawValue)'" })")
        print("ðŸ› DEBUG: Bundle ID = '\(Bundle.main.bundleIdentifier ?? "nil")'")
        print("ðŸ› DEBUG: Subscription enabled = \(isSubscriptionEnabled)")
    }
    #endif
    
    deinit {
        transactionListener?.cancel()
    }
    
    // MARK: - Daily Calendar-Based Live Matches
    
    var dailyFreeMatchesUsed: Int {
        get {
            let today = Calendar.current.startOfDay(for: Date())
            let todayString = DateFormatter.yyyyMMdd.string(from: today)
            return UserDefaults.standard.integer(forKey: "dailyMatchesUsed_\(todayString)")
        }
        set {
            let today = Calendar.current.startOfDay(for: Date())
            let todayString = DateFormatter.yyyyMMdd.string(from: today)
            UserDefaults.standard.set(newValue, forKey: "dailyMatchesUsed_\(todayString)")
        }
    }
    
    var adRewardedMatchesToday: Int {
        get {
            let today = Calendar.current.startOfDay(for: Date())
            let todayString = DateFormatter.yyyyMMdd.string(from: today)
            return UserDefaults.standard.integer(forKey: "adRewardedMatches_\(todayString)")
        }
        set {
            let today = Calendar.current.startOfDay(for: Date())
            let todayString = DateFormatter.yyyyMMdd.string(from: today)
            UserDefaults.standard.set(newValue, forKey: "adRewardedMatches_\(todayString)")
        }
    }
    
    /// Enhanced canUseLiveFeatures with feature flags
    var canUseLiveFeatures: Bool {
        // If unlimited daily matches feature is enabled, always allow
        if AppConfig.hasUnlimitedDailyMatches {
            return true
        }
        
        // Always allow during free testing period
        if AppConfig.isFreeLiveTestingActive {
            return true
        }
        
        // If subscription is disabled, use daily limit logic
        if !isSubscriptionEnabled {
            return remainingFreeMatchesToday > 0
        }
        
        // Normal subscription logic when enabled
        return currentTier == .premium || remainingFreeMatchesToday > 0
    }
    
    /// Enhanced remainingFreeMatchesToday with feature flags
    var remainingFreeMatchesToday: Int {
        // Unlimited if feature flag is enabled
        if AppConfig.hasUnlimitedDailyMatches {
            return Int.max
        }
        
        // Unlimited during free testing
        if AppConfig.isFreeLiveTestingActive {
            return Int.max
        }
        
        // Normal daily limit calculation
        let dailyLimit = 1
        let used = dailyFreeMatchesUsed
        let adRewarded = adRewardedMatchesToday
        let total = dailyLimit + adRewarded
        return max(0, total - used)
    }
    
    /// Enhanced useFreeLiveMatch with feature flags
    func useFreeLiveMatch() {
        // Don't count usage if unlimited feature is enabled
        if AppConfig.hasUnlimitedDailyMatches {
            print("ðŸŽ Unlimited matches feature enabled - usage not counted")
            return
        }
        
        // Don't count usage during free testing period
        if AppConfig.isFreeLiveTestingActive {
            print("ðŸŽ Free testing active - match usage not counted")
            AppConfig.recordFreeLiveModeUsage()
            return
        }
        
        // Normal usage counting
        dailyFreeMatchesUsed += 1
        print("ðŸ“Š Used daily live match. Remaining today: \(remainingFreeMatchesToday)")
    }
    
    func grantAdRewardedMatch() {
        adRewardedMatchesToday += 1
        print("ðŸŽ Granted ad-rewarded match. Total ad matches today: \(adRewardedMatchesToday)")
        objectWillChange.send()
    }
    
    // MARK: - Competition Access (Now All Free)
    
    func canAccessCompetition(_ competitionCode: String) -> Bool {
        // All competitions are now free (with ads for free users)
        return true
    }
    
    // MARK: - Product Management
    
    func loadProducts() async {
        guard isSubscriptionEnabled else {
            print("ðŸ’¡ Subscription disabled for this release")
            return
        }
        
        print("ðŸ” Loading products...")
        isLoading = true
        purchaseError = nil
        
        do {
            let productIDs = Set(ProductID.allCases.map { $0.rawValue })
            print("ðŸ” Requesting products: \(productIDs)")
            
            let products = try await Product.products(for: productIDs)
            
            await MainActor.run {
                self.availableProducts = products
                self.isLoading = false
                
                if products.isEmpty {
                    self.purchaseError = "Subscription not available. Please try again later."
                    print("âŒ No products loaded - check App Store Connect status")
                } else {
                    print("âœ… Loaded \(products.count) products:")
                    for product in products {
                        print("  - \(product.id): \(product.displayName) - \(product.displayPrice)")
                        if let subscription = product.subscription {
                            print("    Subscription period: \(subscription.subscriptionPeriod)")
                            print("    Subscription group: \(subscription.subscriptionGroupID)")
                        }
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
                self.purchaseError = "Failed to load subscription: \(error.localizedDescription)"
                print("âŒ Failed to load products: \(error)")
            }
        }
    }
    
    func purchase(_ productID: ProductID) async throws -> Bool {
        guard let product = availableProducts.first(where: { $0.id == productID.rawValue }) else {
            throw PurchaseError.productNotFound
        }
        
        isLoading = true
        purchaseError = nil
        
        defer {
            Task { @MainActor in
                self.isLoading = false
            }
        }
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await updatePurchaseState(for: transaction)
                await transaction.finish()
                return true
                
            case .userCancelled:
                throw PurchaseError.userCancelled
                
            case .pending:
                throw PurchaseError.purchasePending
                
            @unknown default:
                throw PurchaseError.unknown
            }
        } catch {
            await MainActor.run {
                self.purchaseError = error.localizedDescription
            }
            throw error
        }
    }
    
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
        // Feature flag bypass - if purchases disabled, check feature flags instead
        if !AppConfig.PurchaseConfig.purchasesEnabled {
            return true // All access when purchases disabled for testing
        }
        
        // Premium gives access to everything
        if hasPremium {
            return true
        }
        
        switch productID {
        case .premium:
            return currentTier == .premium || activeSubscriptions.contains(productID.rawValue)
            
        case .removeAds:
            return hasRemovedAds
            
        case .worldCup2026:
            return hasWorldCup2026
            
        case .leaguePL, .leagueLaLiga, .leagueBundesliga, .leagueSerieA, .leagueCL:
            return activeSubscriptions.contains(productID.rawValue)
        }
    }
    
    func validateSubscriptionConfiguration() {
        print("ðŸ” Validating subscription configuration...")
        
        guard let bundleID = Bundle.main.bundleIdentifier else {
            print("âŒ No bundle identifier found")
            return
        }
        
        print("ðŸ“± Bundle ID: \(bundleID)")
        print("ðŸ›ï¸ Expected Product ID: \(ProductID.premium.rawValue)")
        print("ðŸš€ Subscription enabled: \(isSubscriptionEnabled)")
        
        if availableProducts.isEmpty && isSubscriptionEnabled {
            print("âŒ No products loaded - subscription may not be active in App Store Connect")
        } else if !isSubscriptionEnabled {
            print("ðŸ’¡ Subscription disabled - using feature flags for premium features")
        } else {
            print("âœ… App Store products loaded successfully")
        }
    }
    
    // MARK: - Restore Purchases
    
    func restorePurchases() async {
        print("ðŸ”„ Restoring purchases...")
        isLoading = true
        purchaseError = nil
        
        do {
            try await AppStore.sync()
            await updateEntitlements()
            print("âœ… Purchases restored successfully")
        } catch {
            print("âŒ Failed to restore purchases: \(error)")
            purchaseError = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
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
                    print("âŒ Transaction verification failed: \(error)")
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
    
    func updateEntitlements() async {
        var hasActivePremium = false
        var newActiveSubscriptions: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                let productIDString = transaction.productID
                
                // Handle subscriptions
                if let product = ProductID(rawValue: productIDString), product.isSubscription {
                    if let expirationDate = transaction.expirationDate {
                        if expirationDate > Date() {
                            newActiveSubscriptions.insert(productIDString)
                            if product == .premium {
                                hasActivePremium = true
                            }
                            print("Active subscription: \(product.displayName) expires \(expirationDate)")
                        }
                    } else {
                        newActiveSubscriptions.insert(productIDString)
                        if product == .premium {
                            hasActivePremium = true
                        }
                    }
                }
                
                // Handle one-time purchases
                if productIDString == ProductID.removeAds.rawValue {
                    await MainActor.run { self.hasRemovedAds = true }
                }
                if productIDString == ProductID.worldCup2026.rawValue {
                    await MainActor.run { self.hasWorldCup2026 = true }
                }
                
            } catch {
                print("Failed to verify transaction: \(error)")
            }
        }
        
        await MainActor.run {
            self.activeSubscriptions = newActiveSubscriptions
            let newTier: PurchaseTier = hasActivePremium ? .premium : .free
            if newTier != currentTier {
                currentTier = newTier
                savePurchaseState()
            }
        }
    }
    
    private func updatePurchaseState(for transaction: Transaction) async {
        let productIDString = transaction.productID
        
        // Handle Premium subscription
        if productIDString == ProductID.premium.rawValue {
            currentTier = .premium
            savePurchaseState()
        }
        
        // Handle one-time purchases
        if productIDString == ProductID.removeAds.rawValue {
            hasRemovedAds = true
        }
        if productIDString == ProductID.worldCup2026.rawValue {
            hasWorldCup2026 = true
        }
        
        // Handle league subscriptions
        if let product = ProductID(rawValue: productIDString), product.isLeagueSubscription {
            activeSubscriptions.insert(productIDString)
        }
    }
    
    private func loadPurchaseState() {
        // Load tier
        if let tierString = UserDefaults.standard.string(forKey: "purchaseTier"),
           let tier = PurchaseTier(rawValue: tierString) {
            currentTier = tier
        }
    }
    
    private func savePurchaseState() {
        UserDefaults.standard.set(currentTier.rawValue, forKey: "purchaseTier")
        print("ðŸ’¾ Purchase state saved - Tier: \(currentTier.displayName)")
    }
    
    // MARK: - Session Management
    
    func resetSessionStateIfNeeded() {
        // Reset the upgrade prompt flag when app becomes active
        UserDefaults.standard.set(false, forKey: "upgradePromptShownThisSession")
        
        // Clean up old daily data
        cleanupOldDailyData()
    }
    
    private func cleanupOldDailyData() {
        let keys = UserDefaults.standard.dictionaryRepresentation().keys
        let dateFormatter = DateFormatter.yyyyMMdd
        let currentDate = dateFormatter.string(from: Date())
        
        // Remove data older than 7 days
        for key in keys {
            if key.hasPrefix("dailyMatchesUsed_") || key.hasPrefix("adRewardedMatches_") {
                let dateString = String(key.split(separator: "_").last ?? "")
                if dateString != currentDate && dateString.count == 10 { // YYYY-MM-DD format
                    if let date = dateFormatter.date(from: dateString),
                       Date().timeIntervalSince(date) > 7 * 24 * 60 * 60 {
                        UserDefaults.standard.removeObject(forKey: key)
                    }
                }
            }
        }
    }
    
    // MARK: - Development/Testing Methods

    #if DEBUG
    /// Sets the user to premium tier for testing purposes (Debug builds only)
    func setToPremiumForTesting() {
        currentTier = .premium
        activeSubscriptions.insert(ProductID.premium.rawValue)
        savePurchaseState()
        print("🧪 User set to premium for testing")
        objectWillChange.send()
    }

    /// Resets the user to free tier for testing purposes (Debug builds only)
    func setToFreeForTesting() {
        currentTier = .free
        activeSubscriptions.removeAll()
        hasRemovedAds = false
        hasWorldCup2026 = false
        savePurchaseState()
        print("🧪 User set to free for testing")
        objectWillChange.send()
    }

    /// Resets daily match usage for testing
    func resetDailyMatchUsageForTesting() {
        let today = Calendar.current.startOfDay(for: Date())
        let todayString = DateFormatter.yyyyMMdd.string(from: today)
        UserDefaults.standard.removeObject(forKey: "dailyMatchesUsed_\(todayString)")
        UserDefaults.standard.removeObject(forKey: "adRewardedMatches_\(todayString)")
        print("🧪 Daily match usage reset for testing")
        objectWillChange.send()
    }
    
    /// Simulates purchasing Remove Ads
    func simulateRemoveAdsPurchase() {
        hasRemovedAds = true
        print("🧪 Simulated Remove Ads purchase")
        objectWillChange.send()
    }
    
    /// Simulates purchasing World Cup 2026
    func simulateWorldCupPurchase() {
        hasWorldCup2026 = true
        print("🧪 Simulated World Cup 2026 purchase")
        objectWillChange.send()
    }
    
    /// Simulates subscribing to a specific league
    func simulateLeagueSubscription(_ productID: ProductID) {
        guard productID.isLeagueSubscription else {
            print("🧪 Error: \(productID.displayName) is not a league subscription")
            return
        }
        activeSubscriptions.insert(productID.rawValue)
        print("🧪 Simulated \(productID.displayName) subscription")
        objectWillChange.send()
    }
    
    /// Removes a simulated league subscription
    func removeSimulatedLeagueSubscription(_ productID: ProductID) {
        activeSubscriptions.remove(productID.rawValue)
        print("🧪 Removed simulated \(productID.displayName) subscription")
        objectWillChange.send()
    }
    
    /// Resets all simulated purchases
    func resetAllSimulatedPurchases() {
        currentTier = .free
        activeSubscriptions.removeAll()
        hasRemovedAds = false
        hasWorldCup2026 = false
        UserDefaults.standard.removeObject(forKey: "purchase_removeAds")
        UserDefaults.standard.removeObject(forKey: "purchase_worldCup2026")
        savePurchaseState()
        print("🧪 All simulated purchases reset")
        objectWillChange.send()
    }
    
    /// Returns debug status of all purchases
    func getDebugPurchaseStatus() -> [String: Any] {
        var status: [String: Any] = [:]
        
        status["currentTier"] = currentTier.displayName
        status["hasPremium"] = hasPremium
        status["hasRemovedAds"] = hasRemovedAds
        status["hasWorldCup2026"] = hasWorldCup2026
        status["isAdFree"] = isAdFree
        status["activeSubscriptions"] = Array(activeSubscriptions)
        
        var productAccess: [String: Bool] = [:]
        for product in ProductID.allCases {
            productAccess[product.displayName] = hasAccess(to: product)
        }
        status["productAccess"] = productAccess
        
        return status
    }
    
    /// Prints debug status to console
    func printDebugStatus() {
        print("========== PURCHASE MANAGER DEBUG STATUS ==========")
        let status = getDebugPurchaseStatus()
        for (key, value) in status.sorted(by: { $0.key < $1.key }) {
            print("  \(key): \(value)")
        }
        print("===================================================")
    }
    #endif
}

// MARK: - Purchase Error

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
