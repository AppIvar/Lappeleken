//
//  SetupReviewView.swift
//  Lucky Football Slip
//
//  Step 4: Review and start - Football themed design
//

import SwiftUI

struct SetupReviewView: View {
    @ObservedObject var gameSession: GameSession
    let selectedPlayerIds: Set<UUID>
    let betAmounts: [Bet.EventType: Double]
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            SetupStepHeaderNew(
                icon: "checkmark.seal.fill",
                title: "Ready to Play!",
                subtitle: "Review your setup and start the game"
            )
            
            // Summary cards
            VStack(spacing: 14) {
                // Participants
                ReviewSummaryCard(
                    title: "Participants",
                    icon: "person.2.fill",
                    count: gameSession.participants.count,
                    color: AppDesignSystem.Colors.grassGreen
                ) {
                    ForEach(gameSession.participants) { participant in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                                    .frame(width: 28, height: 28)
                                
                                Text(String(participant.name.prefix(1)).uppercased())
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                            }
                            
                            Text(participant.name)
                                .font(.system(size: 14))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Spacer()
                            
                            // Show assigned players count if available
                            if !participant.selectedPlayers.isEmpty {
                                Text("\(participant.selectedPlayers.count) players")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            }
                        }
                    }
                }
                
                // Players
                ReviewSummaryCard(
                    title: "Selected Players",
                    icon: "sportscourt.fill",
                    count: selectedPlayerIds.count,
                    color: AppDesignSystem.Colors.goalYellow
                ) {
                    Text(playersFromTeamsText)
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    // Show team breakdown
                    let teamCounts = getTeamPlayerCounts()
                    if !teamCounts.isEmpty {
                        VStack(spacing: 6) {
                            ForEach(Array(teamCounts.keys.sorted()), id: \.self) { teamName in
                                HStack {
                                    Text(teamName)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                                    Spacer()
                                    Text("\(teamCounts[teamName] ?? 0)")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppDesignSystem.Colors.goalYellow)
                                }
                            }
                        }
                        .padding(.top, 6)
                    }
                }
                
                // Bet rules
                ReviewSummaryCard(
                    title: "Bet Rules",
                    icon: "dollarsign.circle.fill",
                    count: activeBetCount,
                    color: AppDesignSystem.Colors.accent
                ) {
                    VStack(spacing: 6) {
                        // Active standard bets
                        ForEach(Array(betAmounts.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { eventType in
                            let amount = betAmounts[eventType] ?? 0
                            if amount != 0 {
                                HStack {
                                    Text(eventType.rawValue.capitalized)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                                    
                                    Spacer()
                                    
                                    Text(formatCurrencyAmount(amount))
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(amount < 0 ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.grassGreen)
                                }
                            }
                        }
                        
                        // Custom events
                        ForEach(gameSession.getCustomEvents(), id: \.id) { customEvent in
                            HStack {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(AppDesignSystem.Colors.accent)
                                    Text(customEvent.name)
                                        .font(.system(size: 13))
                                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                                }
                                
                                Spacer()
                                
                                Text(formatCurrencyAmount(customEvent.amount))
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(customEvent.amount < 0 ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.grassGreen)
                            }
                        }
                    }
                }
            }
            
            // Ready indicator
            readyIndicator
        }
    }
    
    // MARK: - Ready Indicator
    
    private var readyIndicator: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(AppDesignSystem.Colors.grassGreen)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("All set!")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Tap 'Start Game' to begin playing")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.grassGreen.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppDesignSystem.Colors.grassGreen.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Helpers
    
    private var playersFromTeamsText: String {
        let selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
        let uniqueTeams = Set(selectedPlayers.map { $0.team.name })
        return "\(selectedPlayers.count) players from \(uniqueTeams.count) team\(uniqueTeams.count == 1 ? "" : "s")"
    }
    
    private func getTeamPlayerCounts() -> [String: Int] {
        let selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
        var counts: [String: Int] = [:]
        for player in selectedPlayers {
            counts[player.team.name, default: 0] += 1
        }
        return counts
    }
    
    private var activeBetCount: Int {
        let standardBets = betAmounts.filter { $0.value != 0 }.count
        let customBets = gameSession.getCustomEvents().count
        return standardBets + customBets
    }
}

// MARK: - Review Summary Card

struct ReviewSummaryCard<Content: View>: View {
    let title: String
    let icon: String
    let count: Int
    let color: Color
    @ViewBuilder let content: () -> Content
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with accent strip
            HStack(spacing: 10) {
                // Accent strip
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 4, height: 24)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text("\(count)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(color))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(color.opacity(0.06))
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                content()
            }
            .padding(14)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}
