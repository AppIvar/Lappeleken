//
//  PlayerDrawingView.swift
//  Lucky Football Slip
//
//  Random assignment animation - Football themed
//  Fixed: First participant name now shows correctly
//

import SwiftUI

struct PlayerDrawingView: View {
    @ObservedObject var gameSession: GameSession
    let selectedPlayers: [Player]
    let participants: [Participant]
    let onComplete: ([Participant: [Player]]) -> Void
    let onBack: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    @State private var assignments: [Participant: [Player]] = [:]
    @State private var drawnSlips: Set<Int> = []
    @State private var enlargedSlips: Set<Int> = []
    @State private var disappearingSlips: Set<Int> = []
    @State private var showingAssignments = false
    @State private var isDrawingComplete = false
    @State private var slipPositions: [CGPoint] = []
    @State private var screenSize: CGSize = .zero
    @State private var showPickAllButton = true
    @State private var isDrawingInProgress = false

    // MARK: Randomness (all fixed once, in setupDraw)
    //
    // Three independent things get randomized, and all three are shared by the
    // manual tap flow and "Pick All" so the two can never disagree:
    //
    //  1. drawPool     - which player is behind slip i. Shuffled so the slips
    //                    don't reveal players in selection order (grouped by team).
    //  2. slipLayout   - which grid cell slip i sits in, plus a per-slip tilt, so
    //                    the slips read as a scattered pile instead of a lattice.
    //  3. turnQueue    - who draws slip i. A fresh shuffle of the participants per
    //                    round, so nobody is permanently first and an uneven
    //                    remainder lands on random people instead of always the
    //                    first names in the list.
    @State private var drawPool: [Player] = []
    @State private var slipLayoutOrder: [Int] = []
    @State private var slipRotations: [Double] = []
    @State private var turnQueue: [Int] = []
    @State private var turnCursor = 0
    @State private var didSetupDraw = false

    // NEW: Toast state for showing assignment feedback
    @State private var toastMessage: String = ""
    @State private var showToast = false
    
    private let slipSize: CGFloat = 60
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    footballBackground
                    
                    VStack(spacing: 0) {
                        headerView
                        
                        if showingAssignments {
                            assignmentResultsView
                        } else {
                            VStack(spacing: 16) {
                                drawingAreaView(in: geometry)
                                
                                if showPickAllButton && !isDrawingComplete {
                                    pickAllButtonSection
                                }
                            }
                        }
                        
                        bottomButtonsView
                    }
                    
