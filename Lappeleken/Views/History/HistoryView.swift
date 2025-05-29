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
            // Try to load from GameHistoryManager using the correct method name
            self.savedGames = GameHistoryManager.shared.getSavedGameSessions()
            self.isLoading = false
            
            print("📚 Loaded \(self.savedGames.count) saved games")
        }
    }
    
    private func deleteGames(at offsets: IndexSet) {
        for index in offsets {
            let gameToDelete = savedGames[index]
            GameHistoryManager.shared.deleteGameSession(gameToDelete.id)
        }
        savedGames.remove(atOffsets: offsets)
    }
}

// MARK: - Game History Row

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

// MARK: - SavedGameSession Model

struct SavedGameSession: Identifiable, Codable {
    let id: UUID
    let name: String
    let dateSaved: Date
    let participants: [Participant]
    let events: [GameEvent]
    let selectedPlayers: [Player]
    
    init(from gameSession: GameSession, name: String) {
        self.id = UUID()
        self.name = name
        self.dateSaved = Date()
        self.participants = gameSession.participants
        self.events = gameSession.events
        self.selectedPlayers = gameSession.selectedPlayers
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
