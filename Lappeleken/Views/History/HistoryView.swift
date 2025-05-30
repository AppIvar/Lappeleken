//
//  HistoryView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 16/05/2025.
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var savedGames: [SavedGameSession] = []
    @State private var isLoading = true
    @State private var showingGameDetail = false
    @State private var selectedGame: SavedGameSession? = nil
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    loadingView
                } else if savedGames.isEmpty {
                    emptyStateView
                } else {
                    gamesList
                }
            }
            .navigationTitle("Game History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                loadSavedGames()
            }
            .sheet(isPresented: $showingGameDetail) {
                if let game = selectedGame {
                    SavedGameDetailView(savedGame: game)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Loading game history...")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 60))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("No Saved Games")
                .font(AppDesignSystem.Typography.headingFont)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("Your saved game sessions will appear here. Start playing to create your first game history!")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button("Start New Game") {
                presentationMode.wrappedValue.dismiss()
                // Post notification to start new game
                NotificationCenter.default.post(
                    name: Notification.Name("StartNewGame"),
                    object: nil
                )
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private var gamesList: some View {
        List {
            ForEach(savedGames) { game in
                GameHistoryRow(savedGame: game)
                    .listRowBackground(AppDesignSystem.Colors.cardBackground)
                    .onTapGesture {
                        selectedGame = game
                        showingGameDetail = true
                    }
            }
            .onDelete(perform: deleteGames)
        }
        .listStyle(PlainListStyle())
        .background(AppDesignSystem.Colors.background)
    }
    
    // MARK: - Helper Methods
    
    private func loadSavedGames() {
        isLoading = true
        
        // Simulate loading delay for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Fixed: Use the correct method name
            self.savedGames = GameHistoryManager.shared.getSavedGameSessions()
            self.isLoading = false
            
            print("📚 Loaded \(self.savedGames.count) saved games")
        }
    }
    
    private func deleteGames(at offsets: IndexSet) {
        for index in offsets {
            let gameToDelete = savedGames[index]
            // Fixed: Use the correct method signature
            GameHistoryManager.shared.deleteGame(id: gameToDelete.id)
        }
        savedGames.remove(atOffsets: offsets)
    }
}

// MARK: - Game History Row (Updated with tap indication)

struct GameHistoryRow: View {
    let savedGame: SavedGameSession
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: savedGame.dateSaved)
    }
    
    private var totalEvents: Int {
        return savedGame.events.count
    }
    
    private var participantCount: Int {
        return savedGame.participants.count
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(savedGame.name)
                        .font(AppDesignSystem.Typography.subheadingFont)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                HStack(spacing: 16) {
                    Label("\(participantCount) players", systemImage: "person.2")
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Label("\(totalEvents) events", systemImage: "list.bullet")
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Spacer()
                }
                
                if let winner = getWinner() {
                    Text("Winner: \(winner)")
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.success)
                }
            }
            
            // Add chevron to indicate it's tappable
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(.vertical, 4)
    }
    
    private func getWinner() -> String? {
        guard !savedGame.participants.isEmpty else { return nil }
        
        let sortedParticipants = savedGame.participants.sorted { $0.balance > $1.balance }
        let topParticipant = sortedParticipants.first!
        
        // Only show winner if they have a positive balance
        return topParticipant.balance > 0 ? topParticipant.name : nil
    }
}

// MARK: - NEW: Saved Game Detail View

struct SavedGameDetailView: View {
    let savedGame: SavedGameSession
    @Environment(\.presentationMode) var presentationMode
    @State private var showingGameSummary = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Game Info Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text(savedGame.name)
                            .font(AppDesignSystem.Typography.titleFont)
                        
                        Text("Saved on \(formattedDate)")
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    // Participants and Final Balances
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Final Results")
                                .font(AppDesignSystem.Typography.subheadingFont)
                            
