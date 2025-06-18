//
//  StatsView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 16/05/2025.
//

// Create StatsView.swift
import SwiftUI

struct StatsView: View {
    @ObservedObject var gameSession: GameSession
    @State private var selectedTab = 0
    
    private let calculator: StatsCalculator
    
    init(gameSession: GameSession) {
        self.gameSession = gameSession
        self.calculator = StatsCalculator(gameSession: gameSession)
    }
    
    var body: some View {
        VStack {
            // Tab selector
            Picker("Statistics", selection: $selectedTab) {
                Text("Team Stats").tag(0)
                Text("Players").tag(1)
                Text("Participants").tag(2)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Content based on selected tab
            ScrollView {
                switch selectedTab {
                case 0:
                    teamStatsView
                case 1:
                    playerStatsView
                case 2:
                    participantStatsView
                default:
                    EmptyView()
                }
            }
            .background(AppDesignSystem.Colors.background)
            
            .withTabBanner(tabName: "StatsView") // Revenue from tab switching
            .onAppear {
                AdManager.shared.recordViewTransition(from: "EventsTimeline", to: "StatsView")
            }
        }
        .navigationTitle("Statistics")
    }
    
    private var teamStatsView: some View {
        VStack(spacing: 16) {
            let teamStats = calculator.calculateTeamStats()
            
            if teamStats.isEmpty {
                Text("No team statistics available")
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .padding()
            } else {
                ForEach(teamStats) { stats in
                    VStack {
                        HStack {
                            Text(stats.team.name)
                                .font(AppDesignSystem.Typography.subheadingFont)
                                .foregroundColor(AppDesignSystem.TeamColors.getColor(for: stats.team))
                            
                            Spacer()
                            
                            Text("\(stats.players) players")
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                        
                        HStack(spacing: 20) {
                            statPill(
                                label: "Goals",
                                value: stats.goals,
                                color: AppDesignSystem.TeamColors.getColor(for: stats.team)
                            )
                            
                            statPill(
                                label: "Assists",
                                value: stats.assists,
                                color: AppDesignSystem.TeamColors.getColor(for: stats.team)
                            )
                            
                            statPill(
                                label: "Yellow",
                                value: stats.yellowCards,
                                color: AppDesignSystem.Colors.warning
                            )
                            
                            statPill(
                                label: "Red",
                                value: stats.redCards,
                                color: AppDesignSystem.Colors.error
                            )
                        }
                        .padding(.vertical, 8)
                    }
                    .padding()
                    .background(AppDesignSystem.Colors.cardBackground)
                    .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
        }
        .padding()
    }
    
    private var playerStatsView: some View {
        VStack(spacing: 16) {
            let playerStats = calculator.calculatePlayerStats()
            
            if playerStats.isEmpty {
                Text("No player statistics available")
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .padding()
            } else {
                VStack(alignment: .leading) {
                    Text("Top Performers")
                        .font(AppDesignSystem.Typography.headingFont)
                        .padding(.bottom, 8)
                    
                    ForEach(playerStats.prefix(10)) { stats in
                        HStack {
                            // Breaking down the complex index calculation
                            let index = playerStats.firstIndex(where: { $0.id == stats.id }) ?? 0
                            Text("\(index + 1).")
                                .font(AppDesignSystem.Typography.bodyFont)
                                .frame(width: 25, alignment: .leading)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stats.player.name)
                                    .font(AppDesignSystem.Typography.bodyFont.bold())
                                
                                Text("\(stats.player.team.name) • \(stats.participant)")
                                    .font(AppDesignSystem.Typography.captionFont)
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(format: "+%.2f pts", stats.pointsGenerated))
                                    .font(AppDesignSystem.Typography.bodyFont.bold())
                                    .foregroundColor(AppDesignSystem.Colors.success)
                                
                                Text("\(stats.eventsCount) events")
                                    .font(AppDesignSystem.Typography.captionFont)
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            }
                        }
                        .padding()
                        .background(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        AppDesignSystem.TeamColors.getAccentColor(for: stats.player.team),
                                        AppDesignSystem.Colors.cardBackground
                                    ]
                                ),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
                
                VStack(alignment: .leading) {
                    Text("Most Efficient Players")
                        .font(AppDesignSystem.Typography.headingFont)
                        .padding(.vertical, 16)
                    
                    // Breaking down the complex chain of filters and sorts
                    let filteredStats = playerStats.filter { $0.eventsCount > 0 }
                    let sortedStats = filteredStats.sorted(by: { $0.efficiency > $1.efficiency })
                    let topEfficientPlayers = sortedStats.prefix(5)
                    
                    ForEach(topEfficientPlayers) { stats in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stats.player.name)
                                    .font(AppDesignSystem.Typography.bodyFont.bold())
                                
                                Text("\(stats.player.team.name) • \(stats.participant)")
                                    .font(AppDesignSystem.Typography.captionFont)
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(String(format: "%.2f pts/event", stats.efficiency))
                                    .font(AppDesignSystem.Typography.bodyFont.bold())
                                    .foregroundColor(AppDesignSystem.Colors.accent)
                                
                                Text("\(stats.eventsCount) events")
                                    .font(AppDesignSystem.Typography.captionFont)
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            }
                        }
                        .padding()
                        .background(AppDesignSystem.Colors.cardBackground)
                        .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                    }
                }
            }
        }
        .padding()
    }
    
    private var participantStatsView: some View {
        VStack(spacing: 16) {
            let participantStats = calculator.calculateParticipantStats()
            
            if participantStats.isEmpty {
                Text("No participant statistics available")
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .padding()
            } else {
                ForEach(participantStats) { stats in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(stats.participant.name)
                                .font(AppDesignSystem.Typography.subheadingFont)
                            
                            Spacer()
                            
                            Text(formatCurrency(stats.participant.balance))
                                .font(AppDesignSystem.Typography.bodyFont.bold())
                                .foregroundColor(stats.participant.balance >= 0 ?
                                                 AppDesignSystem.Colors.success :
                                                 AppDesignSystem.Colors.error)
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Total Events")
                                    .font(AppDesignSystem.Typography.captionFont)
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                
                                Text("\(stats.totalEvents)")
                                    .font(AppDesignSystem.Typography.bodyFont)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("ROI Per Player")
                                    .font(AppDesignSystem.Typography.captionFont)
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                
                                Text(String(format: "%.2f", stats.roi))
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(stats.roi >= 0 ?
                                                     AppDesignSystem.Colors.success :
                                                     AppDesignSystem.Colors.error)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading) {
                                Text("MVP")
                                    .font(AppDesignSystem.Typography.captionFont)
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                
                                if let mvp = stats.mostValuablePlayer {
                                    Text(mvp.name)
                                        .font(AppDesignSystem.Typography.bodyFont)
                                } else {
                                    Text("None")
                                        .font(AppDesignSystem.Typography.bodyFont)
                                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(AppDesignSystem.Colors.cardBackground)
                    .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                    .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
        }
        .padding()
    }
    
    private func statPill(label: String, value: Int, color: Color) -> some View {
        VStack {
            Text("\(value)")
                .font(AppDesignSystem.Typography.bodyFont.bold())
                .foregroundColor(color)
            
            Text(label)
                .font(AppDesignSystem.Typography.captionFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .cornerRadius(AppDesignSystem.Layout.smallCornerRadius)
    }
    
    // Breaking down the complex formatCurrency function
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        
        // Get the currency symbol from UserDefaults
        let symbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        formatter.currencySymbol = symbol
        
        // Format the number
        let formattedString = formatter.string(from: NSNumber(value: value))
        return formattedString ?? "€0.00"
    }
}