                    // Toast overlay
                    if showToast {
                        toastOverlay
                    }
                }
                .onAppear {
                    setupDraw()
                    setupSlipPositions(in: geometry.size)
                }
                .onChange(of: geometry.size) { size in
                    if screenSize != size {
                        setupSlipPositions(in: size)
                    }
                }
            }
            .navigationTitle("Lucky Draw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { onBack() }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            
            VStack {
                LinearGradient(
                    colors: [AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.15 : 0.08), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header View (FIXED: Always shows current participant)
    
    private var headerView: some View {
        VStack(spacing: 10) {
            if !isDrawingComplete, let currentParticipant = currentParticipant {
                // FIXED: Always show who is drawing, even with Pick All button visible
                VStack(spacing: 6) {
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                                .frame(width: 36, height: 36)
                            Text(String(currentParticipant.name.prefix(1).uppercased()))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppDesignSystem.Colors.grassGreen)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Drawing for")
                                .font(.system(size: 12))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            Text(currentParticipant.name)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                        }
                    }

                    Text(showPickAllButton ? "Tap a slip or use Pick All below" : "Tap a slip to reveal their player!")
                        .font(.system(size: 13))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                    Text("All players assigned!")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    
    // MARK: - Toast Overlay
    
    private var toastOverlay: some View {
        VStack {
            Spacer()
            
            Text(toastMessage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(AppDesignSystem.Colors.grassGreen)
                        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            
            Spacer().frame(height: 120)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: showToast)
    }
    
    // MARK: - Pick All Button
    
    private var pickAllButtonSection: some View {
        VStack(spacing: 10) {
            Button(action: pickAllSlips) {
                HStack(spacing: 10) {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18))
                    Text("Pick All Slips")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppDesignSystem.Colors.grassGreen)
                        .shadow(color: AppDesignSystem.Colors.grassGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            
            Text("Auto-distributes players evenly")
                .font(.system(size: 12))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(.horizontal)
    }
    
    // MARK: - Drawing Area View
    
    private func drawingAreaView(in geometry: GeometryProxy) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppDesignSystem.Colors.grassGreen.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [10, 5]))
                )
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
            
            ForEach(0..<selectedPlayers.count, id: \.self) { index in
                if index < slipPositions.count && index < drawPool.count && !disappearingSlips.contains(index) {
                    FootballSlipView(
                        isDrawn: drawnSlips.contains(index),
                        isEnlarged: enlargedSlips.contains(index),
                        player: drawPool[index],
                        onTap: {
                            if !drawnSlips.contains(index) && !isDrawingInProgress {
                                if showPickAllButton {
                                    showPickAllButton = false
                                }
                                drawSlip(at: index)
                            }
                        }
                    )
                    // Face-down slips sit at a random angle so the pile doesn't
                    // read as a grid; a revealed slip straightens up to be legible.
                    .rotationEffect(.degrees(drawnSlips.contains(index) ? 0 : rotation(for: index)))
                    .position(slipPositions[index])
                    .zIndex(enlargedSlips.contains(index) ? 2 : 1)
                }
            }
        }
        .padding()
        .clipped()
    }
    
    // MARK: - Assignment Results View
    
    private var assignmentResultsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "person.3.fill")
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                    Text("Player Assignments")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                }
                .padding(.bottom, 8)
                
                ForEach(participants) { participant in
                    DrawingResultCard(
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
                Button(action: { onComplete(assignments) }) {
                    HStack(spacing: 8) {
                        Image(systemName: "play.fill")
                        Text("Start Game")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(RoundedRectangle(cornerRadius: 12).fill(AppDesignSystem.Colors.grassGreen))
                }
            } else {
                Button(action: { if isDrawingComplete { showingAssignments = true } }) {
                    Text("View Assignments")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(isDrawingComplete ? .white : AppDesignSystem.Colors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isDrawingComplete ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.2))
                        )
                }
                .disabled(!isDrawingComplete)
            }
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: -2)
        )
    }
    
    // MARK: - Helper Methods
    
    /// Fixes everything random about this draw, exactly once.
    private func setupDraw() {
        guard !didSetupDraw else { return }
        didSetupDraw = true

        let slipCount = selectedPlayers.count

        drawPool = selectedPlayers.shuffled()
        slipLayoutOrder = Array(0..<slipCount).shuffled()
        slipRotations = (0..<slipCount).map { _ in Double.random(in: -11...11) }
        turnQueue = buildTurnQueue(slipCount: slipCount)
        turnCursor = 0

        for participant in participants {
            assignments[participant] = []
        }
    }

    /// Who draws each slip, in order. One fresh shuffle of the participants per
    /// full round: every round stays balanced (nobody gets two before everyone
    /// has had one), but the order within a round — and therefore who picks up
    /// the extra players when the count doesn't divide evenly — is random.
    private func buildTurnQueue(slipCount: Int) -> [Int] {
        guard !participants.isEmpty else { return [] }

        var queue: [Int] = []
        while queue.count < slipCount {
            queue.append(contentsOf: Array(participants.indices).shuffled())
        }
        return Array(queue.prefix(slipCount))
    }

    /// The participant whose turn it is, or nil once every slip has been drawn.
    private var currentParticipant: Participant? {
        guard turnCursor < turnQueue.count else { return nil }
        return participants[turnQueue[turnCursor]]
    }

    private func rotation(for index: Int) -> Double {
        index < slipRotations.count ? slipRotations[index] : 0
    }

    private func setupSlipPositions(in size: CGSize) {
        screenSize = size
        let drawingArea = CGRect(x: 20, y: 20, width: size.width - 40, height: size.height - 300)

        let spacing: CGFloat = slipSize + 15
        let columns = max(1, Int((drawingArea.width) / spacing))
        let rows = max(1, Int(ceil(Double(selectedPlayers.count) / Double(columns))))

        let actualGridWidth = CGFloat(columns - 1) * spacing + slipSize
        let actualGridHeight = CGFloat(rows - 1) * spacing + slipSize
        let startX = drawingArea.minX + (drawingArea.width - actualGridWidth) / 2
        let startY = drawingArea.minY + (drawingArea.height - actualGridHeight) / 2

        // Build the grid cells first, then hand them out in shuffled order, so a
        // slip's place in the pile says nothing about where it sits in drawPool.
        var cells: [CGPoint] = []
        for i in 0..<selectedPlayers.count {
            let row = i / columns
            let col = i % columns

            let baseX = startX + CGFloat(col) * spacing + slipSize/2
            let baseY = startY + CGFloat(row) * spacing + slipSize/2

            let randomOffsetX = CGFloat.random(in: -10...10)
            let randomOffsetY = CGFloat.random(in: -10...10)

            let position = CGPoint(
                x: max(drawingArea.minX + slipSize/2, min(drawingArea.maxX - slipSize/2, baseX + randomOffsetX)),
                y: max(drawingArea.minY + slipSize/2, min(drawingArea.maxY - slipSize/2, baseY + randomOffsetY))
            )
            cells.append(position)
        }

        // On a rotation/resize the layout order is already fixed, so the slips
        // keep their relative places instead of jumping around.
        if slipLayoutOrder.count != cells.count {
            slipLayoutOrder = Array(0..<cells.count).shuffled()
        }
        slipPositions = slipLayoutOrder.map { cells[$0] }
    }

    private func drawSlip(at index: Int) {
        guard !drawnSlips.contains(index),
              !isDrawingInProgress,
              index < drawPool.count,
              let drawingParticipant = currentParticipant else { return }

        isDrawingInProgress = true

        let player = drawPool[index]

        // Show toast with assignment
        showAssignmentToast(participant: drawingParticipant, player: player)

        withAnimation(.easeInOut(duration: 0.5)) {
            drawnSlips.insert(index)
            enlargedSlips.insert(index)
        }

        if assignments[drawingParticipant] == nil {
            assignments[drawingParticipant] = []
        }
        assignments[drawingParticipant]?.append(player)

        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.5)) {
                enlargedSlips.remove(index)
                disappearingSlips.insert(index)
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                advanceTurn()
                isDrawingInProgress = false
            }
        }
    }
    
    private func showAssignmentToast(participant: Participant, player: Player) {
        toastMessage = "\(participant.name) got \(player.name)!"
        withAnimation { showToast = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            withAnimation { showToast = false }
        }
    }
    
    private func pickAllSlips() {
        guard !participants.isEmpty else { return }
        showPickAllButton = false

        for participant in participants {
            assignments[participant] = []
        }

        // Same drawPool and same turnQueue the manual flow would have used, so
        // "Pick All" is exactly the draw the player would have tapped out by hand.
        for (index, player) in drawPool.enumerated() where index < turnQueue.count {
            let participant = participants[turnQueue[index]]
            assignments[participant]?.append(player)

            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    _ = drawnSlips.insert(index)
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + Double(selectedPlayers.count) * 0.1 + 0.5) {
            turnCursor = turnQueue.count
            withAnimation(.easeInOut(duration: 0.3)) {
                isDrawingComplete = true
            }
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }

    private func advanceTurn() {
        turnCursor += 1

        if drawnSlips.count >= selectedPlayers.count {
            isDrawingComplete = true
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}

// MARK: - Football Slip View

struct FootballSlipView: View {
    let isDrawn: Bool
    let isEnlarged: Bool
    let player: Player
    let onTap: () -> Void
    
    @State private var isAnimating = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                if !isDrawn {
                    // Crumpled paper
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.95, green: 0.94, blue: 0.89), Color(red: 0.88, green: 0.86, blue: 0.78)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.black.opacity(0.1), lineWidth: 1)
                                
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
                    // Revealed slip
                    VStack(spacing: 2) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                            .frame(height: 3)
                        
                        Text(player.name)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.6)
                        
                        Text(player.position.rawValue)
                            .font(.system(size: 7, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    }
                    .padding(4)
                    .frame(width: 54, height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .shadow(color: AppDesignSystem.Colors.grassGreen.opacity(0.4), radius: 6, x: 0, y: 3)
                    )
                }
            }
            .frame(width: 60, height: 60)
            .scaleEffect(isEnlarged ? 1.3 : 1.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: isEnlarged)
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            if !isDrawn {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double.random(in: 0...2)) {
                    isAnimating = true
                }
            }
        }
    }
}

// MARK: - Drawing Result Card

struct DrawingResultCard: View {
    let participant: Participant
    let players: [Player]
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Text(String(participant.name.prefix(1).uppercased()))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(participant.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("\(players.count) player\(players.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
            }
            
            if !players.isEmpty {
                VStack(spacing: 6) {
                    ForEach(players) { player in
                        HStack(spacing: 10) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(AppDesignSystem.TeamColors.getColor(for: player.team))
                                .frame(width: 3, height: 24)
                            
                            Text(player.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Spacer()
                            
                            Text(player.position.rawValue)
                                .font(.system(size: 11))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(AppDesignSystem.Colors.secondaryText.opacity(0.1))
                                )
                        }
                    }
                }
                .padding(.leading, 8)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}
