//
//  Team.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import Foundation

struct Team: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let shortName: String
    let logoName: String
    let primaryColor: String
    
    init(id: UUID = UUID(), name: String, shortName: String, logoName: String, primaryColor: String) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.logoName = logoName
        self.primaryColor = primaryColor
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement Equatable
    static func == (lhs: Team, rhs: Team) -> Bool {
        return lhs.id == rhs.id
    }
}
