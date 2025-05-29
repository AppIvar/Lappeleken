//
//  SettingsView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 09/05/2025.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var gameSession: GameSession
    @AppStorage("selectedCurrency") private var selectedCurrency = "EUR"
    @AppStorage("currencySymbol") private var currencySymbol = "€"
    @AppStorage("isLiveMode") private var isLiveMode = false
    
    @State private var showingUpgradeView = false
    @State private var showingLiveSetupInfo = false
    @State private var showingMatchSelection = false
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var purchaseManager = AppPurchaseManager.shared
    
    private let currencies = [
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("NOK", "kr", "Norwegian Krone"),
        ("SEK", "kr", "Swedish Krona"),
        ("DKK", "kr", "Danish Krone")
    ]
    
    // Computed properties to break up complex expressions
    private var currentModeIcon: String {
        return isLiveMode ? "globe" : "gamecontroller.fill"
    }
    
    private var currentModeText: String {
        return isLiveMode ? "Live Mode" : "Manual Mode"
    }
    
    private var remainingFreeMatches: Int {
        let used = UserDefaults.standard.integer(forKey: "usedLiveMatchCount")
        return max(0, AppConfig.maxFreeMatches - used)
    }
    
    var body: some View {
        NavigationView {
            List {
                // Game Mode Section
                gameModeSection
                
                // Premium Features Section
                premiumFeaturesSection
                
                // Currency Settings Section
                currencySettingsSection
                
                // About Section
                aboutSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingUpgradeView) {
                UpgradeView()
            }
            .sheet(isPresented: $showingLiveSetupInfo) {
                LiveModeInfoView(onGetStarted: {
                    NotificationCenter.default.post(
                        name: Notification.Name("StartLiveGameFlow"),
                        object: nil
                    )
                })
            }
            .sheet(isPresented: $showingMatchSelection) {
                MatchSelectionView(gameSession: gameSession)
            }
        }
        .withBannerAd(placement: .bottom)
    }
    
    // MARK: - View Components
    
    private var gameModeSection: some View {
        Section(header: Text("Game Mode")) {
            HStack {
                Image(systemName: currentModeIcon)
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text(currentModeText)
                    .font(AppDesignSystem.Typography.bodyFont)
                
                Spacer()
                
                Text("Current")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if isLiveMode {
                currentMatchButton
                
                Button(action: {
                    showingLiveSetupInfo = true
                }) {
                    Text("About Live Mode")
                        .foregroundColor(AppDesignSystem.Colors.secondary)
                }
            }
        }
    }
    
    private var currentMatchButton: some View {
        Button(action: {
            showingMatchSelection = true
        }) {
            HStack {
                if let selectedMatch = gameSession.selectedMatch {
                    VStack(alignment: .leading) {
                        Text("Current Match")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("\(selectedMatch.homeTeam.name) vs \(selectedMatch.awayTeam.name)")
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                    }
                } else {
                    Text("Select Match")
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
    
    private var premiumFeaturesSection: some View {
        Section(header: Text("Premium Features")) {
            upgradeButton
            
            if purchaseManager.currentTier == .free {
                freeMatchesInfo
            }
            
            if purchaseManager.currentTier != .free {
                Button(action: {
                    Task {
                        await purchaseManager.restorePurchases()
                    }
                }) {
                    Text("Restore Purchases")
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
        }
    }
    
    private var upgradeButton: some View {
        Button(action: {
            showingUpgradeView = true
        }) {
            HStack {
                if purchaseManager.currentTier == .free {
                    Label("Upgrade to Premium", systemImage: "star.circle")
                        .foregroundColor(AppDesignSystem.Colors.primary)
                } else {
                    let planName = purchaseManager.currentTier.displayName
                    Label("Current Plan: \(planName)", systemImage: "checkmark.seal.fill")
                        .foregroundColor(AppDesignSystem.Colors.success)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
    
    private var freeMatchesInfo: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Free Live Matches")
                    .font(AppDesignSystem.Typography.bodyFont)
                
                Text("Remaining: \(remainingFreeMatches)/\(AppConfig.maxFreeMatches)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var currencySettingsSection: some View {
        Section(header: Text("Currency Settings")) {
            ForEach(currencies, id: \.0) { currency in
                currencyRow(for: currency)
            }
        }
    }
    
    private func currencyRow(for currency: (String, String, String)) -> some View {
        Button(action: {
            selectedCurrency = currency.0
            currencySymbol = currency.1
        }) {
            HStack {
                Text("\(currency.1) \(currency.0)")
                    .font(AppDesignSystem.Typography.bodyFont)
                
                Text("(\(currency.2))")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Spacer()
                
                if selectedCurrency == currency.0 {
                    Image(systemName: "checkmark")
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
        }
        .foregroundColor(AppDesignSystem.Colors.primaryText)
    }
    
    private var aboutSection: some View {
        Section(header: Text("About")) {
            HStack {
                Text("Version")
                Spacer()
                Text("1.0.0")
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Link(destination: URL(string: "https://football-data.org")!) {
                HStack {
                    Text("Data Provided By")
                    Spacer()
                    Text("Football-Data.org")
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
            
            Link(destination: URL(string: "https://lappeleken.com/privacy")!) {
                Text("Privacy Policy")
            }
            
            Link(destination: URL(string: "https://lappeleken.com/terms")!) {
                Text("Terms of Service")
            }
        }
    }
}

// MARK: - Live Mode Info View

struct LiveModeInfoView: View {
    @Environment(\.presentationMode) var presentationMode
    var onGetStarted: () -> Void
    
    private var remainingFreeMatches: Int {
        let used = UserDefaults.standard.integer(forKey: "usedLiveMatchCount")
        return max(0, AppConfig.maxFreeMatches - used)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("About Live Mode")
                        .font(AppDesignSystem.Typography.headingFont)
                    
                    Text("Live Mode connects your game to real football matches happening now. Here's how it works:")
                        .font(AppDesignSystem.Typography.bodyFont)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        featureItem(
                            icon: "sportscourt.fill",
                            title: "Select a Match",
                            description: "Choose from live or upcoming matches from major leagues."
                        )
                        
                        featureItem(
                            icon: "person.2.fill",
                            title: "Set Up Participants",
                            description: "Add the people who will be participating in your game."
                        )
                        
                        featureItem(
                            icon: "scalemass.fill",
                            title: "Configure Bets",
                            description: "Set your bet amounts for different types of events."
                        )
                        
                        featureItem(
                            icon: "person.crop.circle.badge.checkmark",
                            title: "Select Players",
                            description: "Choose football players from the match to include in your game."
                        )
                        
                        featureItem(
                            icon: "bell.fill",
                            title: "Real-time Updates",
                            description: "Goals, cards, and other events are automatically recorded as they happen."
                        )
                        
                        featureItem(
                            icon: "arrow.left.arrow.right",
                            title: "Automatic Substitutions",
                            description: "When a player is substituted in the real match, the same happens in your game."
                        )
                    }
                    .padding(.vertical)
                    
                    if AppPurchaseManager.shared.currentTier == .free {
                        freeModeInfoCard
                    }
                    
                    Text("Note: Live Mode requires an internet connection and uses data. Updates may be delayed by 1-2 minutes from the actual match.")
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Button("Get Started") {
                        presentationMode.wrappedValue.dismiss()
                        onGetStarted()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding()
            }
            .navigationTitle("Live Mode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private var freeModeInfoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Free Mode Limitations")
                .font(AppDesignSystem.Typography.subheadingFont)
                .foregroundColor(AppDesignSystem.Colors.primary)
            
            Text("You can follow up to \(AppConfig.maxFreeMatches) live matches in free mode.")
                .font(AppDesignSystem.Typography.bodyFont)
            
            Text("Remaining matches: \(remainingFreeMatches)")
                .font(AppDesignSystem.Typography.bodyFont.bold())
                .foregroundColor(AppDesignSystem.Colors.primary)
            
            Text("Upgrade to premium to get unlimited matches and the ability to follow multiple matches simultaneously.")
                .font(AppDesignSystem.Typography.captionFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding()
        .background(AppDesignSystem.Colors.primary.opacity(0.1))
        .cornerRadius(AppDesignSystem.Layout.cornerRadius)
    }
    
    private func featureItem(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppDesignSystem.Colors.primary)
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppDesignSystem.Typography.subheadingFont)
                
                Text(description)
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
}


