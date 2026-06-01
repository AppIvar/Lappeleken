//
//  GameLogicManager.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 07/08/2025.
//

import Foundation

class GameLogicManager {
    static let shared = GameLogicManager()
    
    private init() {}
    
    // MARK: - Event Processing
    
    /// Process a game event and update participant balances
    func processEvent(_ event: GameEvent, in gameSession: GameSession) {
        // Snapshot every balance BEFORE this event, keyed to the event id, for exact undo.
        let snapshot = gameSession.participants.reduce(into: [UUID: Double]()) { result, participant in
            result[participant.id] = participant.balance
        }
        gameSession.balanceSnapshots.append((eventId: event.id, balances: snapshot))

        gameSession.events.append(event)
        calculatePayments(for: event, in: gameSession)

        gameSession.canUndoLastEvent = true
        gameSession.objectWillChange.send()

        print("✅ Processed event: \(getEventLabel(event)) for \(event.player.name)")
    }
    
    /// Undo the last event and reverse all changes
    func undoLastEvent(in gameSession: GameSession) {
        guard !gameSession.events.isEmpty else { return }

        let lastEvent = gameSession.events.removeLast()

        // Restore balances exactly, if we have a snapshot for this event.
        // Recompute-free: immune to ownership changes (substitutions) since the event.
        if let top = gameSession.balanceSnapshots.last, top.eventId == lastEvent.id {
            gameSession.balanceSnapshots.removeLast()
            for i in 0..<gameSession.participants.count {
                if let restored = top.balances[gameSession.participants[i].id] {
                    gameSession.participants[i].balance = restored
                }
            }
        } else {
            // No matching snapshot → the event had no balance effect (e.g. a substitution
            // timeline entry). Remove it without touching balances. Roster reversal for
            // substitutions is intentionally out of scope here.
            print("ℹ️ Undo: no balance snapshot for \(getEventLabel(lastEvent)) — removed event only")
        }

        gameSession.canUndoLastEvent = !gameSession.events.isEmpty
        gameSession.objectWillChange.send()

        print("🔄 Undid event: \(getEventLabel(lastEvent)) for \(lastEvent.player.name)")
    }
    
    // MARK: - Payment Calculations
    
    /// Calculate and apply payments for an event
    private func calculatePayments(for event: GameEvent, in gameSession: GameSession) {
        // Find the bet for this event type
        guard let bet = resolveBet(for: event, in: gameSession) else {
            print("⚠️ No bet found for event type: \(event.eventType.rawValue)")
            return
        }
        
        // Get participant groups
        let (participantsWithPlayer, participantsWithoutPlayer) = getParticipantGroups(
            for: event.player,
            in: gameSession
        )
        
        // Ensure both groups have participants
        guard !participantsWithPlayer.isEmpty && !participantsWithoutPlayer.isEmpty else {
            print("⚠️ Cannot process payment - missing participants in one group")
            return
        }
        
        // Apply payment logic based on bet amount sign
        if bet.amount >= 0 {
            applyPositiveBetPayment(
                bet: bet,
                participantsWithPlayer: participantsWithPlayer,
                participantsWithoutPlayer: participantsWithoutPlayer,
                in: gameSession
            )
        } else {
            applyNegativeBetPayment(
                bet: bet,
                participantsWithPlayer: participantsWithPlayer,
                participantsWithoutPlayer: participantsWithoutPlayer,
                in: gameSession
            )
        }
    }
    
    /// Find the bet a given event should pay out against.
    /// Custom events must match the *specific* custom bet by name, not just the first `.custom` bet.
    private func resolveBet(for event: GameEvent, in gameSession: GameSession) -> Bet? {
        if event.eventType == .custom {
            return gameSession.bets.first { bet in
                bet.eventType == .custom &&
                gameSession.customEventMappings[bet.id] == event.customEventName
            }
        }
        return gameSession.bets.first { $0.eventType == event.eventType }
    }

