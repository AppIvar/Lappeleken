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
                    "Manual mode games",
                    "1 free live match daily",
                    "All leagues & competitions",
                    "Watch ads for extra matches",
                    "Banner ads throughout app"
                ]
            case .premium:
                return [
                    "Unlimited live matches daily",
                    "All leagues & competitions",
                    "Multiple match tracking",
                    "Completely ad-free experience",
                    "Premium support",
                    "Export game summaries",
                    "Priority customer support"
                ]
            }
        }
        
        var monthlyPrice: String {
            switch self {
            case .free: return "Free"
            case .premium: return "$2.99/month"
            }
        }
    }
    
    enum ProductID: String, CaseIterable {
        case premium = "HovlandGames.Lucky_Football_Slip.premium_monthly"
        
        var displayName: String {
            switch self {
            case .premium: return "Premium Monthly"
            }
        }
        
        var description: String {
            switch self {
            case .premium: return "Unlimited live matches and completely ad-free experience"
            }
        }
    }
    
    // MARK: - Initialization
    
    private init() {
        loadPurchaseState()
        transactionListener = listenForTransactions()
        
        Task {
            await loadProducts()
            await updateEntitlements()
        }
    }
    
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
    
    var remainingFreeMatchesToday: Int {
        let dailyLimit = 1 // 1 free match per calendar day
        let used = dailyFreeMatchesUsed
        let adRewarded = adRewardedMatchesToday
        let total = dailyLimit + adRewarded
        return max(0, total - used)
    }
    
    var canUseLiveFeatures: Bool {
        return currentTier == .premium || remainingFreeMatchesToday > 0
    }
    
    func useFreeLiveMatch() {
        dailyFreeMatchesUsed += 1
        print("📊 Used daily live match. Remaining today: \(remainingFreeMatchesToday)")
    }
    
    func grantAdRewardedMatch() {
        adRewardedMatchesToday += 1
        print("🎁 Granted ad-rewarded match. Total ad matches today: \(adRewardedMatchesToday)")
        objectWillChange.send()
    }
    
    // MARK: - Competition Access (Now All Free)
    
    func canAccessCompetition(_ competitionCode: String) -> Bool {
        // All competitions are now free (with ads for free users)
        return true
    }
    
    // MARK: - Product Management
    
    func loadProducts() async {
        do {
            let products = try await Product.products(for: ProductID.allCases.map { $0.rawValue })
            
            await MainActor.run {
                self.availableProducts = products
                print("✅ Loaded \(products.count) products")
                for product in products {
                    print("  - \(product.id): \(product.displayName) - \(product.displayPrice)")
                }
            }
        } catch {
            await MainActor.run {
                print("❌ Failed to load products: \(error)")
                self.purchaseError = "Failed to load products: \(error.localizedDescription)"
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
        switch productID {
        case .premium:
            return currentTier == .premium
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
            print("✅ Premium subscription activated")
            
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
    }
    
    private func savePurchaseState() {
        UserDefaults.standard.set(currentTier.rawValue, forKey: "purchaseTier")
        print("💾 Purchase state saved - Tier: \(currentTier.displayName)")
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
        savePurchaseState()
        print("🧪 User set to premium for testing")
        objectWillChange.send()
    }

    /// Resets the user to free tier for testing purposes (Debug builds only)
    func setToFreeForTesting() {
        currentTier = .free
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

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let yyyyMMdd: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone.current
        return formatter
    }()
}

