//
//  SampleData.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 08/05/2025.
//

import Foundation

struct SampleData {
    static let premierLeagueTeams: [Team] = [
        Team(name: "Arsenal", shortName: "ARS", logoName: "arsenal_logo", primaryColor: "#EF0107"),
        Team(name: "Manchester City", shortName: "MCI", logoName: "mancity_logo", primaryColor: "#6CABDD"),
        Team(name: "Liverpool", shortName: "LIV", logoName: "liverpool_logo", primaryColor: "#C8102E"),
        Team(name: "Manchester United", shortName: "MUN", logoName: "manutd_logo", primaryColor: "#DA291C"),
        Team(name: "Chelsea", shortName: "CHE", logoName: "chelsea_logo", primaryColor: "#034694")
    ]
    
    static let samplePlayers: [Player] = [
        // Arsenal
        Player(name: "Bukayo Saka", team: premierLeagueTeams[0], position: .forward),
        Player(name: "Martin Ødegaard", team: premierLeagueTeams[0], position: .midfielder),
        Player(name: "Declan Rice", team: premierLeagueTeams[0], position: .midfielder),
        
        // Manchester City
        Player(name: "Erling Haaland", team: premierLeagueTeams[1], position: .forward),
        Player(name: "Kevin De Bruyne", team: premierLeagueTeams[1], position: .midfielder),
        Player(name: "Phil Foden", team: premierLeagueTeams[1], position: .midfielder),
        
        // Liverpool
        Player(name: "Mohamed Salah", team: premierLeagueTeams[2], position: .forward),
        Player(name: "Virgil van Dijk", team: premierLeagueTeams[2], position: .defender),
        Player(name: "Trent Alexander-Arnold", team: premierLeagueTeams[2], position: .defender),
        
        // Manchester United
        Player(name: "Bruno Fernandes", team: premierLeagueTeams[3], position: .midfielder),
        Player(name: "Marcus Rashford", team: premierLeagueTeams[3], position: .forward),
        Player(name: "Lisandro Martínez", team: premierLeagueTeams[3], position: .defender),
        
        // Chelsea
        Player(name: "Cole Palmer", team: premierLeagueTeams[4], position: .midfielder),
        Player(name: "Enzo Fernández", team: premierLeagueTeams[4], position: .midfielder),
        Player(name: "Reece James", team: premierLeagueTeams[4], position: .defender)
    ]
}