                            ForEach(savedGame.participants.sorted(by: { $0.balance > $1.balance }), id: \.id) { participant in
                                HStack {
                                    Text(participant.name)
                                        .font(AppDesignSystem.Typography.bodyFont)
                                    
                                    Spacer()
                                    
                                    Text(formatCurrency(participant.balance))
                                        .font(AppDesignSystem.Typography.bodyFont.bold())
                                        .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                                }
                            }
                        }
                    }
                    
                    // Game Statistics
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Game Statistics")
                                .font(AppDesignSystem.Typography.subheadingFont)
                            
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Participants")
                                        .font(AppDesignSystem.Typography.captionFont)
                                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    Text("\(savedGame.participants.count)")
                                        .font(AppDesignSystem.Typography.bodyFont.bold())
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .center) {
                                    Text("Events")
                                        .font(AppDesignSystem.Typography.captionFont)
                                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    Text("\(savedGame.events.count)")
                                        .font(AppDesignSystem.Typography.bodyFont.bold())
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing) {
                                    Text("Players")
                                        .font(AppDesignSystem.Typography.captionFont)
                                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    Text("\(savedGame.selectedPlayers.count)")
                                        .font(AppDesignSystem.Typography.bodyFont.bold())
                                }
                            }
                        }
                    }
                    
                    // Recent Events
                    if !savedGame.events.isEmpty {
                        CardView {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Recent Events")
                                    .font(AppDesignSystem.Typography.subheadingFont)
                                
                                ForEach(savedGame.events.suffix(5).reversed(), id: \.id) { event in
                                    HStack {
                                        Text(event.player.name)
                                            .font(AppDesignSystem.Typography.bodyFont)
                                        
                                        Text("•")
                                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                        
                                        Text(event.eventType.rawValue)
                                            .font(AppDesignSystem.Typography.bodyFont)
                                            .foregroundColor(AppDesignSystem.Colors.primary)
                                        
                                        Spacer()
                                        
                                        Text(formatTime(event.timestamp))
                                            .font(AppDesignSystem.Typography.captionFont)
                                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    }
                                    .padding(.vertical, 2)
                                }
                                
                                if savedGame.events.count > 5 {
                                    Text("... and \(savedGame.events.count - 5) more events")
                                        .font(AppDesignSystem.Typography.captionFont)
                                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                        .italic()
                                }
                            }
                        }
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Continue Game Button (NEW)
                        Button("Continue This Game") {
                            continueGame()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button("View Full Game Summary") {
                            showingGameSummary = true
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        if AppPurchaseManager.shared.currentTier == .premium {
                            Button("Export Game Summary") {
                                exportGameSummary()
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("Game Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingGameSummary) {
            SavedGameSummaryView(savedGame: savedGame)
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: savedGame.dateSaved)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func exportGameSummary() {
        // Create a temporary GameSession from saved data for PDF export
        let tempGameSession = createGameSessionFromSaved()
        
        PDFExporter.exportGameSummary(gameSession: tempGameSession) { fileURL in
            guard let url = fileURL else {
                print("Error exporting PDF")
                return
            }
            
            let activityVC = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            // Present the share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true, completion: nil)
            }
        }
    }
    
    private func createGameSessionFromSaved() -> GameSession {
        let tempSession = GameSession()
        tempSession.participants = savedGame.participants
        tempSession.events = savedGame.events
        tempSession.selectedPlayers = savedGame.selectedPlayers
        return tempSession
    }
    
    private func continueGame() {
        // Check if we should show interstitial ad for free users
        if AppPurchaseManager.shared.currentTier == .free &&
           AdManager.shared.shouldShowInterstitialForContinueGame() {
            showInterstitialThenContinueGame()
        } else {
            // Premium users or no ad needed - continue directly
            loadAndContinueGame()
        }
    }

    private func showInterstitialThenContinueGame() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            // Fallback: continue without ad
            loadAndContinueGame()
            return
        }
        
        AdManager.shared.showInterstitialAd(from: rootViewController) { success in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadAndContinueGame()
            }
        }
    }

    private func loadAndContinueGame() {
        // Create a new GameSession from the saved game data
        let restoredGameSession = GameSession()
        
        // Restore all the game state
        restoredGameSession.participants = savedGame.participants
        restoredGameSession.events = savedGame.events
        restoredGameSession.selectedPlayers = savedGame.selectedPlayers
        restoredGameSession.availablePlayers = savedGame.selectedPlayers // Use selected players as available
        
        // Enable undo if there are events
        restoredGameSession.canUndoLastEvent = !savedGame.events.isEmpty
        
        // Post notification to continue the game with restored session
        NotificationCenter.default.post(
            name: Notification.Name("ContinueSavedGame"),
            object: nil,
            userInfo: ["gameSession": restoredGameSession, "gameName": savedGame.name]
        )
        
        // Close the detail view and history view
        presentationMode.wrappedValue.dismiss()
        
        // Post another notification to close the history view
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: Notification.Name("CloseHistoryView"),
                object: nil
            )
        }
        
        print("🎮 Continuing saved game: \(savedGame.name)")
    }
}


// MARK: - Saved Game Summary View (Full screen version)

struct SavedGameSummaryView: View {
    let savedGame: SavedGameSession
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Game: \(savedGame.name)")
                        .font(AppDesignSystem.Typography.headingFont)
                        .padding(.bottom)
                    
                    // Final Balances Section
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Final Balances")
                                .font(AppDesignSystem.Typography.subheadingFont)
                            
                            ForEach(savedGame.participants.sorted(by: { $0.balance > $1.balance }), id: \.id) { participant in
                                HStack {
                                    Text(participant.name)
                                        .font(AppDesignSystem.Typography.bodyFont)
                                    
                                    Spacer()
                                    
                                    Text(formatCurrency(participant.balance))
                                        .font(AppDesignSystem.Typography.bodyFont.bold())
                                        .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    // Events Section
                    CardView {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("All Events (\(savedGame.events.count))")
                                .font(AppDesignSystem.Typography.subheadingFont)
                            
                            if savedGame.events.isEmpty {
                                Text("No events recorded in this game")
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    .italic()
                            } else {
                                ForEach(savedGame.events.sorted(by: { $0.timestamp > $1.timestamp }), id: \.id) { event in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(event.player.name)
                                                .font(AppDesignSystem.Typography.bodyFont)
                                            
                                            Text("\(event.eventType.rawValue) • \(event.player.team.name)")
                                                .font(AppDesignSystem.Typography.captionFont)
                                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(formatTime(event.timestamp))
                                            .font(AppDesignSystem.Typography.captionFont)
                                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Game Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


// MARK: - GameHistoryManager Extension

extension GameHistoryManager {
    func getAllSavedGames() -> [SavedGameSession] {
        // This method calls the existing getSavedGameSessions() to avoid conflicts
        return getSavedGameSessions()
    }
    
    func deleteSavedGameSession(_ gameId: UUID) {
        // This method calls the existing deleteGameSession to avoid conflicts
        deleteGameSession(gameId)
    }
    
    func saveNewGameSession(_ gameSession: GameSession, name: String) {
        // This method calls the existing saveGameSession to avoid conflicts
        saveGameSession(gameSession, name: name)
    }
}
