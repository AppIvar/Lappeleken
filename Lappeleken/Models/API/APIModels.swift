//
//  CoreDataModel.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 08/05/2025.
//

import Foundation

// API client for future live functionality
class FootballAPIClient {
    // API endpoints
    private enum Endpoint {
        case matches
        case players
        case events(matchId: String)
        
        var url: URL? {
            switch self {
            case .matches:
                return URL(string: "https://api.football-data.org/v4/matches")
            case .players:
                return URL(string: "https://api.football-data.org/v4/players")
            case .events(let matchId):
                return URL(string: "https://api.football-data.org/v4/matches/\(matchId)/events")
            }
        }
    }
    
    // API key (will be provided later)
    private var apiKey: String?
    
    // Fetch matches
    func fetchMatches(completion: @escaping (Result<[APIMatch], Error>) -> Void) {
        // This will be implemented when we add the live functionality
        // For now, it's just a placeholder
    }
    
    // Fetch players
    func fetchPlayers(teamId: String, completion: @escaping (Result<[Player], Error>) -> Void) {
        // This will be implemented when we add the live functionality
        // For now, it's just a placeholder
    }
    
    // Fetch live events
    func fetchEvents(matchId: String, completion: @escaping (Result<[LiveEvent], Error>) -> Void) {
        // This will be implemented when we add the live functionality
        // For now, it's just a placeholder
    }
}

// Models for API responses


struct APITeam: Codable {
    let id: Int
    let name: String
    let shortName: String?
    let crest: String?
    let squad: [APIPlayer]?
    
    func toAppModel() -> Team {
        return Team(
            id: UUID(), // Generate a new UUID for the team
            name: name,
            shortName: shortName ?? name.prefix(3).uppercased(),
            logoName: "team_logo", // Default logo name
            primaryColor: "#1a73e8" // Default color
        )
    }
}

struct APILineup: Codable {
    let homeTeam: APITeamLineup
    let awayTeam: APITeamLineup
    
    func toAppModel() -> Lineup {
        return Lineup(
            homeTeam: homeTeam.toAppModel(),
            awayTeam: awayTeam.toAppModel()
        )
    }
}

struct APITeamLineup: Codable {
    let team: APITeam
    let formation: String?
    let startXI: [APILineupPlayer]
    let substitutes: [APILineupPlayer]
    let coach: APICoach?
    
    func toAppModel() -> TeamLineup {
        return TeamLineup(
            team: team.toAppModel(),
            formation: formation,
            startingXI: startXI.map { $0.player.toAppModel(team: team.toAppModel()) },
            substitutes: substitutes.map { $0.player.toAppModel(team: team.toAppModel()) },
            coach: coach?.toAppModel()
        )
    }
}

struct APILineupPlayer: Codable {
    let player: APIPlayer
    let position: String?
    
    enum CodingKeys: String, CodingKey {
        case player
        case position
    }
}

struct APICoach: Codable {
    let id: Int
    let name: String
    let countryOfBirth: String?
    let nationality: String?
    
    func toAppModel() -> Coach {
        return Coach(
            id: "\(id)",
            name: name,
            nationality: nationality
        )
    }
}

struct APIMatchWithEvents: Codable {
    let match: APIMatch
    let goals: [APIGoal]?
    let bookings: [APIBooking]?
    let substitutions: [APISubstitution]?
    
