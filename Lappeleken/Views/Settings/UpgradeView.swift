//
//  UpgradeView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 22/05/2025.
//  Updated for tiered purchase system on 04/02/2026.
//

import SwiftUI
import StoreKit

struct UpgradeView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var purchaseManager = AppPurchaseManager.shared
    @ObservedObject private var leagueManager = LeagueAccessManager.shared
    @State private var selectedTab = 0
    @State private var isLoadingProducts = true
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var expandedSection: PurchaseSection? = nil
    
    enum PurchaseSection: String, CaseIterable {
        case premium = "Premium"
        case leagues = "Leagues"
        case extras = "Extras"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current Status Card
                    currentStatusCard
                    
                    // Tab Selector
                    Picker("View", selection: $selectedTab) {
                        Text("Packages").tag(0)
                        Text("My Access").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if selectedTab == 0 {
                        purchaseOptionsView
                    } else {
                        myAccessView
                    }
                    
                    // Restore Purchases
                    restorePurchasesButton
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .navigationTitle("Upgrade")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
        .onAppear {
            loadProducts()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Current Status Card
    
    private var currentStatusCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: purchaseManager.hasPremium ? "crown.fill" : "person.circle")
                            .foregroundColor(purchaseManager.hasPremium ? .yellow : AppDesignSystem.Colors.primary)
                        
                        Text(purchaseManager.hasPremium ? "Premium" : "Free Plan")
                            .font(.headline)
                    }
                    
                    if purchaseManager.hasPremium {
                        Text("All features unlocked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Upgrade to unlock more features")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if purchaseManager.isAdFree {
                    Label("Ad-Free", systemImage: "xmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Purchase Options View
    
    private var purchaseOptionsView: some View {
        VStack(spacing: 20) {
            // Premium - Best Value
            premiumSection
            
            // Individual League Subscriptions
            leaguesSection
            
            // One-time Purchases
            extrasSection
        }
    }
    
    // MARK: - Premium Section
    
    private var premiumSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Best Value", icon: "star.fill", color: .yellow)
            
            PurchaseCard(
                productID: .premium,
                title: "Premium All-Access",
                subtitle: "Everything included",
                price: "$19.99/year",
                features: [
                    "All leagues & competitions",
                    "Unlimited live matches daily",
                    "Multiple match selection",
                    "No advertisements",
                    "World Cup 2026 included"
                ],
                isPurchased: purchaseManager.hasPremium,
                isHighlighted: true,
                onPurchase: { purchaseProduct(.premium) }
            )
        }
    }
    
    // MARK: - Leagues Section
    
    private var leaguesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("League Subscriptions", icon: "sportscourt.fill", color: AppDesignSystem.Colors.primary)
            
            Text("Unlimited matches for your favorite league")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Big 4 Leagues
            VStack(spacing: 8) {
                LeaguePurchaseRow(
                    productID: .leaguePL,
                    leagueName: "Premier League",
                    leagueCode: "PL",
                    price: "$6.99/year",
                    isPurchased: purchaseManager.hasAccess(to: .leaguePL),
                    freeMatchesRemaining: leagueManager.getRemainingFreeMatches(for: "PL"),
                    onPurchase: { purchaseProduct(.leaguePL) }
                )
                
                LeaguePurchaseRow(
                    productID: .leagueLaLiga,
                    leagueName: "La Liga",
                    leagueCode: "PD",
                    price: "$6.99/year",
                    isPurchased: purchaseManager.hasAccess(to: .leagueLaLiga),
                    freeMatchesRemaining: leagueManager.getRemainingFreeMatches(for: "PD"),
                    onPurchase: { purchaseProduct(.leagueLaLiga) }
                )
                
                LeaguePurchaseRow(
                    productID: .leagueBundesliga,
                    leagueName: "Bundesliga",
                    leagueCode: "BL1",
                    price: "$6.99/year",
                    isPurchased: purchaseManager.hasAccess(to: .leagueBundesliga),
                    freeMatchesRemaining: leagueManager.getRemainingFreeMatches(for: "BL1"),
                    onPurchase: { purchaseProduct(.leagueBundesliga) }
                )
                
                LeaguePurchaseRow(
                    productID: .leagueSerieA,
                    leagueName: "Serie A",
                    leagueCode: "SA",
                    price: "$6.99/year",
                    isPurchased: purchaseManager.hasAccess(to: .leagueSerieA),
                    freeMatchesRemaining: leagueManager.getRemainingFreeMatches(for: "SA"),
                    onPurchase: { purchaseProduct(.leagueSerieA) }
                )
            }
            
            // Champions League
            Divider().padding(.vertical, 4)
            
            LeaguePurchaseRow(
                productID: .leagueCL,
                leagueName: "Champions League",
                leagueCode: "CL",
                price: "$4.99/year",
                isPurchased: purchaseManager.hasAccess(to: .leagueCL),
                freeMatchesRemaining: 0, // CL has no free matches
                isLocked: true,
                onPurchase: { purchaseProduct(.leagueCL) }
            )
        }
    }
    
    // MARK: - Extras Section
    
    private var extrasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("One-Time Purchases", icon: "bag.fill", color: .orange)
            
            // Remove Ads
            PurchaseCard(
                productID: .removeAds,
                title: "Remove Ads",
                subtitle: "One-time purchase",
                price: "$2.99",
                features: [
                    "Remove all banner ads",
                    "Remove interstitial ads",
                    "Cleaner experience"
                ],
                isPurchased: purchaseManager.hasRemovedAds,
                isHighlighted: false,
                onPurchase: { purchaseProduct(.removeAds) }
            )
            
            // World Cup 2026
            PurchaseCard(
                productID: .worldCup2026,
                title: "World Cup 2026",
                subtitle: "Valid until August 2026",
                price: "$4.99",
                features: [
                    "All World Cup matches",
                    "June - July 2026",
                    "One-time purchase"
                ],
                isPurchased: purchaseManager.hasWorldCup2026,
                isHighlighted: false,
                onPurchase: { purchaseProduct(.worldCup2026) }
            )
        }
    }
    
    // MARK: - My Access View
    
    private var myAccessView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Free Leagues
            accessSection(
                title: "Free Leagues",
                icon: "checkmark.seal.fill",
                color: .green,
                items: [
                    ("Eredivisie", "Unlimited (with ads)", true),
                    ("Primeira Liga", "Unlimited (with ads)", true),
                    ("Championship", "Unlimited (with ads)", true),
                    ("Eliteserien", "Unlimited (with ads)", true)
                ]
            )
            
            // Big Leagues
            accessSection(
                title: "Big Leagues",
                icon: "star.fill",
                color: .blue,
                items: [
                    ("Premier League", bigLeagueStatus(for: "PL"), purchaseManager.hasAccess(to: .leaguePL) || leagueManager.getRemainingFreeMatches(for: "PL") > 0),
                    ("La Liga", bigLeagueStatus(for: "PD"), purchaseManager.hasAccess(to: .leagueLaLiga) || leagueManager.getRemainingFreeMatches(for: "PD") > 0),
                    ("Bundesliga", bigLeagueStatus(for: "BL1"), purchaseManager.hasAccess(to: .leagueBundesliga) || leagueManager.getRemainingFreeMatches(for: "BL1") > 0),
                    ("Serie A", bigLeagueStatus(for: "SA"), purchaseManager.hasAccess(to: .leagueSerieA) || leagueManager.getRemainingFreeMatches(for: "SA") > 0)
                ]
            )
            
            // Premium Competitions
            accessSection(
                title: "Premium Competitions",
                icon: "crown.fill",
                color: .yellow,
                items: [
                    ("Champions League", purchaseManager.hasAccess(to: .leagueCL) ? "Subscribed" : "Locked", purchaseManager.hasAccess(to: .leagueCL)),
                    ("World Cup 2026", purchaseManager.hasWorldCup2026 ? "Purchased" : "Locked", purchaseManager.hasWorldCup2026)
                ]
            )
            
            // Features
            accessSection(
                title: "Features",
                icon: "gearshape.fill",
                color: .purple,
                items: [
                    ("Ad-Free Experience", purchaseManager.isAdFree ? "Active" : "Upgrade required", purchaseManager.isAdFree),
                    ("Multiple Match Selection", purchaseManager.hasPremium ? "Active" : "Premium only", purchaseManager.hasPremium),
                    ("Unlimited Daily Matches", purchaseManager.hasPremium ? "Active" : "1 per day", purchaseManager.hasPremium)
                ]
            )
        }
    }
    
    private func bigLeagueStatus(for code: String) -> String {
        let productID: AppPurchaseManager.ProductID
        switch code {
        case "PL": productID = .leaguePL
        case "PD": productID = .leagueLaLiga
        case "BL1": productID = .leagueBundesliga
        case "SA": productID = .leagueSerieA
        default: return "Unknown"
        }
        
        if purchaseManager.hasPremium || purchaseManager.hasAccess(to: productID) {
            return "Unlimited"
        }
        
        let remaining = leagueManager.getRemainingFreeMatches(for: code)
        if remaining > 0 {
            return "\(remaining) free left"
        }
        return "Locked"
    }
    
    // MARK: - Helper Views
    
    private func sectionHeader(_ title: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
    
    private func accessSection(title: String, icon: String, color: Color, items: [(String, String, Bool)]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader(title, icon: icon, color: color)
            
            VStack(spacing: 4) {
                ForEach(items, id: \.0) { item in
                    HStack {
                        Text(item.0)
                            .font(.subheadline)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: item.2 ? "checkmark.circle.fill" : "lock.fill")
                                .foregroundColor(item.2 ? .green : .red)
                                .font(.caption)
                            Text(item.1)
                                .font(.caption)
                                .foregroundColor(item.2 ? .green : .secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
            .cornerRadius(8)
        }
    }
    
    private var restorePurchasesButton: some View {
        Button("Restore Purchases") {
            Task {
                await purchaseManager.restorePurchases()
            }
        }
        .font(.subheadline)
        .foregroundColor(AppDesignSystem.Colors.primary)
        .padding(.top, 8)
    }
    
    // MARK: - Actions
    
    private func loadProducts() {
        isLoadingProducts = true
        Task {
            await purchaseManager.loadProducts()
            isLoadingProducts = false
        }
    }
    
    private func purchaseProduct(_ productID: AppPurchaseManager.ProductID) {
        // Check if purchases are enabled (feature flag)
        guard AppConfig.PurchaseConfig.purchasesEnabled else {
            errorMessage = "Purchases are not enabled in this build. This is a testing/preview version."
            showingError = true
            return
        }
        
        Task {
            do {
                _ = try await purchaseManager.purchase(productID)
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
    }
}

// MARK: - Purchase Card

struct PurchaseCard: View {
    let productID: AppPurchaseManager.ProductID
    let title: String
    let subtitle: String
    let price: String
    let features: [String]
    let isPurchased: Bool
    let isHighlighted: Bool
    let onPurchase: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isPurchased {
                    Label("Active", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                } else {
                    Text(price)
                        .font(.headline)
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
            
            // Features
            VStack(alignment: .leading, spacing: 6) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text(feature)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // Purchase Button
            if !isPurchased {
                Button(action: onPurchase) {
                    Text("Purchase")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            isHighlighted ?
                            LinearGradient(colors: [.yellow, .orange], startPoint: .leading, endPoint: .trailing) :
                            LinearGradient(colors: [AppDesignSystem.Colors.primary, AppDesignSystem.Colors.primary.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                        )
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHighlighted && !isPurchased ? Color.yellow : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - League Purchase Row

struct LeaguePurchaseRow: View {
    let productID: AppPurchaseManager.ProductID
    let leagueName: String
    let leagueCode: String
    let price: String
    let isPurchased: Bool
    var freeMatchesRemaining: Int = 0
    var isLocked: Bool = false
    let onPurchase: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(leagueName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if isPurchased {
                    Text("Unlimited access")
                        .font(.caption)
                        .foregroundColor(.green)
                } else if isLocked {
                    Text("Subscription required")
                        .font(.caption)
                        .foregroundColor(.orange)
                } else if freeMatchesRemaining > 0 {
                    Text("\(freeMatchesRemaining) free matches left")
                        .font(.caption)
                        .foregroundColor(.blue)
                } else {
                    Text("No free matches left")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
            
            if isPurchased {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Button(action: onPurchase) {
                    Text(price)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppDesignSystem.Colors.primary)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Preview

struct UpgradeView_Previews: PreviewProvider {
    static var previews: some View {
        UpgradeView()
    }
}
