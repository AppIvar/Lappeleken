//
//  MatchHeaderView.swift
//  Lucky Football Slip
//
//  Football themed match header
//

import SwiftUI

struct MatchHeaderView: View {
    let match: Match
    @State private var currentTime = Date()
    @Environment(\.colorScheme) var colorScheme
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 14) {
            // Competition and status row
            HStack {
                Text(match.competition.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Spacer()
                
                matchStatusBadge
            }
            
            // Teams and score
            HStack(spacing: 16) {
                // Home team
                teamColumn(team: match.homeTeam, isHome: true)
                
                // Score / VS
                scoreSection
                
                // Away team
                teamColumn(team: match.awayTeam, isHome: false)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppDesignSystem.Colors.grassGreen.opacity(0.15), lineWidth: 1)
                )
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                    radius: 6,
                    x: 0,
                    y: 3
                )
        )
        .padding(.horizontal)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    // MARK: - Team Column
    
    private func teamColumn(team: Team, isHome: Bool) -> some View {
        VStack(spacing: 6) {
            // Team color indicator
            Circle()
                .fill(AppDesignSystem.TeamColors.getColor(for: team))
                .frame(width: 40, height: 40)
                .overlay(
                    Text(team.shortName.prefix(2))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                )
            
            Text(team.name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.center)
            
            Text(team.shortName)
                .font(.system(size: 11))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Score Section
    
    private var scoreSection: some View {
        VStack(spacing: 4) {
            if match.status == .inProgress || match.status == .halftime || match.status == .completed || match.status == .finished {
                HStack(spacing: 8) {
                    Text("0")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("-")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Text("0")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                }
            } else {
                Text("vs")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Text(matchTimeText)
                .font(.system(size: 11))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
    }
    
    // MARK: - Status Badge
    
    private var matchStatusBadge: some View {
        let (text, color) = matchStatusInfo
        
        return HStack(spacing: 4) {
            if match.status == .inProgress {
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
            }
            
            Text(text)
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule().fill(color)
        )
    }
    
    private var matchStatusInfo: (String, Color) {
        switch match.status {
        case .upcoming: return ("Upcoming", AppDesignSystem.Colors.info)
        case .inProgress: return ("LIVE", AppDesignSystem.Colors.grassGreen)
        case .halftime: return ("HT", AppDesignSystem.Colors.goalYellow)
        case .completed, .finished: return ("FT", AppDesignSystem.Colors.secondaryText)
        case .postponed: return ("PPD", AppDesignSystem.Colors.error)
        case .cancelled: return ("CAN", AppDesignSystem.Colors.error)
        case .paused: return ("Paused", AppDesignSystem.Colors.goalYellow)
        case .suspended: return ("SUS", AppDesignSystem.Colors.error)
        case .unknown: return ("—", AppDesignSystem.Colors.secondaryText)
        }
    }
    
    private var matchTimeText: String {
        let formatter = DateFormatter()
        
        switch match.status {
        case .upcoming:
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: match.startTime)
        case .inProgress: return "Live"
        case .halftime: return "Half-time"
        case .completed, .finished: return "Full-time"
        case .postponed: return "Postponed"
        case .cancelled: return "Cancelled"
        case .paused: return "Paused"
        case .suspended: return "Suspended"
        case .unknown: return "Unknown"
        }
    }
}
