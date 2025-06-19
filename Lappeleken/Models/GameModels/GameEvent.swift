//
//  GameEvent.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import Foundation

struct GameEvent: Identifiable, Codable {
    let id = UUID()
    let player: Player
    let eventType: Bet.EventType
    let timestamp: Date
    let customEventName: String? 
    
    init(player: Player, eventType: Bet.EventType, timestamp: Date, customEventName: String? = nil) {
        self.player = player
        self.eventType = eventType
        self.timestamp = timestamp
        self.customEventName = customEventName
    }
}
