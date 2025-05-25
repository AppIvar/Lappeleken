//
//  NewGameSetupView.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 08/05/2025.
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
    
    private let steps = ["Participants", "Select Players", "Set Bets", "Review"]
    
    var body: some View {
        NavigationView {
            VStack {
                // Progress indicator
                HStack {
                    ForEach(0..<steps.count, id: \.self) { index in
                        VStack {
                            Circle()
                                .fill(index <= currentStep ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.secondaryText.opacity(0.3))
                                .frame(width: 20, height: 20)
                            
                            Text(steps[index])
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(index <= currentStep ? AppDesignSystem.Colors.primaryText : AppDesignSystem.Colors.secondaryText)
                        }
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.secondaryText.opacity(0.3))
                                .frame(height: 2)
                        }
                    }
                }
                .padding()
                
                // Content based on current step
                ScrollView {
                    VStack {
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
                    .padding()
                }
                
                // Navigation buttons
                HStack {
                    if currentStep > 0 {
                        Button("Back") {
                            currentStep -= 1
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                    
                    Spacer()
                    
                    if currentStep < steps.count - 1 {
                        Button("Next") {
                            if currentStep == 0 && gameSession.participants.isEmpty {
                                // Don't proceed if no participants added
                                return
                            }
                            
                            if currentStep == 1 {
                                // Set selected players
                                gameSession.selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
                                
                                if gameSession.selectedPlayers.isEmpty {
                                    // Don't proceed if no players selected
                                    return
                                }
                            }
                            
                            if currentStep == 2 {
                                // Add bets with new negative bet support
                                gameSession.bets = []
                                for (eventType, amount) in betAmounts {
                                    gameSession.addBet(eventType: eventType, amount: amount)
                                }
                                print("Added \(gameSession.bets.count) bets")
                            }
                            
                            currentStep += 1
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    } else {
                        Button("Assign Players") {
                            // Make sure we have the selected players set
                            gameSession.selectedPlayers = gameSession.availablePlayers.filter { selectedPlayerIds.contains($0.id) }
                            
                            // Debug print
                            print("Before assignment setup:")
                            print("Participants: \(gameSession.participants.count)")
                            print("Selected players: \(gameSession.selectedPlayers.count)")
                            
                            for i in 0..<gameSession.participants.count {
                                gameSession.participants[i].selectedPlayers = []
                            }
                            presentationMode.wrappedValue.dismiss()
                            
                            NotificationCenter.default.post(name: Notification.Name("ShowAssignment"), object: nil)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding()
            }
            .onAppear {
                // Load sample data when the view appears
                if gameSession.availablePlayers.isEmpty {
                    gameSession.addPlayers(SampleData.samplePlayers)
                }
                
                // Initialize bet amounts and negative flags
                if betAmounts.isEmpty {
                    for eventType in Bet.EventType.allCases {
                        betAmounts[eventType] = 1.0
                        
                        // Set certain bets as negative by default
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
            .navigationTitle("New Game Setup")
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            
            .sheet(isPresented: $showingCustomBetSheet) {
                CustomBetView(gameSession: gameSession)
            }
        }
    }
    
    // MARK: - Step Views
    
    private var participantsSetupView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            Text("Add Participants")
                .font(AppDesignSystem.Typography.headingFont)
            
            HStack {
                TextField("Participant name", text: $participantName)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Button(action: {
                    if !participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        gameSession.addParticipant(participantName)
                        participantName = ""
                    }
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .disabled(participantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            
            if gameSession.participants.isEmpty {
                Text("Add at least one participant to continue")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(.top, 4)
            }
            
            Text("Current Participants:")
                .font(AppDesignSystem.Typography.subheadingFont)
                .padding(.top)
            
            ForEach(gameSession.participants) { participant in
                HStack {
                    Text(participant.name)
                        .font(AppDesignSystem.Typography.bodyFont)
                    
                    Spacer()
                    
                    Button(action: {
                        if let index = gameSession.participants.firstIndex(where: { $0.id == participant.id }) {
                            gameSession.participants.remove(at: index)
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(AppDesignSystem.Colors.error)
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    private var playersSelectionView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            HStack {
                Text("Select Players")
                    .font(AppDesignSystem.Typography.headingFont)
                
                Spacer()
                
                NavigationLink(destination: ManualPlayerEntryView(gameSession: gameSession)) {
                    Label("Add Player", systemImage: "plus.circle")
                        .font(AppDesignSystem.Typography.bodyFont)
                }
            }
            
            Text("Choose players to include in the game. These will be randomly assigned to participants.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            if selectedPlayerIds.isEmpty {
                Text("Select at least one player to continue")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.error)
                    .padding(.top, 4)
            }
            
            // Grouped by team
            ForEach(Array(Set(gameSession.availablePlayers.map { $0.team })).sorted(by: { $0.name < $1.name }), id: \.id) { team in
                Section {
                    Text(team.name)
                        .font(AppDesignSystem.Typography.subheadingFont)
                        .padding(.top)
                    
                    // Players for this team
                    ForEach(gameSession.availablePlayers.filter { $0.team.id == team.id }) { player in
                        PlayerCard(
                            player: player,
                            isSelected: selectedPlayerIds.contains(player.id),
                            action: {
                                if selectedPlayerIds.contains(player.id) {
                                    selectedPlayerIds.remove(player.id)
                                } else {
                                    selectedPlayerIds.insert(player.id)
                                }
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var setBetsView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            HStack {
                Text("Set Betting Amounts")
                    .font(AppDesignSystem.Typography.headingFont)
                
                Spacer()
                
                Button(action: {
                    showingCustomBetSheet = true
                }) {
                    Label("Add Custom Bet", systemImage: "plus.circle")
                        .font(AppDesignSystem.Typography.bodyFont)
                }
            }
            
            // Currency Selection
            HStack {
                Text("Select Currency")
                    .font(AppDesignSystem.Typography.subheadingFont)
                
                Spacer()
                
                // Currency Picker
                Menu {
                    Button(action: {
                        UserDefaults.standard.set("USD", forKey: "selectedCurrency")
                        UserDefaults.standard.set("$", forKey: "currencySymbol")
                    }) {
                        Label("USD ($)", systemImage: UserDefaults.standard.string(forKey: "selectedCurrency") == "USD" ? "checkmark" : "")
                    }
                    
                    Button(action: {
                        UserDefaults.standard.set("EUR", forKey: "selectedCurrency")
                        UserDefaults.standard.set("€", forKey: "currencySymbol")
                    }) {
                        Label("EUR (€)", systemImage: UserDefaults.standard.string(forKey: "selectedCurrency") == "EUR" ? "checkmark" : "")
                    }
                    
                    Button(action: {
                        UserDefaults.standard.set("GBP", forKey: "selectedCurrency")
                        UserDefaults.standard.set("£", forKey: "currencySymbol")
                    }) {
                        Label("GBP (£)", systemImage: UserDefaults.standard.string(forKey: "selectedCurrency") == "GBP" ? "checkmark" : "")
                    }
                    
                    Button(action: {
                        UserDefaults.standard.set("NOK", forKey: "selectedCurrency")
                        UserDefaults.standard.set("kr", forKey: "currencySymbol")
                    }) {
                        Label("NOK (kr)", systemImage: UserDefaults.standard.string(forKey: "selectedCurrency") == "NOK" ? "checkmark" : "")
                    }
                    
                    Button(action: {
                        UserDefaults.standard.set("SEK", forKey: "selectedCurrency")
                        UserDefaults.standard.set("kr", forKey: "currencySymbol")
                    }) {
                        Label("SEK (kr)", systemImage: UserDefaults.standard.string(forKey: "selectedCurrency") == "SEK" ? "checkmark" : "")
                    }
                    
                    Button(action: {
                        UserDefaults.standard.set("DKK", forKey: "selectedCurrency")
                        UserDefaults.standard.set("kr", forKey: "currencySymbol")
                    }) {
                        Label("DKK (kr)", systemImage: UserDefaults.standard.string(forKey: "selectedCurrency") == "DKK" ? "checkmark" : "")
                    }
                } label: {
                    HStack {
                        Text(UserDefaults.standard.string(forKey: "selectedCurrency") ?? "EUR")
                            .font(AppDesignSystem.Typography.bodyFont)
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                    .padding(8)
                    .background(AppDesignSystem.Colors.primary.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(.bottom)
            
            Text("Set how much participants will pay for each event type.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("Toggle +/- to change who pays whom.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.primary)
                .padding(.bottom)
            
            ForEach(Bet.EventType.allCases, id: \.self) { eventType in
                BetSettingsRow(
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
        }
    }
    
    private var reviewView: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
            Text("Review Game Setup")
                .font(AppDesignSystem.Typography.headingFont)
            
            CardView {
                VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                    Text("Participants (\(gameSession.participants.count))")
                        .font(AppDesignSystem.Typography.subheadingFont)
                    
                    Text(gameSession.participants.map { $0.name }.joined(separator: ", "))
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            
            CardView {
                VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                    Text("Selected Players (\(gameSession.selectedPlayers.count))")
                        .font(AppDesignSystem.Typography.subheadingFont)
                    
                    let playersByTeam = Dictionary(grouping: gameSession.selectedPlayers) { $0.team.name }
                    
                    ForEach(playersByTeam.keys.sorted(), id: \.self) { teamName in
                        Text(teamName)
                            .font(AppDesignSystem.Typography.bodyFont.bold())
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                            .padding(.top, 4)
                        
                        if let players = playersByTeam[teamName] {
                            Text(players.map { $0.name }.joined(separator: ", "))
                                .font(AppDesignSystem.Typography.bodyFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                    }
                }
            }
            
            CardView {
                VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                    Text("Betting Amounts")
                        .font(AppDesignSystem.Typography.subheadingFont)
                    
                    ForEach(Bet.EventType.allCases, id: \.self) { eventType in
                        let amount = betAmounts[eventType] ?? 0.0
                        let isNegative = amount < 0
                        let formattedAmount = formatCurrency(abs(amount))
                        
                        HStack {
                            Text(eventType.rawValue)
                                .font(AppDesignSystem.Typography.bodyFont)
                            
                            Spacer()
                            
                            Text("\(isNegative ? "-" : "+")\(formattedAmount)")
                                .font(AppDesignSystem.Typography.bodyFont.bold())
                                .foregroundColor(isNegative ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                        }
                    }
                }
            }
            
            Text("Ready to start the game? Players will be randomly assigned to participants.")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .padding(.top)
        }
    }
    
    // Helper function for bet descriptions
    private func eventDescription(for eventType: Bet.EventType) -> String {
        switch eventType {
        case .goal:
            return "scores a goal"
        case .assist:
            return "makes an assist"
        case .yellowCard:
            return "receives a yellow card"
        case .redCard:
            return "receives a red card"
        case .ownGoal:
            return "scores own goal"
        case .penalty:
            return "scores a penalty"
        case .penaltyMissed:
            return "misses a penalty"
        case .cleanSheet:
            return "kept a clean sheet"
        case .custom:
            return "custom event"
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}

struct NewGameSetupView_Previews: PreviewProvider {
    static var previews: some View {
        NewGameSetupView(gameSession: GameSession())
    }
}
