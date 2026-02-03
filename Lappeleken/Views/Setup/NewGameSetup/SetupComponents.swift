//
//  SetupComponents.swift
//  Lucky Football Slip
//
//  Shared UI components for game setup views
//

import SwiftUI

// MARK: - Team Player Group Component

struct TeamPlayerGroup: View {
    let team: Team
    let players: [Player]
    @Binding var selectedPlayerIds: Set<UUID>
    let onDeletePlayer: (Player) -> Void
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                withAnimation(AppDesignSystem.Animations.standard) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Circle()
                        .fill(AppDesignSystem.TeamColors.getColor(for: team))
                        .frame(width: 28, height: 28)
                        .shadow(color: AppDesignSystem.TeamColors.getColor(for: team).opacity(0.3), radius: 4, x: 0, y: 2)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(team.name)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("\(players.count) player\(players.count == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(allPlayersSelected ? "Deselect All" : "Select All") {
                        withAnimation(AppDesignSystem.Animations.quick) {
                            if allPlayersSelected {
                                for player in players {
                                    selectedPlayerIds.remove(player.id)
                                }
                            } else {
                                for player in players {
                                    selectedPlayerIds.insert(player.id)
                                }
                            }
                        }
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppDesignSystem.TeamColors.getAccentColor(for: team))
                    )
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .font(.system(size: 14, weight: .medium))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                        .fill(AppDesignSystem.TeamColors.getAccentColor(for: team))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                                .stroke(AppDesignSystem.TeamColors.getColor(for: team).opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(players, id: \.id) { player in
                        SetupPlayerSelectionCard(
                            player: player,
                            isSelected: selectedPlayerIds.contains(player.id),
                            onToggleSelection: {
                                withAnimation(AppDesignSystem.Animations.quick) {
                                    if selectedPlayerIds.contains(player.id) {
                                        selectedPlayerIds.remove(player.id)
                                    } else {
                                        selectedPlayerIds.insert(player.id)
                                    }
                                }
                            },
                            onDelete: {
                                onDeletePlayer(player)
                            }
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 4)
    }
    
    private var allPlayersSelected: Bool {
        players.allSatisfy { selectedPlayerIds.contains($0.id) }
    }
}

// MARK: - Setup Player Selection Card

