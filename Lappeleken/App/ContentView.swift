//
//  ContentView.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 08/05/2025.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var gameSession = GameSession()
    @State private var activeGame = false
    @State private var showAssignmentView = false
    @State private var showLiveGameSetupView = false
    @State private var showSummaryView = false
    @State private var showHistoryView = false
    @State private var showSettingsView = false
    @State private var showUpgradeView = false
    @State private var showSaveGameSheet = false
    @State private var gameName = ""
    
    var body: some View {
        NavigationView {
            if activeGame {
                GameView(gameSession: gameSession)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Save") {
                                showSaveGameSheet = true
                            }
                        }
                        
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button("Settings") {
                                showSettingsView = true
                            }
                            
                            Button("End Game") {
                                showSummaryView = true
                            }
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
                    .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartNewGame"))) { _ in
                        // Handle start new game from history empty state
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
