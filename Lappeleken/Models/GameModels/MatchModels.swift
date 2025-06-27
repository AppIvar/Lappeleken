//
//  MatchModels.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

enum MatchStatus: String, Codable, CaseIterable {
    case upcoming = "SCHEDULED"
    case inProgress = "IN_PLAY"
    case halftime = "HALFTIME"
    case completed = "COMPLETED"
    case finished = "FINISHED"      // ADDED - alias for completed
    case postponed = "POSTPONED"    // ADDED
    case cancelled = "CANCELLED"    // ADDED
    case paused = "PAUSED"          // ADDED
    case suspended = "SUSPENDED"    // ADDED
    case unknown = "UNKNOWN"
    
    var displayName: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .inProgress: return "Live"
        case .halftime: return "Half Time"
        case .completed, .finished: return "Finished"
        case .postponed: return "Postponed"
        case .cancelled: return "Cancelled"
        case .paused: return "Paused"
        case .suspended: return "Suspended"
        case .unknown: return "Unknown"
        }
    }
    
    var isLive: Bool {
        return self == .inProgress || self == .paused || self == .halftime
    }
    
    var isActive: Bool {
        return self == .inProgress || self == .halftime || self == .paused
    }
}

// Basic match structure
struct Match: Identifiable {
    let id: String
    let homeTeam: Team
    let awayTeam: Team
    let startTime: Date
    let status: MatchStatus
    let competition: Competition
}

// Competition model
struct Competition: Identifiable {
    let id: String
    let name: String
    let code: String
    
    init(id: String, name: String, code: String) {
        self.id = id
        self.name = name
        self.code = code
    }
}

// Match detail with additional information
struct MatchDetail {
    let match: Match
    let venue: String?
    let attendance: Int?
    let referee: String?
    let homeScore: Int
    let awayScore: Int
}

// Match event for tracking goals, cards, etc.
struct MatchEvent: Identifiable {
    let id: String
    let type: String // goal, assist, yellow_card, etc.
    let playerId: String
    let playerName: String
    let minute: Int
    let teamId: String
    
    // For substitutions
    let playerOffId: String?
    let playerOnId: String?
    
    init(id: String, type: String, playerId: String, playerName: String, minute: Int, teamId: String, playerOffId: String? = nil, playerOnId: String? = nil) {
        self.id = id
        self.type = type
        self.playerId = playerId
        self.playerName = playerName
        self.minute = minute
        self.teamId = teamId
        self.playerOffId = playerOffId
        self.playerOnId = playerOnId
    }
}


