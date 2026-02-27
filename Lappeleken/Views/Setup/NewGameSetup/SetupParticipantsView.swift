//
//  SetupParticipantsView.swift
//  Lucky Football Slip
//
//  Step 1: Add participants - Football themed design
//

import SwiftUI

struct SetupParticipantsView: View {
    @ObservedObject var gameSession: GameSession
    @Binding var participantName: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            SetupStepHeaderNew(
                icon: "person.2.fill",
                title: "Who's Playing?",
                subtitle: "Add everyone joining this game"
            )
            
            // Add participant input
            addParticipantSection
            
            // Participants list
            if !gameSession.participants.isEmpty {
                participantsList
            } else {
                emptyState
            }
        }
    }
    
    // MARK: - Add Participant Section
    
    private var addParticipantSection: some View {
        HStack(spacing: 12) {
            // Input field
            HStack(spacing: 10) {
                Image(systemName: "person.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                TextField("Enter name", text: $participantName)
                    .font(.system(size: 16))
                    .submitLabel(.done)
                    .onSubmit(addParticipant)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppDesignSystem.Colors.grassGreen.opacity(0.3), lineWidth: 1)
                    )
            )
            
            // Add button
            Button(action: addParticipant) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                participantName.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? AppDesignSystem.Colors.secondaryText.opacity(0.4)
                                    : AppDesignSystem.Colors.grassGreen
                            )
                    )
            }
            .disabled(participantName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
    
    // MARK: - Participants List
    
    private var participantsList: some View {
        VStack(spacing: 14) {
            // Section header
            HStack {
                Text("Participants")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text("\(gameSession.participants.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(AppDesignSystem.Colors.grassGreen))
            }
            
            // Participant rows
            LazyVStack(spacing: 10) {
                ForEach(Array(gameSession.participants.enumerated()), id: \.element.id) { index, participant in
                    ParticipantRowNew(
                        participant: participant,
                        index: index,
                        onDelete: { deleteParticipant(participant) }
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(0.1))
                    .frame(width: 72, height: 72)
                
                Image(systemName: "person.2")
                    .font(.system(size: 32))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen.opacity(0.5))
            }
            
            VStack(spacing: 6) {
                Text("No Participants Yet")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Add at least 2 people to start a game")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                    radius: 6,
                    x: 0,
                    y: 3
                )
        )
    }
    
    // MARK: - Actions
    
    private func addParticipant() {
        let trimmedName = participantName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                gameSession.addParticipant(trimmedName)
                participantName = ""
            }
            
            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }
    }
    
    private func deleteParticipant(_ participant: Participant) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if let index = gameSession.participants.firstIndex(where: { $0.id == participant.id }) {
                gameSession.participants.remove(at: index)
            }
        }
    }
}

// MARK: - Participant Row (New Design)

struct ParticipantRowNew: View {
    let participant: Participant
    let index: Int
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    // Rotating colors for visual variety
    private var accentColor: Color {
        let colors: [Color] = [
            AppDesignSystem.Colors.grassGreen,
            AppDesignSystem.Colors.goalYellow,
            AppDesignSystem.Colors.primary,
            AppDesignSystem.Colors.accent
        ]
        return colors[index % colors.count]
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar with jersey number style
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(accentColor)
                    .frame(width: 44, height: 44)
                
                Text("\(index + 1)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(participant.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Player \(index + 1)")
                    .font(.system(size: 12))
                    .foregroundColor(accentColor)
            }
            
            Spacer()
            
            // Delete button
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(10)
                    .background(
                        Circle()
                            .fill(AppDesignSystem.Colors.error.opacity(0.1))
                    )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.15) : Color.black.opacity(0.04),
                    radius: 3,
                    x: 0,
                    y: 2
                )
        )
    }
}
