//
//  Enhanced PlayerCard.swift
//  Lucky Football Slip
//
//  Vibrant player card with enhanced design system - ANIMATIONS REMOVED
//

import SwiftUI

struct PlayerCard: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    private var playerAvatarGradient: RadialGradient {
        RadialGradient(
            colors: [
                AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.8),
                AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.4),
                AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.1)
            ],
            center: .center,
            startRadius: 5,
            endRadius: 25
        )
    }
    
    var body: some View {
        Button(action: action) { // SIMPLIFIED: Direct action call, no animation
            HStack(spacing: 16) {
                // Enhanced player avatar with team colors
                ZStack {
                    Circle()
                        .fill(playerAvatarGradient)
                        .frame(width: 50, height: 50)
                    
                    // Player initials or position icon
                    Group {
                        if let firstLetter = player.name.first {
                            Text(String(firstLetter).uppercased())
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: positionIcon(for: player.position))
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .shadow(
                    color: AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.4),
                    radius: 6,
                    x: 0,
                    y: 3
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    // Player name
                    Text(player.name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .lineLimit(1)
                    
                    // Team info with enhanced styling
                    HStack(spacing: 8) {
                        // Team color indicator
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                            .frame(width: 4, height: 16)
                        
                        Text(player.team.name)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.TeamColors.getColor(for: player.team))
                        
                        Text("•")
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Text(player.position.rawValue)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    // Enhanced stats row
                    if hasStats {
                        HStack(spacing: 12) {
                            if player.goals > 0 {
                                StatBadge(icon: "soccerball", value: player.goals, color: AppDesignSystem.Colors.success)
                            }
                            if player.assists > 0 {
                                StatBadge(icon: "arrow.up.forward", value: player.assists, color: AppDesignSystem.Colors.info)
                            }
                            if player.yellowCards > 0 {
                                StatBadge(icon: "square.fill", value: player.yellowCards, color: AppDesignSystem.Colors.warning)
                            }
                            if player.redCards > 0 {
                                StatBadge(icon: "square.fill", value: player.redCards, color: AppDesignSystem.Colors.error)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Enhanced selection indicator (no animation)
                if isSelected {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        AppDesignSystem.Colors.success.opacity(0.3),
                                        AppDesignSystem.Colors.success.opacity(0.1),
                                        Color.clear
                                    ],
                                    center: .center,
                                    startRadius: 5,
                                    endRadius: 20
                                )
                            )
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.success)
                    }
                    // REMOVED: .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [
                                AppDesignSystem.TeamColors.getAccentColor(for: player.team),
                                AppDesignSystem.TeamColors.getAccentColor(for: player.team).opacity(0.5)
                            ],
                            startPoint: .topLeading, // REMOVED: animation-dependent values
                            endPoint: .bottomTrailing
                        ) :
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
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ?
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.TeamColors.getColor(for: player.team),
                                        AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.7)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [
                                        Color.gray.opacity(0.2),
                                        Color.gray.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )
            )
            .shadow(
                color: isSelected ?
                AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.2) :
                Color.black.opacity(0.05),
                radius: isSelected ? 12 : 4,
                x: 0,
                y: isSelected ? 6 : 2
            )
            // REMOVED: .scaleEffect(isPressed ? 0.96 : (isSelected ? 1.02 : 1.0))
            .scaleEffect(isSelected ? 1.02 : 1.0) // SIMPLIFIED: Just scale when selected, no press animation
        }
        .buttonStyle(PlainButtonStyle())
        // REMOVED: All .onAppear and .onChange animation code
    }
    
    // MARK: - Helper Properties
    
    private var hasStats: Bool {
        player.goals > 0 || player.assists > 0 || player.yellowCards > 0 || player.redCards > 0
    }
    
    private func positionIcon(for position: Player.Position) -> String {
        switch position {
        case .goalkeeper: return "hand.raised.fill"
        case .defender: return "shield.fill"
        case .midfielder: return "arrow.triangle.swap"
        case .forward: return "flame.fill"
        }
    }
}

// MARK: - Enhanced Participant Card (Animations Removed)

struct ParticipantCard: View {
    let participant: Participant
    @AppStorage("currencySymbol") private var currencySymbol = "€"
    // REMOVED: @State private var animateBalance = false
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                // Participant avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.primary,
                                    AppDesignSystem.Colors.primary.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    if let firstLetter = participant.name.first {
                        Text(String(firstLetter).uppercased())
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .shadow(
                    color: AppDesignSystem.Colors.primary.opacity(0.3),
                    radius: 6,
                    x: 0,
                    y: 3
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(participant.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    HStack(spacing: 8) {
                        Label {
                            Text("\(participant.selectedPlayers.count) active")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        } icon: {
                            Image(systemName: "person.fill")
                                .font(.system(size: 10))
                                .foregroundColor(AppDesignSystem.Colors.success)
                        }
                        
                        if !participant.substitutedPlayers.isEmpty {
                            Label {
                                Text("\(participant.substitutedPlayers.count) subbed")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            } icon: {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 10))
                                    .foregroundColor(AppDesignSystem.Colors.warning)
                            }
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text(formatCurrency(participant.balance))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                        // REMOVED: .scaleEffect and .animation
                    
                    VibrantStatusBadge(
                        balanceStatus,
                        color: participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error
                    )
                }
            }
        }
        .enhancedCard()
        // REMOVED: All .onAppear animation code
    }
    
    private var balanceStatus: String {
        if participant.balance > 0 {
            return "Winning"
        } else if participant.balance < 0 {
            return "Losing"
        } else {
            return "Even"
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currencySymbol
        return formatter.string(from: NSNumber(value: value)) ?? "\(currencySymbol)0.00"
    }
}

// MARK: - Enhanced Event Card (kept as-is since no continuous animations)

struct EventCard: View {
    let event: GameEvent
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    private func getEventColor(_ eventType: Bet.EventType) -> Color {
        switch eventType {
        case .goal, .assist: return AppDesignSystem.Colors.success
        case .yellowCard: return AppDesignSystem.Colors.warning
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.warning
        case .penalty: return AppDesignSystem.Colors.primary
        case .cleanSheet: return AppDesignSystem.Colors.info
        case .custom: return AppDesignSystem.Colors.secondary
        }
    }
    
    private func getEventIcon(_ eventType: Bet.EventType) -> String {
        switch eventType {
        case .goal: return "soccerball"
        case .assist: return "arrow.up.forward"
        case .yellowCard: return "square.fill"
        case .redCard: return "square.fill"
        case .ownGoal: return "arrow.uturn.backward"
        case .penalty: return "p.circle"
        case .penaltyMissed: return "p.circle.fill"
        case .cleanSheet: return "lock.shield"
        case .custom: return "star"
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Enhanced event icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                getEventColor(event.eventType),
                                getEventColor(event.eventType).opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Image(systemName: getEventIcon(event.eventType))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(
                color: getEventColor(event.eventType).opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.eventType.rawValue)
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    VibrantStatusBadge(
                        dateFormatter.string(from: event.timestamp),
                        color: getEventColor(event.eventType)
                    )
                }
                
                Text(event.player.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: event.player.team))
                
                HStack(spacing: 8) {
                    Text(event.player.team.name)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Text("•")
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Text(event.player.position.rawValue)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
        }
        .enhancedCard(team: event.player.team)
    }
}
