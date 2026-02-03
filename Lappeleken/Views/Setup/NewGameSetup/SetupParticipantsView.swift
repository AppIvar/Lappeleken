//
//  SetupParticipantsView.swift
//  Lucky Football Slip
//
//  Step 1: Add participants
//

import SwiftUI

struct SetupParticipantsView: View {
    @ObservedObject var gameSession: GameSession
    @Binding var participantName: String
    
    var body: some View {
        VStack(spacing: 24) {
            SetupStepHeader(
                icon: "person.2.fill",
                iconColor: AppDesignSystem.Colors.primary,
                title: "Who's Playing?",
                subtitle: "Add the names of everyone who will be participating in this game."
            )
            
            // Add participant section
            VStack(spacing: 16) {
                HStack {
                    TextField("Enter participant name", text: $participantName)
                        .font(AppDesignSystem.Typography.bodyFont)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                                .fill(AppDesignSystem.Colors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                                        .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .onSubmit {
                            addParticipant()
                        }
                    
                    Button(action: addParticipant) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Add")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(
                            participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                            Color.gray.opacity(0.5) :
                            AppDesignSystem.Colors.primary
                        )
                        .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                        .vibrantButton()
                    }
                    .disabled(participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            
            // Participants list
            if !gameSession.participants.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Participants")
                            .font(AppDesignSystem.Typography.subheadingFont)
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Spacer()
                        
                        VibrantStatusBadge("\(gameSession.participants.count)", color: AppDesignSystem.Colors.success)
                    }
                    
                    LazyVStack(spacing: 12) {
                        ForEach(gameSession.participants) { participant in
                            ParticipantRow(
                                participant: participant,
                                onDelete: { deleteParticipant(participant) }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func addParticipant() {
        let trimmedName = participantName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            gameSession.addParticipant(trimmedName)
            participantName = ""
        }
    }
    
    private func deleteParticipant(_ participant: Participant) {
        if let index = gameSession.participants.firstIndex(where: { $0.id == participant.id }) {
            gameSession.participants.remove(at: index)
        }
    }
}

// MARK: - Participant Row

struct ParticipantRow: View {
    let participant: Participant
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Circle()
                .fill(AppDesignSystem.Colors.primary)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(participant.name.prefix(1)).uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                )
            
            Text(participant.name)
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}
