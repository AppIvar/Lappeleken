//
//  SettingsView.swift
//  Lucky Football Slip
//
//  Simplified settings interface
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var purchaseManager = AppPurchaseManager.shared
    @ObservedObject private var leagueManager = LeagueAccessManager.shared
    
    @AppStorage("selectedCurrency") private var selectedCurrency = "EUR"
    @AppStorage("currencySymbol") private var currencySymbol = "€"
    
    @State private var showingUpgradeView = false
    
    private let currencies = [
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("NOK", "kr", "Norwegian Krone"),
        ("SEK", "kr", "Swedish Krona"),
        ("DKK", "kr", "Danish Krone")
    ]
    
    var body: some View {
        ZStack {
            AppDesignSystem.Colors.background.ignoresSafeArea()
            
            NavigationView {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Subscription Section
                        subscriptionSection
                        
                        // Currency Section
                        currencySection
                        
                        // About Section
                        aboutSection
                        
                        #if DEBUG
                        debugSection
                        #endif
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
                .navigationTitle("Settings")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    }
                }
            }
        }
        .sheet(isPresented: $showingUpgradeView) {
            UpgradeView()
        }
        .withMinimalBanner()
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        SettingsSection(title: "Subscription", icon: "crown.fill", color: .yellow) {
            VStack(spacing: 12) {
                // Current status card
                subscriptionStatusCard
                
                // Upgrade button (if not premium)
                if !purchaseManager.hasPremium {
                    Button(action: { showingUpgradeView = true }) {
                        HStack {
                            Image(systemName: "sparkles")
                            Text("View Upgrade Options")
                                .fontWeight(.semibold)
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [AppDesignSystem.Colors.primary, AppDesignSystem.Colors.primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                
                // Restore purchases
                Button(action: {
                    Task { await purchaseManager.restorePurchases() }
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Restore Purchases")
                        Spacer()
                    }
                    .font(.subheadline)
                    .foregroundColor(AppDesignSystem.Colors.primary)
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(10)
                }
            }
        }
    }
    
    private var subscriptionStatusCard: some View {
        HStack(spacing: 16) {
            // Status icon
            ZStack {
                Circle()
                    .fill(purchaseManager.hasPremium ? Color.yellow.opacity(0.2) : Color.gray.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: purchaseManager.hasPremium ? "crown.fill" : "person.circle")
                    .font(.title2)
                    .foregroundColor(purchaseManager.hasPremium ? .yellow : .gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(purchaseManager.hasPremium ? "Premium" : "Free Plan")
                    .font(.headline)
                
                if purchaseManager.hasPremium {
                    Text("All features unlocked")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Text("Limited access to leagues")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Feature badges
            VStack(alignment: .trailing, spacing: 4) {
                if purchaseManager.isAdFree {
                    StatusBadge(text: "Ad-Free", color: .green)
                }
                if purchaseManager.hasWorldCup2026 {
                    StatusBadge(text: "WC 2026", color: .blue)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemBackground))
        )
    }
    
    // MARK: - Currency Section
    
    private var currencySection: some View {
        SettingsSection(title: "Currency", icon: "dollarsign.circle.fill", color: .green) {
            VStack(spacing: 8) {
                ForEach(currencies, id: \.0) { currency in
                    CurrencyRow(
                        code: currency.0,
                        symbol: currency.1,
                        name: currency.2,
                        isSelected: selectedCurrency == currency.0
                    ) {
                        selectedCurrency = currency.0
                        currencySymbol = currency.1
                    }
                }
            }
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle.fill", color: .blue) {
            VStack(spacing: 8) {
                SettingsRow(
                    title: "Version",
                    value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
                )
                
                SettingsLinkRow(
                    title: "Data by Football-Data.org",
                    icon: "link",
                    url: "https://football-data.org"
                )
                
                SettingsLinkRow(
                    title: "Privacy Policy",
                    icon: "lock.shield",
                    url: "https://lucky-football-slip.netlify.app/#privacy"
                )
                
                SettingsLinkRow(
                    title: "Terms of Service",
                    icon: "doc.text",
                    url: "https://lucky-football-slip.netlify.app/#terms"
                )
            }
        }
    }
    
    // MARK: - Debug Section
    
    #if DEBUG
    private var debugSection: some View {
        SettingsSection(title: "Debug", icon: "wrench.fill", color: .orange) {
            VStack(spacing: 12) {
                // Purchase testing
                VStack(alignment: .leading, spacing: 8) {
                    Text("Purchase Testing")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Button("Premium") {
                            purchaseManager.setToPremiumForTesting()
                        }
                        .debugButton(color: .green)
                        
                        Button("Free") {
                            purchaseManager.setToFreeForTesting()
                        }
                        .debugButton(color: .orange)
                        
                        Button("Reset All") {
                            purchaseManager.resetAllSimulatedPurchases()
                            leagueManager.resetAllFreeMatches()
                        }
                        .debugButton(color: .red)
                    }
                }
                
                Divider()
                
                // League access testing
                VStack(alignment: .leading, spacing: 8) {
                    Text("League Testing")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 8) {
                        Button("Use All Free") {
                            leagueManager.simulateAllFreeMatchesUsed()
                        }
                        .debugButton(color: .purple)
                        
                        Button("Reset Free") {
                            leagueManager.resetAllFreeMatches()
                        }
                        .debugButton(color: .blue)
                    }
                }
                
                Divider()
                
                // Status
                VStack(alignment: .leading, spacing: 4) {
                    Text("Status")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    Text("Purchases: \(AppConfig.PurchaseConfig.purchasesEnabled ? "Enabled" : "Disabled (Test Mode)")")
                        .font(.caption)
                    Text("Premium: \(purchaseManager.hasPremium ? "Yes" : "No")")
                        .font(.caption)
                    Text("Ad-Free: \(purchaseManager.isAdFree ? "Yes" : "No")")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // Print full status
                Button("Print Debug Status") {
                    purchaseManager.printDebugStatus()
                    leagueManager.printDebugStatus()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
        }
    }
    #endif
}

// MARK: - Supporting Views

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            
            // Content
            content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
    }
}

struct StatusBadge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.15))
            .cornerRadius(4)
    }
}

struct CurrencyRow: View {
    let code: String
    let symbol: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(symbol)
                    .font(.title3.bold())
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(code)
                        .font(.subheadline.bold())
                    Text(name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color(UIColor.tertiarySystemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SettingsRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
        .padding()
        .background(Color(UIColor.tertiarySystemBackground))
        .cornerRadius(10)
    }
}

struct SettingsLinkRow: View {
    let title: String
    let icon: String
    let url: String
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                UIApplication.shared.open(url)
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .frame(width: 24)
                Text(title)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.tertiarySystemBackground))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Debug Button Modifier

extension View {
    func debugButton(color: Color) -> some View {
        self
            .font(.caption.bold())
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color)
            .cornerRadius(6)
    }
}

// MARK: - Preview

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
