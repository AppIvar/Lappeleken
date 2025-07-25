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
    @Published var customEventMappings: [UUID: String] = [:]
    @Published var processedEventIds: Set<String> = []

    private var dataService: GameDataService
    private var matchMonitoringTask: Task<Void, Error>?
    internal var matchService: MatchService?
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
        case id, participants, bets, events, availablePlayers, selectedPlayers, substitutions, customBetNames, customEventMappings
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
        
        // Encode custom event mappings
        let customMappingsArray = customEventMappings.map { (key, value) in
            ["id": key.uuidString, "name": value]
        }
        try container.encode(customMappingsArray, forKey: .customEventMappings)
        
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
        
        // Decode custom event mappings
        if let customMappingsArray = try container.decodeIfPresent([[String: String]].self, forKey: .customEventMappings) {
            customEventMappings = Dictionary(uniqueKeysWithValues:
                customMappingsArray.compactMap { dict in
                    guard let idString = dict["id"],
                          let name = dict["name"],
                          let uuid = UUID(uuidString: idString) else { return nil }
                    return (uuid, name)
                }
            )
        } else {
            customEventMappings = [:]
        }
        
        // Handle legacy custom bet names if needed
        if let customBetNamesArray = try container.decodeIfPresent([[String: String]].self, forKey: .customBetNames) {
            customBetNames = Dictionary(uniqueKeysWithValues:
                customBetNamesArray.compactMap { dict in
                    guard let idString = dict["id"],
                          let name = dict["name"],
                          let uuid = UUID(uuidString: idString) else { return nil }
                    return (uuid, name)
                }
            )
        } else {
            customBetNames = [:]
        }
        
        // Load match service if in live mode
        if isLiveMode {
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
        
        do {
            let lineup: Lineup
            if let footballService = matchService as? FootballDataMatchService {
                lineup = try await footballService.fetchMatchLineup(matchId: matchId)
            } else {
                lineup = try await matchService.fetchMatchLineup(matchId: matchId)
            }
            
            await MainActor.run {
                self.matchLineups[matchId] = lineup
                
                // Extract players from lineup and add to availablePlayers
                let lineupPlayers = extractPlayersFromLineup(lineup)
                
                // Replace or add players
                let existingPlayerIds = Set(availablePlayers.map { $0.id })
                let newPlayers = lineupPlayers.filter { !existingPlayerIds.contains($0.id) }
                
                availablePlayers.append(contentsOf: newPlayers)
                
                print("✅ Lineup fetched: \(lineupPlayers.count) players added to session")
                objectWillChange.send()
            }
        } catch {
            print("❌ Failed to fetch lineup for match \(matchId): \(error)")
            
            // Check if it's the specific LineupError.notAvailableYet by checking the error description
            if error.localizedDescription.contains("Lineup data not available yet") {
                // Re-throw the specific error
                throw LineupError.notAvailableYet
            }
            
            // For other errors, throw as-is
            throw error
        }
    }
    
    private func extractPlayersFromLineup(_ lineup: Lineup) -> [Player] {
        var players: [Player] = []
        
        // Extract home team players
        players.append(contentsOf: lineup.homeTeam.startingXI)
        players.append(contentsOf: lineup.homeTeam.substitutes)
        
        // Extract away team players
        players.append(contentsOf: lineup.awayTeam.startingXI)
        players.append(contentsOf: lineup.awayTeam.substitutes)
        
        return players
    }
    
    @MainActor func startMonitoringMatch(_ match: Match) {
        guard isLiveMode, let matchService = matchService else { return }
        
        // Cancel any existing monitoring first
        stopAllMonitoring()
        
        print("🎯 Starting match monitoring for: \(match.homeTeam.name) vs \(match.awayTeam.name)")
        print("🔧 Using service type: \(type(of: matchService))")
        
        // Clear processed events when starting new monitoring
        processedEventIds.removeAll()
        
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
        var savedGames = GameHistoryManager.shared.getSavedGameSessions()
        savedGames.append(savedGame)
        
        // Save to UserDefaults using the working method
        if let encoded = try? JSONEncoder().encode(savedGames) {
            UserDefaults.standard.set(encoded, forKey: "savedGameSessions")
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
        // Don't add another custom bet if we already have custom events
        if eventType == .custom && !getCustomEvents().isEmpty {
            print("⚠️ Skipping duplicate custom bet - custom events already exist")
            return
        }
        
        let bet = Bet(eventType: eventType, amount: amount)
        bets.append(bet)
        print("✅ Added bet: \(eventType.rawValue) = \(amount)")
    }
    
    func recreateBetsWithPreservation(newBetAmounts: [Bet.EventType: Double]) {
        print("🔄 Recreating bets while preserving custom events...")
        
        // Backup custom events
        let customEventsBackup = getCustomEvents()
        print("📦 Backing up \(customEventsBackup.count) custom events")
        
        // Clear existing bets and mappings
        bets.removeAll()
        customEventMappings.removeAll()
        
        // Add standard bets (excluding custom)
        for (eventType, amount) in newBetAmounts {
            if eventType != .custom {
                let bet = Bet(eventType: eventType, amount: amount)
                bets.append(bet)
            }
        }
        
        // Restore custom events
        for customEvent in customEventsBackup {
            addCustomEvent(name: customEvent.name, amount: customEvent.amount)
        }
        
        print("✅ Bet recreation complete. Total bets: \(bets.count), Custom events: \(getCustomEvents().count)")
    }
    
    func autoFixCustomEventsOnGameStart() {
        let customEvents = bets.filter { $0.eventType == .custom }
        let orphanedMappings = customEventMappings.filter { (betId, _) in
            !bets.contains { $0.id == betId }
        }
        
        if !customEvents.isEmpty && !orphanedMappings.isEmpty {
            debugAndFixCustomEventMappings()
        }
    }
    
    @MainActor func startRealEventDrivenMode() {
        guard isLiveMode else {
            print("⚠️ Not in live mode, skipping event-driven setup")
            return
        }
        
        print("🎯 Setting up REAL event-driven mode for game \(id)")
        
        // Track usage for free users
        AppConfig.recordLiveMatchUsage()
        
        // Start real monitoring
        EventDrivenManager.shared.startMonitoring(for: self)
    }
    
    @MainActor func getRealEventDrivenStats() -> String {
        return """
        Live Mode Stats:
        - Active Monitoring: \(EventDrivenManager.shared.getActiveGamesCount() > 0 ? "YES" : "NO")
        - Match: \(selectedMatch?.homeTeam.shortName ?? "NONE") vs \(selectedMatch?.awayTeam.shortName ?? "NONE")
        - Players: \(selectedPlayers.count)
        - Live Events: \(events.count)
        """
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
        
        // Check if we should show interstitial ad after every 3rd event
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
        // CRITICAL: Prevent duplicate events
        let eventKey = "\(event.id)_\(event.minute)_\(event.type)_\(event.playerId)"
        
        if processedEventIds.contains(eventKey) {
            print("🚫 Duplicate event detected and skipped: \(eventKey)")
            return
        }
        
        // Mark this event as processed
        processedEventIds.insert(eventKey)
        
        print("🔥 Processing new live event: \(event.type) at \(event.minute)' by \(event.playerName ?? "Unknown")")
        
        // Look up player by API ID first, then fallback to name
        guard let player = findPlayerForEvent(event) else {
            print("❌ Could not find player for event: \(event.playerName ?? "Unknown") (ID: \(event.playerId))")
            return
        }
        
        // Handle substitutions separately
        if event.type.lowercased() == "substitution" {
            print("🔄 Processing substitution...")
            handleSubstitution(event)
            return
        }
        
        // Map API event to app event type
        guard let eventType = mapToEventType(event.type) else {
            print("❌ Unknown event type: \(event.type)")
            return
        }
        
        // Record the event
        Task { @MainActor in
            print("⚽ Recording event: \(eventType.rawValue) for \(player.name)")
            recordEvent(player: player, eventType: eventType)
        }
    }
    
    private func findPlayerForEvent(_ event: MatchEvent) -> Player? {
        // Method 1: Match by API ID (most reliable)
        if let player = availablePlayers.first(where: { $0.apiId == event.playerId }) {
            return player
        }
        
        // Method 2: Match by name (fallback)
        if let playerName = event.playerName {
            if let player = availablePlayers.first(where: {
                $0.name.lowercased() == playerName.lowercased()
            }) {
                return player
            }
        }
        
        return nil
    }
    
    func fetchMatchSquad(matchId: String) async throws -> [Player] {
        guard let matchService = matchService else {
            throw NSError(domain: "SquadError", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Match service not available"
            ])
        }
        
        if let footballService = matchService as? FootballDataMatchService {
            return try await footballService.fetchMatchSquad(matchId: matchId)
        } else {
            throw NSError(domain: "SquadError", code: 2, userInfo: [
                NSLocalizedDescriptionKey: "Football service not available"
            ])
        }
    }

    
    private func handleSubstitution(_ event: MatchEvent) {
        print("🔄 Handling substitution event...")
        
        guard let playerOffId = event.playerOffId,
              let playerOnId = event.playerOnId else {
            print("❌ Substitution missing player IDs: off=\(event.playerOffId ?? "nil"), on=\(event.playerOnId ?? "nil")")
            return
        }
        
        // Find player going off (must be in selected players)
        guard let playerOff = selectedPlayers.first(where: { $0.apiId == playerOffId }) else {
            print("❌ Player going off not found in selected players: \(playerOffId)")
            return
        }
        
        // Find substitute coming in (check available players first, then try to fetch if needed)
        var playerOn: Player?
        
        // First try to find in available players
        playerOn = availablePlayers.first(where: { $0.apiId == playerOnId })
        
        if playerOn == nil {
            print("⚠️ Substitute player not found in available players, trying to find by name...")
            
            // Fallback: try to find by name if available in event
            if let substituteName = event.playerName {
                playerOn = availablePlayers.first(where: {
                    $0.name.lowercased() == substituteName.lowercased()
                })
            }
        }
        
        if playerOn == nil {
            print("❌ Could not find substitute player: \(playerOnId)")
            return
        }
        
        guard let playerOnFound = playerOn else { return }
        
        print("✅ Substitution: \(playerOff.name) OFF → \(playerOnFound.name) ON")
        
        // Perform the substitution
        substitutePlayer(playerOff: playerOff, playerOn: playerOnFound, minute: event.minute)
    }
    
    @MainActor func stopAllMonitoring() {
        print("🛑 Stopping ALL monitoring systems...")
        
        // Stop match monitoring task
        matchMonitoringTask?.cancel()
        matchMonitoringTask = nil
        
        // Stop event-driven monitoring
        EventDrivenManager.shared.stopMonitoring(for: self)
        
        // Stop background monitoring
        BackgroundTaskManager.shared.stopBackgroundMonitoring(for: self)
        
        print("✅ All monitoring stopped")
    }
    
    @MainActor func setupEventDrivenMode() {
        guard isLiveMode else { return }
        print("🎯 Setting up event-driven mode for game \(id)")
        
        // IMPORTANT: Stop any existing monitoring first
        stopAllMonitoring()
        
        // Clear processed events when starting fresh
        processedEventIds.removeAll()
        
        // Track usage for free users
        AppConfig.recordLiveMatchUsage()
        
        // Start only ONE monitoring system
        EventDrivenManager.shared.startMonitoring(for: self)
        
        print("✅ Event-driven mode setup complete")
    }
    
    // Add method to manually clear processed events (useful for testing)
    @MainActor func clearProcessedEvents() {
        processedEventIds.removeAll()
        print("🧹 Cleared processed events cache")
    }

    // Enhanced debug method
    @MainActor func debugEventStatus() -> String {
        return """
        📊 Event Processing Status:
        - Total events recorded: \(events.count)
        - Processed event IDs: \(processedEventIds.count)
        - Active monitoring: \(matchMonitoringTask != nil ? "YES" : "NO")
        - EventDriven active: \(EventDrivenManager.shared.getActiveGamesCount() > 0 ? "YES" : "NO")
        - Last 3 processed IDs: \(Array(processedEventIds.suffix(3)))
        """
    }

    
    private func findOrCreatePlayerFromAPI(apiId: String) -> Player? {
        // First try to find existing player
        if let existingPlayer = availablePlayers.first(where: { $0.apiId == apiId }) {
            return existingPlayer
        }
        
        // If not found, we can't create it without more API data
        // This would require a separate API call to get player details
        print("⚠️ Player with API ID \(apiId) not found in available players")
        return nil
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
    
    func recalculateBalancesFromEvents() {
        // Reset all participant balances to zero
        for i in 0..<participants.count {
            participants[i].balance = 0.0
        }
        
        // Replay all events to recalculate balances
        for event in events {
            guard let bet = bets.first(where: { $0.eventType == event.eventType }) else { continue }
            
            // Find participants who have the player
            let participantsWithPlayer = participants.filter { participant in
                participant.selectedPlayers.contains { $0.id == event.player.id } ||
                participant.substitutedPlayers.contains { $0.id == event.player.id }
            }
            
            // Find participants who don't have the player
            let participantsWithoutPlayer = participants.filter { participant in
                !participant.selectedPlayers.contains { $0.id == event.player.id } &&
                !participant.substitutedPlayers.contains { $0.id == event.player.id }
            }
            
            guard !participantsWithPlayer.isEmpty && !participantsWithoutPlayer.isEmpty else {
                continue
            }
            
            // Apply the same payment logic as the existing calculatePayments method
            if bet.amount >= 0 {
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
    }
    
    func addCustomEvent(name: String, amount: Double) {
        let bet = Bet(eventType: .custom, amount: amount)
        bets.append(bet)
        customEventMappings[bet.id] = name
        objectWillChange.send()
    }
    
    func getEventDisplayName(for event: GameEvent) -> String {
        if event.eventType == .custom {
            return event.customEventName ?? "Custom Event"
        }
        return event.eventType.rawValue
    }
    
    func getCustomEvents() -> [(id: UUID, name: String, amount: Double)] {
        return bets.compactMap { bet -> (id: UUID, name: String, amount: Double)? in
            if bet.eventType == .custom {
                if let customName = customEventMappings[bet.id] {
                    return (id: bet.id, name: customName, amount: bet.amount)
                }
            }
            return nil
        }
    }
    
    // Method to remove custom events
    func removeCustomEvent(id: UUID) {
        // Remove the bet
        bets.removeAll { bet in
            bet.id == id && bet.eventType == .custom
        }
        
        // Remove from mappings
        customEventMappings.removeValue(forKey: id)
    }
    
    @MainActor func recordCustomEvent(player: Player, eventName: String) {
        // Find the custom bet that matches this event name
        guard let customBet = bets.first(where: { bet in
            bet.eventType == .custom && customEventMappings[bet.id] == eventName
        }) else {
            print("❌ Could not find custom bet for event: \(eventName)")
            return
        }
        
        // Create the event WITH the custom event name stored
        let event = GameEvent(
            player: player,
            eventType: .custom,
            timestamp: Date(),
            customEventName: eventName  // Store the actual event name
        )
        
        // Store backup for undo
        let participantBalanceBackup = participants.reduce(into: [UUID: Double]()) { result, participant in
            result[participant.id] = participant.balance
        }
        lastEventBackup = (event: event, participantBalances: participantBalanceBackup)
        canUndoLastEvent = true
        
        // Add the event
        events.append(event)
        
        // Process betting logic
        processCustomEventBetting(event: event, customBet: customBet, eventName: eventName)
        
        print("✅ Recorded custom event: \(eventName) for \(player.name)")
        
        // Force UI update
        objectWillChange.send()
    }

    private func processCustomEventBetting(event: GameEvent, customBet: Bet, eventName: String) {
        // Determine which participants have the player who triggered the event
        let participantsWithPlayer = participants.enumerated().compactMap { (index, participant) in
            let hasPlayer = participant.selectedPlayers.contains { $0.id == event.player.id } ||
                           participant.substitutedPlayers.contains { $0.id == event.player.id }
            return hasPlayer ? index : nil
        }
        
        let participantsWithoutPlayer = participants.enumerated().compactMap { (index, participant) in
            let hasPlayer = participant.selectedPlayers.contains { $0.id == event.player.id } ||
                           participant.substitutedPlayers.contains { $0.id == event.player.id }
            return hasPlayer ? nil : index
        }
        
        // Apply the betting logic based on whether it's positive or negative
        if customBet.amount > 0 {
            // Positive bet: participants WITHOUT player pay those WITH player
            let payAmount = customBet.amount
            
            for i in 0..<participants.count {
                let hasPlayer = participantsWithPlayer.contains(i)
                
                if hasPlayer {
                    participants[i].balance += payAmount * Double(participantsWithoutPlayer.count)
                } else {
                    participants[i].balance -= payAmount
                }
            }
        } else {
            // Negative bet: participants WITH player pay those WITHOUT player
            let payAmount = abs(customBet.amount)
            
            for i in 0..<participants.count {
                let hasPlayer = participantsWithPlayer.contains(i)
                
                if hasPlayer {
                    participants[i].balance -= payAmount * Double(participantsWithoutPlayer.count)
                } else {
                    participants[i].balance += payAmount * Double(participantsWithPlayer.count)
                }
            }
        }
        
        print("💰 Processed betting for custom event '\(eventName)': \(customBet.amount > 0 ? "Positive" : "Negative") bet of \(abs(customBet.amount))")
    }
    
    func debugAndFixCustomEventMappings() {
        // Find custom bets without mappings
        var unmappedCustomBets: [Bet] = []
        
        for bet in bets where bet.eventType == .custom {
            if customEventMappings[bet.id] == nil {
                unmappedCustomBets.append(bet)
            }
        }
        
        // Remove mappings for bets that no longer exist
        let existingBetIds = Set(bets.map { $0.id })
        for (betId, _) in customEventMappings {
            if !existingBetIds.contains(betId) {
                customEventMappings.removeValue(forKey: betId)
            }
        }
        
        // Fix unmapped custom bets
        for (index, bet) in unmappedCustomBets.enumerated() {
            let recoveredName = "Custom Event \(index + 1)"
            customEventMappings[bet.id] = recoveredName
        }
        
        objectWillChange.send()
    }
    
    func preserveCustomEventsAndRecreateStandardBets(standardBetAmounts: [Bet.EventType: Double]) {
        print("🔄 Preserving custom events during bet recreation...")
        
        // Store existing custom events
        let existingCustomEvents = getCustomEvents()
        print("📦 Found \(existingCustomEvents.count) existing custom events to preserve")
        
        // Clear all bets
        bets.removeAll()
        customEventMappings.removeAll()
        
        // Recreate standard bets
        for (eventType, amount) in standardBetAmounts {
            if eventType != .custom {
                let bet = Bet(eventType: eventType, amount: amount)
                bets.append(bet)
                print("✅ Recreated standard bet: \(eventType.rawValue) = \(amount)")
            }
        }
        
        // Restore custom events with proper new IDs
        for customEvent in existingCustomEvents {
            addCustomEvent(name: customEvent.name, amount: customEvent.amount)
            print("✅ Restored custom event: \(customEvent.name) with amount \(customEvent.amount)")
        }
        
        print("🎯 Final bet count after preservation: \(bets.count)")
        print("🗂️ Final custom mappings: \(customEventMappings)")
        
        // Force UI update
        objectWillChange.send()
    }
    
    func getBetDisplayName(for bet: Bet) -> String {
        if bet.eventType == .custom {
            return customEventMappings[bet.id] ?? "Custom Event"
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
    
    func substitutePlayer(playerOff: Player, playerOn: Player, minute: Int? = nil) {
        let timestamp = Date()
        
        // Create a substitution record
        let substitution = Substitution(
            from: playerOff,
            to: playerOn,
            timestamp: timestamp,
            team: playerOff.team,
            minute: minute
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
                
                // Add the new player to active players
                participants[i].selectedPlayers.append(updatedPlayerOn)
                
                // ALSO update selectedPlayers at session level
                selectedPlayers.removeAll { $0.id == playerOff.id }
                selectedPlayers.append(updatedPlayerOn)
                
                print("✅ Substitution completed: \(playerOff.name) → \(updatedPlayerOn.name) for participant \(participants[i].name)")
                break
            }
        }
        
        // Notify UI to update
        objectWillChange.send()
    }
    
    func handleLiveSubstitution(playerOutId: String, playerInId: String, minute: Int, teamId: String) {
        // Find the player going out
        guard let playerOut = selectedPlayers.first(where: { $0.apiId == playerOutId }) else {
            print("⚠️ Player going out not found in selected players")
            return
        }
        
        // Find the substitute coming in
        guard let playerIn = availablePlayers.first(where: { $0.apiId == playerInId }) else {
            print("⚠️ Substitute player not found in available players")
            return
        }
        
        // Use the existing substitutePlayer method
        substitutePlayer(playerOff: playerOut, playerOn: playerIn, minute: minute)
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
        
        await testAPIAccess()
        
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
            
            // Handle real football service
            if let footballService = matchService as? FootballDataMatchService {
                print("🌐 Using real FootballDataMatchService")
                matches = try await footballService.fetchLiveMatches(competitionCode: nil)
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
    
    private func testAPIAccess() async {
        guard let footballService = matchService as? FootballDataMatchService else {
            print("❌ No football service available")
            return
        }
        await footballService.debugAPIAccess()
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
                return try await footballService.fetchMatchPlayers(matchId: matchId)
            } else {
                // Fallback to generic interface
                return try await matchService.fetchMatchPlayers(matchId: matchId)
            }
        } catch {
            print("❌ Error fetching players for match \(matchId): \(error)")
            throw error
        }
    }

    @MainActor func cleanupEventDrivenMode() {
        print("🧹 Cleaning up event-driven mode for game \(id)")
        
        // Stop event monitoring
        EventDrivenManager.shared.stopMonitoring(for: self)
        
        // Cancel any existing monitoring tasks
        matchMonitoringTask?.cancel()
        matchMonitoringTask = nil
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
        } else {
            // Fallback to basic monitoring
            matchMonitoringTask = matchService.startMonitoringMatch(
                matchId: match.id,
                updateInterval: 30,
                onUpdate: { [weak self] (update: MatchUpdate) in
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
    
    // MARK: - Player Persistence
    
    private static let userPlayersKey = "userCustomPlayers"
    private static let userTeamsKey = "userCustomTeams"
    
    /// Save user's custom players to UserDefaults for persistence
    func saveCustomPlayers() {
        do {
            let playersData = try JSONEncoder().encode(availablePlayers)
            UserDefaults.standard.set(playersData, forKey: Self.userPlayersKey)
            
            // Extract and save unique teams
            let uniqueTeams = Array(Set(availablePlayers.map { $0.team }))
            let teamsData = try JSONEncoder().encode(uniqueTeams)
            UserDefaults.standard.set(teamsData, forKey: Self.userTeamsKey)
            
            print("💾 Saved \(availablePlayers.count) players and \(uniqueTeams.count) teams")
        } catch {
            print("❌ Failed to save custom players: \(error)")
        }
    }
    
    /// Load user's custom players from UserDefaults
    func loadCustomPlayers() {
        do {
            if let playersData = UserDefaults.standard.data(forKey: Self.userPlayersKey) {
                let players = try JSONDecoder().decode([Player].self, from: playersData)
                availablePlayers = players
                print("📂 Loaded \(players.count) custom players")
            } else {
                // First time - initialize with empty array
                availablePlayers = []
                print("🆕 No saved players found - starting fresh")
            }
        } catch {
            print("❌ Failed to load custom players: \(error)")
            availablePlayers = []
        }
    }
    
    /// Load saved teams for team selection
    func loadCustomTeams() -> [Team] {
        do {
            if let teamsData = UserDefaults.standard.data(forKey: Self.userTeamsKey) {
                let teams = try JSONDecoder().decode([Team].self, from: teamsData)
                return teams
            }
        } catch {
            print("❌ Failed to load custom teams: \(error)")
        }
        return []
    }
    
    /// Clear all saved player data
    func clearAllSavedData() {
        UserDefaults.standard.removeObject(forKey: Self.userPlayersKey)
        UserDefaults.standard.removeObject(forKey: Self.userTeamsKey)
        availablePlayers = []
        selectedPlayers = []
        print("🗑️ Cleared all saved player data")
    }
    
    // MARK: - Performance Optimizations
    
    /// Efficient player search by team
    func getPlayersByTeam() -> [UUID: [Player]] {
        return Dictionary(grouping: availablePlayers) { $0.team.id }
    }
    
    /// Get teams sorted by player count (most players first)
    func getTeamsSortedByPlayerCount() -> [(team: Team, playerCount: Int)] {
        let teamGroups = Dictionary(grouping: availablePlayers) { $0.team }
        return teamGroups.map { (team: $0.key, playerCount: $0.value.count) }
                         .sorted { $0.playerCount > $1.playerCount }
    }
    
    /// Memory-efficient player addition with automatic saving
    func addPlayerWithPersistence(_ player: Player) {
        // Check for duplicates before adding
        guard !availablePlayers.contains(where: { $0.id == player.id }) else {
            print("⚠️ Player \(player.name) already exists")
            return
        }
        
        availablePlayers.append(player)
        saveCustomPlayers() // Auto-save after each addition
        print("✅ Added and saved player: \(player.name)")
    }
    
    /// Memory-efficient player removal with automatic saving
    func removePlayerWithPersistence(_ playerId: UUID) {
        if let index = availablePlayers.firstIndex(where: { $0.id == playerId }) {
            let removedPlayer = availablePlayers.remove(at: index)
            saveCustomPlayers() // Auto-save after removal
            print("🗑️ Removed and saved: \(removedPlayer.name)")
        }
    }
    
    /// Batch add players with single save operation
    func addPlayersWithPersistence(_ players: [Player]) {
        let initialCount = availablePlayers.count
        
        for player in players {
            // Only add if not already present
            if !availablePlayers.contains(where: { $0.id == player.id }) {
                availablePlayers.append(player)
            }
        }
        
        let addedCount = availablePlayers.count - initialCount
        if addedCount > 0 {
            saveCustomPlayers() // Single save operation
            print("✅ Batch added \(addedCount) players")
        }
    }
    
    // MARK: - Data Validation and Cleanup
    
    /// Validate and clean up player data
    func validateAndCleanupPlayerData() {
        let initialCount = availablePlayers.count
        
        // Remove players with empty names or invalid teams
        availablePlayers = availablePlayers.filter { player in
            !player.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !player.team.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        
        // Remove duplicate players (same name and team)
        var seen = Set<String>()
        availablePlayers = availablePlayers.filter { player in
            let key = "\(player.name.lowercased())_\(player.team.id)"
            if seen.contains(key) {
                return false
            } else {
                seen.insert(key)
                return true
            }
        }
        
        let finalCount = availablePlayers.count
        let removedCount = initialCount - finalCount
        
        if removedCount > 0 {
            saveCustomPlayers()
            print("🧹 Cleaned up \(removedCount) invalid/duplicate players")
        }
    }
    
    /// Get statistics about current player data
    func getPlayerStatistics() -> PlayerStatistics {
        let teamGroups = Dictionary(grouping: availablePlayers) { $0.team }
        let positionGroups = Dictionary(grouping: availablePlayers) { $0.position }
        
        return PlayerStatistics(
            totalPlayers: availablePlayers.count,
            totalTeams: teamGroups.count,
            averagePlayersPerTeam: teamGroups.isEmpty ? 0 : Double(availablePlayers.count) / Double(teamGroups.count),
            positionBreakdown: positionGroups.mapValues { $0.count },
            largestTeam: teamGroups.max(by: { $0.value.count < $1.value.count }),
            memoryUsageEstimate: estimateMemoryUsage()
        )
    }
    
    private func estimateMemoryUsage() -> String {
        // Rough estimate: each player ~200 bytes (name, team, position, IDs)
        let estimatedBytes = availablePlayers.count * 200
        if estimatedBytes < 1024 {
            return "\(estimatedBytes) bytes"
        } else if estimatedBytes < 1024 * 1024 {
            return String(format: "%.1f KB", Double(estimatedBytes) / 1024.0)
        } else {
            return String(format: "%.1f MB", Double(estimatedBytes) / (1024.0 * 1024.0))
        }
    }
}

// MARK: - Supporting Structures

struct PlayerStatistics {
    let totalPlayers: Int
    let totalTeams: Int
    let averagePlayersPerTeam: Double
    let positionBreakdown: [Player.Position: Int]
    let largestTeam: (key: Team, value: [Player])?
    let memoryUsageEstimate: String
    
    var summary: String {
        var parts: [String] = []
        parts.append("\(totalPlayers) players")
        parts.append("\(totalTeams) teams")
        parts.append("~\(String(format: "%.1f", averagePlayersPerTeam)) players/team")
        parts.append("Memory: \(memoryUsageEstimate)")
        
        if let largest = largestTeam {
            parts.append("Largest: \(largest.key.name) (\(largest.value.count))")
        }
        
        return parts.joined(separator: ", ")
    }
}
