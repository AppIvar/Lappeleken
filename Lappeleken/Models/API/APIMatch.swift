//
//  APIMatch.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

struct APIMatch: Codable {
    let id: Int
    let competition: APICompetition
    let utcDate: String
    let status: String
    let homeTeam: APITeam
    let awayTeam: APITeam
    let score: APIScore
    
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
    
    private func matchStatus(from status: String) -> MatchStatus {
        switch status {
        case "SCHEDULED": return .upcoming
        case "LIVE", "IN_PLAY": return .inProgress
        case "PAUSED": return .halftime
        case "FINISHED": return .completed
        default: return .unknown
        }
    }
}


