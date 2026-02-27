//
//  PreviewHelpers.swift
//  Lucky Football Slip
//
//  Preview utilities for SwiftUI views
//

import SwiftUI

// MARK: - Preview Game Session

/// Factory for creating preview-ready GameSession instances
enum PreviewData {
    
    /// Creates a GameSession with sample data for previews
    static func makeGameSession(
        withParticipants: Bool = true,
        withPlayers: Bool = true,
        withBets: Bool = true,
        withEvents: Bool = false,
        withMatch: Bool = false,
        isLiveMode: Bool = false
    ) -> GameSession {
        let session = GameSession()
        
        if withParticipants {
            session.participants = sampleParticipants
        }
        
        if withPlayers {
            session.availablePlayers = samplePlayers
            session.selectedPlayers = Array(samplePlayers.prefix(6))
        }
        
        if withBets {
            session.bets = sampleBets
        }
        
        if withEvents {
            session.events = sampleEvents
        }
        
        if withMatch {
            session.selectedMatch = sampleMatch
            session.selectedMatches = [sampleMatch]
            session.availableMatches = sampleMatches
        }
        
        session.isLiveMode = isLiveMode
        
        // Assign players to participants if both exist
        if withParticipants && withPlayers {
            assignPlayersToParticipants(session)
        }
        
        return session
    }
    
    private static func assignPlayersToParticipants(_ session: GameSession) {
        let playersPerParticipant = session.selectedPlayers.count / max(session.participants.count, 1)
        
        for (index, _) in session.participants.enumerated() {
            let startIndex = index * playersPerParticipant
            let endIndex = min(startIndex + playersPerParticipant, session.selectedPlayers.count)
            
            if startIndex < session.selectedPlayers.count {
                session.participants[index].selectedPlayers = Array(session.selectedPlayers[startIndex..<endIndex])
                session.participants[index].balance = Double.random(in: -20...50)
            }
        }
    }
    
    // MARK: - Sample Data
    
    static let sampleTeams: [Team] = [
        Team(name: "Arsenal", shortName: "ARS", logoName: "arsenal", primaryColor: "#EF0107"),
        Team(name: "Chelsea", shortName: "CHE", logoName: "chelsea", primaryColor: "#034694"),
        Team(name: "Liverpool", shortName: "LIV", logoName: "liverpool", primaryColor: "#C8102E"),
        Team(name: "Manchester City", shortName: "MCI", logoName: "mancity", primaryColor: "#6CABDD")
    ]
    
    static let sampleParticipants: [Participant] = [
        Participant(name: "Ivar"),
        Participant(name: "Erik"),
        Participant(name: "Magnus")
    ]
    
    static let samplePlayers: [Player] = {
        let arsenal = sampleTeams[0]
        let chelsea = sampleTeams[1]
        
        return [
            Player(name: "Bukayo Saka", team: arsenal, position: .forward),
            Player(name: "Martin Ødegaard", team: arsenal, position: .midfielder),
            Player(name: "William Saliba", team: arsenal, position: .defender),
            Player(name: "Aaron Ramsdale", team: arsenal, position: .goalkeeper),
            Player(name: "Gabriel Jesus", team: arsenal, position: .forward),
            Player(name: "Declan Rice", team: arsenal, position: .midfielder),
            Player(name: "Cole Palmer", team: chelsea, position: .midfielder),
            Player(name: "Nicolas Jackson", team: chelsea, position: .forward),
            Player(name: "Enzo Fernández", team: chelsea, position: .midfielder),
            Player(name: "Robert Sánchez", team: chelsea, position: .goalkeeper)
        ]
    }()
    
    static let sampleBets: [Bet] = [
        Bet(eventType: .goal, amount: 10.0),
        Bet(eventType: .assist, amount: 5.0),
        Bet(eventType: .yellowCard, amount: -5.0),
        Bet(eventType: .redCard, amount: -15.0),
        Bet(eventType: .ownGoal, amount: -10.0)
    ]
    
    static let sampleEvents: [GameEvent] = {
        let players = samplePlayers
        return [
            GameEvent(player: players[0], eventType: .goal, timestamp: Date().addingTimeInterval(-3600)),
            GameEvent(player: players[1], eventType: .assist, timestamp: Date().addingTimeInterval(-3600)),
            GameEvent(player: players[6], eventType: .goal, timestamp: Date().addingTimeInterval(-1800)),
            GameEvent(player: players[2], eventType: .yellowCard, timestamp: Date().addingTimeInterval(-900))
        ]
    }()
    
    static let sampleMatch: Match = {
        let arsenal = sampleTeams[0]
        let chelsea = sampleTeams[1]
        let competition = Competition(id: "2021", name: "Premier League", code: "PL")
        
        return Match(
            id: "12345",
            homeTeam: arsenal,
            awayTeam: chelsea,
            startTime: Date(),
            status: .inProgress,
            competition: competition
        )
    }()
    
