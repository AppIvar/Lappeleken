//
//  Player.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import Foundation
import SwiftUI

// Enhanced Player model with better stats tracking
struct Player: Identifiable, Codable, Equatable, Hashable {
    var id = UUID()
    var apiId: String?
    var name: String
    var team: Team
    var position: Position
    var substitutionStatus: SubstitutionStatus = .active
    
    // Stats
    var goals: Int = 0
    var assists: Int = 0
    var yellowCards: Int = 0
    var redCards: Int = 0
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    enum Position: String, CaseIterable, Codable {
        case goalkeeper = "Goalkeeper"
        case defender = "Defender"
        case midfielder = "Midfielder"
        case forward = "Forward"
    }
    
    enum SubstitutionStatus: Codable, Equatable {
        case active
        case substitutedOn(timestamp: Date)
        case substitutedOff(timestamp: Date)
        
        // Custom coding for enum with associated values
        enum CodingKeys: String, CodingKey {
            case type, timestamp
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .active:
                try container.encode("active", forKey: .type)
            case .substitutedOn(let timestamp):
                try container.encode("substitutedOn", forKey: .type)
                try container.encode(timestamp, forKey: .timestamp)
            case .substitutedOff(let timestamp):
                try container.encode("substitutedOff", forKey: .type)
                try container.encode(timestamp, forKey: .timestamp)
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            
            switch type {
            case "active":
                self = .active
            case "substitutedOn":
                let timestamp = try container.decode(Date.self, forKey: .timestamp)
                self = .substitutedOn(timestamp: timestamp)
            case "substitutedOff":
                let timestamp = try container.decode(Date.self, forKey: .timestamp)
                self = .substitutedOff(timestamp: timestamp)
            default:
                self = .active
            }
        }
    }
    
    // Conform to Equatable
    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Create a copy of the player with merged stats
    func mergeStats(from player: Player) -> Player {
        var updatedPlayer = self
        updatedPlayer.goals += player.goals
        updatedPlayer.assists += player.assists
        updatedPlayer.yellowCards += player.yellowCards
        updatedPlayer.redCards += player.redCards
        return updatedPlayer
    }
}
