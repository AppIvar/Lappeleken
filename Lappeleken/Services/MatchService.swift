//
//  MatchService.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

protocol MatchService {
    func fetchCompetitions() async throws -> [Competition]
    func fetchUpcomingMatches(competitionCode: String?) async throws -> [Match]
    func fetchLiveMatches(competitionCode: String?) async throws -> [Match]
    func fetchMatchDetails(matchId: String) async throws -> MatchDetail
    func fetchMatchPlayers(matchId: String) async throws -> [Player]
    func fetchMatchEvents(matchId: String) async throws -> [MatchEvent]
    
    // Keep only one monitoring method
    func monitorMatch(
        matchId: String,
        onUpdate: @escaping (MatchUpdate) -> Void
    ) -> Task<Void, Error>
    
    // Premium features
    func fetchMatchLineup(matchId: String) async throws -> Lineup
    func fetchLiveMatchDetails(matchId: String) async throws -> MatchWithEvents
    func fetchTeamSquad(teamId: String) async throws -> TeamSquad
}

// Define this in one place to avoid redeclaration
struct MatchUpdate {
    let match: Match
    let newEvents: [MatchEvent]
}
