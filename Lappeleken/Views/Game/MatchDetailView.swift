//
//  Enhanced MatchDetailView.swift
//  Lucky Football Slip
//
//  Vibrant match detail experience with live updates
//

import SwiftUI

struct MatchDetailView: View {
    @ObservedObject var gameSession: GameSession
    @State private var selectedTab = 0
    @State private var isLoading = false
    @State private var pulseMatchHeader = false
    
    var body: some View {
        ZStack {
            // Enhanced animated background
            backgroundView
            
            VStack(spacing: 0) {
                // Enhanced match header with live updates
                if let match = gameSession.selectedMatch {
                    EnhancedMatchHeader(match: match)
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                }
                
                // Enhanced tab selector with modern design
                VStack(spacing: 0) {
                    EnhancedTabSelector(selectedTab: $selectedTab)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Tab content with smooth transitions
                    TabView(selection: $selectedTab) {
                        EnhancedLineupView(gameSession: gameSession)
                            .tag(0)
                        
                        EnhancedEventsTimelineView(gameSession: gameSession)
                            .tag(1)
                        
                        EnhancedMatchStatsView(gameSession: gameSession)
                            .tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .animation(AppDesignSystem.Animations.smooth, value: selectedTab)
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                pulseMatchHeader = true
            }
        }
        .showBannerAdForFreeUsers()
    }
    
    // MARK: - Enhanced Background
    
    private var backgroundView: some View {
        AppDesignSystem.Colors.background
            .ignoresSafeArea()
    }
}

// MARK: - Enhanced Match Header

struct EnhancedMatchHeader: View {
    let match: Match
    @State private var currentTime = Date()
    @State private var animateScore = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 20) {
            // Competition and status row
            HStack {
                HStack(spacing: 8) {
                    Circle()
                        .fill(AppDesignSystem.Colors.primary.opacity(0.2))
                        .frame(width: 8, height: 8)
                    
                    Text(match.competition.name)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                }
                
                Spacer()
                
                enhancedMatchStatusBadge
            }
            
            // Enhanced team display with score
            HStack(spacing: 24) {
                // Home team
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppDesignSystem.TeamColors.getColor(for: match.homeTeam).opacity(0.3),
                                        AppDesignSystem.TeamColors.getColor(for: match.homeTeam).opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 15,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        // Team emblem placeholder or initials
                        Text(match.homeTeam.shortName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.TeamColors.getColor(for: match.homeTeam))
                    }
                    
                    Text(match.homeTeam.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                
                // Enhanced score or vs display
                VStack(spacing: 8) {
                    if match.status == .inProgress || match.status == .halftime || match.status == .completed {
                        // Enhanced score display
                        HStack(spacing: 12) {
                            Text("0")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                                .scaleEffect(animateScore ? 1.05 : 1.0)
                            
                            Text("-")
                                .font(.system(size: 28, weight: .medium, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            
                            Text("0")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                                .scaleEffect(animateScore ? 1.05 : 1.0)
                        }
                        .animation(AppDesignSystem.Animations.bouncy, value: animateScore)
                    } else {
                        Text("vs")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    // Enhanced match time
                    VibrantStatusBadge(
                        matchTimeText,
                        color: matchTimeColor
                    )
                }
                
                // Away team
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppDesignSystem.TeamColors.getColor(for: match.awayTeam).opacity(0.3),
                                        AppDesignSystem.TeamColors.getColor(for: match.awayTeam).opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 15,
                                    endRadius: 40
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Text(match.awayTeam.shortName)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.TeamColors.getColor(for: match.awayTeam))
                    }
                    
                    Text(match.awayTeam.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            AppDesignSystem.Colors.cardBackground,
                            AppDesignSystem.Colors.cardBackground.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.primary.opacity(0.3),
                                    AppDesignSystem.Colors.secondary.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: Color.black.opacity(0.1),
            radius: 12,
            x: 0,
            y: 6
        )
        .onReceive(timer) { _ in
            currentTime = Date()
            
            // Animate score periodically during live matches
            if match.status == .inProgress {
                withAnimation(AppDesignSystem.Animations.bouncy) {
                    animateScore.toggle()
                }
            }
        }
    }
    
    private var enhancedMatchStatusBadge: some View {
        let (text, color) = matchStatusInfo
        
        return HStack(spacing: 6) {
            if match.status == .inProgress {
                Circle()
                    .fill(color)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animateScore ? 1.3 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1).repeatForever(autoreverses: true),
                        value: animateScore
                    )
            }
            
            Text(text)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .shadow(
            color: color.opacity(0.4),
            radius: 6,
            x: 0,
            y: 3
        )
    }
    
    private var matchStatusInfo: (String, Color) {
        switch match.status {
        case .upcoming:
            return ("Upcoming", AppDesignSystem.Colors.primary)
        case .inProgress:
            return ("LIVE", AppDesignSystem.Colors.success)
        case .halftime:
            return ("Half-time", AppDesignSystem.Colors.warning)
        case .completed:
            return ("Full-time", AppDesignSystem.Colors.secondary)
        case .unknown:
            return ("Unknown", AppDesignSystem.Colors.error)
        case .finished:
            return ("Finished", AppDesignSystem.Colors.accent)
        case .postponed:
            return ("Postponed", AppDesignSystem.Colors.error)
        case .cancelled:
            return ("Cancelled", AppDesignSystem.Colors.error)
        case .paused:
            return ("Paused", AppDesignSystem.Colors.warning)
        case .suspended:
            return ("Suspended", AppDesignSystem.Colors.warning)
        }
    }
    
    private var matchTimeText: String {
        let formatter = DateFormatter()
        
        switch match.status {
        case .upcoming:
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: match.startTime)
            
        case .inProgress:
            let elapsed = Int(currentTime.timeIntervalSince(match.startTime) / 60)
            return "\(min(elapsed, 90))'"
            
        case .halftime:
            return "Half-time"
            
        case .completed:
            return "Full-time"
            
        case .unknown:
            return "Unknown"
        case .finished:
            return "Finished"
        case .postponed:
            return "Postponed"
        case .cancelled:
            return "Cancelled"
        case .paused:
            return "Paused"
        case .suspended:
            return "Suspended"
        }
    }
    
    private var matchTimeColor: Color {
        switch match.status {
        case .inProgress: return AppDesignSystem.Colors.success
        case .halftime: return AppDesignSystem.Colors.warning
        case .completed: return AppDesignSystem.Colors.secondary
        default: return AppDesignSystem.Colors.primary
        }
    }
}

// MARK: - Enhanced Tab Selector

struct EnhancedTabSelector: View {
    @Binding var selectedTab: Int
    private let tabs = ["Lineups", "Events", "Stats"]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(AppDesignSystem.Animations.bouncy) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 8) {
                        Text(tabs[index])
                            .font(.system(size: 16, weight: selectedTab == index ? .bold : .medium, design: .rounded))
                            .foregroundColor(
                                selectedTab == index ?
                                AppDesignSystem.Colors.primary :
                                AppDesignSystem.Colors.secondaryText
                            )
                        
                        // Enhanced active indicator
                        RoundedRectangle(cornerRadius: 2)
                            .fill(
                                selectedTab == index ?
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.Colors.primary,
                                        AppDesignSystem.Colors.secondary
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ) :
                                LinearGradient(
                                    colors: [Color.clear, Color.clear],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 3)
                            .scaleX(selectedTab == index ? 1.0 : 0.0)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}

// MARK: - Enhanced Lineup View

struct EnhancedLineupView: View {
    @ObservedObject var gameSession: GameSession
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                if let match = gameSession.selectedMatch {
                    EnhancedTeamLineupSection(
                        team: match.homeTeam,
                        playersWithOwners: getPlayersWithOwners(team: match.homeTeam),
                        isHome: true
                    )
                    
                    // VS divider
                    HStack {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        AppDesignSystem.Colors.primary.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                        
                        VibrantStatusBadge("VS", color: AppDesignSystem.Colors.accent)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        AppDesignSystem.Colors.primary.opacity(0.3),
                                        Color.clear
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 1)
                    }
                    
