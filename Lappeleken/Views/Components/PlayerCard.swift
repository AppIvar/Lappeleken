//
//  PlayerCard.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import SwiftUI

// Player card
struct PlayerCard: View {
    let player: Player
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation {
                    isPressed = false
                }
                
                action()
            }
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(player.name)
                        .font(AppDesignSystem.Typography.subheadingFont)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    HStack {
                        Rectangle()
                            .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                            .frame(width: 4, height: 16)
                            .cornerRadius(2)
                        
                        Text(player.team.name)
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Text(player.position.rawValue)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .padding(.top, 2)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(AppDesignSystem.Colors.success)
                        .font(.title2)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(AppDesignSystem.Layout.standardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                    .fill(isSelected ?
                          AppDesignSystem.TeamColors.getAccentColor(for: player.team) :
                            AppDesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                    .stroke(isSelected ? AppDesignSystem.TeamColors.getColor(for: player.team) : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .withSelectionFeedback()
    }
}

