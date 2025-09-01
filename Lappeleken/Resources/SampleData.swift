//
//  ReducedSampleData.swift
//  Lucky Football Slip
//
//  Reduced dataset for better performance
//

import Foundation

struct SampleData {
    
    // MARK: - Core Teams (Only 12 teams instead of 40+)
    
    static let coreTeams: [Team] = [
        // Premier League (6 teams)
        Team(name: "Arsenal", shortName: "ARS", logoName: "arsenal_logo", primaryColor: "#EF0107"),
        Team(name: "Chelsea", shortName: "CHE", logoName: "chelsea_logo", primaryColor: "#034694"),
        Team(name: "Liverpool", shortName: "LIV", logoName: "liverpool_logo", primaryColor: "#C8102E"),
        Team(name: "Manchester City", shortName: "MCI", logoName: "mancity_logo", primaryColor: "#6CABDD"),
        Team(name: "Manchester United", shortName: "MUN", logoName: "manutd_logo", primaryColor: "#DA020E"),
        Team(name: "Tottenham", shortName: "TOT", logoName: "tottenham_logo", primaryColor: "#132257"),
        
        // Other Major Teams (6 teams)
        Team(name: "Bayern Munich", shortName: "BAY", logoName: "bayern_logo", primaryColor: "#DC052D"),
        Team(name: "Real Madrid", shortName: "RMA", logoName: "realmadrid_logo", primaryColor: "#FEBE10"),
        Team(name: "Barcelona", shortName: "BAR", logoName: "barcelona_logo", primaryColor: "#004D98"),
        Team(name: "Juventus", shortName: "JUV", logoName: "juventus_logo", primaryColor: "#000000"),
        Team(name: "AC Milan", shortName: "MIL", logoName: "milan_logo", primaryColor: "#FB090B"),
        Team(name: "Inter Milan", shortName: "INT", logoName: "inter_logo", primaryColor: "#0068A8")
    ]
    
    // MARK: - Core Players (Only 36 players - 3 per team)
    
    static let corePlayers: [Player] = [
        // Arsenal (3 players)
        Player(name: "Bukayo Saka", team: coreTeams[0], position: .forward),
        Player(name: "Martin Ødegaard", team: coreTeams[0], position: .midfielder),
        Player(name: "Gabriel Jesus", team: coreTeams[0], position: .forward),
        
        // Chelsea (3 players)
        Player(name: "Enzo Fernández", team: coreTeams[1], position: .midfielder),
        Player(name: "Nicolas Jackson", team: coreTeams[1], position: .forward),
        Player(name: "Raheem Sterling", team: coreTeams[1], position: .forward),
        
        // Liverpool (3 players)
        Player(name: "Mohamed Salah", team: coreTeams[2], position: .forward),
        Player(name: "Virgil van Dijk", team: coreTeams[2], position: .defender),
        Player(name: "Darwin Núñez", team: coreTeams[2], position: .forward),
        
        // Manchester City (3 players)
        Player(name: "Erling Haaland", team: coreTeams[3], position: .forward),
        Player(name: "Kevin De Bruyne", team: coreTeams[3], position: .midfielder),
        Player(name: "Phil Foden", team: coreTeams[3], position: .midfielder),
        
        // Manchester United (3 players)
        Player(name: "Marcus Rashford", team: coreTeams[4], position: .forward),
        Player(name: "Bruno Fernandes", team: coreTeams[4], position: .midfielder),
        Player(name: "Casemiro", team: coreTeams[4], position: .midfielder),
        
        // Tottenham (3 players)
        Player(name: "Son Heung-min", team: coreTeams[5], position: .forward),
        Player(name: "Harry Kane", team: coreTeams[5], position: .forward),
        Player(name: "James Maddison", team: coreTeams[5], position: .midfielder),
        
        // Bayern Munich (3 players)
        Player(name: "Harry Kane", team: coreTeams[6], position: .forward),
        Player(name: "Jamal Musiala", team: coreTeams[6], position: .midfielder),
        Player(name: "Joshua Kimmich", team: coreTeams[6], position: .midfielder),
        
        // Real Madrid (3 players)
        Player(name: "Vinícius Jr.", team: coreTeams[7], position: .forward),
        Player(name: "Jude Bellingham", team: coreTeams[7], position: .midfielder),
        Player(name: "Kylian Mbappé", team: coreTeams[7], position: .forward),
        
        // Barcelona (3 players)
        Player(name: "Robert Lewandowski", team: coreTeams[8], position: .forward),
        Player(name: "Pedri", team: coreTeams[8], position: .midfielder),
        Player(name: "Gavi", team: coreTeams[8], position: .midfielder),
        
        // Juventus (3 players)
        Player(name: "Dušan Vlahović", team: coreTeams[9], position: .forward),
        Player(name: "Federico Chiesa", team: coreTeams[9], position: .forward),
        Player(name: "Paul Pogba", team: coreTeams[9], position: .midfielder),
        
        // AC Milan (3 players)
        Player(name: "Rafael Leão", team: coreTeams[10], position: .forward),
        Player(name: "Olivier Giroud", team: coreTeams[10], position: .forward),
        Player(name: "Theo Hernández", team: coreTeams[10], position: .defender),
        
        // Inter Milan (3 players)
        Player(name: "Lautaro Martínez", team: coreTeams[11], position: .forward),
        Player(name: "Nicolò Barella", team: coreTeams[11], position: .midfielder),
        Player(name: "Alessandro Bastoni", team: coreTeams[11], position: .defender)
    ]
    
