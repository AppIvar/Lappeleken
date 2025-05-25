//
//  Bet.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import Foundation

// Bet model
struct Bet: Identifiable, Codable {
    let id: UUID
    let eventType: EventType
    let amount: Double
    
    init(id: UUID = UUID(), eventType: EventType, amount: Double) {
        self.id = id
        self.eventType = eventType
        self.amount = amount
    }
    
    enum EventType: String, CaseIterable, Codable {
        case goal = "Goal"
        case assist = "Assist"
        case yellowCard = "Yellow Card"
        case redCard = "Red Card"
        case ownGoal = "Own Goal"
        case penalty = "Penalty Scored"
        case penaltyMissed = "Penalty Missed"
        case cleanSheet = "Clean Sheet"
        case custom = "Custom Event"
    }
}

