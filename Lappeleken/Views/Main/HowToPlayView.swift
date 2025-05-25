//
//  HowToPlayView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import SwiftUI

struct HowToPlayView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                Text("How to Play Lappeleken")
                    .font(AppDesignSystem.Typography.headingFont)
                    .padding(.bottom, AppDesignSystem.Layout.smallPadding)
                
                CardView {
                    VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                        instructionStep(number: "1", title: "Add participants", description: "Enter the names of all players participating in the betting game.")
                        
                        instructionStep(number: "2", title: "Select football players", description: "Choose which football players will be part of the game.")
                        
                        instructionStep(number: "3", title: "Set betting amounts", description: "Decide how much to bet on different events like goals, assists, and cards.")
                        
                        instructionStep(number: "4", title: "Start the game", description: "Players will be randomly assigned to participants.")
                        
                        instructionStep(number: "5", title: "Record events", description: "When a football player scores or gets a card, record it in the app.")
                        
                        instructionStep(number: "6", title: "Track winnings", description: "The app automatically calculates payments between participants.")
                    }
                }
            }
            .padding(AppDesignSystem.Layout.standardPadding)
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
        .navigationTitle("How to Play")
    }
    
    private func instructionStep(number: String, title: String, description: String) -> some View {
        HStack(alignment: .top) {
            Text(number)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(AppDesignSystem.Colors.primary)
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
}
