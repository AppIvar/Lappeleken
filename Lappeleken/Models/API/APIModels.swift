//
//  APIModels.swift
//  Lucky Football Slip
//
//  Clean API models based on football-data.org v4 documentation
//

import Foundation

// MARK: - Core API Response Models

struct MatchesResponse: Codable {
    let matches: [APIMatch]
    let count: Int?
    
    enum CodingKeys: String, CodingKey {
        case matches, count
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        do {
            matches = try container.decode([APIMatch].self, forKey: .matches)
        } catch {
            print("Could not decode matches: \(error)")
            matches = []
        }
        
        count = try container.decodeIfPresent(Int.self, forKey: .count)
    }
}

struct CompetitionsResponse: Codable {
    let competitions: [APICompetition]
}

struct TeamResponse: Codable {
    let id: Int
    let name: String
    let shortName: String?
    let crest: String?
    let squad: [APIPlayer]
    let coach: APICoach?
    
    func toTeamSquad() -> TeamSquad {
        let team = Team(
            name: name,
            shortName: shortName ?? String(name.prefix(3)).uppercased(),
            logoName: "team_logo",
            primaryColor: "#1a73e8"
        )
        
        let players = squad.map { $0.toAppModel(team: team) }
        
        return TeamSquad(
            team: team,
            players: players,
            coach: coach?.toAppModel()
        )
    }
}

// MARK: - Match Models

struct APIMatch: Codable {
    let id: Int
    let competition: APICompetition
    let utcDate: String
    let status: String
    let homeTeam: APITeam
    let awayTeam: APITeam
    let score: APIScore
    
    // Optional lineup data (only present with proper headers)
    let goals: [APIGoal]?
    let bookings: [APIBooking]?
    let substitutions: [APISubstitution]?
    
    func toAppModel() -> Match {
        let date = DateUtility.iso8601Full.date(from: utcDate) ?? Date()
        
        return Match(
            id: "\(id)",
            homeTeam: homeTeam.toAppModel(),
            awayTeam: awayTeam.toAppModel(),
            startTime: date,
            status: matchStatus(from: status),
            competition: competition.toAppModel()
        )
    }
    
    func toMatchWithEvents() -> MatchWithEvents {
        let match = toAppModel()
        var events: [MatchEvent] = []
        
        // Convert goals to events
        if let goals = goals {
            for goal in goals {
                events.append(MatchEvent(
                    id: "\(goal.minute)_goal_\(goal.scorer.id)",
                    type: goal.type.lowercased(),
                    playerId: "\(goal.scorer.id)",
                    playerName: goal.scorer.name,
                    minute: goal.minute,
                    teamId: "\(goal.team.id)",
                    playerOffId: nil,
                    playerOnId: goal.assist?.id != nil ? "\(goal.assist!.id)" : nil
                ))
            }
        }
        
        // Convert bookings to events
        if let bookings = bookings {
            for booking in bookings {
                events.append(MatchEvent(
                    id: "\(booking.minute)_\(booking.card.lowercased())_\(booking.player.id)",
                    type: booking.card == "YELLOW" ? "yellow_card" : "red_card",
                    playerId: "\(booking.player.id)",
                    playerName: booking.player.name,
                    minute: booking.minute,
                    teamId: "\(booking.team.id)",
                    playerOffId: nil,
                    playerOnId: nil
                ))
            }
        }
        
        // Convert substitutions to events
        if let substitutions = substitutions {
            for sub in substitutions {
                events.append(MatchEvent(
                    id: "\(sub.minute)_sub_\(sub.playerOut.id)",
                    type: "substitution",
                    playerId: "\(sub.playerOut.id)",
                    playerName: sub.playerOut.name,
                    minute: sub.minute,
                    teamId: "\(sub.team.id)",
                    playerOffId: "\(sub.playerOut.id)",
                    playerOnId: "\(sub.playerIn.id)"
                ))
            }
        }
        
        return MatchWithEvents(
            match: match,
            events: events,
            homeLineup: nil,
            awayLineup: nil
        )
    }
    
    private func matchStatus(from status: String) -> MatchStatus {
        switch status.uppercased() {
        case "SCHEDULED", "TIMED":
            return .upcoming
        case "LIVE", "IN_PLAY":
            return .inProgress
        case "PAUSED":
            return .halftime
        case "FINISHED":
            return .completed
        case "POSTPONED":
            return .postponed
        case "CANCELLED":
            return .cancelled
        case "SUSPENDED":
            return .suspended
        default:
            print("⚠️ Unknown match status: \(status)")
            return .unknown
        }
    }
}

// MARK: - Team Models

struct APITeam: Codable {
    let id: Int
    let name: String
    let shortName: String?
    let crest: String?
    
