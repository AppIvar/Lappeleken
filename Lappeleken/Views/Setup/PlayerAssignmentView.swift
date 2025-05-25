//
//  PlayerAssignmentView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 09/05/2025.
//

import SwiftUI

struct PlayerAssignmentView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppDesignSystem.Layout.standardPadding) {
                    Text("Players have been randomly assigned!")
                        .font(AppDesignSystem.Typography.headingFont)
                        .padding(.bottom)
                    
                    ForEach(gameSession.participants) { participant in
                        VStack(alignment: .leading) {
                            HStack {
                                Text(participant.name)
                                    .font(AppDesignSystem.Typography.subheadingFont)
                                
                                Spacer()
                                
                                Text("\(participant.selectedPlayers.count) players")
                                    .font(AppDesignSystem.Typography.captionFont)
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            }
                            .padding(.bottom, 4)
                            
                            ForEach(participant.selectedPlayers) { player in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(player.name)
                                            .font(AppDesignSystem.Typography.bodyFont)
                                        
                                        Text("\(player.team.name) · \(player.position.rawValue)")
                                            .font(AppDesignSystem.Typography.captionFont)
                                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(AppDesignSystem.Colors.cardBackground)
                                .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                            }
                        }
                        .padding(.vertical, AppDesignSystem.Layout.smallPadding)
                    }
                    
                    Button("Let's Play!") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.top, AppDesignSystem.Layout.largePadding)
                }
                padding()
            }
            .background(AppDesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Player Assignments")
        }
    }
}
