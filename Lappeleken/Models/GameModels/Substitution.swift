//
//  Substitution.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import Foundation

struct Substitution: Identifiable, Codable {
    let id: UUID
    let from: Player
    let to: Player
    let timestamp: Date
    let team: Team
    let minute: Int?
    
    init(id: UUID = UUID(), from: Player, to: Player, timestamp: Date, team: Team, minute: Int? = nil) {
        self.id = id
        self.from = from
        self.to = to
        self.timestamp = timestamp
        self.team = team
        self.minute = minute
    }
}

