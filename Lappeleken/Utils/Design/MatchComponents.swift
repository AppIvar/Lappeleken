//
//  MatchComponents.swift
//  Lucky Football Slip
//
//  Apple Sports-inspired match UI components
//  Uses AppDesignSystem for consistency
//

import SwiftUI

// MARK: - Match Card (Apple Sports Style)

struct AppleSportsMatchCard: View {
    let match: Match
    let isSelected: Bool
    let accessStatus: LeagueAccessStatus
    let onTap: () -> Void
    
    private var isLocked: Bool {
        if case .locked(_) = accessStatus { return true }
        return false
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 0) {
                // Home team
                teamView(team: match.homeTeam, isHome: true)
                
                // Center: Score or Time
                centerView
                
                // Away team
                teamView(team: match.awayTeam, isHome: false)
                
                // Selection indicator
                selectionIndicator
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(cardBackground)
            .overlay(selectionBorder)
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium))
            .opacity(isLocked ? 0.5 : 1.0)
            .overlay(lockOverlay)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Team View
    
    private func teamView(team: Team, isHome: Bool) -> some View {
        HStack(spacing: 8) {
            if !isHome { Spacer(minLength: 0) }
            
            Text(team.shortName.isEmpty ? team.name : team.shortName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(isLocked ? AppDesignSystem.Colors.tertiaryText : AppDesignSystem.Colors.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            if isHome { Spacer(minLength: 0) }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Center View (Score/Time)
    
    private var centerView: some View {
        VStack(spacing: 2) {
            Text(formatKickoffTime(match.startTime))
                .font(AppDesignSystem.Typography.scoreMedium)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            statusLabel
        }
        .frame(width: 100)
    }
    
    private var statusLabel: some View {
        Group {
            switch match.status {
            case .inProgress:
                LiveIndicator()
            case .halftime:
                StatusBadge("HT", color: AppDesignSystem.Colors.halftime, style: .soft)
            case .completed, .finished:
                StatusBadge("FT", color: AppDesignSystem.Colors.finished, style: .soft)
            case .upcoming:
                Text(formatKickoffDate(match.startTime))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            case .postponed:
                StatusBadge("POSTPONED", color: AppDesignSystem.Colors.error, style: .soft)
            case .cancelled:
                StatusBadge("CANCELLED", color: AppDesignSystem.Colors.error, style: .soft)
            default:
                Text(formatKickoffDate(match.startTime))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
    
    // MARK: - Selection Indicator
    
    private var selectionIndicator: some View {
        Group {
            if isLocked {
                Image(systemName: "lock.fill")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.disabled)
                    .frame(width: 32)
            } else {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.tertiaryText)
                    .frame(width: 32)
            }
        }
    }
    
    // MARK: - Background & Borders
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
            .fill(isSelected ? AppDesignSystem.Colors.selected : AppDesignSystem.Colors.cardBackground)
    }
    
    private var selectionBorder: some View {
        RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
            .stroke(isSelected ? AppDesignSystem.Colors.selectedBorder : Color.clear, lineWidth: 1.5)
    }
    
    private var lockOverlay: some View {
        Group {
            if isLocked {
                VStack {
                    Spacer()
                    Text("Tap to unlock")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(AppDesignSystem.Colors.live.opacity(0.9)))
                        .padding(.bottom, 6)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func formatKickoffTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    private func formatKickoffDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - League Section Header

struct LeagueSectionHeader: View {
    let leagueName: String
    let leagueCode: String
    let matchCount: Int
    let selectedCount: Int
    let accessStatus: LeagueAccessStatus
    let isExpanded: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // League badge
                LeagueBadge(leagueCode, size: .medium)
                
                // League info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(leagueName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        AccessBadge(status: accessStatus)
                    }
                    
                    Text("\(matchCount) match\(matchCount == 1 ? "" : "es")")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                // Selected count badge
                if selectedCount > 0 {
                    CountBadge(selectedCount)
                }
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.tertiaryText)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(AppDesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Date Section Header

struct DateSectionHeader: View {
    let date: Date
    
    var body: some View {
        HStack {
            Text(formattedDate)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .textCase(.uppercase)
            
            Spacer()
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }
    
    private var formattedDate: String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            return formatter.string(from: date)
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Compact Match Row (for tables/lists)

struct CompactMatchRow: View {
    let match: Match
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Status indicator
                MatchStatusIndicator(match.status)
                    .frame(width: 70)
                
                // Teams
                VStack(alignment: .leading, spacing: 2) {
                    Text(match.homeTeam.shortName.isEmpty ? match.homeTeam.name : match.homeTeam.shortName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .lineLimit(1)
                    
                    Text(match.awayTeam.shortName.isEmpty ? match.awayTeam.name : match.awayTeam.shortName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Kickoff time
                Text(formatTime(match.startTime))
                    .font(AppDesignSystem.Typography.timeDisplay)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                // Selection
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.tertiaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(isSelected ? AppDesignSystem.Colors.selected : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}

// MARK: - Empty State View

struct EmptyMatchesView: View {
    let onRefresh: () -> Void
    
    var body: some View {
        EmptyState(
            icon: "sportscourt",
            title: "No Matches Available",
            message: "Check back later for upcoming fixtures",
            actionTitle: "Refresh",
            action: onRefresh
        )
    }
}