    /// Readable label for logging (custom events show their name, not "Custom Event").
    private func getEventLabel(_ event: GameEvent) -> String {
        if event.eventType == .custom { return event.customEventName ?? "Custom Event" }
        return event.eventType.rawValue
    }
    
    // MARK: - Player Assignment
    
    /// Randomly assign players to participants
    func assignPlayersRandomly(in gameSession: GameSession) {
        guard !gameSession.participants.isEmpty, !gameSession.selectedPlayers.isEmpty else {
            print("❌ Cannot assign players - no participants or no selected players")
            return
        }
        
        print("🎲 Starting player assignment...")
        print("  Participants: \(gameSession.participants.count)")
        print("  Selected players: \(gameSession.selectedPlayers.count)")
        
        // Clear existing assignments
        clearPlayerAssignments(in: gameSession)
        
        // Shuffle players for random distribution
        var playersToAssign = gameSession.selectedPlayers
        playersToAssign.shuffle()
        
        // Calculate distribution
        let distribution = calculatePlayerDistribution(
            totalPlayers: playersToAssign.count,
            totalParticipants: gameSession.participants.count
        )
        
        // Assign players
        assignPlayersToParticipants(
            players: playersToAssign,
            distribution: distribution,
            in: gameSession
        )
        
        // Notify UI of changes
        gameSession.objectWillChange.send()
        
        printPlayerAssignments(gameSession)
    }
    
    /// Recalculate all balances from scratch based on events
    func recalculateBalances(in gameSession: GameSession) {
        // Reset all participant balances to zero
        for i in 0..<gameSession.participants.count {
            gameSession.participants[i].balance = 0.0
        }
        
        // Replay all events to recalculate balances
        print("🔄 Recalculating balances from \(gameSession.events.count) events...")
        
        for event in gameSession.events {
            calculatePayments(for: event, in: gameSession)
        }
        
        print("✅ Balance recalculation complete")
        gameSession.balanceSnapshots.removeAll()
        gameSession.canUndoLastEvent = false
        gameSession.objectWillChange.send()
    }
    
    // MARK: - Substitution Logic
    
    /// Process a player substitution using the unified SubstitutionManager
    @MainActor func processSubstitution(playerOff: Player, playerOn: Player, minute: Int?, in gameSession: GameSession) {
        // Delegate to SubstitutionManager for unified processing
        SubstitutionManager.shared.processManualSubstitution(
            playerOff: playerOff,
            playerOn: playerOn,
            minute: minute,
            in: gameSession
        )
    }
    
    /// Process a live substitution from API data
    @MainActor func processLiveSubstitution(playerOutId: String, playerInId: String, minute: Int, teamId: String, in gameSession: GameSession) {
        // Delegate to SubstitutionManager for unified processing
        SubstitutionManager.shared.processLiveSubstitution(
            playerOutId: playerOutId,
            playerInId: playerInId,
            minute: minute,
            teamId: teamId,
            in: gameSession
        )
    }
    
    /// Handle substitution from MatchEvent (for live mode)
    @MainActor func handleSubstitutionEvent(_ event: MatchEvent, in gameSession: GameSession) {
        // Delegate to SubstitutionManager for unified processing
        SubstitutionManager.shared.handleSubstitutionEvent(event, in: gameSession)
    }
    
    // MARK: - Helper Methods
    
    
    /// Check if a player is currently active (not substituted off)
    func isPlayerActive(_ player: Player) -> Bool {
        return SubstitutionManager.shared.isPlayerActive(player)
    }
}
// MARK: - Private helper methods

extension GameLogicManager {
    
    // MARK: - Participant Grouping
    
    /// Get participants who have/don't have the event player
    func getParticipantGroups(for player: Player, in gameSession: GameSession) -> (withPlayer: [Int], withoutPlayer: [Int]) {
        var participantsWithPlayer: [Int] = []
        var participantsWithoutPlayer: [Int] = []
        
        for (index, participant) in gameSession.participants.enumerated() {
            let hasPlayer = participant.selectedPlayers.contains { $0.id == player.id } ||
            participant.substitutedPlayers.contains { $0.id == player.id }
            
            if hasPlayer {
                participantsWithPlayer.append(index)
            } else {
                participantsWithoutPlayer.append(index)
            }
        }
        
        return (participantsWithPlayer, participantsWithoutPlayer)
    }
    
