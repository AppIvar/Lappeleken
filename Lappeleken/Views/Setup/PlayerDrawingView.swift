//
//  PlayerDrawingView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 17/09/2025.
//

import SwiftUI

struct PlayerDrawingView: View {
    @ObservedObject var gameSession: GameSession
    let selectedPlayers: [Player]
    let participants: [Participant]
    let onComplete: ([Participant: [Player]]) -> Void
    let onBack: () -> Void
    
    @State private var assignments: [Participant: [Player]] = [:]
    @State private var drawnSlips: Set<Int> = []
    @State private var enlargedSlips: Set<Int> = [] // Track which slips are enlarged
    @State private var disappearingSlips: Set<Int> = [] // Track which slips are disappearing
    @State private var currentParticipantIndex = 0
    @State private var showingAssignments = false
    @State private var isDrawingComplete = false
    @State private var slipPositions: [CGPoint] = []
    @State private var screenSize: CGSize = .zero
    @State private var showPickAllButton = true
    @State private var isDrawingInProgress = false
    
    private let slipSize: CGFloat = 60
    private let animationDuration: Double = 0.8
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    headerView
                    
                    if showingAssignments {
                        assignmentResultsView
                    } else {
                        VStack(spacing: 16) {
                            drawingAreaView(in: geometry)
                            
                            // Pick All Button below the drawing area
                            if showPickAllButton && !isDrawingComplete {
                                VStack(spacing: 12) {
                                    Button(action: pickAllSlips) {
                                        HStack(spacing: 12) {
                                            Image(systemName: "hand.tap.fill")
                                                .font(.system(size: 20))
                                            
                                            Text("Pick All Slips")
                                                .font(.system(size: 18, weight: .semibold))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 16)
                                        .background(
                                            LinearGradient(
                                                colors: [
                                                    AppDesignSystem.Colors.primary,
                                                    AppDesignSystem.Colors.primary.opacity(0.8)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(25)
                                        .shadow(color: AppDesignSystem.Colors.primary.opacity(0.4), radius: 8, x: 0, y: 4)
                                    }
                                    
                                    Text("Or tap individual slips one by one")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    bottomButtonsView
                }
                .onAppear {
                    setupSlipPositions(in: geometry.size)
                    setupInitialAssignments()
                }
                .onChange(of: geometry.size) { size in
                    if screenSize != size {
                        setupSlipPositions(in: size)
                    }
                }
            }
            .navigationTitle("Lucky Football Slip")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(
                leading: Button("Back") {
                    onBack()
                }
                .foregroundColor(AppDesignSystem.Colors.primary)
            )
        }
    }
    
    // MARK: - Header View
    
    private var headerView: some View {
        VStack(spacing: 8) {
            if !isDrawingComplete {
                if showPickAllButton {
                    Text("Pick crumpled slips to assign players!")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                } else {
                    VStack(spacing: 4) {
                        Text("Drawing for: \(participants[currentParticipantIndex].name)")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Tap a slip to reveal their player!")
                            .font(.system(size: 14))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
            } else {
                Text("All players have been assigned!")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.success)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Drawing Area View
    
    private func drawingAreaView(in geometry: GeometryProxy) -> some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [
                            AppDesignSystem.Colors.primary.opacity(0.05),
                            AppDesignSystem.Colors.primary.opacity(0.02)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppDesignSystem.Colors.primary.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                )
            
            // Slips
            ForEach(0..<selectedPlayers.count, id: \.self) { index in
                if index < slipPositions.count && !disappearingSlips.contains(index) {
                    CrumbledSlipView(
                        isDrawn: drawnSlips.contains(index),
                        isEnlarged: enlargedSlips.contains(index),
                        player: selectedPlayers[index],
                        onTap: {
                            if !drawnSlips.contains(index) && !isDrawingInProgress {
                                if showPickAllButton {
                                    // If "Pick All" button is showing, hide it and enable individual drawing
                                    showPickAllButton = false
                                }
                                drawSlip(at: index)
                            }
                        }
                    )
                    .position(slipPositions[index])
                    .zIndex(enlargedSlips.contains(index) ? 2 : 1) // Enlarged slips go on top
                }
            }
        }
        .padding()
        .clipped()
    }
    
    // MARK: - Assignment Results View
    
    private var assignmentResultsView: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Player Assignments")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .padding(.bottom, 8)
                
                ForEach(participants) { participant in
                    AssignmentResultCard(
                        participant: participant,
                        players: assignments[participant] ?? []
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Bottom Buttons View
    
    private var bottomButtonsView: some View {
        HStack(spacing: 16) {
            if showingAssignments {
                Button("Start Game") {
                    onComplete(assignments)
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.primary,
                                    AppDesignSystem.Colors.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            } else {
                Button("Continue") {
                    if isDrawingComplete {
                        showingAssignments = true
                    }
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            isDrawingComplete ?
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.primary,
                                    AppDesignSystem.Colors.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.gray.opacity(0.5),
                                    Color.gray.opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .disabled(!isDrawingComplete)
            }
        }
        .padding()
        .background(
            Rectangle()
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: -2)
        )
    }
    
    // MARK: - Helper Methods
    
    private func setupSlipPositions(in size: CGSize) {
        screenSize = size
        let drawingArea = CGRect(
            x: 20,
            y: 20,
            width: size.width - 40,
            height: size.height - 280 // Increased space for header, button below, and bottom buttons
        )
        
        var positions: [CGPoint] = []
        let spacing: CGFloat = slipSize + 15 // Reduced spacing for better fit
        let columns = max(1, Int((drawingArea.width) / spacing))
        let rows = max(1, Int(ceil(Double(selectedPlayers.count) / Double(columns))))
        
        // Calculate actual grid spacing to center the grid
        let actualGridWidth = CGFloat(columns - 1) * spacing + slipSize
        let actualGridHeight = CGFloat(rows - 1) * spacing + slipSize
        let startX = drawingArea.minX + (drawingArea.width - actualGridWidth) / 2
        let startY = drawingArea.minY + (drawingArea.height - actualGridHeight) / 2
        
        // Generate grid positions with slight randomization
        for i in 0..<selectedPlayers.count {
            let row = i / columns
            let col = i % columns
            
            let baseX = startX + CGFloat(col) * spacing + slipSize/2
            let baseY = startY + CGFloat(row) * spacing + slipSize/2
            
            // Add smaller random offset to avoid perfect grid while preventing overlap
            let randomOffsetX = CGFloat.random(in: -8...8)
            let randomOffsetY = CGFloat.random(in: -8...8)
            
            let position = CGPoint(
                x: max(drawingArea.minX + slipSize/2, min(drawingArea.maxX - slipSize/2, baseX + randomOffsetX)),
                y: max(drawingArea.minY + slipSize/2, min(drawingArea.maxY - slipSize/2, baseY + randomOffsetY))
            )
            
            positions.append(position)
        }
        
        slipPositions = positions
    }
    
    private func getSlipPosition(for index: Int) -> CGPoint {
        guard index < slipPositions.count else { return CGPoint.zero }
        
        let originalPosition = slipPositions[index]
        
        // If slip is drawn, move it toward the edge
        if drawnSlips.contains(index) {
            let centerX = screenSize.width / 2
            let centerY = screenSize.height / 2
            
            // Calculate direction from center to original position
            let deltaX = originalPosition.x - centerX
            let deltaY = originalPosition.y - centerY
            
            // Normalize and extend the vector
            let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
            if distance > 0 {
                let normalizedX = deltaX / distance
                let normalizedY = deltaY / distance
                
                // Move slip toward the edge (but not off screen)
                let moveDistance: CGFloat = 80
                return CGPoint(
                    x: max(30, min(screenSize.width - 30, originalPosition.x + normalizedX * moveDistance)),
                    y: max(100, min(screenSize.height - 150, originalPosition.y + normalizedY * moveDistance))
                )
            }
        }
        
        return originalPosition
    }
    
    private func setupInitialAssignments() {
        // Initialize empty assignments for each participant
        for participant in participants {
            assignments[participant] = []
        }
    }
    
    private func drawSlip(at index: Int) {
        guard !drawnSlips.contains(index) && !isDrawingInProgress else { return }
        
        // Set debounce flag
        isDrawingInProgress = true
        
        // Step 1: Mark slip as drawn and enlarged
        withAnimation(.easeInOut(duration: 0.5)) {
            drawnSlips.insert(index)
            enlargedSlips.insert(index)
        }
        
        // Assign player to current participant
        let player = selectedPlayers[index]
        let participant = participants[currentParticipantIndex]
        
        if assignments[participant] == nil {
            assignments[participant] = []
        }
        assignments[participant]?.append(player)
        
        print("🎯 Assigned \(player.name) to \(participant.name)")
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Step 2: After 2 seconds, make the slip disappear
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                enlargedSlips.remove(index)
                disappearingSlips.insert(index)
            }
            
            // Step 3: Move to next participant after disappear animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                advanceToNextParticipant()
                
                // Release debounce flag
                isDrawingInProgress = false
            }
        }
    }
    
    private func pickAllSlips() {
        showPickAllButton = false
        
        // Distribute players evenly among all participants
        var shuffledPlayers = selectedPlayers.shuffled()
        var participantIndex = 0
        
        // Clear existing assignments
        for participant in participants {
            assignments[participant] = []
        }
        
        // Distribute players round-robin style
        for (index, player) in shuffledPlayers.enumerated() {
            let participant = participants[participantIndex % participants.count]
            
            assignments[participant]?.append(player)
            participantIndex += 1
            
            // Animate slip drawing with delay
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    _ = drawnSlips.insert(index)
                }
            }
        }
        
        // Log the distribution for debugging
        print("🎲 Player distribution:")
        for (participant, players) in assignments {
            print("  \(participant.name): \(players.count) players - \(players.map { $0.name }.joined(separator: ", "))")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + Double(selectedPlayers.count) * 0.1 + 0.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                isDrawingComplete = true
            }
            
            // Haptic feedback for completion
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        }
    }
    
    private func advanceToNextParticipant() {
        if drawnSlips.count >= selectedPlayers.count {
            isDrawingComplete = true
            
            // Haptic feedback for completion
            let notification = UINotificationFeedbackGenerator()
            notification.notificationOccurred(.success)
        } else {
            // Move to next participant (round-robin)
            currentParticipantIndex = (currentParticipantIndex + 1) % participants.count
        }
    }
}

// MARK: - Supporting Views

struct CrumbledSlipView: View {
    let isDrawn: Bool
    let isEnlarged: Bool
    let player: Player
    let onTap: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            ZStack {
                if !isDrawn {
                    // Crumpled paper effect
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.95, green: 0.94, blue: 0.89),
                                    Color(red: 0.88, green: 0.86, blue: 0.78)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            // Crumple lines
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                
                                // Random crumple lines
                                Path { path in
                                    path.move(to: CGPoint(x: 10, y: 15))
                                    path.addLine(to: CGPoint(x: 45, y: 20))
                                    path.move(to: CGPoint(x: 5, y: 35))
                                    path.addLine(to: CGPoint(x: 55, y: 30))
                                    path.move(to: CGPoint(x: 15, y: 50))
                                    path.addLine(to: CGPoint(x: 40, y: 45))
                                }
                                .stroke(Color.black.opacity(0.05), lineWidth: 0.5)
                            }
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 2, y: 2)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isAnimating)
                } else {
                    // Uncrumpled slip with player info
                    VStack(spacing: isEnlarged ? 2 : 2) {
                        // Team color indicator
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                            .frame(height: isEnlarged ? 3 : 3)
                        
                        Text(player.name)
                            .font(.system(size: isEnlarged ? 9 : 9, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .lineLimit(isEnlarged ? 3 : 2)
                            .minimumScaleFactor(0.6)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text(player.position.rawValue)
                            .font(.system(size: isEnlarged ? 7 : 7, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(isEnlarged ? 4 : 3)
                    .frame(width: isEnlarged ? 70 : 54, height: isEnlarged ? 70 : 54)
                    .background(
                        RoundedRectangle(cornerRadius: isEnlarged ? 10 : 8)
                            .fill(Color.white)
                            .shadow(
                                color: AppDesignSystem.Colors.primary.opacity(isEnlarged ? 0.6 : 0.3),
                                radius: isEnlarged ? 8 : 6,
                                x: 0,
                                y: isEnlarged ? 4 : 3
                            )
                    )
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.1).combined(with: .opacity),
                        removal: .scale(scale: 0.1).combined(with: .opacity)
                    ))
                }
            }
            .frame(width: 60, height: 60)
            .scaleEffect(isEnlarged ? 1.2 : 1.0) // Further reduced from 1.4 to 1.2
            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0), value: isEnlarged)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if !isDrawn {
                // Start subtle floating animation
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...2)) {
                    isAnimating = true
                }
            }
        }
    }
}

struct AssignmentResultCard: View {
    let participant: Participant
    let players: [Player]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Participant header
            HStack {
                Circle()
                    .fill(AppDesignSystem.Colors.primary)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(participant.name.prefix(1).uppercased()))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading) {
                    Text(participant.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("\(players.count) player\(players.count == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            // Players list
            if !players.isEmpty {
                VStack(spacing: 8) {
                    ForEach(players) { player in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                                .frame(width: 4, height: 24)
                            
                            Text(player.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Spacer()
                            
                            Text(player.position.rawValue)
                                .font(.system(size: 12))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(AppDesignSystem.Colors.secondaryText.opacity(0.1))
                                .cornerRadius(4)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}
