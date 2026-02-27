//
//  GameSummaryView.swift
//  Lucky Football Slip
//
//  End game results - Football themed
//

import SwiftUI

struct GameSummaryView: View {
    let gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var gameName: String = ""
    @State private var showingSaveDialog = false
    @State private var showConfetti = false
    @State private var pulseWinner = false
    
    private var sortedParticipants: [Participant] {
        gameSession.participants.sorted { $0.balance > $1.balance }
    }
    
    private var winner: Participant? {
        sortedParticipants.first { $0.balance > 0 }
    }
    
    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                footballBackground
                
                if showConfetti { ConfettiView().ignoresSafeArea() }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerSection
                        if let winner = winner { winnerCard(winner) }
                        standingsSection
                        if !gameSession.events.isEmpty { eventsSection }
                        paymentsSection
                        actionButtons
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
            }
            .navigationTitle("Game Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                        .font(.system(size: 16, weight: .semibold))
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { showInterstitialIfNeeded() }
            }
            .sheet(isPresented: $showingSaveDialog) { saveGameSheet }
        }
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            
            VStack {
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.2 : 0.1),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
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
                    .fill(AppDesignSystem.Colors.goalYellow.opacity(0.15))
                    .frame(width: 90, height: 90)
                    .scaleEffect(pulseWinner ? 1.1 : 1.0)
                
                Image(systemName: winner != nil ? "trophy.fill" : "flag.checkered")
                    .font(.system(size: 40))
                    .foregroundColor(AppDesignSystem.Colors.goalYellow)
            }
            
            VStack(spacing: 6) {
                Text(winner != nil ? "Game Complete!" : "Game Summary")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("\(gameSession.events.count) events • \(gameSession.participants.count) participants")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
    
    // MARK: - Winner Card
    
    private func winnerCard(_ winner: Participant) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "crown.fill")
                    .foregroundColor(AppDesignSystem.Colors.goalYellow)
                Text("WINNER")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.goalYellow)
            }
            
            Text(winner.name)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("+\(currencySymbol)\(String(format: "%.2f", winner.balance))")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.grassGreen)
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(AppDesignSystem.Colors.goalYellow.opacity(0.4), lineWidth: 2)
                )
                .shadow(color: AppDesignSystem.Colors.goalYellow.opacity(0.2), radius: 12, x: 0, y: 6)
        )
    }
    
    // MARK: - Standings
    
    private var standingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "list.number")
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                Text("Final Standings")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            
            VStack(spacing: 0) {
                ForEach(Array(sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                    SummaryStandingRow(participant: participant, position: index + 1, currencySymbol: currencySymbol)
                    
                    if index < sortedParticipants.count - 1 {
                        Divider().padding(.horizontal, 12)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppDesignSystem.Colors.cardBackground)
            )
        }
    }
    
    // MARK: - Events Summary
    
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundColor(AppDesignSystem.Colors.accent)
                Text("Event Summary")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            
            let eventCounts = Dictionary(grouping: gameSession.events, by: { $0.eventType }).mapValues { $0.count }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(Bet.EventType.allCases.filter { eventCounts[$0] ?? 0 > 0 }, id: \.self) { eventType in
                    if let count = eventCounts[eventType] {
                        SummaryEventBadge(eventType: eventType, count: count)
                    }
                }
            }
        }
    }
    
    // MARK: - Payments
    
    private var paymentsSection: some View {
        let payments = calculatePayments()
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.left.arrow.right")
                    .foregroundColor(AppDesignSystem.Colors.info)
                Text("Settlements")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
            
            if payments.isEmpty {
                HStack {
                    Spacer()
                    Text("No settlements needed")
                        .font(.system(size: 13))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    Spacer()
                }
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 10).fill(AppDesignSystem.Colors.cardBackground))
            } else {
                VStack(spacing: 8) {
                    ForEach(payments) { payment in
                        SummaryPaymentRow(payment: payment, currencySymbol: currencySymbol)
                    }
                }
            }
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { showingSaveDialog = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                    Text("Save Game")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 12).fill(AppDesignSystem.Colors.grassGreen))
            }
            
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("Return to Home")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppDesignSystem.Colors.grassGreen, lineWidth: 1.5)
                    )
            }
        }
    }
    
    // MARK: - Save Sheet
    
    private var saveGameSheet: some View {
        NavigationView {
            ZStack {
                footballBackground
                
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                            .frame(width: 64, height: 64)
                        Image(systemName: "square.and.arrow.down")
                            .font(.system(size: 28))
                            .foregroundColor(AppDesignSystem.Colors.grassGreen)
                    }
                    
                    Text("Save Game Session")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Game Name")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        TextField("Enter game name", text: $gameName)
                            .font(.system(size: 15))
                            .padding(14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(AppDesignSystem.Colors.grassGreen.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    
                    Button(action: {
                        let name = gameName.isEmpty ? "Game \(Date().formatted(date: .abbreviated, time: .shortened))" : gameName
                        GameHistoryManager.shared.saveGameSession(gameSession, name: name)
                        showingSaveDialog = false
                        gameName = ""
                    }) {
                        Text("Save Game")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(AppDesignSystem.Colors.grassGreen))
                    }
                    
                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Save Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { showingSaveDialog = false }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func showInterstitialIfNeeded() {
        guard AppPurchaseManager.shared.currentTier == .free else { return }
        if AdManager.shared.shouldShowInterstitial(for: .gameComplete) {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else { return }
            AdManager.shared.showInterstitialAd(from: rootViewController) { _ in }
        }
    }
    
    private func calculatePayments() -> [Payment] {
        var payments: [Payment] = []
        var debtors = gameSession.participants.filter { $0.balance < 0 }.map { createParticipantCopy($0) }.sorted { abs($0.balance) > abs($1.balance) }
        var creditors = gameSession.participants.filter { $0.balance > 0 }.map { createParticipantCopy($0) }.sorted { $0.balance > $1.balance }
        
        while !debtors.isEmpty && !creditors.isEmpty {
            var debtor = debtors[0]
            var creditor = creditors[0]
            let amount = min(abs(debtor.balance), creditor.balance)
            
            if amount > 0.01 {
                payments.append(Payment(from: debtor.name, to: creditor.name, amount: amount))
                debtor.balance += amount
                creditor.balance -= amount
                debtors[0] = debtor
                creditors[0] = creditor
            }
            if abs(debtor.balance) < 0.01 { debtors.remove(at: 0) }
            if creditor.balance < 0.01 { creditors.remove(at: 0) }
        }
        return payments
    }
    
    private func createParticipantCopy(_ p: Participant) -> Participant {
        Participant(id: p.id, name: p.name, selectedPlayers: p.selectedPlayers, substitutedPlayers: p.substitutedPlayers, balance: p.balance)
    }
    
    struct Payment: Identifiable {
        let id = UUID()
        let from: String
        let to: String
        let amount: Double
    }
}

// MARK: - Supporting Components

struct SummaryStandingRow: View {
    let participant: Participant
    let position: Int
    let currencySymbol: String
    
    private var positionColor: Color {
        switch position {
        case 1: return AppDesignSystem.Colors.goalYellow
        case 2: return AppDesignSystem.Colors.secondaryText
        case 3: return AppDesignSystem.Colors.accent
        default: return AppDesignSystem.Colors.secondaryText.opacity(0.5)
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(positionColor.opacity(position <= 3 ? 0.15 : 0.08))
                    .frame(width: 28, height: 28)
                Text("\(position)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(positionColor)
            }
            
            Text(participant.name)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Text("\(participant.balance >= 0 ? "+" : "")\(currencySymbol)\(String(format: "%.2f", participant.balance))")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.error)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}

struct SummaryEventBadge: View {
    let eventType: Bet.EventType
    let count: Int
    
    private var icon: String {
        switch eventType {
        case .goal: return "soccerball"
        case .assist: return "arrow.up.forward"
        case .yellowCard: return "square.fill"
        case .redCard: return "square.fill"
        case .ownGoal: return "arrow.uturn.backward"
        case .penalty: return "p.circle"
        case .penaltyMissed: return "p.circle.fill"
        case .cleanSheet: return "lock.shield"
        case .custom: return "star"
        }
    }
    
    private var color: Color {
        switch eventType {
        case .goal, .assist: return AppDesignSystem.Colors.grassGreen
        case .yellowCard: return AppDesignSystem.Colors.goalYellow
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.warning
        case .penalty, .cleanSheet: return AppDesignSystem.Colors.info
        case .custom: return AppDesignSystem.Colors.accent
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            
            Text(eventType.rawValue.capitalized)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Text("\(count)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(color)
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 8).fill(color.opacity(0.1)))
    }
}

struct SummaryPaymentRow: View {
    let payment: GameSummaryView.Payment
    let currencySymbol: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text(payment.from)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.error)
            
            Image(systemName: "arrow.right")
                .font(.system(size: 12))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text(payment.to)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.grassGreen)
            
            Spacer()
            
            Text("\(currencySymbol)\(String(format: "%.2f", payment.amount))")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 8).fill(AppDesignSystem.Colors.cardBackground))
    }
}
