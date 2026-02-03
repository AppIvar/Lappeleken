//
//  SetupBetsView.swift
//  Lucky Football Slip
//
//  Step 3: Set bet rules
//

import SwiftUI

struct SetupBetsView: View {
    @ObservedObject var gameSession: GameSession
    @Binding var betAmounts: [Bet.EventType: Double]
    @Binding var betNegativeFlags: [Bet.EventType: Bool]
    @Binding var showCustomBetSheet: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            SetupStepHeader(
                icon: "target",
                iconColor: AppDesignSystem.Colors.accent,
                title: "Bet Rules",
                subtitle: "Set the money values for different football events. Positive values reward players who have the event player, while negative values penalize them."
            )
            
            // Currency selection
            VStack(alignment: .leading, spacing: 12) {
                Text("Currency")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                CurrencySelector()
            }
            
            // Standard bet rules
            VStack(spacing: 16) {
                Text("Standard Events")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(spacing: 12) {
                    ForEach(Array(Bet.EventType.allCases.filter { $0 != .custom }.enumerated()), id: \.offset) { index, eventType in
                        BetRuleCard(
                            eventType: eventType,
                            amount: Binding(
                                get: { abs(betAmounts[eventType] ?? getDefaultBetAmount(for: eventType)) },
                                set: { newValue in
                                    let isNegative = betNegativeFlags[eventType] ?? getDefaultIsNegative(for: eventType)
                                    betAmounts[eventType] = isNegative ? -abs(newValue) : abs(newValue)
                                }
                            ),
                            isNegative: Binding(
                                get: { betNegativeFlags[eventType] ?? getDefaultIsNegative(for: eventType) },
                                set: { isNegative in
                                    betNegativeFlags[eventType] = isNegative
                                    let currentAmount = abs(betAmounts[eventType] ?? getDefaultBetAmount(for: eventType))
                                    betAmounts[eventType] = isNegative ? -currentAmount : currentAmount
                                }
                            )
                        )
                    }
                }
            }
            
            // Custom events section
            customEventsSection
        }
    }
    
    private var customEventsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Custom Events")
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button("Add Custom") {
                    showCustomBetSheet = true
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(AppDesignSystem.Colors.accent)
                .cornerRadius(AppDesignSystem.Layout.smallCornerRadius)
                .vibrantButton(color: AppDesignSystem.Colors.accent)
                
                if !gameSession.getCustomEvents().isEmpty {
                    VibrantStatusBadge("\(gameSession.getCustomEvents().count)", color: AppDesignSystem.Colors.accent)
                }
            }
            
            if !gameSession.getCustomEvents().isEmpty {
                VStack(spacing: 8) {
                    ForEach(gameSession.getCustomEvents(), id: \.id) { customEvent in
                        CustomEventDisplayCard(
                            name: customEvent.name,
                            amount: customEvent.amount,
                            onDelete: {
                                gameSession.removeCustomEvent(id: customEvent.id)
                            }
                        )
                    }
                }
            } else {
                emptyCustomEventsView
            }
        }
    }
    
    private var emptyCustomEventsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "star.circle")
                .font(.system(size: 32))
                .foregroundColor(AppDesignSystem.Colors.accent.opacity(0.5))
            
            Text("No custom events added yet")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("Tap 'Add Custom' to create your own events")
                .font(.system(size: 12))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                .fill(AppDesignSystem.Colors.accent.opacity(0.05))
        )
    }
}
