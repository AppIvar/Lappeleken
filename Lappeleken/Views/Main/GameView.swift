//
//  GameView.swift (Cleaned Up Version)
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 08/05/2025.
//

import SwiftUI

struct GameView: View {
    @ObservedObject var gameSession: GameSession
    @State private var selectedPlayer: Player? = nil
    @State private var selectedEventType: Bet.EventType? = nil
    @State private var showingEventSheet = false
    @State private var showingSubstitutionSheet = false
    @State private var showingAutoSavePrompt = false
    @State private var autoSaveGameName = ""
    @State private var showingUndoConfirmation = false

    var body: some View {
        TabView {
            participantsView
                .tabItem {
                    Label("Participants", systemImage: "person.3")
                }
            
            playersView
                .tabItem {
                    Label("Players", systemImage: "sportscourt")
                }
            
            TimelineView(gameSession: gameSession)
                .tabItem {
                    Label("Timeline", systemImage: "clock")
                }
            
            StatsView(gameSession: gameSession)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .navigationTitle("Lucky Football Slip")
        .navigationBarTitleDisplayMode(.inline)
        .accentColor(AppDesignSystem.Colors.primary)
        .sheet(isPresented: $showingEventSheet) {
            recordEventView
        }
        .sheet(isPresented: $showingSubstitutionSheet) {
            SubstitutionView(gameSession: gameSession)
        }
        .sheet(isPresented: $showingAutoSavePrompt) {
            autoSaveGamePrompt
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartGame"))) { _ in
            // Show auto-save prompt when game starts
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if AppPurchaseManager.shared.currentTier == .free {
                    showingAutoSavePrompt = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowInterstitialAfterEvent"))) { notification in
            // Handle interstitial ad after events
            if let userInfo = notification.object as? [String: Any],
               let eventCount = userInfo["eventCount"] as? Int {
                showInterstitialForEvent(eventCount: eventCount)
            }
        }
    }
    
    private var autoSaveGamePrompt: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 50))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Save Your Game?")
                    .font(AppDesignSystem.Typography.headingFont)
                
