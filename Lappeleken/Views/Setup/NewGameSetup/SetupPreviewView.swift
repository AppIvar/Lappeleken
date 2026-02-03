//
//  SetupReviewView.swift
//  Lucky Football Slip
//
//  Step 4: Review and start
//

import SwiftUI

struct SetupReviewView: View {
    @ObservedObject var gameSession: GameSession
    let selectedPlayerIds: Set<UUID>
    let betAmounts: [Bet.EventType: Double]
    
    var body: some View {
        VStack(spacing: 24) {
            SetupStepHeader(
                icon: "checkmark.circle.fill",
                iconColor: AppDesignSystem.Colors.success,
                title: "Review & Start",
                subtitle: "Review your game setup and start playing!"
            )
            
            VStack(spacing: 20) {
                // Participants summary
                SetupSummaryCard(
                    title: "Participants",
                    count: gameSession.participants.count,
                    color: AppDesignSystem.Colors.primary
                ) {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(gameSession.participants) { participant in
                            HStack {
                                Circle()
                                    .fill(AppDesignSystem.Colors.primary)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text(String(participant.name.prefix(1)).uppercased())
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                Text(participant.name)
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                
                                Spacer()
                            }
                        }
                    }
                }
                
                // Players summary
                SetupSummaryCard(
                    title: "Selected Players",
                    count: selectedPlayerIds.count,
                    color: AppDesignSystem.Colors.secondary
                ) {
                    Text(playersFromTeamsText)
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                // Bet rules summary
                SetupSummaryCard(
                    title: "Bet Rules",
                    count: betAmounts.count + gameSession.getCustomEvents().count,
                    color: AppDesignSystem.Colors.accent
                ) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Standard bets
                        ForEach(Array(betAmounts.keys.sorted { $0.rawValue < $1.rawValue }), id: \.self) { eventType in
                            HStack {
                                Text(eventType.rawValue.capitalized)
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                
                                Spacer()
                                
                                Text(formatCurrencyAmount(betAmounts[eventType] ?? 0))
                                    .font(AppDesignSystem.Typography.bodyBold)
                                    .foregroundColor(betAmounts[eventType] ?? 0 < 0 ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                            }
                        }
                        
                        // Custom events
                        ForEach(gameSession.getCustomEvents(), id: \.id) { customEvent in
                            HStack {
                                Text(customEvent.name)
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                
                                Spacer()
                                
                                Text(formatCurrencyAmount(customEvent.amount))
                                    .font(AppDesignSystem.Typography.bodyBold)
                                    .foregroundColor(customEvent.amount < 0 ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var playersFromTeamsText: String {
        let selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
        let teamNames = selectedPlayers.map { $0.team.name }
        let uniqueTeams = Set(teamNames)
        return "Players from \(uniqueTeams.count) team\(uniqueTeams.count == 1 ? "" : "s")"
    }
}
