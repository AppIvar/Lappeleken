//
//  PlayerAssignmentView.swift
//  Lucky Football Slip
//
//  Shows random player assignments - Football themed
//

import SwiftUI

struct PlayerAssignmentView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    @State private var animateCards = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Football background
                footballBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Participant cards
                        participantCardsSection
                        
                        // Start button
                        startButton
                        
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Player Assignments")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2)) {
                animateCards = true
            }
        }
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            
            VStack {
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.15 : 0.08),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 180)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "shuffle")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
            }
            
            VStack(spacing: 6) {
                Text("Players Assigned!")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Here's who got which players")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
    
    // MARK: - Participant Cards
    
    private var participantCardsSection: some View {
        VStack(spacing: 12) {
            ForEach(Array(gameSession.participants.enumerated()), id: \.element.id) { index, participant in
                ParticipantAssignmentCard(
                    participant: participant,
                    index: index,
                    isAnimated: animateCards
                )
            }
        }
    }
    
    // MARK: - Start Button
    
    private var startButton: some View {
        Button(action: {
            presentationMode.wrappedValue.dismiss()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "play.fill")
                    .font(.system(size: 16))
                
                Text("Let's Play!")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppDesignSystem.Colors.grassGreen)
            )
            .shadow(
                color: AppDesignSystem.Colors.grassGreen.opacity(0.3),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .padding(.top, 8)
    }
}

// MARK: - Participant Assignment Card

struct ParticipantAssignmentCard: View {
    let participant: Participant
    let index: Int
    let isAnimated: Bool
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isExpanded = true
    
    private let accentColors: [Color] = [
        AppDesignSystem.Colors.grassGreen,
        AppDesignSystem.Colors.goalYellow,
        AppDesignSystem.Colors.accent,
        AppDesignSystem.Colors.info
    ]
    
    private var accentColor: Color {
        accentColors[index % accentColors.count]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Participant avatar
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(accentColor.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Text("\(index + 1)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(accentColor)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(participant.name)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("\(participant.selectedPlayers.count) players")
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(12)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Players list
            if isExpanded {
                VStack(spacing: 6) {
                    ForEach(participant.selectedPlayers) { player in
                        AssignedPlayerRow(player: player)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.15) : Color.black.opacity(0.04),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
        .scaleEffect(isAnimated ? 1.0 : 0.9)
        .opacity(isAnimated ? 1.0 : 0.0)
        .animation(
            .spring(response: 0.4, dampingFraction: 0.7).delay(Double(index) * 0.1),
            value: isAnimated
        )
    }
}

// MARK: - Assigned Player Row

struct AssignedPlayerRow: View {
    let player: Player
    @Environment(\.colorScheme) var colorScheme
    
    private var teamColor: Color {
        AppDesignSystem.TeamColors.getColor(for: player.team)
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Team color bar
            RoundedRectangle(cornerRadius: 2)
                .fill(teamColor)
                .frame(width: 3, height: 28)
            
            // Player info
            VStack(alignment: .leading, spacing: 2) {
                Text(player.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text(player.team.shortName)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(teamColor)
                    
                    Text("•")
                        .font(.system(size: 10))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Text(player.position.rawValue)
                        .font(.system(size: 11))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
        )
    }
}
