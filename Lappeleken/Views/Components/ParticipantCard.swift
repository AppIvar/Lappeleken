//
//  ParticipantCard.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import SwiftUI

// Participant card
struct ParticipantCard: View {
    let participant: Participant
    @AppStorage("currencySymbol") private var currencySymbol = "€"
    
    var body: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppDesignSystem.Layout.smallPadding) {
                Text(participant.name)
                    .font(AppDesignSystem.Typography.subheadingFont)
                
                Text("Balance: \(formatCurrency(participant.balance))")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                
                Text("Players: \(participant.selectedPlayers.count)")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currencySymbol
        
        return formatter.string(from: NSNumber(value: value)) ?? "\(currencySymbol)0.00"
    }
}
