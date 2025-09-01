//
//  ContentView.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 08/05/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameSession = GameSession()
    @EnvironmentObject var notificationDelegate: NotificationDelegate
    @State private var activeGame = false
    @State private var showAssignmentView = false
    @State private var showLiveGameSetupView = false
    @State private var showSummaryView = false
    @State private var showHistoryView = false
    @State private var showSettingsView = false
    @State private var showUpgradeView = false
    @State private var showSaveGameSheet = false
    @State private var gameName = ""
    @State private var showAutoSavePrompt = false
    @State private var isLoadingGame = false
    @State private var isContinuingSavedGame = false
    @State private var notificationGameId: String?
    @State private var showNotificationGame = false

    var body: some View {
        NavigationView {
            if activeGame {
                GameView(gameSession: gameSession, shouldShowSummary: $showSummaryView)
                    .onAppear {
                        // Show save prompt when game view appears (game has started)
                        // BUT skip it if we're continuing a saved game
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            if AppPurchaseManager.shared.currentTier == .free &&
                               !gameSession.participants.isEmpty &&
                               !isContinuingSavedGame &&
                               !UserDefaults.standard.bool(forKey: "hasShownSavePromptFor\(gameSession.id.uuidString)") {
                                
                                showAutoSavePrompt = true
                                UserDefaults.standard.set(true, forKey: "hasShownSavePromptFor\(gameSession.id.uuidString)")
                            }
                            
                            // Reset the flag after checking
                            isContinuingSavedGame = false
                        }
                    }
            } else {
                HomeView()
                    .environmentObject(gameSession)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: {
                                showSettingsView = true
                            }) {
                                Image(systemName: "gear")
                                    .foregroundColor(AppDesignSystem.Colors.primary)
                            }
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showHistoryView = true
                            }) {
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(AppDesignSystem.Colors.primary)
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowAssignment"))) { _ in
                        showAssignmentView = true
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartLiveGameFlow"))) { _ in
                        showLiveGameSetupView = true
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowUpgradePrompt"))) { _ in
                        showUpgradeView = true
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartGameWithSelectedMatch"))) { _ in
                        activeGame = true
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowGameSummary"))) { _ in
                        showSummaryView = true
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowHistory"))) { _ in
                        showHistoryView = true
                    }
                    // Handle notification navigation
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("OpenGameFromNotification"))) { notification in
                        handleNotificationNavigation(notification: notification)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NavigateToGame"))) { notification in
                        handleNotificationNavigation(notification: notification)
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ContinueSavedGame"))) { notification in
                        if let userInfo = notification.userInfo,
                           let restoredGameSession = userInfo["gameSession"] as? GameSession,
                           let gameName = userInfo["gameName"] as? String {
                            
                            // Set flag to indicate we're continuing a saved game
                            isContinuingSavedGame = true
                            
                            // Replace current game session with restored one
                            gameSession.participants = restoredGameSession.participants
                            gameSession.events = restoredGameSession.events
                            gameSession.selectedPlayers = restoredGameSession.selectedPlayers
                            gameSession.availablePlayers = restoredGameSession.availablePlayers
                            gameSession.canUndoLastEvent = restoredGameSession.canUndoLastEvent
                            gameSession.bets = restoredGameSession.bets
                            
                            // Close history view immediately
                            showHistoryView = false
                            
                            // Start the game
                            activeGame = true
                            
                            print("Continued saved game: \(gameName)")
                            print("Restored \(gameSession.participants.count) participants, \(gameSession.events.count) events")
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("CloseHistoryView"))) { _ in
                        showHistoryView = false
                    }
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartNewGame"))) { _ in
                        showHistoryView = false
                    }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensure consistent behavior across devices
        .sheet(isPresented: $showAssignmentView) {
            AssignPlayersView(gameSession: gameSession)
                .onDisappear {
                    activeGame = true
                }
        }
        .sheet(isPresented: $showLiveGameSetupView) {
            LiveGameSetupView(gameSession: gameSession)
        }
        .sheet(isPresented: $showSummaryView) {
            GameSummaryView(gameSession: gameSession)
                .onDisappear {
                    gameSession.reset()
                    activeGame = false
                }
        }
        .sheet(isPresented: $showAutoSavePrompt) {
            autoSaveGamePrompt
        }
        .sheet(isPresented: $showHistoryView) {
            HistoryView()
        }
        .sheet(isPresented: $showSettingsView) {
            SettingsView()
                .environmentObject(gameSession)
        }
        .sheet(isPresented: $showUpgradeView) {
            UpgradeView()
        }
        .sheet(isPresented: $showNotificationGame) {
            notificationGameView
        }
        .alert("Save Game", isPresented: $showSaveGameSheet) {
            TextField("Game name", text: $gameName)
            
            Button("Save") {
                let finalName = gameName.isEmpty ? "Game \(Date())" : gameName
                gameSession.saveGame(name: finalName)
                gameName = ""
            }
            
            Button("Cancel", role: .cancel) {
                gameName = ""
            }
        } message: {
            Text("Enter a name for this game session")
        }
    }
    
    private func handleNotificationNavigation(notification: Notification) {
        if let userInfo = notification.userInfo,
           let gameId = userInfo["gameId"] as? String,
           let type = userInfo["type"] as? String {
            
            print("Handling notification navigation - Game: \(gameId), Type: \(type)")
            
            // Check if the game ID matches the current session
            if gameSession.id.uuidString == gameId {
                // Navigate to current game
                if !activeGame {
                    activeGame = true
                }
            } else {
                // Try to load the saved game with this ID
                let savedGames = GameHistoryManager.shared.getSavedGameSessions()
                if let savedGame = savedGames.first(where: { $0.id.uuidString == gameId }) {
                    // Load the saved game
                    loadSavedGame(savedGame)
                } else {
                    // Show notification-specific view for game updates
                    notificationGameId = gameId
                    showNotificationGame = true
                }
            }
        }
    }
    
    private func loadSavedGame(_ savedGame: SavedGameSession) {
        // Restore the game session
        if let restoredSession = savedGame.toGameSession() {
            gameSession.participants = restoredSession.participants
            gameSession.events = restoredSession.events
            gameSession.selectedPlayers = restoredSession.selectedPlayers
            gameSession.availablePlayers = restoredSession.availablePlayers
            gameSession.bets = restoredSession.bets
            gameSession.id = restoredSession.id
            
            isContinuingSavedGame = true
            activeGame = true
        }
    }
    
    private var notificationGameView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 50))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Match Update")
                    .font(AppDesignSystem.Typography.headingFont)
                
                if let gameId = notificationGameId {
                    Text("Game ID: \(gameId)")
                        .font(.caption)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Text("This game is no longer available or has ended.")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Button("OK") {
                    showNotificationGame = false
                    notificationGameId = nil
                }
                .buttonStyle(PrimaryButtonStyle())
            }
            .padding()
            .navigationTitle("Game Update")
            .navigationBarTitleDisplayMode(.inline)
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
                
                TextField("Game name (optional)", text: $gameName)
                    .padding()
                    .background(AppDesignSystem.Colors.cardBackground)
                    .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                HStack(spacing: 16) {
                    Button("Skip") {
                        showAutoSavePrompt = false
                        gameName = ""
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Save & Continue") {
                        let finalGameName = gameName.isEmpty ?
                            "Game \(Date().formatted(date: .abbreviated, time: .shortened))" :
                            gameName
                        
                        GameHistoryManager.shared.saveGameSession(gameSession, name: finalGameName)
                        
                        showAutoSavePrompt = false
                        gameName = ""
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            }
            .padding()
            .navigationTitle("Quick Save")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
