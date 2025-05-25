//
//  GameHistoryManager.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 16/05/2025.
//

import Foundation
import Combine

class GameHistoryManager: ObservableObject {
    static let shared = GameHistoryManager()
    
    @Published var savedGames: [SavedGame] = []
    
    private init() {
        loadSavedGames()
    }
    
    struct SavedGame: Identifiable, Codable {
        let id: UUID
        let name: String
        let date: Date
        let participants: [String] // Just names for the list view
        let gameData: Data // Serialized GameSession
        
        var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
    }
    
    func saveGame(_ gameSession: GameSession, name: String) {
        let encoder = JSONEncoder()
        
        do {
            // Serialize the game session
            let gameData = try encoder.encode(gameSession)
            
            // Create a saved game record
            let savedGame = SavedGame(
                id: UUID(),
                name: name,
                date: Date(),
                participants: gameSession.participants.map{ $0.name },
                gameData: gameData
            )
            
            // Add to the list
            savedGames.append(savedGame)
            
            // Save to persisten storage
            saveToStorage()
            
            print("Game saved successfully: \(name)")
        } catch {
            print("Failed to save game: \(error.localizedDescription)")
        }
    }
    
    func loadGame(id: UUID) -> GameSession? {
        guard let savedGame = savedGames.first(where: { $0.id == id }) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        
        do {
            let gameSession = try decoder.decode(GameSession.self, from: savedGame.gameData)
            return gameSession
        } catch {
            print("Failed to load game: \(error.localizedDescription)")
            return nil
        }
    }
    
    func deleteGame(id: UUID) {
        savedGames.removeAll { $0.id == id }
        saveToStorage()
    }
    
    private func saveToStorage() {
        let encoder = JSONEncoder()
        
        do {
            let data = try encoder.encode(savedGames)
            UserDefaults.standard.set(data, forKey: "savedGames")
        } catch {
            print("Failed to save to storage: \(error.localizedDescription)")
        }
    }
    
    private func loadSavedGames() {
        guard let data = UserDefaults.standard.data(forKey: "savedGames") else {
            return
        }
        
        let decoder = JSONDecoder()
        
        do {
            savedGames = try decoder.decode([SavedGame].self, from: data)
        } catch {
            print("Failed to load saved games: \(error.localizedDescription)")
        }
    }
}
