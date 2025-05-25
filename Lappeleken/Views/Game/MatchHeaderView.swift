//
//  MatchHeaderView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 22/05/2025.
//

import SwiftUI

struct MatchHeaderView: View {
    let match: Match
    @State private var currentTime = Date()
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 12) {
            // Competition and status
            HStack {
                Text(match.competition.name)
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Spacer()
                
                matchStatusBadge
            }
            
            // Team names and score
            HStack(spacing: 20) {
                // Home team
                VStack {
                    Text(match.homeTeam.name)
                        .font(AppDesignSystem.Typography.headingFont)
                        .foregroundColor(AppDesignSystem.TeamColors.getColor(for: match.homeTeam))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(match.homeTeam.shortName)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                
                // Score or vs
                VStack {
                    if match.status == .inProgress || match.status == .halftime || match.status == .completed {
                        // Show score (placeholder for now - will be updated with API data)
                        HStack(spacing: 8) {
                            Text("0")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Text("-")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            
                            Text("0")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                        }
                    } else {
                        Text("vs")
                            .font(AppDesignSystem.Typography.headingFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    // Match time info
                    Text(matchTimeText)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                // Away team
                VStack {
                    Text(match.awayTeam.name)
                        .font(AppDesignSystem.Typography.headingFont)
                        .foregroundColor(AppDesignSystem.TeamColors.getColor(for: match.awayTeam))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                    
                    Text(match.awayTeam.shortName)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(AppDesignSystem.Colors.cardBackground)
        .cornerRadius(AppDesignSystem.Layout.cornerRadius)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .padding(.horizontal)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private var matchStatusBadge: some View {
        let (text, color) = matchStatusInfo
        
        return Text(text)
            .font(AppDesignSystem.Typography.captionFont)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(8)
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
            // Calculate elapsed time (this would be more accurate with API data)
            let elapsed = Int(currentTime.timeIntervalSince(match.startTime) / 60)
            return "\(min(elapsed, 90))'"
            
        case .halftime:
            return "Half-time"
            
        case .completed:
            return "Full-time"
            
        case .unknown:
            return "Unknown"
        }
    }
}