    // MARK: - Backwards Compatibility
    
    // Keep the old property names for compatibility
    static let premierLeagueTeams: [Team] = Array(coreTeams[0..<6])
    static let samplePlayers: [Player] = corePlayers
    static let allTeams: [Team] = coreTeams
    
    // MARK: - Helper Methods
    
    static func findTeam(byName name: String) -> Team? {
        return coreTeams.first { team in
            team.name.lowercased() == name.lowercased() ||
            team.shortName.lowercased() == name.lowercased()
        }
    }
    
    static func getTeamNames() -> [String] {
        return coreTeams.map { $0.name }.sorted()
    }
    
    static func searchPlayers(byName name: String) -> [Player] {
        let searchTerm = name.lowercased()
        return corePlayers.filter { player in
            player.name.lowercased().contains(searchTerm) ||
            player.team.name.lowercased().contains(searchTerm)
        }
    }
    
    static func getPlayersByTeam(_ team: Team) -> [Player] {
        return corePlayers.filter { $0.team.id == team.id }
    }
}

extension SampleData {
    static var availableCompetitions: [Competition] {
        return [
            Competition(id: "PL", name: "Premier League", code: "PL"),
            Competition(id: "CL", name: "UEFA Champions League", code: "CL"),
            Competition(id: "BL1", name: "Bundesliga", code: "BL1"),
            Competition(id: "PD", name: "La Liga", code: "PD"),
            Competition(id: "SA", name: "Serie A", code: "SA"),
            Competition(id: "FL1", name: "Ligue 1", code: "FL1")
        ]
    }
    
    static var sampleMatches: [Match] {
        let competitions = availableCompetitions
        var matches: [Match] = []
        
        let homeTeams = ["Arsenal", "Liverpool", "Manchester City", "Chelsea", "Tottenham"]
        let awayTeams = ["Manchester United", "Newcastle", "Brighton", "Aston Villa", "West Ham"]
        
        for i in 0..<5 {
            let homeTeam = Team(
                name: homeTeams[i],
                shortName: String(homeTeams[i].prefix(3)).uppercased(),
                logoName: "\(homeTeams[i].lowercased())_logo",
                primaryColor: ["#DC052D", "#C8102E", "#6CABDD", "#034694", "#132257"][i]
            )
            
            let awayTeam = Team(
                name: awayTeams[i],
                shortName: String(awayTeams[i].prefix(3)).uppercased(),
                logoName: "\(awayTeams[i].lowercased())_logo",
                primaryColor: ["#DA020E", "#241F20", "#0057B8", "#95BFE5", "#7A263A"][i]
            )
            
            matches.append(Match(
                id: "sample_\(i)",
                homeTeam: homeTeam,
                awayTeam: awayTeam,
                startTime: Date().addingTimeInterval(TimeInterval(i * 3600)),
                status: [.upcoming, .inProgress, .upcoming, .halftime, .upcoming][i],
                competition: competitions[i % competitions.count]
            ))
        }
        
        return matches
    }
}
