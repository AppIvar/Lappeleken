//
//  MatchModels.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

// Define match status enum
enum MatchStatus {
    case upcoming
    case inProgress
    case halftime
    case completed
    case unknown
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


