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
    @State private var autoRefreshTimer: Timer?
    
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
            startAutoRefresh()
        }
        .onDisappear {
            stopAutoRefresh()
        }
    }
    
    // MARK: - Auto Refresh
    
    private func startAutoRefresh() {
        // Initial fetch
        Task { await refreshAllMatches() }
        
        // Set up timer for live matches (every 30 seconds)
        autoRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            // Only refresh if we have live matches
            let hasLiveMatch = gameSession.selectedMatches.contains {
                $0.status == .inProgress || $0.status == .halftime
            }
            if hasLiveMatch {
                Task { await refreshAllMatches() }
            }
        }
    }
    
    private func stopAutoRefresh() {
        autoRefreshTimer?.invalidate()
        autoRefreshTimer = nil
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
                // Fetch match details with events
                let (detail, events) = try await fetchMatchWithEvents(matchId: match.id, homeTeamId: match.homeTeam.effectiveApiId)
                await MainActor.run {
                    matchData[match.id] = LiveMatchData(
                        from: detail,
                        goals: events.goals,
                        bookings: events.bookings,
                        substitutions: events.substitutions
                    )
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
    
    private func fetchMatchWithEvents(matchId: String, homeTeamId: String) async throws -> (MatchDetail, MatchEvents) {
        // Route through APIClient so this respects the rate limiter AND the cache
        // server (it injects X-Auth-Token / cache routing) instead of hitting
        // football-data.org directly.
        let apiClient = ServiceProvider.shared.getFootballDataAPIClient()
        let data = try await apiClient.footballDataRawData(endpoint: "matches/\(matchId)")

        // Parse the full response including events
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw URLError(.cannotParseResponse)
        }
        
        // Get home team ID for determining event side
        let apiHomeTeamId = (json["homeTeam"] as? [String: Any])?["id"] as? Int ?? 0
        
        // Parse goals
        var goals: [MatchGoalEvent] = []
        if let goalsArray = json["goals"] as? [[String: Any]] {
            for (index, goal) in goalsArray.enumerated() {
                if let minute = goal["minute"] as? Int,
                   let scorer = goal["scorer"] as? [String: Any],
                   let scorerName = scorer["name"] as? String,
                   let team = goal["team"] as? [String: Any],
                   let teamId = team["id"] as? Int {
                    let assist = goal["assist"] as? [String: Any]
                    let assistName = assist?["name"] as? String
                    let type = goal["type"] as? String ?? "REGULAR"
                    
                    goals.append(MatchGoalEvent(
                        id: "goal_\(matchId)_\(index)",
                        minute: minute,
                        scorerName: scorerName,
                        assistName: assistName,
                        type: type,
                        teamId: teamId,
                        isHome: teamId == apiHomeTeamId
                    ))
                }
            }
        }
        
        // Parse bookings
        var bookings: [MatchBookingEvent] = []
        if let bookingsArray = json["bookings"] as? [[String: Any]] {
            for (index, booking) in bookingsArray.enumerated() {
                if let minute = booking["minute"] as? Int,
                   let player = booking["player"] as? [String: Any],
                   let playerName = player["name"] as? String,
                   let card = booking["card"] as? String,
                   let team = booking["team"] as? [String: Any],
                   let teamId = team["id"] as? Int {
                    bookings.append(MatchBookingEvent(
                        id: "booking_\(matchId)_\(index)",
                        minute: minute,
                        playerName: playerName,
                        card: card,
                        teamId: teamId,
                        isHome: teamId == apiHomeTeamId
                    ))
                }
            }
        }
        
        // Parse substitutions
        var substitutions: [MatchSubstitutionEvent] = []
        if let subsArray = json["substitutions"] as? [[String: Any]] {
            for (index, sub) in subsArray.enumerated() {
                if let minute = sub["minute"] as? Int,
                   let playerIn = sub["playerIn"] as? [String: Any],
                   let playerOut = sub["playerOut"] as? [String: Any],
                   let playerInName = playerIn["name"] as? String,
                   let playerOutName = playerOut["name"] as? String,
                   let team = sub["team"] as? [String: Any],
                   let teamId = team["id"] as? Int {
                    substitutions.append(MatchSubstitutionEvent(
                        id: "sub_\(matchId)_\(index)",
                        minute: minute,
                        playerInName: playerInName,
                        playerOutName: playerOutName,
                        teamId: teamId,
                        isHome: teamId == apiHomeTeamId
                    ))
                }
            }
        }
        
        // Get basic match detail
        let detail = try await DataManager.shared.fetchMatchDetails(matchId)
        
        return (detail, MatchEvents(goals: goals, bookings: bookings, substitutions: substitutions))
    }
}

struct MatchEvents {
    let goals: [MatchGoalEvent]
    let bookings: [MatchBookingEvent]
    let substitutions: [MatchSubstitutionEvent]
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
    
