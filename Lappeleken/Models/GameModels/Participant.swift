//
//  Participant.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import Foundation

// Game participant model
struct Participant: Identifiable, Codable {
    let id: UUID
    let name: String
    var selectedPlayers: [Player] = []
    var substitutedPlayers: [Player] = []
    var balance: Double = 0.0

    
    init(id: UUID = UUID(), name: String, selectedPlayers: [Player] = [], substitutedPlayers: [Player] = [], balance: Double = 0.0) {
        self.id = id
        self.name = name
        self.selectedPlayers = selectedPlayers
        self.substitutedPlayers = substitutedPlayers
        self.balance = balance
    }
}


