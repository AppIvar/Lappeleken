//
//  Enhanced GameSummaryView.swift
//  Lucky Football Slip
//
//  Enhanced with vibrant design patterns
//

import SwiftUI

struct GameSummaryView: View {
    let gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @State private var gameName: String = ""
    @State private var showingSaveDialog = false
    @State private var showConfetti = false
    @State private var pulseWinner = false

    
    // Computed properties
    private var sortedEvents: [GameEvent] {
        return gameSession.events.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    private var sortedParticipants: [Participant] {
        return gameSession.participants.sorted(by: { $0.balance > $1.balance })
    }
    
    private var hasEvents: Bool {
        return !gameSession.events.isEmpty
    }
    
    private var winner: Participant? {
        return sortedParticipants.first { $0.balance > 0 }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background with celebration effect
                backgroundView
                
                if showConfetti {
                    ConfettiView()
                        .ignoresSafeArea()
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Enhanced header with winner celebration
                        headerSection
                        
                        // Winner spotlight
                        if let winner = winner {
                            winnerSpotlightSection(winner)
                        }
                        
                        // Final standings
                        standingsSection
                        
                        // Events summary
                        if hasEvents {
                            eventsSection
                        }
                        
                        // Payments section
                        paymentsSection
                        
                        // Action buttons
                        actionButtonsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Game Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppDesignSystem.Colors.primary)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            .onAppear {
                
                if winner != nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                            pulseWinner = true
                        }
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                            showConfetti = true
                        }
                    }
                }
            }
            .sheet(isPresented: $showingSaveDialog) {
                enhancedSaveGameSheet
            }
        }
        
        .withSmartBanner()
        .onAppear {
            // Show interstitial after game completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showInterstitialIfNeeded()
            }
        }
    }
    
    private func showInterstitialIfNeeded() {
        guard AppPurchaseManager.shared.currentTier == .free else { return }
        
        if AdManager.shared.shouldShowInterstitialAfterGameComplete() {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }
            
            AdManager.shared.showInterstitialAd(from: rootViewController) { success in
                if success {
                    print("✅ Game completion interstitial shown")
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                AppDesignSystem.Colors.background,
                AppDesignSystem.Colors.background.opacity(0.95),
                AppDesignSystem.Colors.cardBackground
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppDesignSystem.Colors.success.opacity(0.2),
                                AppDesignSystem.Colors.success.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: winner != nil ? "trophy.fill" : "flag.checkered")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: winner != nil ? [
                                AppDesignSystem.Colors.goalYellow,
                                AppDesignSystem.Colors.success
                            ] : [
                                AppDesignSystem.Colors.primary,
                                AppDesignSystem.Colors.secondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: (winner != nil ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.primary).opacity(0.3),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            }
            .scaleEffect(pulseWinner ? 1.05 : 1.0)
            
            VStack(spacing: 8) {
                Text(winner != nil ? "Game Complete!" : "Game Summary")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.primaryText,
                                AppDesignSystem.Colors.primary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                if hasEvents {
                    Text("\(gameSession.events.count) events • \(gameSession.participants.count) participants")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                } else {
                    Text("Practice game completed")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
        }
    }
    
    // MARK: - Winner Spotlight
    
    private func winnerSpotlightSection(_ winner: Participant) -> some View {
        VStack(spacing: 16) {
            Text("🏆 Champion")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.goalYellow)
            
            VStack(spacing: 12) {
                Text(winner.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(formatCurrency(winner.balance))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.success,
                                AppDesignSystem.Colors.grassGreen
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Final winnings")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.Colors.goalYellow,
                                        AppDesignSystem.Colors.success
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(
                color: AppDesignSystem.Colors.success.opacity(0.2),
                radius: 12,
                x: 0,
                y: 6
            )
        }
    }
    
    // MARK: - Standings Section
    
    private var standingsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "list.number")
                    .font(.system(size: 20))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Final Standings")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                    participantRow(participant: participant, position: index + 1)
                        .animation(
                            AppDesignSystem.Animations.bouncy.delay(Double(index) * 0.1),
                            value: sortedParticipants.count
                        )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
    
    private func participantRow(participant: Participant, position: Int) -> some View {
        HStack(spacing: 16) {
            // Position badge
            ZStack {
                Circle()
                    .fill(positionColor(position))
                    .frame(width: 32, height: 32)
                
                Text("\(position)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(participant.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("\(participant.selectedPlayers.count + participant.substitutedPlayers.count) players")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Text(formatCurrency(participant.balance))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    participant.balance > 0 ?
                    AppDesignSystem.Colors.success.opacity(0.1) :
                    Color.clear
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            participant.balance > 0 ?
                            AppDesignSystem.Colors.success.opacity(0.3) :
                            Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private func positionColor(_ position: Int) -> Color {
        switch position {
        case 1: return AppDesignSystem.Colors.goalYellow
        case 2: return AppDesignSystem.Colors.secondary
        case 3: return AppDesignSystem.Colors.warning
        default: return AppDesignSystem.Colors.secondaryText.opacity(0.6)
        }
    }
    
    // MARK: - Events Section
    
    private var eventsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 20))
                    .foregroundColor(AppDesignSystem.Colors.accent)
                
                Text("Game Events")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                VibrantStatusBadge("\(sortedEvents.count)", color: AppDesignSystem.Colors.accent)
            }
            
            if sortedEvents.count > 3 {
                // Show only recent events with expand option
                VStack(spacing: 8) {
                    ForEach(Array(sortedEvents.prefix(3).enumerated()), id: \.element.id) { index, event in
                        enhancedEventRow(event: event, index: index)
                    }
                    
                    Button("View all \(sortedEvents.count) events") {
                        // Could expand or navigate to full timeline
                    }
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.accent)
                    .padding(.top, 8)
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(sortedEvents.enumerated()), id: \.element.id) { index, event in
                        enhancedEventRow(event: event, index: index)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
    
    private func enhancedEventRow(event: GameEvent, index: Int) -> some View {
        HStack(spacing: 12) {
            // Event icon
            Circle()
                .fill(eventColor(event.eventType).opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: eventIcon(event.eventType))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(eventColor(event.eventType))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.player.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                HStack(spacing: 8) {
                    Text(event.eventType.rawValue)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(eventColor(event.eventType))
                    
                    Text("•")
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Text(event.player.team.name)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            Text(formatTime(event.timestamp))
                .font(AppDesignSystem.Typography.captionFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    private func eventColor(_ eventType: Bet.EventType) -> Color {
        switch eventType {
        case .goal, .penalty: return AppDesignSystem.Colors.success
        case .assist: return AppDesignSystem.Colors.primary
        case .yellowCard: return AppDesignSystem.Colors.goalYellow
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.warning
        default: return AppDesignSystem.Colors.accent
        }
    }
    
    private func eventIcon(_ eventType: Bet.EventType) -> String {
        switch eventType {
        case .goal: return "soccerball"
        case .assist: return "arrow.up.forward"
        case .yellowCard, .redCard: return "square.fill"
        case .penalty: return "p.circle"
        case .ownGoal: return "arrow.uturn.backward"
        default: return "star"
        }
    }
    
    // MARK: - Payments Section
    
    private var paymentsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "creditcard")
                    .font(.system(size: 20))
                    .foregroundColor(AppDesignSystem.Colors.info)
                
                Text("Payments")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            let payments = calculatePayments()
            
            if payments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppDesignSystem.Colors.success)
                    
                    Text("All Even!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("No payments needed between participants")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppDesignSystem.Colors.success.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppDesignSystem.Colors.success.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(payments.enumerated()), id: \.element.id) { index, payment in
                        paymentRow(payment: payment)
                            .animation(
                                AppDesignSystem.Animations.bouncy.delay(Double(index) * 0.1),
                                value: payments.count
                            )
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
    
    private func paymentRow(payment: Payment) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.from)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Pays")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.info)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.to)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Receives")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Text(formatCurrency(payment.amount))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.info)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.info.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppDesignSystem.Colors.info.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Action Buttons
    
    @ObservedObject private var adManager = AdManager.shared
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button("Save Game") {
                showingSaveDialog = true
            }
            .buttonStyle(EnhancedPrimaryButtonStyle())
            
            Button("Return to Home") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(EnhancedSecondaryButtonStyle())
        }
    }
    
    // MARK: - Enhanced Save Game Sheet
    
    private var enhancedSaveGameSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 50))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    
                    Text("Save Game Session")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("Give your game a memorable name")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 12) {
                    Text("Game Name")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField("Enter game name", text: $gameName)
                        .font(AppDesignSystem.Typography.bodyFont)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppDesignSystem.Colors.background)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.05),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                }
                
                Button("Save Game") {
                    let finalGameName = gameName.isEmpty ? "Game \(Date().formatted(date: .abbreviated, time: .shortened))" : gameName
                    
                    GameHistoryManager.shared.saveGameSession(gameSession, name: finalGameName)
                    
                    showingSaveDialog = false
                    gameName = ""
                    
                    print("✅ Game save dialog completed")
                }
                .buttonStyle(EnhancedPrimaryButtonStyle())
                .padding(.top)
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Save Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingSaveDialog = false
                    }
                    .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
        }
        .showBannerAdForFreeUsers()
    }
    
    
    // MARK: - Helper Methods (keeping your existing logic)
    

    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func calculatePayments() -> [Payment] {
        var payments: [Payment] = []
        
        var debtors = gameSession.participants.filter { $0.balance < 0 }
            .map { createParticipantCopy($0) }
            .sorted(by: { abs($0.balance) > abs($1.balance) })
        
        var creditors = gameSession.participants.filter { $0.balance > 0 }
            .map { createParticipantCopy($0) }
            .sorted(by: { $0.balance > $1.balance })
            
        while !debtors.isEmpty && !creditors.isEmpty {
            var debtor = debtors[0]
            var creditor = creditors[0]
            
            let paymentAmount = min(abs(debtor.balance), creditor.balance)
            
            if paymentAmount > 0.01 {
                payments.append(Payment(
                    from: debtor.name,
                    to: creditor.name,
                    amount: paymentAmount
                ))
                
                debtor.balance += paymentAmount
                creditor.balance -= paymentAmount
                
                debtors[0] = debtor
                creditors[0] = creditor
            }
            
            if abs(debtor.balance) < 0.01 {
                debtors.remove(at: 0)
            }
            
            if creditor.balance < 0.01 {
                creditors.remove(at: 0)
            }
        }
        
        return payments
    }
    
    private func createParticipantCopy(_ participant: Participant) -> Participant {
        return Participant(
            id: participant.id,
            name: participant.name,
            selectedPlayers: participant.selectedPlayers,
            substitutedPlayers: participant.substitutedPlayers,
            balance: participant.balance
        )
    }
}

// MARK: - Payment Helper Struct

extension GameSummaryView {
    struct Payment: Identifiable {
        let id = UUID()
        let from: String
        let to: String
        let amount: Double
    }
}

// MARK: - Enhanced Button Styles

struct EnhancedTertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(AppDesignSystem.Colors.secondaryText)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.1))
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: configuration.isPressed)
    }
}
