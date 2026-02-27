//
//  MatchDetailView.swift
//  Lucky Football Slip
//
//  Match detail with tabs - Football themed
//

import SwiftUI

struct MatchDetailView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.colorScheme) var colorScheme
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            footballBackground
            
            VStack(spacing: 0) {
                if let match = gameSession.selectedMatch {
                    DetailMatchHeader(match: match)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                }
                
                // Tab selector
                DetailTabSelector(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                
                // Tab content
                TabView(selection: $selectedTab) {
                    DetailLineupTab(gameSession: gameSession)
                        .tag(0)
                    
                    TimelineView(gameSession: gameSession)
                        .tag(1)
                    
                    MatchStatsView(gameSession: gameSession)
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
        }
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            
            VStack {
                LinearGradient(
                    colors: [AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.1 : 0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 150)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Detail Match Header

struct DetailMatchHeader: View {
    let match: Match
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            headerRow
            teamsRow
        }
        .padding(16)
        .background(headerBackground)
    }
    
    // MARK: - Header Row
    
    private var headerRow: some View {
        HStack {
            Text(match.competition.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Spacer()
            
            matchStatusBadge
        }
    }
    
    // MARK: - Teams Row
    
    private var teamsRow: some View {
        HStack(spacing: 20) {
            teamColumn(team: match.homeTeam)
            scoreDisplay
            teamColumn(team: match.awayTeam)
        }
    }
    
    private func teamColumn(team: Team) -> some View {
        VStack(spacing: 8) {
            teamCircle(team: team)
            
            Text(team.shortName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func teamCircle(team: Team) -> some View {
        ZStack {
            Circle()
                .fill(AppDesignSystem.TeamColors.getColor(for: team).opacity(0.15))
                .frame(width: 56, height: 56)
            
            Text(team.shortName.prefix(2).uppercased())
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
        }
    }
    
    // MARK: - Score Display
    
    private var scoreDisplay: some View {
        VStack(spacing: 4) {
            if isMatchStarted {
                scoreNumbers
            } else {
                upcomingDisplay
            }
        }
    }
    
    private var isMatchStarted: Bool {
        match.status == .inProgress || match.status == .halftime || match.status == .completed || match.status == .finished
    }
    
    private var scoreNumbers: some View {
        HStack(spacing: 10) {
            Text("0")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("-")
                .font(.system(size: 20))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("0")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
        }
    }
    
    private var upcomingDisplay: some View {
        VStack(spacing: 4) {
            Text("vs")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text(formattedKickoff)
                .font(.system(size: 12))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
    }
    
    private var formattedKickoff: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: match.startTime)
    }
    
    // MARK: - Status Badge
    
    private var matchStatusBadge: some View {
        HStack(spacing: 5) {
            if match.status == .inProgress {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
            }
            
            Text(statusText)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Capsule().fill(statusColor.opacity(0.12)))
    }
    
    private var statusText: String {
        switch match.status {
        case .inProgress: return "LIVE"
        case .halftime: return "HT"
        case .finished, .completed: return "FT"
        case .upcoming: return "Upcoming"
        default: return match.status.rawValue
        }
    }
    
    private var statusColor: Color {
        switch match.status {
        case .inProgress: return AppDesignSystem.Colors.error
        case .halftime: return AppDesignSystem.Colors.warning
        case .finished, .completed: return AppDesignSystem.Colors.secondaryText
        case .upcoming: return AppDesignSystem.Colors.info
        default: return AppDesignSystem.Colors.secondaryText
        }
    }
    
    // MARK: - Background
    
    private var headerBackground: some View {
        let strokeColor = match.status == .inProgress ? AppDesignSystem.Colors.grassGreen.opacity(0.4) : Color.clear
        let shadowColor = colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05)
        
        return RoundedRectangle(cornerRadius: 16)
            .fill(AppDesignSystem.Colors.cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(strokeColor, lineWidth: 2)
            )
            .shadow(color: shadowColor, radius: 6, x: 0, y: 3)
    }
}

// MARK: - Detail Tab Selector

struct DetailTabSelector: View {
    @Binding var selectedTab: Int
    
    private let tabs = ["Lineup", "Timeline", "Stats"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 14, weight: selectedTab == index ? .bold : .medium))
                            .foregroundColor(selectedTab == index ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText)
                        
                        Rectangle()
                            .fill(selectedTab == index ? AppDesignSystem.Colors.grassGreen : Color.clear)
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Detail Lineup Tab

struct DetailLineupTab: View {
    @ObservedObject var gameSession: GameSession
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            if let match = gameSession.selectedMatch {
                VStack(spacing: 16) {
                    // Home team
                    DetailTeamLineup(
                        team: match.homeTeam,
                        players: getPlayersForTeam(match.homeTeam),
                        gameSession: gameSession
                    )
                    
                    // Away team
                    DetailTeamLineup(
                        team: match.awayTeam,
                        players: getPlayersForTeam(match.awayTeam),
                        gameSession: gameSession
                    )
                    
                    Spacer(minLength: 100)
                }
                .padding(20)
            } else {
                emptyLineupState
            }
        }
    }
    
    private var emptyLineupState: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.3")
                .font(.system(size: 36))
                .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
            
            Text("No lineup available")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    private func getPlayersForTeam(_ team: Team) -> [Player] {
        gameSession.availablePlayers.filter { $0.team.id == team.id }
    }
}

// MARK: - Detail Team Lineup

struct DetailTeamLineup: View {
    let team: Team
    let players: [Player]
    let gameSession: GameSession
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Team header
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(AppDesignSystem.TeamColors.getColor(for: team))
                    .frame(width: 4, height: 28)
                
                Text(team.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text("\(players.count) players")
                    .font(.system(size: 12))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            // Players by position
            let grouped = Dictionary(grouping: players) { $0.position }
            let positions: [Player.Position] = [.goalkeeper, .defender, .midfielder, .forward]
            
            ForEach(positions, id: \.self) { position in
                if let positionPlayers = grouped[position], !positionPlayers.isEmpty {
                    DetailPositionGroup(
                        position: position,
                        players: positionPlayers,
                        team: team,
                        gameSession: gameSession
                    )
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppDesignSystem.TeamColors.getColor(for: team).opacity(0.2), lineWidth: 1)
                )
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.15) : Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Detail Position Group

struct DetailPositionGroup: View {
    let position: Player.Position
    let players: [Player]
    let team: Team
    let gameSession: GameSession
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(position.rawValue + "s")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
            
            ForEach(players) { player in
                DetailPlayerRow(player: player, team: team, owner: getOwner(for: player))
            }
        }
    }
    
    private func getOwner(for player: Player) -> Participant? {
        gameSession.participants.first { p in
            p.selectedPlayers.contains { $0.id == player.id } ||
            p.substitutedPlayers.contains { $0.id == player.id }
        }
    }
}

// MARK: - Detail Player Row

struct DetailPlayerRow: View {
    let player: Player
    let team: Team
    let owner: Participant?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(AppDesignSystem.TeamColors.getColor(for: team))
                .frame(width: 3, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(player.position.rawValue)
                    .font(.system(size: 10))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            // Stats
            HStack(spacing: 6) {
                if player.goals > 0 {
                    DetailStatBadge(icon: "soccerball", value: player.goals, color: AppDesignSystem.Colors.grassGreen)
                }
                if player.assists > 0 {
                    DetailStatBadge(icon: "arrow.up.forward", value: player.assists, color: AppDesignSystem.Colors.info)
                }
                if player.yellowCards > 0 {
                    DetailStatBadge(icon: "square.fill", value: player.yellowCards, color: AppDesignSystem.Colors.goalYellow)
                }
                if player.redCards > 0 {
                    DetailStatBadge(icon: "square.fill", value: player.redCards, color: AppDesignSystem.Colors.error)
                }
            }
            
            // Owner
            if let owner = owner {
                Text(owner.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppDesignSystem.Colors.grassGreen.opacity(0.12)))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
        )
    }
}

// MARK: - Detail Stat Badge

struct DetailStatBadge: View {
    let icon: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text("\(value)")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 5)
        .padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 4).fill(color.opacity(0.12)))
    }
}