                Text("Give your game a name so you don't lose your progress. You can always save it later from the game summary.")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Game name (optional)", text: $autoSaveGameName)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                HStack(spacing: 16) {
                    Button("Skip") {
                        showingAutoSavePrompt = false
                        autoSaveGameName = ""
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Save & Continue") {
                        let finalGameName = autoSaveGameName.isEmpty ?
                            "Game \(Date().formatted(date: .abbreviated, time: .shortened))" :
                            autoSaveGameName
                        
                        GameHistoryManager.shared.saveGameSession(gameSession, name: finalGameName)
                        
                        showingAutoSavePrompt = false
                        autoSaveGameName = ""
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding()
            .navigationTitle("Quick Save")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Tab Views
    
    private var participantsView: some View {
        ScrollView {
            VStack(spacing: AppDesignSystem.Layout.standardPadding) {
                // Action buttons row with undo functionality
                HStack {
                    HStack(spacing: 10) {
                        Button(action: {
                            showingSubstitutionSheet = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                Text("Sub")
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button(action: {
                            showingEventSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Event")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        // Undo button
                        if gameSession.canUndoLastEvent {
                            Button(action: {
                                showUndoConfirmation()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.uturn.backward.circle.fill")
                                    Text("Undo")
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .foregroundColor(AppDesignSystem.Colors.error)
                        }
                    }
                    
                    Spacer()
                }
                
                ForEach(gameSession.participants) { participant in
                    ParticipantCard(participant: participant)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
        .alert("Undo Last Event", isPresented: $showingUndoConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Undo", role: .destructive) {
                gameSession.undoLastEvent()
            }
        } message: {
            if let lastEvent = gameSession.events.last {
                Text("This will undo '\(lastEvent.eventType.rawValue)' for \(lastEvent.player.name) and reverse all balance changes.")
            }
        }
    }
    
    private var playersView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                HStack {
                    Text("Assigned Players")
                        .font(AppDesignSystem.Typography.headingFont)
                    
                    Spacer()
                    
                    Button(action: {
                        showingEventSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Event")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                
                if gameSession.participants.flatMap({ $0.selectedPlayers}).isEmpty &&
                    gameSession.participants.flatMap({ $0.substitutedPlayers}).isEmpty {
                    VStack {
                        Text("No players assigned yet")
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .padding(.top, 40)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(gameSession.participants) { participant in
                        VStack(alignment: .leading) {
                            Text(participant.name)
                                .font(AppDesignSystem.Typography.subheadingFont)
                                .padding(.top)
                            
                            if participant.selectedPlayers.isEmpty && participant.substitutedPlayers.isEmpty {
                                Text("No players assigned")
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    .padding(.vertical, 8)
                            } else {
                                // Active players
                                if !participant.selectedPlayers.isEmpty {
                                    Text("Active Players")
                                        .font(AppDesignSystem.Typography.bodyFont.bold())
                                        .foregroundColor(AppDesignSystem.Colors.primary)
                                        .padding(.top, 4)
                                    
                                    ForEach(participant.selectedPlayers) { player in
                                        PlayerStatsCard(gameSession: gameSession, player: player)
                                            .padding(.vertical, 4)
                                            .id("\(player.id)-\(gameSession.events.count)")
                                    }
                                }
                                
                                // Substituted players
                                if !participant.substitutedPlayers.isEmpty {
                                    Text("Substituted Players")
                                        .font(AppDesignSystem.Typography.bodyFont.bold())
                                        .foregroundColor(AppDesignSystem.Colors.secondary)
                                        .padding(.top, 12)
                                    
                                    ForEach(participant.substitutedPlayers) { player in
                                        PlayerStatsCard(gameSession: gameSession, player: player, isSubstituted: true)
                                            .padding(.vertical, 4)
                                            .id("\(player.id)-subbed-\(gameSession.events.count)")
                                    }
                                }
                            }
                        }
                        .padding(.bottom, AppDesignSystem.Layout.standardPadding)
                    }
                }
            }
            .padding()
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
        .withBannerAd(placement: .bottom)
        .id("players-view-\(gameSession.events.count)-\(gameSession.substitutions.count)")
    }
    
    private func showUndoConfirmation() {
        showingUndoConfirmation = true
    }
    
    // MARK: - Record Event Sheet
    
    private var recordEventView: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Select Player")) {
                        if gameSession.participants.flatMap({ $0.selectedPlayers + $0.substitutedPlayers }).isEmpty {
                            Text("No players assigned yet")
                                .foregroundColor(AppDesignSystem.Colors.error)
                        } else {
                            ForEach(gameSession.participants) { participant in
                                Section(header: Text(participant.name)) {
                                    // Active players
                                    ForEach(participant.selectedPlayers) { player in
                                        playerSelectionRow(player: player)
                                    }
                                    
                                    // Including substituted players
                                    ForEach(participant.substitutedPlayers) { player in
                                        playerSelectionRow(player: player, isSubstituted: true)
                                    }
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Select Event Type")) {
                        ForEach(Bet.EventType.allCases, id: \.self) { eventType in
                            Button(action: {
                                selectedEventType = eventType
                            }) {
                                HStack {
                                    Text(eventType.rawValue)
                                    Spacer()
                                    if selectedEventType == eventType {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppDesignSystem.Colors.primary)
                                    }
                                }
                            }
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        }
                    }
                    
                    if let player = selectedPlayer, let eventType = selectedEventType {
                        Section {
                            Button("Record \(eventType.rawValue) for \(player.name)") {
                                Task { @MainActor in
                                    gameSession.recordEvent(player: player, eventType: eventType)
                                }
                                showingEventSheet = false
                                selectedPlayer = nil
                                selectedEventType = nil
                            }
                            .foregroundColor(AppDesignSystem.Colors.primary)
                        }
                    }
                }
            }
            .navigationTitle("Record Event")
            .navigationBarItems(trailing: Button("Cancel") {
                showingEventSheet = false
            })
        }
    }
    
    // Helper function for player selection row
    private func playerSelectionRow(player: Player, isSubstituted: Bool = false) -> some View {
        Button(action: {
            selectedPlayer = player
        }) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(player.name)
                            .font(.body)
                        
                        if isSubstituted {
                            Text("(Subbed Off)")
                                .font(.caption)
                                .foregroundColor(AppDesignSystem.Colors.error)
                        }
                    }
                    
                    Text("\(player.team.name) · \(player.position.rawValue)")
                        .font(.caption)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if selectedPlayer?.id == player.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
        }
        .foregroundColor(AppDesignSystem.Colors.primaryText)
        .opacity(isSubstituted ? 0.8 : 1.0)
    }
    
    private func showInterstitialForEvent(eventCount: Int) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        print("🎯 Showing interstitial ad after \(eventCount) events")
        
        AdManager.shared.showInterstitialAd(from: rootViewController) { success in
            if success {
                print("✅ Interstitial ad shown successfully after \(eventCount) events")
                AdManager.shared.trackAdImpression(type: "interstitial_event")
            } else {
                print("❌ Failed to show interstitial ad after events")
            }
        }
    }
}
