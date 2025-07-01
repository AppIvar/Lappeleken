//
//  BetSettingsRow.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import SwiftUI

// Custom component for bet setting with positive/negative toggle
struct BetSettingsRow: View {
    let eventType: Bet.EventType
    @Binding var betAmount: Double
    @Binding var isNegative: Bool
    
    private func eventDescription(for eventType: Bet.EventType, isNegative: Bool) -> String {
        let action: String
        
        switch eventType {
        case .goal:
            action = "scores a goal"
        case .assist:
            action = "makes an assist"
        case .yellowCard:
            action = "receives a yellow card"
        case .redCard:
            action = "receives a red card"
        case .ownGoal:
            action = "scores own goal"
        case .penalty:
            action = "scores a penalty"
        case .penaltyMissed:
            action = "misses a penalty"
        case .cleanSheet:
            action = "kept a clean sheet"
        case .custom:
            action = "custom event"
        }
        
        let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        let amountString = String(format: "%.2f", abs(betAmount))
        
        if isNegative {
            return "When a player \(action), participants who have that player will pay \(currencySymbol)\(amountString) to those who don't."
        } else {
            return "When a player \(action), participants who don't have that player will pay \(currencySymbol)\(amountString) to those who do."
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(eventType.rawValue)
                .font(AppDesignSystem.Typography.subheadingFont)
            
            HStack {
                // Type indicator (positive or negative)
                Button(action: {
                    isNegative.toggle()
                }) {
                    Text(isNegative ? "-" : "+")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success
                        )
                        .cornerRadius(8)
                }
                
                Text(UserDefaults.standard.string(forKey: "currencySymbol") ?? "€")
                    .font(AppDesignSystem.Typography.bodyFont)
                
                TextField("Amount", value: Binding(
                    get: { abs(betAmount) },
                    set: { betAmount = isNegative ? -abs($0) : abs($0) }
                ), formatter: NumberFormatter())
                .keyboardType(.decimalPad)
                .padding()
                .background(AppDesignSystem.Colors.cardBackground)
                .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            
            Text(eventDescription(for: eventType, isNegative: isNegative))
                .font(AppDesignSystem.Typography.captionFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(.bottom)
    }
}