    // MARK: - Payment Logic - Positive Bets
    
    /// Apply payment logic for positive bets (participants WITHOUT player pay those WITH player)
    func applyPositiveBetPayment(bet: Bet, participantsWithPlayer: [Int], participantsWithoutPlayer: [Int], in gameSession: GameSession) {
        let totalAmount = Double(participantsWithoutPlayer.count) * bet.amount
        let amountPerWinner = totalAmount / Double(participantsWithPlayer.count)
        
        // Participants WITH player receive money
        for index in participantsWithPlayer {
            gameSession.participants[index].balance += amountPerWinner
        }
        
        // Participants WITHOUT player pay money
        for index in participantsWithoutPlayer {
            gameSession.participants[index].balance -= bet.amount
        }
        
        print("💰 Positive bet: \(participantsWithoutPlayer.count) pay \(bet.amount) each, \(participantsWithPlayer.count) receive \(amountPerWinner) each")
    }
    
    /// Apply payment logic for negative bets (participants WITH player pay those WITHOUT player)
    func applyNegativeBetPayment(bet: Bet, participantsWithPlayer: [Int], participantsWithoutPlayer: [Int], in gameSession: GameSession) {
        let payAmount = abs(bet.amount)
        let totalPayment = payAmount * Double(participantsWithoutPlayer.count)
        
        // Participants WITH player pay money
        for index in participantsWithPlayer {
            gameSession.participants[index].balance -= totalPayment
        }
        
        // Participants WITHOUT player receive money
        for index in participantsWithoutPlayer {
            gameSession.participants[index].balance += payAmount * Double(participantsWithPlayer.count)
        }
        
        print("💸 Negative bet: \(participantsWithPlayer.count) pay \(totalPayment) each, \(participantsWithoutPlayer.count) receive proportionally")
    }
    
    // MARK: - Player Assignment Helpers
    
    /// Clear all existing player assignments
    func clearPlayerAssignments(in gameSession: GameSession) {
        for i in 0..<gameSession.participants.count {
            gameSession.participants[i].selectedPlayers = []
        }
    }
    
    /// Calculate how to distribute players among participants
    func calculatePlayerDistribution(totalPlayers: Int, totalParticipants: Int) -> (playersPerParticipant: Int, remainingPlayers: Int) {
        let playersPerParticipant = totalPlayers / totalParticipants
        let remainingPlayers = totalPlayers % totalParticipants
        
        print("  Distribution: \(playersPerParticipant) per participant, \(remainingPlayers) extra")
        
        return (playersPerParticipant, remainingPlayers)
    }
    
    /// Assign players to participants based on distribution
    func assignPlayersToParticipants(players: [Player], distribution: (playersPerParticipant: Int, remainingPlayers: Int), in gameSession: GameSession) {
        var playerIndex = 0
        
        for i in 0..<gameSession.participants.count {
            let numberOfPlayers = i < distribution.remainingPlayers ?
            distribution.playersPerParticipant + 1 :
            distribution.playersPerParticipant
            
            for _ in 0..<numberOfPlayers {
                if playerIndex < players.count {
                    gameSession.participants[i].selectedPlayers.append(players[playerIndex])
                    playerIndex += 1
                }
            }
        }
    }
    
    /// Print current player assignments for debugging
    func printPlayerAssignments(_ gameSession: GameSession) {
        print("📋 Final player assignments:")
        for participant in gameSession.participants {
            let playerNames = participant.selectedPlayers.map { $0.name }.joined(separator: ", ")
            print("  \(participant.name): \(participant.selectedPlayers.count) players - \(playerNames)")
        }
    }
}
