//
//  AssignPlayersView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 09/05/2025.
//

// Replace the existing AssignPlayersView with this improved version:

import SwiftUI

struct AssignPlayersView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @State private var assignmentComplete = false
    @State private var showConfetti = false
    @State private var currentParticipantIndex = -1
    @State private var assignedPlayerIds: [UUID] = []
    
    var body: some View {
        NavigationView {
            VStack {
                if !assignmentComplete {
                    // Before assignment
                    VStack(spacing: 40) {
                        Image(systemName: "shuffle")
                            .font(.system(size: 70))
                            .foregroundColor(AppDesignSystem.Colors.primary)
                            .padding(.top, 40)
                        
                        Text("Ready to assign players")
                            .font(AppDesignSystem.Typography.headingFont)
                        
                        Text("Players will be randomly assigned to participants.")
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        
                        Button("Assign Players") {
                            performPlayerAssignment()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 40)
                        .padding(.top, 20)
                    }
                } else {
                    // After assignment
                    VStack {
                        Text("Players Assigned!")
                            .font(AppDesignSystem.Typography.titleFont)
                            .foregroundColor(AppDesignSystem.Colors.primary)
                            .padding(.top, 20)
                            .padding(.bottom, 10)
                        
                        if showConfetti {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppDesignSystem.Colors.success)
                                .padding(.bottom, 20)
                                .transition(.scale)
                        }
                        
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(0..<gameSession.participants.count, id: \.self) { index in
                                    let participant = gameSession.participants[index]
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(participant.name)
                                            .font(AppDesignSystem.Typography.subheadingFont)
                                            .padding(.bottom, 5)
                                            .opacity(index <= currentParticipantIndex ? 1 : 0.3)
                                        
                                        if index <= currentParticipantIndex {
                                            ForEach(participant.selectedPlayers) { player in
                                                HStack {
                                                    Text(player.name)
                                                        .font(AppDesignSystem.Typography.bodyFont)
                                                    
                                                    Spacer()
                                                    
                                                    Text(player.team.name)
                                                        .font(AppDesignSystem.Typography.captionFont)
                                                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                                }
                                                .padding()
                                                .background(AppDesignSystem.Colors.cardBackground)
                                                .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                                                .opacity(assignedPlayerIds.contains(player.id) ? 1 : 0)
                                                .scaleEffect(assignedPlayerIds.contains(player.id) ? 1 : 0.8)
                                                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: assignedPlayerIds.contains(player.id))
                                            }
                                        }
                                    }
                                    .padding(.bottom, 16)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        if currentParticipantIndex >= gameSession.participants.count - 1 {
                            Button("Start Game") {
                                handleStartGame()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.vertical, 20)
                            .transition(.opacity)
                        }
                    }
                }
            }
            .padding()
            .background(
                ZStack {
                    AppDesignSystem.Colors.background.ignoresSafeArea()
                    
                    if showConfetti {
                        ConfettiView()
                            .ignoresSafeArea()
                    }
                }
            )
            .navigationTitle("Player Assignment")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func performPlayerAssignment() {
        // Debug check
        print("AssignPlayersView - Before assignment:")
        print("Participants: \(gameSession.participants.count)")
        print("Selected players: \(gameSession.selectedPlayers.count)")
        
        // Check if we can assign
        guard !gameSession.participants.isEmpty && !gameSession.selectedPlayers.isEmpty else {
            print("ERROR: Cannot assign players, starting game without assignment")
            startGameDirectly()
            return
        }
        
        // Perform the assignment
        gameSession.assignPlayersRandomly()
        
        // Start animation
        withAnimation(.easeInOut(duration: 0.5)) {
            assignmentComplete = true
            
            // Start showing participants one by one
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                animateNextParticipant()
            }
        }
    }
    
    private func handleStartGame() {
        // Check if we should show interstitial before starting game
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            startGameDirectly()
            return
        }
        
        // Use the new enhanced ad manager method
        AdManager.shared.showInterstitialForGameFlow(.playerAssignment, from: rootViewController) { success in
            DispatchQueue.main.async {
                self.startGameDirectly()
            }
        }
    }
    
    private func startGameDirectly() {
        gameSession.objectWillChange.send()
        
        NotificationCenter.default.post(name: Notification.Name("StartGame"), object: nil)
        
        presentationMode.wrappedValue.dismiss()
    }
    
    // Function to animate through participants one by one
    private func animateNextParticipant() {
        // Move to next participant
        currentParticipantIndex += 1
        
        if currentParticipantIndex < gameSession.participants.count {
            let participant = gameSession.participants[currentParticipantIndex]
            
            // Animate each player one by one
            for (index, player) in participant.selectedPlayers.enumerated() {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.3) {
                    withAnimation {
                        assignedPlayerIds.append(player.id)
                    }
                }
            }
            
            // Schedule next participant after a delay
            let playerCount = participant.selectedPlayers.count
            let delay = Double(playerCount) * 0.3 + 0.7 // Allow time for player animations plus a gap
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                animateNextParticipant()
            }
        } else {
            // All participants have been shown
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    showConfetti = true
                }
            }
        }
    }
}
