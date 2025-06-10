//
//  GameSession.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 08/05/2025.
//

//
//  GameSession.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 08/05/2025.
//

import Foundation

// Game session model
class GameSession: ObservableObject, Codable {
    var id = UUID()
    @Published var participants: [Participant] = []
    @Published var bets: [Bet] = []
    @Published var events: [GameEvent] = []
    @Published var availablePlayers: [Player] = []
    @Published var selectedPlayers: [Player] = []
    @Published var substitutions: [Substitution] = []
    @Published var customBetNames: [UUID: String] = [:]
    @Published var availableMatches: [Match] = []
    @Published var selectedMatch: Match? = nil
    @Published var isLiveMode: Bool = false
    @Published var matchLineups: [String: Lineup] = [:]
    @Published var matchEvents: [MatchEvent] = []
    @Published var canUndoLastEvent: Bool = false
    private var dataService: GameDataService
    private var matchMonitoringTask: Task<Void, Never>?
    private var matchService: MatchService?
    private var lastEventBackup: (event: GameEvent, participantBalances: [UUID: Double])? = nil
    
    // Default initializer
    init() {
        self.dataService = ServiceProvider.shared.getGameDataService()
        
        // Initialize match service if in live mode
        if UserDefaults.standard.bool(forKey: "isLiveMode") {
            self.isLiveMode = true
            self.matchService = ServiceProvider.shared.getMatchService()
        }
        
        // Set up the observer for app mode changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleModeChange),
            name: Notification.Name("AppModeChanged"),
            object: nil
        )
    }
    
    enum CodingKeys: CodingKey {
        case id, participants, bets, events, availablePlayers, selectedPlayers, substitutions, customBetNames
        case selectedMatchId, isLiveMode
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(participants, forKey: .participants)
        try container.encode(bets, forKey: .bets)
        try container.encode(events, forKey: .events)
        try container.encode(availablePlayers, forKey: .availablePlayers)
        try container.encode(selectedPlayers, forKey: .selectedPlayers)
        try container.encode(substitutions, forKey: .substitutions)
        try container.encode(isLiveMode, forKey: .isLiveMode)
        
        // Fix the dictionary encoding
        let customBetNamesArray = customBetNames.map { (key, value) in
            ["id": key.uuidString, "name": value]
        }
        try container.encode(customBetNamesArray, forKey: .customBetNames)
        
        // Store selected match ID if available
        if let selectedMatch = selectedMatch {
            try container.encode(selectedMatch.id, forKey: .selectedMatchId)
        }
    }

    required init(from decoder: Decoder) throws {
        // Initialize non-codable properties first
        self.dataService = ServiceProvider.shared.getGameDataService()
        
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        participants = try container.decode([Participant].self, forKey: .participants)
        bets = try container.decode([Bet].self, forKey: .bets)
        events = try container.decode([GameEvent].self, forKey: .events)
        availablePlayers = try container.decode([Player].self, forKey: .availablePlayers)
        selectedPlayers = try container.decode([Player].self, forKey: .selectedPlayers)
        substitutions = try container.decode([Substitution].self, forKey: .substitutions)
        isLiveMode = try container.decodeIfPresent(Bool.self, forKey: .isLiveMode) ?? false
        
        // Decode custom bet names
        let customBetNamesArray = try container.decode([[String: String]].self, forKey: .customBetNames)
        var decodedCustomBetNames: [UUID: String] = [:]
        
        for item in customBetNamesArray {
            if let idString = item["id"], let uuid = UUID(uuidString: idString),
               let name = item["name"] {
                decodedCustomBetNames[uuid] = name
            }
        }
        customBetNames = decodedCustomBetNames
        
        // Initialize other properties that aren't codable
        availableMatches = []
        selectedMatch = nil
        matchLineups = [:]
        matchEvents = []
        matchMonitoringTask = nil
        matchService = nil
        
        // Initialize match service if in live mode
        if isLiveMode {
            self.matchService = ServiceProvider.shared.getMatchService()
        }
        
        #if DEBUG
        // Connect to test monitoring bridge if in test mode
        if TestConfiguration.shared.isTestMode {
            TestMonitoringBridge.shared.connectToGameSession(self)
        }
        #endif
        
        // Set up the observer
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleModeChange),
            name: Notification.Name("AppModeChanged"),
            object: nil
        )
    }
    
    @objc private func handleModeChange() {
        self.dataService = ServiceProvider.shared.getGameDataService()
        
        // Update isLiveMode from UserDefaults
        let newLiveMode = UserDefaults.standard.bool(forKey: "isLiveMode")
        if newLiveMode != self.isLiveMode {
            self.isLiveMode = newLiveMode
            
            // Initialize or clear match service based on mode
            if newLiveMode {
                self.matchService = ServiceProvider.shared.getMatchService()
            } else {
                self.matchService = nil
            }
            
            print("🔄 GameSession mode updated: Live Mode = \(newLiveMode)")
        }
        
        #if DEBUG
        // Update test bridge connection
        if TestConfiguration.shared.isTestMode {
            TestMonitoringBridge.shared.connectToGameSession(self)
        } else {
            TestMonitoringBridge.shared.disconnect()
        }
        #endif
    }
    

    func fetchAvailableMatches() async throws {
        try await fetchAvailableMatchesRobust()
    }

    
    func fetchMatchLineup(for matchId: String) async throws {
        guard isLiveMode, let matchService = matchService else {
            print("❌ Cannot fetch lineup: Live mode disabled or no match service")
            return
        }
        
        print("📋 Fetching lineup for match \(matchId)")
        print("🔧 Using service type: \(type(of: matchService))")
        
        do {
            let lineup: Lineup
            
            if let footballService = matchService as? FootballDataMatchService {
                print("🌐 Using FootballDataMatchService to fetch lineup")
                lineup = try await footballService.fetchMatchLineup(matchId: matchId)
            } else if let mockService = matchService as? MockFootballDataService {
                print("🧪 Using MockFootballDataService to fetch lineup")
                lineup = try await mockService.fetchMatchLineup(matchId: matchId)
            } else {
                print("🔄 Using generic MatchService to fetch lineup")
                lineup = try await matchService.fetchMatchLineup(matchId: matchId)
            }
            
            await MainActor.run {
                self.matchLineups[matchId] = lineup
                
                // Extract players from lineup
                var allPlayers: [Player] = []
                allPlayers.append(contentsOf: lineup.homeTeam.startingXI)
                allPlayers.append(contentsOf: lineup.homeTeam.substitutes)
                allPlayers.append(contentsOf: lineup.awayTeam.startingXI)
                allPlayers.append(contentsOf: lineup.awayTeam.substitutes)
                
                self.availablePlayers = allPlayers
                self.selectedPlayers = allPlayers
                
                print("✅ Lineup processed: \(allPlayers.count) players available")
                print("  - Home XI: \(lineup.homeTeam.startingXI.count)")
                print("  - Home Subs: \(lineup.homeTeam.substitutes.count)")
                print("  - Away XI: \(lineup.awayTeam.startingXI.count)")
                print("  - Away Subs: \(lineup.awayTeam.substitutes.count)")
                
                self.objectWillChange.send()
            }
            
        } catch {
            print("❌ Error fetching lineup: \(error)")
            throw error
        }
    }
    
    func startMonitoringMatch(_ match: Match) {
        guard isLiveMode, let matchService = matchService else { return }
        
        // Cancel existing monitoring
        matchMonitoringTask?.cancel()
        
        print("🎯 Starting match monitoring for: \(match.homeTeam.name) vs \(match.awayTeam.name)")
        print("🔧 Using service type: \(type(of: matchService))")
        
        // Start monitoring based on service type
        if let footballService = matchService as? FootballDataMatchService {
            print("🌐 Using FootballDataMatchService enhanced monitoring")
            matchMonitoringTask = footballService.enhancedMatchMonitoring(
                matchId: match.id,
                updateInterval: 30,
                onUpdate: { [weak self] update in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        self.processEnhancedMatchUpdate(update)
                    }
                }
            )
        } else if let mockService = matchService as? MockFootballDataService {
            print("🧪 Using MockFootballDataService monitoring")
            matchMonitoringTask = mockService.startMonitoringMatch(
                matchId: match.id,
                updateInterval: 30,
                onUpdate: { [weak self] update in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        self.processEnhancedMatchUpdate(update)
                    }
                }
            )
        } else {
            print("🔄 Using generic MatchService monitoring")
            // Fallback to regular monitoring
            matchMonitoringTask = matchService.startMonitoringMatch(
                matchId: match.id,
                updateInterval: 60,
                onUpdate: { [weak self] update in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        self.processMatchUpdate(update)
                    }
                }
            )
        }
    }
    
    func selectMatch(_ match: Match) async {
        await selectMatchRobust(match)
    }
    
    func fetchMatchPlayers(for matchId: String) async throws -> [Player]? {
        return try await fetchMatchPlayersRobust(for: matchId)
    }
    
    func saveGame(name: String) {
        print("🎮 Starting to save game: \(name)")
        
        // Use the SavedGameSession method from HistoryView
        let savedGame = SavedGameSession(from: self, name: name)
        var savedGames = GameHistoryManager.shared.getSavedGameSessions() // Changed method name
        savedGames.append(savedGame)
        
        // Save to UserDefaults using the working method
        if let encoded = try? JSONEncoder().encode(savedGames) {
            UserDefaults.standard.set(encoded, forKey: "savedGameSessions") // Use different key to avoid conflicts
            print("✅ Game saved successfully: \(name)")
            
            // Update the published property
            GameHistoryManager.shared.objectWillChange.send()
        } else {
            print("❌ Failed to encode and save game")
        }
    }


    func debugSaveStatus() {
        print("🔍 Debug - Game Session Status:")
        print("  - Participants: \(participants.count)")
        print("  - Events: \(events.count)")
        print("  - Bets: \(bets.count)")
        print("  - Selected Players: \(selectedPlayers.count)")
        
        for (index, participant) in participants.enumerated() {
            print("  - Participant \(index): \(participant.name) - Balance: \(participant.balance)")
        }
    }

    
    // Add players to the available pool
    func addPlayers(_ players: [Player]) {
        availablePlayers.append(contentsOf: players)
        
        let isLiveMode = UserDefaults.standard.bool(forKey: "isLiveMode")
        if isLiveMode {
            // To be implemented
        }
    }
    
    // Add a participant
    func addParticipant(_ name: String) {
        let participant = Participant(name: name)
        participants.append(participant)
    }
    
    // Add a bet
    func addBet(eventType: Bet.EventType, amount: Double) {
        let bet = Bet(eventType: eventType, amount: amount)
        bets.append(bet)
    }
    
    // Record an event
    @MainActor func recordEvent(player: Player, eventType: Bet.EventType) {
        let event = GameEvent(player: player, eventType: eventType, timestamp: Date())
        events.append(event)
        
        // Helper function to update player stats based on event type
        func updatePlayerStats(_ playerToUpdate: inout Player) {
            switch eventType {
            case .goal:
                playerToUpdate.goals += 1
                print("Updated \(playerToUpdate.name)'s goals to \(playerToUpdate.goals)")
            case .assist:
                playerToUpdate.assists += 1
                print("Updated \(playerToUpdate.name)'s assists to \(playerToUpdate.assists)")
            case .yellowCard:
                playerToUpdate.yellowCards += 1
                print("Updated \(playerToUpdate.name)'s yellow cards to \(playerToUpdate.yellowCards)")
            case .redCard:
                playerToUpdate.redCards += 1
                print("Updated \(playerToUpdate.name)'s red cards to \(playerToUpdate.redCards)")
            case .ownGoal, .penalty, .penaltyMissed, .cleanSheet, .custom:
                // These events don't update player stats
                break
            }
        }
        
        // Find and update the player in all locations
        if let index = availablePlayers.firstIndex(where: { $0.id == player.id }) {
            var updatedPlayer = availablePlayers[index]
            updatePlayerStats(&updatedPlayer)
            availablePlayers[index] = updatedPlayer
            
            // Store the updated player reference
            let playerWithUpdatedStats = updatedPlayer
            
            // Update in selectedPlayers
            if let selectedIndex = selectedPlayers.firstIndex(where: { $0.id == player.id }) {
                selectedPlayers[selectedIndex] = playerWithUpdatedStats
            }
            
            // IMPORTANT: Update the player in BOTH active and substituted lists for all participants
            for i in 0..<participants.count {
                // Check active players
                if let activeIndex = participants[i].selectedPlayers.firstIndex(where: { $0.id == player.id }) {
                    participants[i].selectedPlayers[activeIndex] = playerWithUpdatedStats
                    print("Updated \(player.name)'s stats for active player in \(participants[i].name)'s roster")
                }
                
                // Check substituted players - critical for tracking stats correctly
                if let subIndex = participants[i].substitutedPlayers.firstIndex(where: { $0.id == player.id }) {
                    participants[i].substitutedPlayers[subIndex] = playerWithUpdatedStats
                    print("Updated \(player.name)'s stats for substituted player in \(participants[i].name)'s roster")
                }
            }
        }
        
        Task {
            do {
                try await dataService.recordEvent(playerId: player.id, eventType: eventType)
            } catch {
                print("Error recording event via service: \(error)")
            }
        }
        
        // Calculate payments
        calculatePayments(for: event)
        
        // Debug: print event recorded
        print("Event recorded: \(eventType.rawValue) for \(player.name)")
        
        canUndoLastEvent = true
        
        // NEW: Check if we should show interstitial ad after every 3rd event
        checkAndShowInterstitialAfterEvent()
        
        // Notify observers of the changes
        objectWillChange.send()
    }
    
    @MainActor func undoLastEvent() {
        guard !events.isEmpty else { return }
        
        let lastEvent = events.removeLast()
        
        // Reverse the balance changes
        reversePayments(for: lastEvent)
        
        // Reverse player stats
        reversePlayerStats(for: lastEvent)
        
        // Update the UI
        objectWillChange.send()
        canUndoLastEvent = !events.isEmpty
        
        print("🔄 Undid event: \(lastEvent.eventType.rawValue) for \(lastEvent.player.name)")
    }
    
    private func reversePayments(for event: GameEvent) {
        // Find the bet for this event type
        guard let bet = bets.first(where: { $0.eventType == event.eventType }) else { return }
        
        // Find participants who have the player (include both active and substituted players)
        let participantsWithPlayer = participants.filter { participant in
            participant.selectedPlayers.contains { $0.id == event.player.id } ||
            participant.substitutedPlayers.contains { $0.id == event.player.id }
        }
        
        // Find participants who don't have the player
        let participantsWithoutPlayer = participants.filter { participant in
            !participant.selectedPlayers.contains { $0.id == event.player.id } &&
            !participant.substitutedPlayers.contains { $0.id == event.player.id }
        }
        
        if participantsWithPlayer.isEmpty || participantsWithoutPlayer.isEmpty {
            return
        }
        
        // Reverse the payment logic (opposite of calculatePayments)
        if bet.amount >= 0 {
            // Reverse: participants WITHOUT player paid those WITH player
            let totalAmount = Double(participantsWithoutPlayer.count) * bet.amount
            let amountPerWinner = totalAmount / Double(participantsWithPlayer.count)
            
            for i in 0..<participants.count {
                let hasPlayer = participants[i].selectedPlayers.contains { $0.id == event.player.id } ||
                participants[i].substitutedPlayers.contains { $0.id == event.player.id }
                
                if hasPlayer {
                    participants[i].balance -= amountPerWinner // Reverse: subtract instead of add
                } else {
                    participants[i].balance += bet.amount // Reverse: add instead of subtract
                }
            }
        } else {
            // Reverse: participants WITH player paid those WITHOUT player
            let payAmount = abs(bet.amount)
            
            for i in 0..<participants.count {
                let hasPlayer = participants[i].selectedPlayers.contains { $0.id == event.player.id } ||
                participants[i].substitutedPlayers.contains { $0.id == event.player.id }
                
                if hasPlayer {
                    participants[i].balance += payAmount * Double(participantsWithoutPlayer.count) // Reverse
                } else {
                    participants[i].balance -= payAmount * Double(participantsWithPlayer.count) // Reverse
                }
            }
        }
    }

    private func reversePlayerStats(for event: GameEvent) {
        // Helper function to reverse player stats
        func reversePlayerStats(_ playerToUpdate: inout Player) {
            switch event.eventType {
            case .goal:
                playerToUpdate.goals = max(0, playerToUpdate.goals - 1)
            case .assist:
                playerToUpdate.assists = max(0, playerToUpdate.assists - 1)
            case .yellowCard:
                playerToUpdate.yellowCards = max(0, playerToUpdate.yellowCards - 1)
            case .redCard:
                playerToUpdate.redCards = max(0, playerToUpdate.redCards - 1)
            case .ownGoal, .penalty, .penaltyMissed, .cleanSheet, .custom:
                // These events don't update player stats
                break
            }
        }
        
        // Find and update the player in all locations (same as recordEvent but reverse)
        if let index = availablePlayers.firstIndex(where: { $0.id == event.player.id }) {
            var updatedPlayer = availablePlayers[index]
            reversePlayerStats(&updatedPlayer)
            availablePlayers[index] = updatedPlayer
            
            // Update in selectedPlayers
            if let selectedIndex = selectedPlayers.firstIndex(where: { $0.id == event.player.id }) {
                selectedPlayers[selectedIndex] = updatedPlayer
            }
            
            // Update in participants
            for i in 0..<participants.count {
                // Check active players
                if let activeIndex = participants[i].selectedPlayers.firstIndex(where: { $0.id == event.player.id }) {
                    participants[i].selectedPlayers[activeIndex] = updatedPlayer
                }
                
                // Check substituted players
                if let subIndex = participants[i].substitutedPlayers.firstIndex(where: { $0.id == event.player.id }) {
                    participants[i].substitutedPlayers[subIndex] = updatedPlayer
                }
            }
        }
    }
    
    @MainActor
    private func checkAndShowInterstitialAfterEvent() {
        guard AppPurchaseManager.shared.currentTier == .free else { return }
        
        let currentEventCount = events.count
        print("📊 Total events recorded: \(currentEventCount)")
        
        if currentEventCount > 0 && currentEventCount % 3 == 0 {
            print("🎯 Showing interstitial ad after \(currentEventCount) events")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                NotificationCenter.default.post(
                    name: Notification.Name("ShowInterstitialAfterEvent"),
                    object: ["eventCount": currentEventCount]
                )
            }
        }
    }
    
    func loadFromService() async {
        do {
            let players = try await dataService.fetchPlayers()
            
            await MainActor.run {
                self.availablePlayers = players
                self.objectWillChange.send()
            }
        } catch {
            print("Error loading from service: \(error)")
        }
    }
    
    private func processEnhancedMatchUpdate(_ update: MatchUpdate) {
        self.selectedMatch = update.match
        
        for event in update.newEvents {
            processLiveEvent(event)
        }
        
        self.matchEvents = update.newEvents
        
        self.objectWillChange.send()
    }
    
    private func processMatchUpdate(_ update: MatchUpdate) {
        DispatchQueue.main.async {
            // Update match info
            self.selectedMatch = update.match
            
            // Process new events
            for event in update.newEvents {
                self.processLiveEvent(event)
            }
            
            self.objectWillChange.send()
        }
    }
    
    private func processLiveEvent(_ event: MatchEvent) {
        // Map API event to app event type
        guard let eventType = mapToEventType(event.type),
              let player = availablePlayers.first(where: { $0.id.uuidString == event.playerId }) else {
            return
        }
        
        // For substitutions
        if event.type == "substitution" {
            guard let playerOff = availablePlayers.first(where: { $0.id.uuidString == event.playerOffId }),
                  let playerOn = availablePlayers.first(where: { $0.id.uuidString == event.playerOnId }) else {
                return
            }
            
            substitutePlayer(playerOff: playerOff, playerOn: playerOn)
        } else {
            // For other events - ensure we're on MainActor
            Task { @MainActor in
                recordEvent(player: player, eventType: eventType)
            }
        }
    }
    
    private func mapToEventType(_ apiEventType: String) -> Bet.EventType? {
        switch apiEventType.lowercased() {
        case "goal": return .goal
        case "assist": return .assist
        case "yellow_card": return .yellowCard
        case "red_card": return .redCard
        case "penalty": return .penalty
        case "penalty_missed": return .penaltyMissed
        case "own_goal": return .ownGoal
        default: return nil
        }
    }

    
    // Calculate payments when an event occurs
    private func calculatePayments(for event: GameEvent) {
        // Find the bet for this event type
        guard let bet = bets.first(where: { $0.eventType == event.eventType }) else { return }
        
        // Find participants who have the player (include both active and substituted players)
        let participantsWithPlayer = participants.filter { participant in
            participant.selectedPlayers.contains { $0.id == event.player.id } ||
            participant.substitutedPlayers.contains { $0.id == event.player.id }
        }
        
        // Find participants who don't have the player
        let participantsWithoutPlayer = participants.filter { participant in
            !participant.selectedPlayers.contains { $0.id == event.player.id } &&
            !participant.substitutedPlayers.contains { $0.id == event.player.id }
        }
        
        if participantsWithPlayer.isEmpty || participantsWithoutPlayer.isEmpty {
            return
        }
        
        // Determine payment direction based on bet amount sign
        if bet.amount >= 0 {
            // Positive bet: participants WITHOUT player pay those WITH player
            let totalAmount = Double(participantsWithoutPlayer.count) * bet.amount
            let amountPerWinner = totalAmount / Double(participantsWithPlayer.count)
            
            for i in 0..<participants.count {
                let hasPlayer = participants[i].selectedPlayers.contains { $0.id == event.player.id } ||
                participants[i].substitutedPlayers.contains { $0.id == event.player.id }
                
                if hasPlayer {
                    participants[i].balance += amountPerWinner
                } else {
                    participants[i].balance -= bet.amount
                }
            }
        } else {
            // Negative bet: participants WITH player pay those WITHOUT player
            let payAmount = abs(bet.amount)
            
            for i in 0..<participants.count {
                let hasPlayer = participants[i].selectedPlayers.contains { $0.id == event.player.id } ||
                participants[i].substitutedPlayers.contains { $0.id == event.player.id }
                
                if hasPlayer {
                    participants[i].balance -= payAmount * Double(participantsWithoutPlayer.count)
                } else {
                    participants[i].balance += payAmount * Double(participantsWithPlayer.count)
                }
            }
        }
    }
    
    func addCustomBet(name: String, amount: Double) {
        customBetNames[UUID()] = name
        
        let bet = Bet(eventType: .custom, amount: amount)
        bets.append(bet)
    }
    
    func getBetDisplayName(for bet: Bet) -> String {
        if bet.eventType == .custom {
            return customBetNames.values.first ?? "Custom Event"
        }
        return bet.eventType.rawValue
    }
    
    func reset() {
        participants = []
        bets = []
        events = []
        selectedPlayers = []
    }
    
    // Randomly assign players to participants
    func assignPlayersRandomly() {
        print("assignPlayersRandomly called")
        print("Participants: \(participants.count)")
        print("Selected players: \(selectedPlayers.count)")
        
        guard !participants.isEmpty, !selectedPlayers.isEmpty else {
            print("ERROR: Cannot assign players - no participants or no selected players")
            return
        }
        
        print("Starting player assignment...")
        print("Participants count: \(participants.count)")
        print("Selected players count: \(selectedPlayers.count)")
        
        // First clear any existing arguments
        for i in 0..<participants.count {
            participants[i].selectedPlayers = []
        }
        
        // Make a copy of the selected players
        var playersToAssign = selectedPlayers
        // Shuffle the players
        playersToAssign.shuffle()
        
        // Calculate how many players each participant should get
        let playersPerParticipant = playersToAssign.count / participants.count
        let remainingPlayers = playersToAssign.count % participants.count
        
        print("Players per participant: \(playersPerParticipant)")
        print("Remaining players: \(remainingPlayers)")
        
        // Debugging before assignment
        print("Before assignment:")
        for (i, participant) in participants.enumerated() {
            print("Participant \(i): \(participant.name) - Players: \(participant.selectedPlayers.count)")
        }
        
        var playerIndex = 0
        
        // Assign players to participants
        for i in 0..<participants.count {
            let numberOfPlayers = i < remainingPlayers ? playersPerParticipant + 1 : playersPerParticipant
            
            for _ in 0..<numberOfPlayers {
                if playerIndex < playersToAssign.count {
                    participants[i].selectedPlayers.append(playersToAssign[playerIndex])
                    playerIndex += 1
                }
            }
        }
        
        // Update participants
        self.objectWillChange.send()
        
        // Debug: print the assignments
        print("Player assignments:")
        for participant in participants {
            print("\(participant.name): \(participant.selectedPlayers.count) players - \(participant.selectedPlayers.map { $0.name }.joined(separator: ", "))")
        }
    }
    
    func substitutePlayer(playerOff: Player, playerOn: Player) {
        let timestamp = Date()
        
        // Create a substitution record
        let substitution = Substitution(
            from: playerOff,
            to: playerOn,
            timestamp: timestamp,
            team: playerOff.team
        )
        
        substitutions.append(substitution)
        
        // Find which participant has the player being substituted out
        for i in 0..<participants.count {
            if let index = participants[i].selectedPlayers.firstIndex(where: { $0.id == playerOff.id }) {
                // Update status of player going off
                var updatedPlayerOff = playerOff
                updatedPlayerOff.substitutionStatus = .substitutedOff(timestamp: timestamp)
                
                // Update the playerOff in all collections
                if let availableIndex = availablePlayers.firstIndex(where: { $0.id == playerOff.id }) {
                    availablePlayers[availableIndex] = updatedPlayerOff
                }
                
                // Update status of player coming on
                var updatedPlayerOn = playerOn
                updatedPlayerOn.substitutionStatus = .substitutedOn(timestamp: timestamp)
                
                // Remove the player going off from active players
                participants[i].selectedPlayers.remove(at: index)
                
                // Keep the player who was substituted out in the history array
                participants[i].substitutedPlayers.append(updatedPlayerOff)
                
                // Add the new player coming on
                participants[i].selectedPlayers.append(updatedPlayerOn)
                
                // Add the new player to the available players if not already there
                if !availablePlayers.contains(where: { $0.id == playerOn.id }) {
                    availablePlayers.append(updatedPlayerOn)
                }
                
                print("Substitution: \(playerOff.name) ➝ \(playerOn.name) for participant \(participants[i].name)")
                break
            }
        }
        
        // Force UI update
        objectWillChange.send()
    }
    
    // Debug method to check current state
    func debugCurrentState() {
        print("🔍 GameSession Debug State:")
        print("  - Available Players: \(availablePlayers.count)")
        print("  - Selected Players: \(selectedPlayers.count)")
        print("  - Participants: \(participants.count)")
        print("  - Bets: \(bets.count)")
        
        if availablePlayers.isEmpty {
            print("⚠️ No available players! This is likely the issue.")
            print("💡 Try calling: gameSession.addPlayers(SampleData.corePlayers)")
        } else {
            print("✅ Players are loaded:")
            for (index, player) in availablePlayers.prefix(5).enumerated() {
                print("     \(index + 1). \(player.name) (\(player.team.shortName))")
            }
            if availablePlayers.count > 5 {
                print("     ... and \(availablePlayers.count - 5) more")
            }
        }
    }
    
    // Force reload sample data
    func forceLoadSampleData() {
        print("🔄 Force loading sample data...")
        availablePlayers = []
        addPlayers(SampleData.corePlayers)
        print("✅ Loaded \(availablePlayers.count) players")
        objectWillChange.send()
    }
    
    // Verify data integrity
    func verifyDataIntegrity() -> Bool {
        print("🔍 Verifying data integrity...")
        
        // Check if we have players
        guard !availablePlayers.isEmpty else {
            print("❌ No available players")
            return false
        }
        
        // Check if all players have valid teams
        let playersWithoutTeams = availablePlayers.filter { $0.team.name.isEmpty }
        if !playersWithoutTeams.isEmpty {
            print("❌ Found \(playersWithoutTeams.count) players without teams")
            return false
        }
        
        // Check if we have multiple teams
        let uniqueTeams = Set(availablePlayers.map { $0.team.id })
        if uniqueTeams.count < 2 {
            print("❌ Need at least 2 teams, found \(uniqueTeams.count)")
            return false
        }
        
        print("✅ Data integrity check passed")
        print("   - \(availablePlayers.count) players")
        print("   - \(uniqueTeams.count) teams")
        return true
    }
    
    func fetchAvailableMatchesRobust() async throws {
        guard isLiveMode else {
            throw NSError(domain: "GameSession", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Live mode is not enabled"
            ])
        }
        
        guard let matchService = matchService else {
            throw NSError(domain: "GameSession", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Match service not available"
            ])
        }
        
        print("🚀 Starting robust match fetch...")
        print("🔧 Using service type: \(type(of: matchService))")
        
        do {
            var matches: [Match] = []
            
            // Handle both real and mock services
            if let footballService = matchService as? FootballDataMatchService {
                print("🌐 Using real FootballDataMatchService")
                matches = try await footballService.fetchLiveMatchesWithFallback(competitionCode: nil)
            } else if let mockService = matchService as? MockFootballDataService {
                print("🧪 Using MockFootballDataService")
                matches = try await mockService.fetchLiveMatchesWithFallback(competitionCode: nil)
            } else {
                print("🔄 Using generic MatchService interface")
                // Try live matches first, then fallback to upcoming
                matches = try await matchService.fetchLiveMatches(competitionCode: nil)
                
                if matches.isEmpty {
                    print("⚪ No live matches, trying upcoming...")
                    matches = try await matchService.fetchUpcomingMatches(competitionCode: nil)
                }
                
                if matches.isEmpty {
                    print("⚪ No upcoming matches, trying date range...")
                    if let footballService = matchService as? FootballDataMatchService {
                        matches = try await footballService.fetchMatchesInDateRange(days: 7)
                    } else if let mockService = matchService as? MockFootballDataService {
                        matches = try await mockService.fetchMatchesInDateRange(days: 7)
                    }
                }
            }
            
            await MainActor.run {
                self.availableMatches = matches
                print("✅ Successfully loaded \(matches.count) matches")
                for match in matches {
                    print("  - \(match.homeTeam.name) vs \(match.awayTeam.name) (\(match.status))")
                }
                self.objectWillChange.send()
            }
            
        } catch let error as APIError {
            let userFriendlyMessage = getUserFriendlyErrorMessage(for: error)
            await MainActor.run {
                print("❌ Failed to fetch matches: \(userFriendlyMessage)")
            }
            throw NSError(domain: "GameSession", code: 3, userInfo: [
                NSLocalizedDescriptionKey: userFriendlyMessage
            ])
            
        } catch {
            await MainActor.run {
                print("❌ Unexpected error fetching matches: \(error)")
            }
            throw error
        }
    }
    
    func fetchMatchPlayersRobust(for matchId: String) async throws -> [Player]? {
        guard let matchService = matchService else {
            throw NSError(domain: "GameSession", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Match service not available"
            ])
        }
        
        do {
            print("🔧 Fetching players using service type: \(type(of: matchService))")
            
            if let footballService = matchService as? FootballDataMatchService {
                return try await footballService.fetchMatchPlayersWithCache(matchId: matchId)
            } else if let mockService = matchService as? MockFootballDataService {
                return try await mockService.fetchMatchPlayersWithCache(matchId: matchId)
            } else {
                // Fallback to generic interface
                return try await matchService.fetchMatchPlayers(matchId: matchId)
            }
        } catch {
            print("❌ Error fetching players for match \(matchId): \(error)")
            throw error
        }
    }
    
    func selectMatchRobust(_ match: Match) async {
        guard isLiveMode, let matchService = matchService else { return }
        
        // Cancel any existing monitoring
        matchMonitoringTask?.cancel()
        
        do {
            print("🏟️ Selected match: \(match.homeTeam.name) vs \(match.awayTeam.name)")
            
            // Set the selected match first
            await MainActor.run {
                self.selectedMatch = match
                self.objectWillChange.send()
            }
            
            // Try to fetch lineup with caching
            do {
                print("📋 Attempting to fetch lineup for match \(match.id)")
                try await fetchMatchLineup(for: match.id)
                print("✅ Lineup fetched successfully")
            } catch {
                print("⚠️ Lineup fetch failed, falling back to basic players: \(error)")
                // If lineup fails, try to get basic players with caching
                let players = try await fetchMatchPlayersRobust(for: match.id) ?? []
                print("👥 Retrieved \(players.count) players for this match")
                
                await MainActor.run {
                    self.availablePlayers = players
                    self.selectedPlayers = players
                    print("🔄 Updated game session state with players")
                    self.objectWillChange.send()
                }
            }
            
            // Start smart monitoring
            print("🎯 Starting smart match monitoring for match ID: \(match.id)")
            startSmartMonitoring(match)
            
        } catch {
            print("❌ Error selecting match: \(error)")
            
            await MainActor.run {
                self.selectedMatch = match
                
                if self.availablePlayers.isEmpty {
                    print("🔄 Using sample players as fallback")
                    self.availablePlayers = SampleData.samplePlayers
                    self.selectedPlayers = SampleData.samplePlayers
                }
                
                self.objectWillChange.send()
            }
        }
    }
    
    private func startSmartMonitoring(_ match: Match) {
        guard let matchService = matchService else { return }
        
        print("🎯 Starting smart match monitoring for match ID: \(match.id)")
        print("🔧 Using service type: \(type(of: matchService))")
        
        if let footballService = matchService as? FootballDataMatchService {
            matchMonitoringTask = footballService.smartMatchMonitoring(
                matchId: match.id,
                onUpdate: { [weak self] update in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        self.processEnhancedMatchUpdate(update)
                    }
                }
            )
        } else if let mockService = matchService as? MockFootballDataService {
            matchMonitoringTask = mockService.smartMatchMonitoring(
                matchId: match.id,
                onUpdate: { [weak self] update in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        self.processEnhancedMatchUpdate(update)
                    }
                }
            )
        } else {
            // Fallback to basic monitoring
            matchMonitoringTask = matchService.startMonitoringMatch(
                matchId: match.id,
                updateInterval: 30,
                onUpdate: { [weak self] update in
                    guard let self = self else { return }
                    
                    Task { @MainActor in
                        self.processMatchUpdate(update)
                    }
                }
            )
        }
    }
    
    private func getUserFriendlyErrorMessage(for error: APIError) -> String {
        switch error {
        case .rateLimited:
            return "Too many requests. Please wait a moment and try again."
            
        case .networkError:
            return "Please check your internet connection and try again."
            
        case .serverError(let code, _):
            if code >= 500 {
                return "The football data service is temporarily unavailable. Please try again later."
            } else {
                return "There was a problem with your request. Please try again."
            }
            
        case .decodingError:
            return "There was a problem processing the match data. Please try again."
            
        case .invalidURL:
            return "There was a configuration error. Please restart the app."
            
        case .unknown:
            return "An unexpected error occurred. Please try again."
        }
    }
}


