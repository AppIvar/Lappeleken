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
    
    init(id: UUID = UUID(), from: Player, to: Player, timestamp: Date, team: Team) {
        self.id = id
        self.from = from
        self.to = to
        self.timestamp = timestamp
        self.team = team
    }
}

