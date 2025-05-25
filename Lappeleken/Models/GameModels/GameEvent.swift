//
//  GameEvent.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import Foundation

// Game event model
struct GameEvent: Identifiable, Codable {
    let id: UUID
    let player: Player
    let eventType: Bet.EventType
    let timestamp: Date
    
    init(id: UUID = UUID(), player: Player, eventType: Bet.EventType, timestamp: Date) {
        self.id = id
        self.player = player
        self.eventType = eventType
        self.timestamp = timestamp
    }
}