    // Match events
    let goals: [MatchGoalEvent]
    let bookings: [MatchBookingEvent]
    let substitutions: [MatchSubstitutionEvent]
    
    init(from detail: MatchDetail, goals: [MatchGoalEvent] = [], bookings: [MatchBookingEvent] = [], substitutions: [MatchSubstitutionEvent] = []) {
        self.minute = detail.minute
        self.injuryTime = detail.injuryTime
        self.status = detail.match.status
        self.homeScore = detail.score?.fullTime?.home ?? 0
        self.awayScore = detail.score?.fullTime?.away ?? 0
        self.halfTimeHome = detail.score?.halfTime?.home
        self.halfTimeAway = detail.score?.halfTime?.away
        self.goals = goals
        self.bookings = bookings
        self.substitutions = substitutions
    }
}

// Event models for display
struct MatchGoalEvent: Identifiable {
    let id: String
    let minute: Int
    let scorerName: String
    let assistName: String?
    let type: String  // REGULAR, PENALTY, OWN_GOAL
    let teamId: Int
    let isHome: Bool
}

struct MatchBookingEvent: Identifiable {
    let id: String
    let minute: Int
    let playerName: String
    let card: String  // YELLOW, RED
    let teamId: Int
    let isHome: Bool
}

struct MatchSubstitutionEvent: Identifiable {
    let id: String
    let minute: Int
    let playerInName: String
    let playerOutName: String
    let teamId: Int
    let isHome: Bool
}

// MARK: - Score Card

struct ScoreCard: View {
    let match: Match
    let liveData: LiveMatchData?
    
    @Environment(\.colorScheme) var colorScheme
    @State private var showEvents = true
    
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
            
            // Events timeline
            if let data = liveData, hasEvents(data) {
                eventsSection(data)
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
    
    private func hasEvents(_ data: LiveMatchData) -> Bool {
        !data.goals.isEmpty || !data.bookings.isEmpty || !data.substitutions.isEmpty
    }
    
    private func eventsSection(_ data: LiveMatchData) -> some View {
        VStack(spacing: 8) {
            Divider()
                .background(AppDesignSystem.Colors.secondaryText.opacity(0.2))
            
            // Combine and sort all events by minute
            let allEvents = buildEventsList(data)
            
            ForEach(allEvents, id: \.id) { event in
                eventRow(event)
            }
        }
    }
    
    private func buildEventsList(_ data: LiveMatchData) -> [MatchEventDisplay] {
        var events: [MatchEventDisplay] = []
        
        // Add goals
        for goal in data.goals {
            let icon = goal.type == "OWN_GOAL" ? "⚽️🔴" : (goal.type == "PENALTY" ? "⚽️(P)" : "⚽️")
            var text = goal.scorerName
            if let assist = goal.assistName {
                text += " (assist: \(assist))"
            }
            if goal.type == "OWN_GOAL" {
                text += " (OG)"
            }
            events.append(MatchEventDisplay(
                id: goal.id,
                minute: goal.minute,
                icon: icon,
                text: text,
                isHome: goal.isHome,
                color: AppDesignSystem.Colors.grassGreen
            ))
        }
        
        // Add bookings
        for booking in data.bookings {
            let icon = booking.card == "RED" ? "🟥" : "🟨"
            events.append(MatchEventDisplay(
                id: booking.id,
                minute: booking.minute,
                icon: icon,
                text: booking.playerName,
                isHome: booking.isHome,
                color: booking.card == "RED" ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.warning
            ))
        }
        
        // Add substitutions
        for sub in data.substitutions {
            events.append(MatchEventDisplay(
                id: sub.id,
                minute: sub.minute,
                icon: "🔄",
                text: "\(sub.playerInName) ↔ \(sub.playerOutName)",
                isHome: sub.isHome,
                color: AppDesignSystem.Colors.secondaryText
            ))
        }
        
        return events.sorted { $0.minute < $1.minute }
    }
    
    private func eventRow(_ event: MatchEventDisplay) -> some View {
        HStack(spacing: 8) {
            // Home side
            if event.isHome {
                Text(event.text)
                    .font(.system(size: 11))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                
                Text(event.icon)
                    .font(.system(size: 12))
            } else {
                Spacer()
                    .frame(maxWidth: .infinity)
                Text("")
                    .frame(width: 24)
            }
            
            // Minute
            Text("\(event.minute)'")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .frame(width: 28)
            
            // Away side
            if !event.isHome {
                Text(event.icon)
                    .font(.system(size: 12))
                
                Text(event.text)
                    .font(.system(size: 11))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("")
                    .frame(width: 24)
                Spacer()
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 2)
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

// Helper struct for unified event display
struct MatchEventDisplay {
    let id: String
    let minute: Int
    let icon: String
    let text: String
    let isHome: Bool
    let color: Color
}