    static let sampleMatches: [Match] = {
        let competition = Competition(id: "2021", name: "Premier League", code: "PL")
        
        return [
            Match(
                id: "12345",
                homeTeam: sampleTeams[0],
                awayTeam: sampleTeams[1],
                startTime: Date(),
                status: .inProgress,
                competition: competition
            ),
            Match(
                id: "12346",
                homeTeam: sampleTeams[2],
                awayTeam: sampleTeams[3],
                startTime: Date().addingTimeInterval(7200),
                status: .upcoming,
                competition: competition
            ),
            Match(
                id: "12347",
                homeTeam: sampleTeams[1],
                awayTeam: sampleTeams[2],
                startTime: Date().addingTimeInterval(86400),
                status: .upcoming,
                competition: competition
            )
        ]
    }()
}

// MARK: - Preview Container

/// A container view that provides common preview setup
struct PreviewContainer<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
    }
}

// MARK: - Preview Modifiers

extension View {
    /// Wraps the view in a NavigationView for preview
    func previewWithNavigation() -> some View {
        NavigationView {
            self
        }
    }
    
    /// Creates both light and dark mode previews
    func previewInBothModes() -> some View {
        Group {
            self
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            self
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
    
    /// Adds a device frame to the preview
    func previewAsDevice(_ device: PreviewDevice = PreviewDevice(rawValue: "iPhone 15 Pro")) -> some View {
        self.previewDevice(device)
    }
}

// MARK: - Example Previews

/*
 
 USAGE EXAMPLES:
 
 // Basic preview with GameSession
 #Preview {
     SetupParticipantsView(gameSession: PreviewData.makeGameSession())
 }
 
 // Preview with navigation
 #Preview {
     SetupPlayersView(gameSession: PreviewData.makeGameSession(withPlayers: true))
         .previewWithNavigation()
 }
 
 // Preview in both light and dark mode
 #Preview("Light & Dark") {
     GameView(gameSession: PreviewData.makeGameSession(withEvents: true))
         .previewInBothModes()
 }
 
 // Live mode preview
 #Preview("Live Mode") {
     LiveGameSetupView(gameSession: PreviewData.makeGameSession(withMatch: true, isLiveMode: true))
 }
 
 // Custom configuration
 #Preview("Custom") {
     let session = PreviewData.makeGameSession(
         withParticipants: true,
         withPlayers: true,
         withBets: true,
         withEvents: true,
         withMatch: true,
         isLiveMode: true
     )
     return GameView(gameSession: session)
 }
 
 // For older iOS (PreviewProvider style):
 struct SetupParticipantsView_Previews: PreviewProvider {
     static var previews: some View {
         SetupParticipantsView(gameSession: PreviewData.makeGameSession())
             .previewInBothModes()
     }
 }
 
 */

// MARK: - Sample Preview Snippets for Quick Copy-Paste

/*
 
 // === SETUP VIEWS ===
 
 #Preview("Participants") {
     SetupParticipantsView(gameSession: PreviewData.makeGameSession())
 }
 
 #Preview("Players") {
     SetupPlayersView(gameSession: PreviewData.makeGameSession())
 }
 
 #Preview("Bets") {
     SetupBetsView(gameSession: PreviewData.makeGameSession())
 }
 
 #Preview("Preview") {
     SetupPreviewView(gameSession: PreviewData.makeGameSession())
 }
 
 // === GAME VIEWS ===
 
 #Preview("Game") {
     GameView(gameSession: PreviewData.makeGameSession(withEvents: true))
 }
 
 #Preview("Timeline") {
     TimelineView(gameSession: PreviewData.makeGameSession(withEvents: true))
 }
 
 #Preview("Summary") {
     GameSummaryView(gameSession: PreviewData.makeGameSession(withEvents: true))
 }
 
 // === LIVE MODE VIEWS ===
 
 #Preview("Live Setup") {
     LiveGameSetupView(gameSession: PreviewData.makeGameSession(withMatch: true, isLiveMode: true))
 }
 
 #Preview("Match Detail") {
     MatchDetailView(gameSession: PreviewData.makeGameSession(withMatch: true, isLiveMode: true))
 }
 
 #Preview("Match Score") {
     MatchScoreView(gameSession: PreviewData.makeGameSession(withMatch: true, isLiveMode: true))
 }
 
 // === COMPONENT VIEWS ===
 
 #Preview("Player Drawing") {
     PlayerDrawingView(
         gameSession: PreviewData.makeGameSession(),
         selectedPlayers: PreviewData.samplePlayers,
         participants: PreviewData.sampleParticipants,
         onComplete: { _ in },
         onBack: { }
     )
 }
 
 #Preview("Assign Players") {
     AssignPlayersView(gameSession: PreviewData.makeGameSession())
 }
 
 */