    func toAppModel() -> MatchWithEvents {
        let matchModel = match.toAppModel()
        
        // Convert API events to app model events
        var events: [MatchEvent] = []
        
        // Add goals
        if let goals = goals {
            for goal in goals {
                events.append(MatchEvent(
                    id: "\(goal.id)",
                    type: goal.type,
                    playerId: "\(goal.scorer.id)",
                    playerName: goal.scorer.name,
                    minute: goal.minute,
                    teamId: "\(goal.team.id)",
                    playerOffId: nil,
                    playerOnId: goal.assistId != nil ? "\(goal.assistId!)" : nil
                ))
            }
        }
        
        // Add bookings
        if let bookings = bookings {
            for booking in bookings {
                events.append(MatchEvent(
                    id: "\(booking.id)",
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
        
        // Add substitutions
        if let substitutions = substitutions {
            for sub in substitutions {
                events.append(MatchEvent(
                    id: "\(sub.id)",
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
            match: matchModel,
            events: events,
            homeLineup: nil,  // These would be populated separately
            awayLineup: nil
        )
    }
}

struct APIGoal: Codable {
    let id: Int
    let minute: Int
    let team: APITeam
    let scorer: APIPlayer
    let assistId: Int?
    let type: String // REGULAR_GOAL, OWN_GOAL, PENALTY
}

struct APIBooking: Codable {
    let id: Int
    let minute: Int
    let team: APITeam
    let player: APIPlayer
    let card: String // YELLOW, RED
}

struct APISubstitution: Codable {
    let id: Int
    let minute: Int
    let team: APITeam
    let playerIn: APIPlayer
    let playerOut: APIPlayer
}

struct LiveEvent: Codable, Identifiable {
    let id: String
    let minute: Int
    let type: String
    let player: APIPlayer?
    let teamId: String
}

struct APITeamSquad: Codable {
    let team: APITeam
    let squad: [APIPlayer]
    let coach: APICoach?
    
    func toAppModel() -> TeamSquad {
        return TeamSquad(
            team: team.toAppModel(),
            players: squad.map { $0.toAppModel(team: team.toAppModel()) },
            coach: coach?.toAppModel()
        )
    }
}

struct APIPlayer: Codable {
    let id: Int
    let name: String
    let position: String?
    
    func toAppModel(team: Team) -> Player {
        // Map API position to app position
        let playerPosition: Player.Position
        switch position?.lowercased() {
        case "goalkeeper":
            playerPosition = .goalkeeper
        case "defender":
            playerPosition = .defender
        case "midfielder":
            playerPosition = .midfielder
        case "forward", "attacker":
            playerPosition = .forward
        default:
            playerPosition = .midfielder // Default to midfielder
        }
        
        return Player(
            name: name,
            team: team,
            position: playerPosition
        )
    }
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

struct APIScore: Codable {
    let fullTime: ScoreDetail?
    let halfTime: ScoreDetail?
    
    struct ScoreDetail: Codable {
        let home: Int?
        let away: Int?
    }
}

struct APIMatchDetail: Codable {
    let id: Int
    let competition: APICompetition
    let homeTeam: APITeam
    let awayTeam: APITeam
    let utcDate: String
    let status: String
    let score: APIScore
    let venue: String?
    let attendance: Int?
    let referee: String?
    
    func toAppModel() -> MatchDetail {
        
        let date = DateUtility.iso8601Full.date(from: utcDate) ?? Date()
        
        let match = Match(
            id: "\(id)",
            homeTeam: homeTeam.toAppModel(),
            awayTeam: awayTeam.toAppModel(),
            startTime: date,
            status: matchStatusFrom(status: status),
            competition: competition.toAppModel()
        )
        
        return MatchDetail(
            match: match,
            venue: venue,
            attendance: attendance,
            referee: referee,
            homeScore: score.fullTime?.home ?? 0,
            awayScore: score.fullTime?.away ?? 0
        )
    }
    
    private func matchStatusFrom(status: String) -> MatchStatus {
        switch status {
        case "SCHEDULED": return .upcoming
        case "LIVE", "IN_PLAY": return .inProgress
        case "PAUSED": return .halftime
        case "FINISHED": return .completed
        default: return .unknown
        }
    }
}

// API responses containers
struct CompetitionsResponse: Codable {
    let competitions: [APICompetition]
}

struct MatchesResponse: Codable {
    let matches: [APIMatch]
    let count: Int?
    
    enum CodingKeys: String, CodingKey {
        case matches
        case count
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

struct MatchEventDetails: Identifiable {
    let id: String
    let minute: Int
    let type: EventType
    let player: Player
    let team: Team
    let detail: String?
    let secondaryPlayer: Player? // For assists, etc.
    
    enum EventType: String {
        case goal
        case card
        case substitution
        case var_goal // VAR-related
        case penalty_missed
        case penalty_scored
        case injury
        case corner
        case foul
    }
}

// Combined match with events
struct MatchWithEvents {
    let match: Match
    let events: [MatchEvent]
    let homeLineup: TeamLineup?
    let awayLineup: TeamLineup?
}

// Team squad
struct TeamSquad {
    let team: Team
    let players: [Player]
    let coach: Coach?
}
