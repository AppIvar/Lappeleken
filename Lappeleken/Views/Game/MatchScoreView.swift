//
//  MatchScoreView.swift
//  Lucky Football Slip
//

import SwiftUI

// MARK: - Simplified MatchScoreView (Score-focused)

struct MatchScoreView: View {
    @ObservedObject var gameSession: GameSession
    @State private var matchData: [String: LiveMatchData] = [:]
    @State private var isLoading = false
    @State private var lastRefresh: Date?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header with refresh info
                HStack {
                    Text("Match Scores")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Button(action: { Task { await refreshAllMatches() } }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.primary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Last updated
                if let lastRefresh = lastRefresh {
                    Text("Updated \(lastRefresh.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                // Match cards
                if gameSession.selectedMatches.isEmpty {
                    emptyState
                } else {
                    ForEach(gameSession.selectedMatches, id: \.id) { match in
                        MatchScoreCard(
                            match: match,
                            liveData: matchData[match.id]
                        )
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 100)
            }
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
        .onAppear {
            // Refresh when tab opens (if stale or first load)
            if lastRefresh == nil || Date().timeIntervalSince(lastRefresh!) > 30 {
                Task { await refreshAllMatches() }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "sportscourt")
                .font(.system(size: 48))
                .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
            
            Text("No match selected")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
    
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

// MARK: - LiveMatchData (Score-focused)

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

// MARK: - MatchScoreCard (Simplified)

struct MatchScoreCard: View {
    let match: Match
    let liveData: LiveMatchData?
    
    var body: some View {
        VStack(spacing: 16) {
            // Status badge
            statusBadge
            
            // Teams and score
            HStack(spacing: 20) {
                // Home team
                VStack(spacing: 8) {
                    Text(match.homeTeam.shortName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(liveData != nil ? "\(liveData!.homeScore)" : "-")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                }
                .frame(maxWidth: .infinity)
                
                // Divider / VS
                VStack(spacing: 4) {
                    if let data = liveData, data.status == .inProgress || data.status == .halftime {
                        Text(minuteDisplay(data))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppDesignSystem.Colors.error)
                    } else {
                        Text("vs")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                
                // Away team
                VStack(spacing: 8) {
                    Text(match.awayTeam.shortName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(liveData != nil ? "\(liveData!.awayScore)" : "-")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                }
                .frame(maxWidth: .infinity)
            }
            
            // Half-time score
            if let data = liveData,
               let htHome = data.halfTimeHome,
               let htAway = data.halfTimeAway,
               (data.status == .halftime || data.status == .inProgress || data.status == .finished || data.status == .completed) {
                Text("HT: \(htHome) - \(htAway)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            // Competition
            Text(match.competition.name)
                .font(.system(size: 12))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    private var statusBadge: some View {
        let (text, color) = statusInfo
        
        return HStack(spacing: 6) {
            if liveData?.status == .inProgress {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
            }
            
            Text(text)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color)
        .cornerRadius(12)
    }
    
    private var statusInfo: (String, Color) {
        guard let data = liveData else {
            return (formatKickoff(match.startTime), AppDesignSystem.Colors.primary)
        }
        
        switch data.status {
        case .upcoming:
            return (formatKickoff(match.startTime), AppDesignSystem.Colors.primary)
        case .inProgress:
            return ("LIVE", Color.red)
        case .halftime:
            return ("HT", AppDesignSystem.Colors.warning)
        case .finished, .completed:
            return ("FT", AppDesignSystem.Colors.secondary)
        case .paused:
            return ("PAUSED", AppDesignSystem.Colors.warning)
        case .postponed:
            return ("POSTPONED", AppDesignSystem.Colors.error)
        case .cancelled:
            return ("CANCELLED", AppDesignSystem.Colors.error)
        case .suspended:
            return ("SUSPENDED", AppDesignSystem.Colors.warning)
        default:
            return ("--", AppDesignSystem.Colors.secondaryText)
        }
    }
    
    private func minuteDisplay(_ data: LiveMatchData) -> String {
        guard let minute = data.minute else { return "" }
        if let injury = data.injuryTime, injury > 0 {
            return "\(minute)+\(injury)'"
        }
        return "\(minute)'"
    }
    
    private func formatKickoff(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

/*struct MatchScoreView: View {
    @ObservedObject var gameSession: GameSession
    @State private var matchDetails: [String: LiveMatchData] = [:]
    @State private var isLoading = false
    @State private var lastRefresh: Date = Date()
    @State private var autoRefreshTimer: Timer?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Header with refresh
                headerSection
                
                if isLoading && matchDetails.isEmpty {
                    loadingView
                } else if gameSession.selectedMatches.isEmpty && gameSession.selectedMatch == nil {
                    noMatchSelectedView
                } else {
                    matchCardsSection
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
        .onAppear {
            refreshMatchData()
            startAutoRefresh()
        }
        .onDisappear {
            stopAutoRefresh()
        }
        .withMinimalBanner()
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Match Score")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Last updated: \(formatTime(lastRefresh))")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Button(action: {
                refreshMatchData()
            }) {
                HStack(spacing: 6) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.clockwise")
                    }
                    Text("Refresh")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppDesignSystem.Colors.primary)
                .cornerRadius(8)
            }
            .disabled(isLoading)
        }
    }
    
    // MARK: - Match Cards
    
    private var matchCardsSection: some View {
        VStack(spacing: 16) {
            let matches = getActiveMatches()
            
            ForEach(matches, id: \.id) { match in
                MatchScoreCard(
                    match: match,
                    liveData: matchDetails[match.id]
                )
            }
        }
    }
    
    // MARK: - Loading & Empty States
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading match data...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 100)
    }
    
    private var noMatchSelectedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sportscourt")
                .font(.system(size: 60))
                .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
            
            Text("No Match Selected")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("Start a live game to see match scores")
                .font(.system(size: 14))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
    
    // MARK: - Helper Methods
    
    private func getActiveMatches() -> [Match] {
        if !gameSession.selectedMatches.isEmpty {
            return gameSession.selectedMatches
        } else if let match = gameSession.selectedMatch {
            return [match]
        }
        return []
    }
    
    private func refreshMatchData() {
        isLoading = true
        
        Task {
            let matches = getActiveMatches()
            
            for match in matches {
                do {
                    let details = try await fetchLiveMatchData(matchId: match.id)
                    await MainActor.run {
                        matchDetails[match.id] = details
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
    
    private func fetchLiveMatchData(matchId: String) async throws -> LiveMatchData {
        let matchDetail = try await DataManager.shared.fetchMatchDetails(matchId)
        return LiveMatchData(from: matchDetail)
    }
    
    private func startAutoRefresh() {
        // Refresh every 60 seconds for live matches
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            let hasLiveMatch = getActiveMatches().contains {
                $0.status == .inProgress || $0.status == .halftime
            }
            if hasLiveMatch {
                refreshMatchData()
            }
        }
    }
    
    private func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Live Match Data Model

struct LiveMatchData {
    let minute: Int?
    let injuryTime: Int?
    let status: MatchStatus
    let homeScore: Int
    let awayScore: Int
    let halfTimeHome: Int?
    let halfTimeAway: Int?
    let possession: (home: Int, away: Int)?
    let shots: (home: Int, away: Int)?
    let shotsOnTarget: (home: Int, away: Int)?
    let corners: (home: Int, away: Int)?
    let fouls: (home: Int, away: Int)?
    let yellowCards: (home: Int, away: Int)?
    let redCards: (home: Int, away: Int)?
    let saves: (home: Int, away: Int)?
    
    var hasStatistics: Bool {
        possession != nil || shots != nil || shotsOnTarget != nil
    }
    
    init(from detail: MatchDetail) {
        self.minute = detail.minute
        self.injuryTime = detail.injuryTime
        self.status = detail.match.status
        self.homeScore = detail.score?.fullTime?.home ?? 0
        self.awayScore = detail.score?.fullTime?.away ?? 0
        self.halfTimeHome = detail.score?.halfTime?.home
        self.halfTimeAway = detail.score?.halfTime?.away
        
        // Extract all available statistics
        let homeStats = detail.homeStatistics
        let awayStats = detail.awayStatistics
        
        // Only set if both teams have the stat
        if let hp = homeStats?.ballPossession, let ap = awayStats?.ballPossession {
            self.possession = (hp, ap)
        } else {
            self.possession = nil
        }
        
        if let hs = homeStats?.shots, let aws = awayStats?.shots {
            self.shots = (hs, aws)
        } else {
            self.shots = nil
        }
        
        if let hsot = homeStats?.shotsOnGoal, let asot = awayStats?.shotsOnGoal {
            self.shotsOnTarget = (hsot, asot)
        } else {
            self.shotsOnTarget = nil
        }
        
        if let hc = homeStats?.cornerKicks, let ac = awayStats?.cornerKicks {
            self.corners = (hc, ac)
        } else {
            self.corners = nil
        }
        
        if let hf = homeStats?.fouls, let af = awayStats?.fouls {
            self.fouls = (hf, af)
        } else {
            self.fouls = nil
        }
        
        if let hy = homeStats?.yellowCards, let ay = awayStats?.yellowCards {
            self.yellowCards = (hy, ay)
        } else {
            self.yellowCards = nil
        }
        
        if let hr = homeStats?.redCards, let ar = awayStats?.redCards {
            self.redCards = (hr, ar)
        } else {
            self.redCards = nil
        }
        
        if let hsv = homeStats?.saves, let asv = awayStats?.saves {
            self.saves = (hsv, asv)
        } else {
            self.saves = nil
        }
    }
}

// MARK: - Match Score Card

struct MatchScoreCard: View {
    let match: Match
    let liveData: LiveMatchData?
    
    var body: some View {
        VStack(spacing: 16) {
            // Status Badge
            matchStatusBadge
            
            // Score Section
            scoreSection
            
            // Half-time score
            if let ht = liveData, let htHome = ht.halfTimeHome, let htAway = ht.halfTimeAway {
                Text("HT: \(htHome) - \(htAway)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Divider()
            
            // Stats Section
            if let data = liveData {
                statsSection(data)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Status Badge
    
    private var matchStatusBadge: some View {
        HStack {
            Text(match.competition.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Spacer()
            
            HStack(spacing: 6) {
                if let data = liveData, data.status == .inProgress || data.status == .halftime {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                }
                
                Text(statusText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(statusColor)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .cornerRadius(8)
        }
    }
    
    private var statusText: String {
        guard let data = liveData else {
            return match.status.displayText
        }
        
        switch data.status {
        case .inProgress:
            if let minute = data.minute {
                if let injury = data.injuryTime, injury > 0 {
                    return "\(minute)+\(injury)'"
                }
                return "\(minute)'"
            }
            return "LIVE"
        case .halftime:
            return "HT"
        case .completed, .finished:
            return "FT"
        default:
            return match.status.displayText
        }
    }
    
    private var statusColor: Color {
        guard let data = liveData else {
            return AppDesignSystem.Colors.secondaryText
        }
        
        switch data.status {
        case .inProgress:
            return AppDesignSystem.Colors.error
        case .halftime:
            return AppDesignSystem.Colors.warning
        case .completed, .finished:
            return AppDesignSystem.Colors.success
        default:
            return AppDesignSystem.Colors.secondaryText
        }
    }
    
    // MARK: - Score Section
    
    private var scoreSection: some View {
        HStack(spacing: 20) {
            // Home Team
            VStack(spacing: 8) {
                Circle()
                    .fill(AppDesignSystem.TeamColors.getColor(for: match.homeTeam))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(match.homeTeam.shortName.prefix(3))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Text(match.homeTeam.shortName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            
            // Score
            HStack(spacing: 12) {
                Text("\(liveData?.homeScore ?? 0)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("-")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Text("\(liveData?.awayScore ?? 0)")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            
            // Away Team
            VStack(spacing: 8) {
                Circle()
                    .fill(AppDesignSystem.TeamColors.getColor(for: match.awayTeam))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Text(match.awayTeam.shortName.prefix(3))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                Text(match.awayTeam.shortName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - Stats Section
    
    @ViewBuilder
    private func statsSection(_ data: LiveMatchData) -> some View {
        if data.hasStatistics {
            VStack(spacing: 10) {
                if let possession = data.possession {
                    statRow(
                        label: "Possession",
                        homeValue: "\(possession.home)%",
                        awayValue: "\(possession.away)%",
                        homePercent: Double(possession.home) / 100.0
                    )
                }
                
                if let shots = data.shots {
                    statRow(
                        label: "Shots",
                        homeValue: "\(shots.home)",
                        awayValue: "\(shots.away)",
                        homePercent: safePercent(shots.home, shots.away)
                    )
                }
                
                if let onTarget = data.shotsOnTarget {
                    statRow(
                        label: "On Target",
                        homeValue: "\(onTarget.home)",
                        awayValue: "\(onTarget.away)",
                        homePercent: safePercent(onTarget.home, onTarget.away)
                    )
                }
                
                if let corners = data.corners {
                    statRow(
                        label: "Corners",
                        homeValue: "\(corners.home)",
                        awayValue: "\(corners.away)",
                        homePercent: safePercent(corners.home, corners.away)
                    )
                }
                
                if let fouls = data.fouls {
                    statRow(
                        label: "Fouls",
                        homeValue: "\(fouls.home)",
                        awayValue: "\(fouls.away)",
                        homePercent: safePercent(fouls.home, fouls.away)
                    )
                }
                
                if let saves = data.saves {
                    statRow(
                        label: "Saves",
                        homeValue: "\(saves.home)",
                        awayValue: "\(saves.away)",
                        homePercent: safePercent(saves.home, saves.away)
                    )
                }
                
                // Cards row (special formatting)
                if let yellow = data.yellowCards, let red = data.redCards {
                    cardsRow(yellowHome: yellow.home, yellowAway: yellow.away,
                            redHome: red.home, redAway: red.away)
                }
            }
        } else {
            // No stats available message
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 24))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
                
                Text("Statistics not available")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                if data.status == .upcoming {
                    Text("Stats will appear once the match starts")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.7))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }

    private func safePercent(_ home: Int, _ away: Int) -> Double {
        let total = home + away
        guard total > 0 else { return 0.5 }
        return Double(home) / Double(total)
    }

    private func cardsRow(yellowHome: Int, yellowAway: Int, redHome: Int, redAway: Int) -> some View {
        HStack {
            // Home cards
            HStack(spacing: 4) {
                if yellowHome > 0 {
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.yellow)
                            .frame(width: 12, height: 16)
                        Text("\(yellowHome)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                if redHome > 0 {
                    HStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.red)
                            .frame(width: 12, height: 16)
                        Text("\(redHome)")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Text("Cards")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            // Away cards
            HStack(spacing: 4) {
                if yellowAway > 0 {
                    HStack(spacing: 2) {
                        Text("\(yellowAway)")
                            .font(.system(size: 12, weight: .semibold))
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.yellow)
                            .frame(width: 12, height: 16)
                    }
                }
                if redAway > 0 {
                    HStack(spacing: 2) {
                        Text("\(redAway)")
                            .font(.system(size: 12, weight: .semibold))
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.red)
                            .frame(width: 12, height: 16)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .foregroundColor(AppDesignSystem.Colors.primaryText)
    }
    
    private func statRow(label: String, homeValue: String, awayValue: String, homePercent: Double) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(homeValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Spacer()
                
                Text(awayValue)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            
            GeometryReader { geo in
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(AppDesignSystem.TeamColors.getColor(for: match.homeTeam))
                        .frame(width: geo.size.width * homePercent)
                    
                    Rectangle()
                        .fill(AppDesignSystem.TeamColors.getColor(for: match.awayTeam))
                        .frame(width: geo.size.width * (1 - homePercent))
                }
                .cornerRadius(2)
            }
            .frame(height: 6)
        }
    }
}

// MARK: - MatchStatus Extension

extension MatchStatus {
    var displayText: String {
        switch self {
        case .upcoming: return "Upcoming"
        case .inProgress: return "LIVE"
        case .halftime: return "HT"
        case .completed, .finished: return "FT"
        case .postponed: return "Postponed"
        case .cancelled: return "Cancelled"
        case .suspended: return "Suspended"
        case .paused: return "Paused"
        case .unknown: return "Unknown"
        }
    }
}*/