                    EnhancedTeamLineupSection(
                        team: match.awayTeam,
                        playersWithOwners: getPlayersWithOwners(team: match.awayTeam),
                        isHome: false
                    )
                } else {
                    // Enhanced empty state
                    VStack(spacing: 16) {
                        Image(systemName: "sportscourt")
                            .font(.system(size: 60))
                            .foregroundColor(AppDesignSystem.Colors.secondary.opacity(0.6))
                        
                        Text("No Match Selected")
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Select a match to view team lineups")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 80)
                }
                
                Spacer(minLength: 100)
            }
            .padding(20)
        }
    }
    
    private func getPlayersWithOwners(team: Team) -> [(player: Player, participant: Participant?)] {
        let teamPlayers = gameSession.availablePlayers.filter { $0.team.id == team.id }
        return teamPlayers.map { player in
            let owner = gameSession.participants.first { participant in
                participant.selectedPlayers.contains { $0.id == player.id } ||
                participant.substitutedPlayers.contains { $0.id == player.id }
            }
            return (player, owner)
        }
    }
}

// MARK: - Enhanced Team Lineup Section

struct EnhancedTeamLineupSection: View {
    let team: Team
    let playersWithOwners: [(player: Player, participant: Participant?)]
    let isHome: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Enhanced team header
            HStack {
                VStack(alignment: isHome ? .leading : .trailing, spacing: 8) {
                    Text(team.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
                    
                    HStack(spacing: 8) {
                        if isHome {
                            VibrantStatusBadge("Home", color: AppDesignSystem.Colors.success)
                            VibrantStatusBadge("\(playersWithOwners.count) players", color: AppDesignSystem.Colors.info)
                        } else {
                            VibrantStatusBadge("\(playersWithOwners.count) players", color: AppDesignSystem.Colors.info)
                            VibrantStatusBadge("Away", color: AppDesignSystem.Colors.warning)
                        }
                    }
                }
                
                if !isHome { Spacer() }
                
                // Team emblem placeholder
                ZStack {
                    Circle()
                        .fill(AppDesignSystem.TeamColors.getGradient(for: team))
                        .frame(width: 60, height: 60)
                    
                    Text(team.shortName)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .shadow(
                    color: AppDesignSystem.TeamColors.getColor(for: team).opacity(0.4),
                    radius: 8,
                    x: 0,
                    y: 4
                )
                
                if isHome { Spacer() }
            }
            
            // Formation display
            HStack {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.secondary)
                
                Text("Formation: 4-3-3")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            // Enhanced players by position
            let playersByPosition = Dictionary(grouping: playersWithOwners) { $0.player.position }
            
            VStack(spacing: 16) {
                ForEach([Player.Position.goalkeeper, .defender, .midfielder, .forward], id: \.self) { position in
                    if let players = playersByPosition[position], !players.isEmpty {
                        EnhancedPositionSection(
                            title: position.rawValue.capitalized + "s",
                            players: players,
                            teamColor: AppDesignSystem.TeamColors.getColor(for: team)
                        )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.TeamColors.getAccentColor(for: team).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            AppDesignSystem.TeamColors.getColor(for: team).opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: AppDesignSystem.TeamColors.getColor(for: team).opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}

// MARK: - Enhanced Position Section

struct EnhancedPositionSection: View {
    let title: String
    let players: [(player: Player, participant: Participant?)]
    let teamColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                VibrantStatusBadge("\(players.count)", color: teamColor)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(players, id: \.player.id) { playerWithOwner in
                    EnhancedPlayerLineupCard(
                        player: playerWithOwner.player,
                        participant: playerWithOwner.participant,
                        teamColor: teamColor
                    )
                }
            }
        }
    }
}

// MARK: - Enhanced Player Lineup Card

struct EnhancedPlayerLineupCard: View {
    let player: Player
    let participant: Participant?
    let teamColor: Color
    
    var body: some View {
        HStack(spacing: 8) {
            // Player avatar
            Circle()
                .fill(teamColor.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(player.name.prefix(1)).uppercased())
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(teamColor)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .lineLimit(1)
                
                if let participant = participant {
                    Text(participant.name)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                } else {
                    Text("Unowned")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .italic()
                }
            }
            
            Spacer()
            
            // Stats badges
            HStack(spacing: 4) {
                if player.goals > 0 {
                    EnhancedStatBadge(icon: "soccerball", value: "\(player.goals)", color: AppDesignSystem.Colors.success)
                }
                if player.assists > 0 {
                    EnhancedStatBadge(icon: "arrow.up.forward", value: "\(player.assists)", color: AppDesignSystem.Colors.info)
                }
                if player.yellowCards > 0 {
                    EnhancedStatBadge(icon: "square.fill", value: "\(player.yellowCards)", color: AppDesignSystem.Colors.warning)
                }
                if player.redCards > 0 {
                    EnhancedStatBadge(icon: "square.fill", value: "\(player.redCards)", color: AppDesignSystem.Colors.error)
                }
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(AppDesignSystem.Colors.cardBackground.opacity(0.8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(teamColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Enhanced Stat Badge

struct EnhancedStatBadge: View {
    let icon: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(value)
                .font(.system(size: 9, weight: .bold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(color)
        )
    }
}

// MARK: - Enhanced Views (Placeholders for Events and Stats)

struct EnhancedEventsTimelineView: View {
    @ObservedObject var gameSession: GameSession
    
    var body: some View {
        TimelineView(gameSession: gameSession)
    }
}

struct EnhancedMatchStatsView: View {
    @ObservedObject var gameSession: GameSession
    
    var body: some View {
        MatchStatsView(gameSession: gameSession)
    }
}

// MARK: - Floating Match Elements

struct FloatingMatchElements: View {
    @State private var offset1 = CGSize.zero
    @State private var offset2 = CGSize.zero
    @State private var offset3 = CGSize.zero
    
    var body: some View {
        ZStack {
            Image(systemName: "soccerball")
                .font(.system(size: 16))
                .foregroundColor(AppDesignSystem.Colors.success.opacity(0.1))
                .offset(offset1)
                .animation(
                    Animation.easeInOut(duration: 4).repeatForever(autoreverses: true),
                    value: offset1
                )
            
            Image(systemName: "flag.2.crossed")
                .font(.system(size: 14))
                .foregroundColor(AppDesignSystem.Colors.warning.opacity(0.1))
                .offset(offset2)
                .animation(
                    Animation.easeInOut(duration: 5).repeatForever(autoreverses: true),
                    value: offset2
                )
            
            Image(systemName: "stopwatch")
                .font(.system(size: 12))
                .foregroundColor(AppDesignSystem.Colors.info.opacity(0.1))
                .offset(offset3)
                .animation(
                    Animation.easeInOut(duration: 6).repeatForever(autoreverses: true),
                    value: offset3
                )
        }
        .onAppear {
            offset1 = CGSize(width: 90, height: 70)
            offset2 = CGSize(width: -70, height: 100)
            offset3 = CGSize(width: 50, height: -80)
        }
    }
}

// MARK: - Helper Extensions

extension View {
    func scaleX(_ scale: CGFloat) -> some View {
        self.scaleEffect(CGSize(width: scale, height: 1.0))
    }
}