    // Squad data (from team endpoint)
    let squad: [APIPlayer]?
    
    // Lineup data (from match endpoint with lineup headers)
    let formation: String?
    let lineup: [APILineupPlayer]?
    let bench: [APILineupPlayer]?
    let coach: APICoach?
    
    func toAppModel() -> Team {
        return Team(
            id: UUID(uuidString: "00000000-0000-0000-0000-\(String(format: "%012d", id))") ?? UUID(),
            name: name,
            shortName: shortName ?? name.prefix(3).uppercased(),
            logoName: "team_logo",
            primaryColor: "#1a73e8"
        )
    }
    
    func toTeamLineup() -> TeamLineup? {
        guard let lineup = lineup else { return nil }
        
        let team = toAppModel()
        
        return TeamLineup(
            team: team,
            formation: formation,
            startingXI: lineup.map { $0.toAppModel(team: team) },
            substitutes: (bench ?? []).map { $0.toAppModel(team: team) },
            coach: coach?.toAppModel()  // This will safely handle nil coaches
        )
    }
}

// MARK: - Player Models

struct APIPlayer: Codable {
    let id: Int
    let name: String
    let position: String?
    let shirtNumber: Int?
    let dateOfBirth: String?
    let nationality: String?
    
    func toAppModel(team: Team) -> Player {
        let playerPosition: Player.Position
        switch position?.lowercased() {
        case "goalkeeper":
            playerPosition = .goalkeeper
        case "defence", "center-back", "centre-back", "right-back", "left-back":
            playerPosition = .defender
        case "midfield", "central midfield", "defensive midfield", "attacking midfield", "right winger", "left winger":
            playerPosition = .midfielder
        case "offence", "centre-forward", "striker":
            playerPosition = .forward
        default:
            playerPosition = .midfielder
        }
        
        return Player(
            apiId: String(id),
            name: name,
            team: team,
            position: playerPosition
        )
    }
}

struct APILineupPlayer: Codable {
    let id: Int
    let name: String
    let position: String?
    let shirtNumber: Int?
    
    func toAppModel(team: Team) -> Player {
        let playerPosition: Player.Position
        switch position?.lowercased() {
        case "goalkeeper":
            playerPosition = .goalkeeper
        case "centre-back", "center-back", "right-back", "left-back":
            playerPosition = .defender
        case "central midfield", "defensive midfield", "attacking midfield", "right winger", "left winger":
            playerPosition = .midfielder
        case "centre-forward":
            playerPosition = .forward
        default:
            playerPosition = .midfielder
        }
        
        return Player(
            apiId: String(id),
            name: name,
            team: team,
            position: playerPosition
        )
    }
}

// MARK: - Event Models

struct APIGoal: Codable {
    let minute: Int
    let type: String // REGULAR, PENALTY, OWN_GOAL
    let team: APITeamBasic
    let scorer: APIPlayerBasic
    let assist: APIPlayerBasic?
}

struct APIBooking: Codable {
    let minute: Int
    let team: APITeamBasic
    let player: APIPlayerBasic
    let card: String // YELLOW, RED
}

struct APISubstitution: Codable {
    let minute: Int
    let team: APITeamBasic
    let playerIn: APIPlayerBasic
    let playerOut: APIPlayerBasic
}

// MARK: - Basic Models

struct APIPlayerBasic: Codable {
    let id: Int
    let name: String
}

struct APITeamBasic: Codable {
    let id: Int
    let name: String
}

struct APICompetition: Codable {
    let id: Int
    let name: String
    let code: String
    
    func toAppModel() -> Competition {
        return Competition(
            id: "\(id)",
            name: name,
            code: code
        )
    }
}

struct APICoach: Codable {
    let id: Int?
    let name: String?
    let nationality: String?
    
    func toAppModel() -> Coach {
        return Coach(
            id: "\(id ?? 0)",
            name: name ?? "Unknown Coach",
            nationality: nationality
        )
    }
}

struct APIScore: Codable {
    let fullTime: ScoreDetail?
    let halfTime: ScoreDetail?
    
    struct ScoreDetail: Codable {
        let home: Int?
        let away: Int?
    }
}

// MARK: - App Models (unchanged)

struct Lineup {
    let homeTeam: TeamLineup
    let awayTeam: TeamLineup
}

struct TeamLineup {
    let team: Team
    let formation: String?
    let startingXI: [Player]
    let substitutes: [Player]
    let coach: Coach?
}

struct Coach {
    let id: String
    let name: String
    let nationality: String?
}

struct MatchWithEvents {
    let match: Match
    let events: [MatchEvent]
    let homeLineup: TeamLineup?
    let awayLineup: TeamLineup?
}

struct TeamSquad {
    let team: Team
    let players: [Player]
    let coach: Coach?
}