struct SetupPlayerSelectionCard: View {
    let player: Player
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(.system(size: 16, weight: .medium))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(player.position.rawValue)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                Button(action: {
                    DispatchQueue.main.async {
                        onDelete()
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.error)
                        .padding(6)
                        .background(Circle().fill(AppDesignSystem.Colors.error.opacity(0.1)))
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button(action: onToggleSelection) {
                HStack {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.secondaryText)
                        .font(.system(size: 18))
                    
                    Text(isSelected ? "Selected" : "Select")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.secondaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? AppDesignSystem.Colors.success.opacity(0.1) : AppDesignSystem.Colors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(isSelected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.secondaryText.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                .fill(isSelected ? AppDesignSystem.TeamColors.getAccentColor(for: player.team) : AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                        .stroke(isSelected ? AppDesignSystem.TeamColors.getColor(for: player.team) : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )
        )
        .shadow(color: isSelected ? AppDesignSystem.TeamColors.getColor(for: player.team).opacity(0.2) : Color.black.opacity(0.05), radius: isSelected ? 6 : 2, x: 0, y: isSelected ? 3 : 1)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(AppDesignSystem.Animations.quick, value: isSelected)
    }
}

// MARK: - Bet Rule Card

struct BetRuleCard: View {
    let eventType: Bet.EventType
    @Binding var amount: Double
    @Binding var isNegative: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(eventType.rawValue.capitalized)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(getEventDescription(eventType))
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button(action: {
                        withAnimation(AppDesignSystem.Animations.quick) {
                            isNegative.toggle()
                        }
                    }) {
                        Image(systemName: isNegative ? "minus.circle.fill" : "plus.circle.fill")
                            .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                            .font(.title2)
                    }
                    .scaleEffect(isNegative ? 1.1 : 1.0)
                    .animation(AppDesignSystem.Animations.bouncy, value: isNegative)
                    
                    TextField("Amount", value: $amount, format: .number)
                        .font(.system(size: 16, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(width: 80)
                        .background(
                            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.smallCornerRadius)
                                .fill(AppDesignSystem.Colors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.smallCornerRadius)
                                        .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .keyboardType(.decimalPad)
                }
            }
            
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Image(systemName: isNegative ? "arrow.down" : "arrow.up")
                            .font(.system(size: 12, weight: .bold))
                        
                        Text(isNegative ? "Penalty" : "Reward")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                    
                    Text(isNegative ? "Others gain money" : "Player owners gain money")
                        .font(.system(size: 10))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill((isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success).opacity(0.1))
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                        .stroke((isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success).opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private func getEventDescription(_ eventType: Bet.EventType) -> String {
        switch eventType {
        case .goal: return "Player scores a goal"
        case .assist: return "Player provides an assist"
        case .yellowCard: return "Player receives a yellow card"
        case .redCard: return "Player receives a red card"
        case .ownGoal: return "Player scores an own goal"
        case .penalty: return "Player scores a penalty"
        case .penaltyMissed: return "Player misses a penalty"
        case .cleanSheet: return "Goalkeeper keeps a clean sheet"
        case .custom: return "Custom event"
        }
    }
}

// MARK: - Currency Selector

struct CurrencySelector: View {
    @AppStorage("selectedCurrency") private var selectedCurrency = "EUR"
    @AppStorage("currencySymbol") private var currencySymbol = "€"
    
    private let currencies = [
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("NOK", "kr", "Norwegian Krone"),
        ("SEK", "kr", "Swedish Krona"),
        ("DKK", "kr", "Danish Krone")
    ]
    
    var body: some View {
        Menu {
            ForEach(currencies, id: \.0) { currency in
                Button(action: {
                    selectedCurrency = currency.0
                    currencySymbol = currency.1
                }) {
                    HStack {
                        Text("\(currency.1) \(currency.0) - \(currency.2)")
                        if selectedCurrency == currency.0 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack {
                Image(systemName: "dollarsign.circle")
                    .font(.system(size: 20))
                    .foregroundColor(AppDesignSystem.Colors.warning)
                
                Text(selectedCurrency)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(currencySymbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                Spacer()
                
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                            .stroke(AppDesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

// MARK: - Custom Event Display Card

struct CustomEventDisplayCard: View {
    let name: String
    let amount: Double
    let onDelete: () -> Void
    
    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
    }
    
    private var isNegative: Bool {
        amount < 0
    }
    
    var body: some View {
        HStack {
            Image(systemName: "star.fill")
                .font(.system(size: 16))
                .foregroundColor(AppDesignSystem.Colors.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(eventDescription)
                    .font(.system(size: 11))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Image(systemName: isNegative ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                    
                    Text("\(currencySymbol)\(String(format: "%.2f", abs(amount)))")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                }
                
                Text(isNegative ? "Penalty" : "Reward")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(6)
                    .background(Circle().fill(AppDesignSystem.Colors.error.opacity(0.1)))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                        .stroke(AppDesignSystem.Colors.accent.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
    
    private var eventDescription: String {
        let amountString = String(format: "%.2f", abs(amount))
        return isNegative ?
            "Players WITH this event pay \(currencySymbol)\(amountString)" :
            "Players WITHOUT this event pay \(currencySymbol)\(amountString)"
    }
}

// MARK: - Setup Step Header

struct SetupStepHeader: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(AppDesignSystem.Typography.headingFont)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text(subtitle)
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
    }
}

// MARK: - Setup Summary Card

struct SetupSummaryCard<Content: View>: View {
    let title: String
    let count: Int
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                VibrantStatusBadge("\(count)", color: color)
            }
            
            content()
        }
        .padding(AppDesignSystem.Layout.standardPadding)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Helper Functions

func formatCurrencyAmount(_ amount: Double) -> String {
    let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
    let sign = amount >= 0 ? "+" : ""
    return "\(sign)\(currencySymbol)\(String(format: "%.2f", abs(amount)))"
}

func getDefaultBetAmount(for eventType: Bet.EventType) -> Double {
    return 0.0
}

func getDefaultIsNegative(for eventType: Bet.EventType) -> Bool {
    switch eventType {
    case .ownGoal, .redCard, .yellowCard, .penaltyMissed:
        return true
    default:
        return false
    }
}
