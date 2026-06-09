//
//  MatchModels.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

// MARK: - MatchStatus

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

// MARK: - Match

struct Match: Identifiable, Codable, Hashable {
    let id: String
    let homeTeam: Team
    let awayTeam: Team
    let startTime: Date
    let status: MatchStatus
    let competition: Competition
    /// Final/current score when available (e.g. finished matches in the list).
    /// Defaults to nil so existing Match(...) call sites stay source-compatible.
    var score: MatchScore? = nil

    /// Convenience full-time score accessors (mirror MatchDetail's).
    var homeScore: Int { score?.fullTime?.home ?? 0 }
    var awayScore: Int { score?.fullTime?.away ?? 0 }

    // MARK: - Hashable Conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Match, rhs: Match) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Competition

struct Competition: Identifiable, Codable {
    let id: String
    let name: String
    let code: String
    
    init(id: String, name: String, code: String) {
        self.id = id
        self.name = name
        self.code = code
    }
}

// MARK: - MatchDetail

struct MatchDetail: Codable {
    let match: Match
    let venue: String?
    let attendance: Int?
    let referee: String?
    
    // Score data
    let score: MatchScore?
    
    // Live match data
    let minute: Int?
    let injuryTime: Int?
    
    // Team statistics
    let homeStatistics: TeamStatistics?
    let awayStatistics: TeamStatistics?
    
    // Computed properties for backwards compatibility
    var homeScore: Int {
        score?.fullTime?.home ?? 0
    }
    
    var awayScore: Int {
        score?.fullTime?.away ?? 0
    }
}

struct MatchScore: Codable {
    let winner: String?
    let duration: String?
    let fullTime: ScoreValues?
    let halfTime: ScoreValues?
    
    struct ScoreValues: Codable {
        let home: Int?
        let away: Int?
    }
}

struct TeamStatistics: Codable {
    let cornerKicks: Int?
    let freeKicks: Int?
    let goalKicks: Int?
    let offsides: Int?
    let fouls: Int?
    let ballPossession: Int?
    let saves: Int?
    let throwIns: Int?
    let shots: Int?
    let shotsOnGoal: Int?
    let shotsOffGoal: Int?
    let yellowCards: Int?
    let yellowRedCards: Int?
    let redCards: Int?
    
    enum CodingKeys: String, CodingKey {
        case cornerKicks = "corner_kicks"
        case freeKicks = "free_kicks"
        case goalKicks = "goal_kicks"
        case offsides, fouls
        case ballPossession = "ball_possession"
        case saves
        case throwIns = "throw_ins"
        case shots
        case shotsOnGoal = "shots_on_goal"
        case shotsOffGoal = "shots_off_goal"
        case yellowCards = "yellow_cards"
        case yellowRedCards = "yellow_red_cards"
        case redCards = "red_cards"
    }
}

// MARK: - MatchEvent

struct MatchEvent: Identifiable, Codable {
    let id: String
    let type: String // goal, assist, yellow_card, etc.
    let playerId: String
    let playerName: String?
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
