//
//  MatchScoreView.swift
//  Lucky Football Slip
//
//  Live match scores - Football themed
//

import SwiftUI

struct MatchScoreView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.colorScheme) var colorScheme
    
    @State private var matchData: [String: LiveMatchData] = [:]
    @State private var isLoading = false
    @State private var lastRefresh: Date?
    
    var body: some View {
        ZStack {
            footballBackground
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    headerSection
                    
                    if gameSession.selectedMatches.isEmpty {
                        emptyState
                    } else {
                        matchCards
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
            }
        }
        .onAppear {
            if lastRefresh == nil || Date().timeIntervalSince(lastRefresh!) > 30 {
                Task { await refreshAllMatches() }
            }
        }
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            
            VStack {
                LinearGradient(
                    colors: [AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.08 : 0.04), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 100)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                
                Text("Match Scores")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            
            Spacer()
            
            if isLoading {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button(action: { Task { await refreshAllMatches() } }) {
                    ZStack {
                        Circle()
                            .fill(AppDesignSystem.Colors.grassGreen.opacity(0.12))
                            .frame(width: 36, height: 36)
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.grassGreen)
                    }
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.secondaryText.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sportscourt")
                    .font(.system(size: 36))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
            }
            
            VStack(spacing: 6) {
                Text("No Match Selected")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Select a match to see live scores")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
    
    // MARK: - Match Cards
    
    private var matchCards: some View {
        VStack(spacing: 12) {
            // Last updated
            if let lastRefresh = lastRefresh {
                Text("Updated \(lastRefresh.formatted(date: .omitted, time: .shortened))")
                    .font(.system(size: 11))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            ForEach(gameSession.selectedMatches, id: \.id) { match in
                ScoreCard(match: match, liveData: matchData[match.id])
            }
        }
    }
    
    // MARK: - Refresh
    
    private func refreshAllMatches() async {
        isLoading = true
        
        for match in gameSession.selectedMatches {
            do {
                let detail = try await DataManager.shared.fetchMatchDetails(match.id)
                await MainActor.run {
                    matchData[match.id] = LiveMatchData(from: detail)
                }
            } catch {
                print("❌ Failed to fetch match \(match.id): \(error)")
            }
        }
        
        await MainActor.run {
            isLoading = false
            lastRefresh = Date()
        }
    }
}

// MARK: - Live Match Data

struct LiveMatchData {
    let minute: Int?
    let injuryTime: Int?
    let status: MatchStatus
    let homeScore: Int
    let awayScore: Int
    let halfTimeHome: Int?
    let halfTimeAway: Int?
    
    init(from detail: MatchDetail) {
        self.minute = detail.minute
        self.injuryTime = detail.injuryTime
        self.status = detail.match.status
        self.homeScore = detail.score?.fullTime?.home ?? 0
        self.awayScore = detail.score?.fullTime?.away ?? 0
        self.halfTimeHome = detail.score?.halfTime?.home
        self.halfTimeAway = detail.score?.halfTime?.away
    }
}

// MARK: - Score Card

struct ScoreCard: View {
    let match: Match
    let liveData: LiveMatchData?
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Status badge
            statusBadge
            
            // Teams and score
            HStack(spacing: 16) {
                // Home team
                teamColumn(team: match.homeTeam, score: liveData?.homeScore, isHome: true)
                
                // Center divider
                centerDisplay
                
                // Away team
                teamColumn(team: match.awayTeam, score: liveData?.awayScore, isHome: false)
            }
            
            // Half-time score
            if let data = liveData,
               let htHome = data.halfTimeHome,
               let htAway = data.halfTimeAway,
               (data.status == .halftime || data.status == .inProgress || data.status == .finished || data.status == .completed) {
                Text("HT: \(htHome) - \(htAway)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            // Competition
            Text(match.competition.name)
                .font(.system(size: 11))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(liveData?.status == .inProgress ? AppDesignSystem.Colors.grassGreen.opacity(0.4) : Color.clear, lineWidth: 2)
                )
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
    
    private var statusBadge: some View {
        let (text, color) = statusInfo
        
        return HStack(spacing: 6) {
            if liveData?.status == .inProgress {
                Circle()
                    .fill(AppDesignSystem.Colors.error)
                    .frame(width: 8, height: 8)
            }
            
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(color.opacity(0.12)))
    }
    
    private var statusInfo: (String, Color) {
        guard let data = liveData else {
            return ("Upcoming", AppDesignSystem.Colors.info)
        }
        
        switch data.status {
        case .inProgress:
            if let minute = data.minute {
                if let injury = data.injuryTime, injury > 0 {
                    return ("\(minute)+\(injury)'", AppDesignSystem.Colors.error)
                }
                return ("\(minute)'", AppDesignSystem.Colors.error)
            }
            return ("LIVE", AppDesignSystem.Colors.error)
        case .halftime:
            return ("HT", AppDesignSystem.Colors.warning)
        case .finished, .completed:
            return ("FT", AppDesignSystem.Colors.secondaryText)
        case .postponed:
            return ("PPD", AppDesignSystem.Colors.warning)
        default:
            return ("—", AppDesignSystem.Colors.secondaryText)
        }
    }
    
    private func teamColumn(team: Team, score: Int?, isHome: Bool) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.TeamColors.getColor(for: team).opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Text(team.shortName.prefix(2).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
            }
            
            Text(team.shortName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text(score != nil ? "\(score!)" : "-")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var centerDisplay: some View {
        VStack(spacing: 4) {
            if let data = liveData, (data.status == .inProgress || data.status == .halftime) {
                Text(minuteDisplay)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.error)
            } else {
                Text("vs")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
    
    private var minuteDisplay: String {
        guard let data = liveData, let minute = data.minute else { return "" }
        if let injury = data.injuryTime, injury > 0 {
            return "\(minute)+\(injury)'"
        }
        return "\(minute)'"
    }
}
