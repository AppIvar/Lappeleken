//
//  Enhanced NewGameSetupView.swift
//  Lucky Football Slip
//
//  Vibrant game setup with enhanced design system
//

import SwiftUI

struct NewGameSetupView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var gameSession: GameSession
    
    @State private var currentStep = 0
    @State private var participantName = ""
    @State private var selectedPlayerIds = Set<UUID>()
    @State private var betAmounts = [Bet.EventType: Double]()
    @State private var betNegativeFlags = [Bet.EventType: Bool]()
    @State private var showingCustomBetSheet = false
    // REMOVED: @State private var animateProgress = false
    // REMOVED: @State private var animateGradient = false
    
    private let steps = ["Participants", "Select Players", "Set Bets", "Review"]
    
    var body: some View {
        ZStack {
            // Enhanced static background (no animation)
            backgroundView
            
            NavigationView {
                VStack(spacing: 0) {
                    // Enhanced progress indicator (no animations)
                    progressIndicatorView
                    
                    // Content with smooth transitions
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            stepContentView
                        }
                        .padding(24)
                        .padding(.bottom, 120) // Space for floating buttons
                    }
                    .background(Color.clear)
                }
                .overlay(
                    // Floating navigation buttons
                    floatingNavigationButtons,
                    alignment: .bottom
                )
                .navigationTitle("New Game Setup")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    }
                }
            }
        }
        .onAppear {
            setupInitialData()
            // REMOVED: All animation code
        }
        .sheet(isPresented: $showingCustomBetSheet) {
            CustomBetView(gameSession: gameSession)
        }
        .withMinimalBanner()
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 1.0),
                Color(red: 0.98, green: 0.96, blue: 1.0),
                Color(red: 0.96, green: 0.97, blue: 1.0)
            ],
            startPoint: .topLeading, // REMOVED: animation-dependent values
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Progress Indicator
    
    private var progressIndicatorView: some View {
        VStack(spacing: 16) {
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack {
                        // Step circle
                        ZStack {
                            Circle()
                                .fill(
                                    index <= currentStep ?
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
                                            AppDesignSystem.Colors.secondaryText.opacity(0.2),
                                            AppDesignSystem.Colors.secondaryText.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            
                            if index < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(
                                        index <= currentStep ? .white : AppDesignSystem.Colors.secondaryText
                                    )
                            }
                        }
                        .shadow(
                            color: index <= currentStep ?
                            AppDesignSystem.Colors.primary.opacity(0.3) :
                            Color.clear,
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                        // REMOVED: .scaleEffect and .animation modifiers
                        
                        // Connection line
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(
                                    index < currentStep ?
                                    AppDesignSystem.Colors.primary :
                                    AppDesignSystem.Colors.secondaryText.opacity(0.2)
                                )
                                .frame(height: 3)
                                .cornerRadius(1.5)
                                // REMOVED: .scaleEffect and .animation modifiers
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Step labels
            HStack {
                ForEach(0..<steps.count, id: \.self) { index in
                    Text(steps[index])
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(
                            index <= currentStep ?
                            AppDesignSystem.Colors.primaryText :
                            AppDesignSystem.Colors.secondaryText
                        )
                        .frame(maxWidth: .infinity)
                        // REMOVED: .opacity and .animation modifiers
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 20)
        .background(
            Rectangle()
                .fill(AppDesignSystem.Colors.cardBackground.opacity(0.8))
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContentView: some View {
        switch currentStep {
        case 0:
            participantsSetupView
        case 1:
            playersSelectionView
        case 2:
            setBetsView
        case 3:
            reviewView
        default:
            EmptyView()
        }
    }
    
    // MARK: - Participants Setup
    
    private var participantsSetupView: some View {
        VStack(spacing: 24) {
            // Enhanced header
            VStack(spacing: 8) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.primary,
                                AppDesignSystem.Colors.secondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: AppDesignSystem.Colors.primary.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                Text("Add Participants")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Who's playing in this game?")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Enhanced participant input
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    TextField("Enter participant name", text: $participantName)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(
                                            participantName.isEmpty ?
                                            Color.gray.opacity(0.3) :
                                            AppDesignSystem.Colors.primary.opacity(0.5),
                                            lineWidth: 1
                                        )
                                )
                        )
                        .shadow(
                            color: Color.black.opacity(0.05),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                    
                    Button(action: addParticipant) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(
                                participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                AppDesignSystem.Colors.disabled :
                                AppDesignSystem.Colors.primary
                            )
                    }
                    .disabled(participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    // REMOVED: .scaleEffect and .animation modifiers
                }
                
                if gameSession.participants.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppDesignSystem.Colors.warning)
                        
                        Text("Add at least one participant to continue")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.warning)
                    }
                }
            }
            
            // Enhanced participants list
            if !gameSession.participants.isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Participants (\(gameSession.participants.count))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    ForEach(gameSession.participants) { participant in
                        EnhancedParticipantRow(
                            participant: participant,
                            onDelete: {
                                deleteParticipant(participant)
                            }
                        )
                    }
                }
            }
        }
    }
    
    
    // MARK: - Players Selection
    
    private var playersSelectionView: some View {
        VStack(spacing: 24) {
            // Enhanced header with action
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "sportscourt.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.Colors.success,
                                        AppDesignSystem.Colors.info
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Select Players")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Choose players for your game")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    NavigationLink(destination: ManualPlayerEntryView(gameSession: gameSession)) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppDesignSystem.Colors.secondary)
                            
                            Text("Add Player")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondary)
                        }
                    }
                }
                
                if selectedPlayerIds.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(AppDesignSystem.Colors.warning)
                        
                        Text("Select at least one player to continue")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.warning)
                    }
                } else {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(AppDesignSystem.Colors.success)
                        
                        Text("\(selectedPlayerIds.count) players selected")
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.success)
                    }
                }
            }
            
            // Enhanced team sections
            ForEach(Array(Set(gameSession.availablePlayers.map { $0.team })).sorted(by: { $0.name < $1.name }), id: \.id) { team in
                EnhancedTeamSection(
                    team: team,
                    players: gameSession.availablePlayers.filter { $0.team.id == team.id },
                    selectedPlayerIds: $selectedPlayerIds
                )
            }
        }
    }
    
    // MARK: - Set Bets
    
    private var setBetsView: some View {
        VStack(spacing: 24) {
            // Enhanced header with custom event action
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.Colors.warning,
                                        AppDesignSystem.Colors.secondary
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Set Betting Amounts")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Configure event payouts")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingCustomBetSheet = true
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(AppDesignSystem.Colors.accent)
                            
                            Text("Custom Event")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.accent)
                        }
                    }
                }
            }
            
            // Enhanced currency selection
            EnhancedCurrencySelector()
            
            // Enhanced betting rules explanation
            VStack(alignment: .leading, spacing: 8) {
                Text("How Betting Works")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                VStack(spacing: 4) {
                    BettingRuleRow(
                        icon: "plus.circle.fill",
                        text: "Positive bets: Players without the event pay those with it",
                        color: AppDesignSystem.Colors.success
                    )
                    
                    BettingRuleRow(
                        icon: "minus.circle.fill",
                        text: "Negative bets: Players with the event pay those without it",
                        color: AppDesignSystem.Colors.error
                    )
                }
            }
            .enhancedCard()
            
            // Enhanced bet settings - excluding .custom from allCases
            ForEach(Bet.EventType.allCases.filter { $0 != .custom }, id: \.self) { eventType in
                EnhancedBetSettingsRow(
                    eventType: eventType,
                    betAmount: Binding(
                        get: { abs(betAmounts[eventType] ?? 1.0) },
                        set: { amount in
                            let isNegative = betNegativeFlags[eventType] ?? false
                            betAmounts[eventType] = isNegative ? -abs(amount) : abs(amount)
                        }
                    ),
                    isNegative: Binding(
                        get: { betNegativeFlags[eventType] ?? false },
                        set: { isNegative in
                            betNegativeFlags[eventType] = isNegative
                            if let amount = betAmounts[eventType] {
                                betAmounts[eventType] = isNegative ? -abs(amount) : abs(amount)
                            }
                        }
                    )
                )
            }
            
            // Custom events section
            if !gameSession.getCustomEvents().isEmpty {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Custom Events")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    ForEach(gameSession.getCustomEvents(), id: \.id) { customEvent in
                        EnhancedCustomEventRow(
                            name: customEvent.name,
                            amount: customEvent.amount,
                            onDelete: {
                                gameSession.removeCustomEvent(id: customEvent.id)
                            }
                        )
                    }
                }
                .enhancedCard()
            }
        }
    }
    
    struct EnhancedCustomEventRow: View {
        let name: String
        let amount: Double
        let onDelete: () -> Void
        
        private var currencySymbol: String {
            UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        }
        
        private var isNegative: Bool {
            amount < 0
        }
        
        var body: some View {
            VStack(spacing: 16) {
                HStack {
                    // Custom event icon with gradient
                    Image(systemName: "star.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.accent,
                                    AppDesignSystem.Colors.accent.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text(name)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                    
                    // Delete button
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                            .foregroundColor(AppDesignSystem.Colors.error)
                            .padding(8)
                            .background(AppDesignSystem.Colors.error.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                
                HStack {
                    // Type indicator with enhanced styling
                    HStack(spacing: 8) {
                        Image(systemName: isNegative ? "minus.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                        
                        Text(isNegative ? "Negative" : "Positive")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill((isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success).opacity(0.1))
                    )
                    
                    Spacer()
                    
                    // Amount with enhanced styling
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(currencySymbol)\(String(format: "%.2f", abs(amount)))")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("Amount")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                
                // Enhanced description
                VStack(alignment: .leading, spacing: 4) {
                    Text("Event Description")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Text(eventDescription)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppDesignSystem.Colors.accent.opacity(0.05))
                        )
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppDesignSystem.Colors.accent.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(
                color: AppDesignSystem.Colors.accent.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        
        private var eventDescription: String {
            let amountString = String(format: "%.2f", abs(amount))
            return isNegative ?
            "Players WITH this event pay \(currencySymbol)\(amountString) to those without it" :
            "Players WITHOUT this event pay \(currencySymbol)\(amountString) to those with it"
        }
    }
    
    // MARK: - Review
    
    private var reviewView: some View {
        VStack(spacing: 24) {
            // Enhanced header
            VStack(spacing: 8) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.success,
                                AppDesignSystem.Colors.primary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: AppDesignSystem.Colors.success.opacity(0.3),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                
                Text("Review Game Setup")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Everything looks good? Let's start playing!")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Enhanced review sections
            EnhancedReviewSection(
                title: "Participants",
                icon: "person.3.fill",
                color: AppDesignSystem.Colors.primary,
                content: gameSession.participants.map { $0.name }.joined(separator: ", "),
                count: gameSession.participants.count
            )
            
            EnhancedReviewSection(
                title: "Selected Players",
                icon: "sportscourt.fill",
                color: AppDesignSystem.Colors.success,
                content: createPlayersReviewText(),
                count: selectedPlayerIds.count
            )
            
            EnhancedReviewSection(
                title: "Betting Rules",
                icon: "dollarsign.circle.fill",
                color: AppDesignSystem.Colors.warning,
                content: createBetsReviewText(),
                count: totalBetsCount
            )
            
            // Ready message
            VStack(spacing: 12) {
                Text("🎉 Ready to Start!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Players will be randomly assigned to participants, and the game will begin.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .enhancedCard()
        }
    }
    
    // MARK: - Floating Navigation
    
    private var floatingNavigationButtons: some View {
        VStack(spacing: 0) {
            Spacer()
            
            HStack(spacing: 16) {
                if currentStep > 0 {
                    Button("Back") {
                        withAnimation(AppDesignSystem.Animations.standard) {
                            currentStep -= 1
                        }
                    }
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                    .padding(.vertical, 16)
                    .padding(.horizontal, 24)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(AppDesignSystem.Colors.primary, lineWidth: 2)
                            )
                    )
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
                
                Spacer()
                
                Button(currentStep < steps.count - 1 ? "Next" : "Assign Players") {
                    handleNextButton()
                }
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, currentStep < steps.count - 1 ? 32 : 24)
                .background(
                    RoundedRectangle(cornerRadius: 25)
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
                .vibrantButton()
                .disabled(!canProceed)
                .opacity(canProceed ? 1.0 : 0.6)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                Rectangle()
                    .fill(AppDesignSystem.Colors.background.opacity(0.95))
                    .shadow(
                        color: Color.black.opacity(0.1),
                        radius: 8,
                        x: 0,
                        y: -4
                    )
            )
        }
    }
    
    // MARK: - Helper Methods
    
    private func setupInitialData() {
        // ALWAYS reset to sample players for manual mode
        gameSession.availablePlayers = []
        gameSession.selectedPlayers = []
        gameSession.addPlayers(SampleData.samplePlayers)
        
        if betAmounts.isEmpty {
            for eventType in Bet.EventType.allCases {
                betAmounts[eventType] = 1.0
                
                if eventType == .ownGoal || eventType == .redCard ||
                   eventType == .yellowCard || eventType == .penaltyMissed {
                    betNegativeFlags[eventType] = true
                    betAmounts[eventType] = -1.0
                } else {
                    betNegativeFlags[eventType] = false
                }
            }
        }
    }
    
    private func addParticipant() {
        let trimmedName = participantName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            // REMOVED: withAnimation wrapper
            gameSession.addParticipant(trimmedName)
            participantName = ""
        }
    }
    
    private func deleteParticipant(_ participant: Participant) {
        // REMOVED: withAnimation wrapper
        if let index = gameSession.participants.firstIndex(where: { $0.id == participant.id }) {
            gameSession.participants.remove(at: index)
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !gameSession.participants.isEmpty
        case 1: return !selectedPlayerIds.isEmpty
        case 2: return true
        case 3: return true
        default: return false
        }
    }
    
    private func handleNextButton() {
        // Auto-add participant if name is entered but not added (for step 0)
        if currentStep == 0 {
            let trimmedName = participantName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedName.isEmpty {
                gameSession.addParticipant(trimmedName)
                participantName = ""
            }
        }
        
        if currentStep < steps.count - 1 {
            if currentStep == 1 {
                gameSession.selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
            }
            
            if currentStep == 2 {
                // FIXED: Preserve custom events while recreating standard bets
                gameSession.preserveCustomEventsAndRecreateStandardBets(standardBetAmounts: betAmounts)
            }
            
            currentStep += 1
        } else {
            // Final step - assign players
            gameSession.selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
            
            for i in 0..<gameSession.participants.count {
                gameSession.participants[i].selectedPlayers = []
            }
            
            presentationMode.wrappedValue.dismiss()
            NotificationCenter.default.post(name: Notification.Name("ShowAssignment"), object: nil)
        }
    }
    
    private func createPlayersReviewText() -> String {
        let playersByTeam = Dictionary(grouping: gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }) { $0.team.name }
        
        return playersByTeam.keys.sorted().map { teamName in
            let players = playersByTeam[teamName] ?? []
            return "\(teamName): \(players.map { $0.name }.joined(separator: ", "))"
        }.joined(separator: "\n")
    }
    
    private func createBetsReviewText() -> String {
        var reviewItems: [String] = []
        
        // Add standard event types
        for (eventType, amount) in betAmounts {
            if eventType != .custom {
                let formattedAmount = formatCurrency(abs(amount))
                let prefix = amount >= 0 ? "+" : "-"
                reviewItems.append("\(eventType.rawValue): \(prefix)\(formattedAmount)")
            }
        }
        
        // Add custom events with their actual names
        let customEvents = gameSession.getCustomEvents()
        for customEvent in customEvents {
            let formattedAmount = formatCurrency(abs(customEvent.amount))
            let prefix = customEvent.amount >= 0 ? "+" : "-"
            reviewItems.append("\(customEvent.name): \(prefix)\(formattedAmount)")
        }
        
        return reviewItems.joined(separator: "\n")
    }

    private var totalBetsCount: Int {
        let standardBetsCount = betAmounts.filter { $0.key != .custom }.count
        let customEventsCount = gameSession.getCustomEvents().count
        return standardBetsCount + customEventsCount
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}

// MARK: - Enhanced Components

struct EnhancedParticipantRow: View {
    let participant: Participant
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        HStack(spacing: 16) {
            // Participant avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.primary,
                                AppDesignSystem.Colors.primary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                if let firstLetter = participant.name.first {
                    Text(String(firstLetter).uppercased())
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .shadow(
                color: AppDesignSystem.Colors.primary.opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
            
            Text(participant.name)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Button(action: {
                showDeleteConfirmation = true
            }) {
                Image(systemName: "trash.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(AppDesignSystem.Colors.error)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppDesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(
            color: Color.black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )
        .alert("Remove Participant", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to remove \(participant.name) from the game?")
        }
    }
}

struct EnhancedTeamSection: View {
    let team: Team
    let players: [Player]
    @Binding var selectedPlayerIds: Set<UUID>
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Team header
            Button(action: {
                withAnimation(AppDesignSystem.Animations.bouncy) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    // Team color indicator
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppDesignSystem.TeamColors.getColor(for: team))
                        .frame(width: 6, height: 24)
                    
                    Text(team.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    VibrantStatusBadge(
                        "\(players.count) players",
                        color: AppDesignSystem.TeamColors.getColor(for: team)
                    )
                    
                    Spacer()
                    
                    let selectedCount = players.filter { selectedPlayerIds.contains($0.id) }.count
                    if selectedCount > 0 {
                        VibrantStatusBadge(
                            "\(selectedCount) selected",
                            color: AppDesignSystem.Colors.success
                        )
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                    ForEach(players) { player in
                        PlayerCard(
                            player: player,
                            isSelected: selectedPlayerIds.contains(player.id),
                            action: {
                                withAnimation(AppDesignSystem.Animations.quick) {
                                    if selectedPlayerIds.contains(player.id) {
                                        selectedPlayerIds.remove(player.id)
                                    } else {
                                        selectedPlayerIds.insert(player.id)
                                    }
                                }
                            }
                        )
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .enhancedCard(team: team)
    }
}

struct EnhancedCurrencySelector: View {
    @AppStorage("selectedCurrency") private var selectedCurrency = "EUR"
    @AppStorage("currencySymbol") private var currencySymbol = "€"
    
    private let currencies = [
        ("USD", "$", "US Dollar"),
        ("EUR", "€", "Euro"),
        ("GBP", "£", "British Pound"),
        ("NOK", "kr", "Norwegian Krone"),
        ("SEK", "kr", "Swedish Krona"),
        ("DKK", "kr", "Danish Krone")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Currency")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Menu {
                ForEach(currencies, id: \.0) { currency in
                    Button(action: {
                        selectedCurrency = currency.0
                        currencySymbol = currency.1
                    }) {
                        HStack {
                            Text("\(currency.1) \(currency.0) - \(currency.2)")
                            if selectedCurrency == currency.0 {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 20))
                        .foregroundColor(AppDesignSystem.Colors.warning)
                    
                    Text(selectedCurrency)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(currencySymbol)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppDesignSystem.Colors.warning.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
        .enhancedCard()
    }
}

struct BettingRuleRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            
            Text(text)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
    }
}

struct EnhancedBetSettingsRow: View {
    let eventType: Bet.EventType
    @Binding var betAmount: Double
    @Binding var isNegative: Bool
    
    private func eventDescription(for eventType: Bet.EventType, isNegative: Bool) -> String {
        let action: String
        
        switch eventType {
        case .goal: action = "scores a goal"
        case .assist: action = "makes an assist"
        case .yellowCard: action = "receives a yellow card"
        case .redCard: action = "receives a red card"
        case .ownGoal: action = "scores own goal"
        case .penalty: action = "scores a penalty"
        case .penaltyMissed: action = "misses a penalty"
        case .cleanSheet: action = "kept a clean sheet"
        case .custom: action = "custom event"
        }
        
        let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        let amountString = String(format: "%.2f", abs(betAmount))
        
        return isNegative ?
        "Players WITH the event pay \(currencySymbol)\(amountString)" :
        "Players WITHOUT the event pay \(currencySymbol)\(amountString)"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(eventType.rawValue)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                // Toggle button
                Button(action: {
                    withAnimation(AppDesignSystem.Animations.bouncy) {
                        isNegative.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isNegative ? "minus.circle.fill" : "plus.circle.fill")
                            .font(.system(size: 20))
                        
                        Text(isNegative ? "Negative" : "Positive")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success,
                                        (isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success).opacity(0.8)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .vibrantButton(color: isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                }
            }
            
            HStack(spacing: 12) {
                Text(UserDefaults.standard.string(forKey: "currencySymbol") ?? "€")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                TextField("Amount", value: $betAmount, formatter: NumberFormatter())
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
            }
            
            Text(eventDescription(for: eventType, isNegative: isNegative))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.leading)
        }
        .enhancedCard()
    }
}

struct EnhancedReviewSection: View {
    let title: String
    let icon: String
    let color: Color
    let content: String
    let count: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                VibrantStatusBadge("\(count)", color: color)
            }
            
            Text(content)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .lineLimit(nil)
        }
        .enhancedCard()
    }
}
