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
    let minute: Int?
    let customEventName: String?
    
    init(player: Player, eventType: Bet.EventType, timestamp: Date, minute: Int? = nil, customEventName: String? = nil) {
        self.player = player
        self.eventType = eventType
        self.timestamp = timestamp
        self.minute = minute
        self.customEventName = customEventName
    }
}
