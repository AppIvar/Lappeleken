//
//  SubstitutionManager.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/08/2025.
//

import Foundation

class SubstitutionManager {
    static let shared = SubstitutionManager()
    
    private init() {}
    
    // MARK: - Main Substitution Processing
    
    /// Process a substitution for both manual and live modes
    /// This is the single source of truth for all substitutions
    @MainActor
    func processSubstitution(
        playerOff: Player,
        playerOn: Player,
        minute: Int? = nil,
        source: SubstitutionSource,
        in gameSession: GameSession
    ) {
        print("🔄 Processing substitution: \(playerOff.name) → \(playerOn.name)")
        
        // Find which participant has the player going off
        var participantIndex: Int? = nil
        for (index, participant) in gameSession.participants.enumerated() {
            if participant.selectedPlayers.contains(where: { $0.id == playerOff.id }) {
                participantIndex = index
                break
            }
        }
        
        guard let index = participantIndex else {
            print("❌ Player \(playerOff.name) not found in any participant's roster")
            return
        }
        
        // Remove player going off from selectedPlayers
        gameSession.participants[index].selectedPlayers.removeAll { $0.id == playerOff.id }
        
        // Add to substituted players
        gameSession.participants[index].substitutedPlayers.append(playerOff)
        
        // Add substitute to selectedPlayers
        gameSession.participants[index].selectedPlayers.append(playerOn)
        
        // Also update gameSession's selectedPlayers
        gameSession.selectedPlayers.removeAll { $0.id == playerOff.id }
        if !gameSession.selectedPlayers.contains(where: { $0.id == playerOn.id }) {
            gameSession.selectedPlayers.append(playerOn)
        }
        
        // Create substitution record with team parameter
        let substitution = Substitution(
            from: playerOff,
            to: playerOn,
            timestamp: Date(),
            team: playerOff.team,
            minute: minute
        )
        gameSession.substitutions.append(substitution)
        
        // IMPORTANT: Create timeline event BEFORE forcing UI update
        let eventName = "Substitution: \(substitution.from.name) → \(substitution.to.name)"
        
        let substitutionEvent = GameEvent(
            player: substitution.from,
            eventType: .custom,
            timestamp: substitution.timestamp,
            minute: substitution.minute,
            customEventName: eventName
        )
        
        // Add to events list for timeline display
        gameSession.events.append(substitutionEvent)
        
        print("✅ Added substitution to timeline: \(eventName)")
        print("   Total events now: \(gameSession.events.count)")
        print("   Event ID: \(substitutionEvent.id)")
        
        // Force immediate UI update
        gameSession.objectWillChange.send()
    }
    
    // MARK: - Live Mode Integration
    
    /// Process substitution from API event (Live Mode)
    @MainActor
    func processLiveSubstitution(
        playerOutId: String,
        playerInId: String,
        minute: Int,
        teamId: String,
        in gameSession: GameSession
    ) {
        print("🌐 Processing live substitution from API")
        print("   Player OUT ID: \(playerOutId)")
        print("   Player IN ID: \(playerInId)")
        
        // Find the player going out
        guard let playerOut = findPlayerInGameByApiId(playerOutId, in: gameSession) else {
            print("⚠️ Player going out not found, creating timeline event anyway")
            
            // Try to find in available players for the name at least
            if let playerOutFromAvailable = gameSession.availablePlayers.first(where: { $0.apiId == playerOutId }),
               let playerInFromAvailable = gameSession.availablePlayers.first(where: { $0.apiId == playerInId }) {
                
                // Create a timeline event even if the player isn't in the game
                let eventName = "Substitution: \(playerOutFromAvailable.name) → \(playerInFromAvailable.name)"
                let substitutionEvent = GameEvent(
                    player: playerOutFromAvailable,
                    eventType: .custom,
                    timestamp: Date(),
                    minute: minute,
                    customEventName: eventName
                )
                gameSession.events.append(substitutionEvent)
                gameSession.objectWillChange.send()
                print("✅ Created timeline event for substitution (players not in active game)")
            }
            return
        }
        
        // Find the substitute coming in
        guard let playerIn = findPlayerByApiId(playerInId, in: gameSession) else {
            print("⌠Substitute player not found in available players: \(playerInId)")
            return
        }
        
        print("✅ Found both players: \(playerOut.name) OUT, \(playerIn.name) IN")
        
        // Process using unified method
        processSubstitution(
            playerOff: playerOut,
            playerOn: playerIn,
            minute: minute,
            source: .liveAPI,
            in: gameSession
        )
    }
    
    /// Handle substitution from MatchEvent (for live mode)
    @MainActor
    func handleSubstitutionEvent(_ event: MatchEvent, in gameSession: GameSession) {
        print("🔄 Handling substitution event from MatchEvent")
        
        guard let playerOffId = event.playerOffId,
              let playerOnId = event.playerOnId else {
            print("❌ Substitution missing player IDs: off=\(event.playerOffId ?? "nil"), on=\(event.playerOnId ?? "nil")")
            return
        }
        
        // Process the live substitution
        processLiveSubstitution(
            playerOutId: playerOffId,
            playerInId: playerOnId,
            minute: event.minute,
            teamId: event.teamId ?? "",
            in: gameSession
        )
    }
    
    // MARK: - Manual Mode Integration
    
    /// Process manual substitution (Manual Mode)
    @MainActor
    func processManualSubstitution(
        playerOff: Player,
        playerOn: Player,
        minute: Int? = nil,
        in gameSession: GameSession
    ) {
        // Use the provided minute parameter directly (from API or manual input)
        let effectiveMinute = minute
        
        // Process using unified method
        processSubstitution(
            playerOff: playerOff,
            playerOn: playerOn,
            minute: effectiveMinute,
            source: .manual,
            in: gameSession
        )
    }
    
    // MARK: - Player Status Management
    
    /// Check if a player is currently active (not substituted off)
    func isPlayerActive(_ player: Player) -> Bool {
        if case .substitutedOff = player.substitutionStatus {
            return false
        }
        return true
    }
    
    /// Get all active players for a participant
    func getActivePlayers(for participant: Participant) -> [Player] {
        return participant.selectedPlayers.filter { isPlayerActive($0) }
    }
    
    /// Get all substituted players for a participant
    func getSubstitutedPlayers(for participant: Participant) -> [Player] {
        return participant.substitutedPlayers
    }
}

// MARK: - Private Helper Methods

extension SubstitutionManager {
    
    // MARK: - Validation
    
    func validateSubstitution(playerOff: Player, playerOn: Player, in gameSession: GameSession) -> Bool {
        // Check if player being substituted off is currently active
        guard isPlayerActive(playerOff) else {
            print("❌ Player \(playerOff.name) is already substituted off")
            return false
        }
        
        // Check if substitute is not already in the game
        let isPlayerOnInGame = gameSession.participants.contains { participant in
            participant.selectedPlayers.contains { $0.id == playerOn.id }
        }
        
        if isPlayerOnInGame {
            print("❌ Player \(playerOn.name) is already in the game")
            return false
        }
        
        // Check if both players are from the same team
        if playerOff.team.id != playerOn.team.id {
            print("⚠️ Warning: Players are from different teams")
            print("   \(playerOff.name): \(playerOff.team.name)")
            print("   \(playerOn.name): \(playerOn.team.name)")
            // Continue anyway - this might be valid in some cases
        }
        
        return true
    }
    
    // MARK: - Player Finding
    
    func findParticipantOwningPlayer(_ player: Player, in gameSession: GameSession) -> Int? {
        for (index, participant) in gameSession.participants.enumerated() {
            if participant.selectedPlayers.contains(where: { $0.id == player.id }) {
                return index
            }
        }
        return nil
    }
    
    func findPlayerInGameByApiId(_ apiId: String, in gameSession: GameSession) -> Player? {
        return gameSession.selectedPlayers.first(where: { $0.apiId == apiId })
    }
    
    func findPlayerByApiId(_ apiId: String, in gameSession: GameSession) -> Player? {
        let player = gameSession.availablePlayers.first(where: { $0.apiId == apiId })
        if player == nil {
            print("❌ Player with API ID \(apiId) not found in availablePlayers")
            print("   Available API IDs: \(gameSession.availablePlayers.compactMap { $0.apiId }.prefix(10))")
        } else {
            print("✅ Found player: \(player!.name) with API ID \(apiId)")
        }
        return player
    }
    
    // MARK: - Player Status Updates
    
    func updatePlayerStatus(_ player: Player, status: Player.SubstitutionStatus) -> Player {
        var updatedPlayer = player
        updatedPlayer.substitutionStatus = status
        return updatedPlayer
    }
    
    // MARK: - Roster Updates
    
    func updateParticipantRoster(
        participantIndex: Int,
        playerOff: Player,
        playerOn: Player,
        in gameSession: GameSession
    ) {
        // Remove player going off from active players
        if let activeIndex = gameSession.participants[participantIndex].selectedPlayers.firstIndex(where: { $0.id == playerOff.id }) {
            gameSession.participants[participantIndex].selectedPlayers.remove(at: activeIndex)
        }
        
        // Add player going off to substituted players list
        gameSession.participants[participantIndex].substitutedPlayers.append(playerOff)
        
        // Add new player to active players
        gameSession.participants[participantIndex].selectedPlayers.append(playerOn)
        
        print("   Updated roster for \(gameSession.participants[participantIndex].name)")
        print("   Active players: \(gameSession.participants[participantIndex].selectedPlayers.count)")
        print("   Substituted players: \(gameSession.participants[participantIndex].substitutedPlayers.count)")
    }
    
    func updateSessionPlayerLists(
        playerOff: Player,
        playerOn: Player,
        in gameSession: GameSession
    ) {
        // Update session-level selectedPlayers
        gameSession.selectedPlayers.removeAll { $0.id == playerOff.id }
        if !gameSession.selectedPlayers.contains(where: { $0.id == playerOn.id }) {
            gameSession.selectedPlayers.append(playerOn)
        }
        
        print("   Updated session player lists")
        print("   Selected players count: \(gameSession.selectedPlayers.count)")
    }
    
    func updateAvailablePlayersStatuses(
        playerOff: Player,
        playerOn: Player,
        in gameSession: GameSession
    ) {
        // Update player going off status in availablePlayers
        if let index = gameSession.availablePlayers.firstIndex(where: { $0.id == playerOff.id }) {
            gameSession.availablePlayers[index] = playerOff
        }
        
        // Update player coming on status in availablePlayers
        if let index = gameSession.availablePlayers.firstIndex(where: { $0.id == playerOn.id }) {
            gameSession.availablePlayers[index] = playerOn
        }
        
        print("   Updated available players statuses")
    }
    
    // MARK: - Timeline Event Creation
    
    func createSubstitutionTimelineEvent(
        substitution: Substitution,
        source: SubstitutionSource,
        in gameSession: GameSession
    ) {
        // Create a timeline event for the substitution
        let eventName = "Substitution: \(substitution.from.name) → \(substitution.to.name)"
        
        let substitutionEvent = GameEvent(
            player: substitution.from,
            eventType: .custom,
            timestamp: substitution.timestamp,
            minute: substitution.minute,
            customEventName: eventName
        )
        
        // Add to events list for timeline display
        gameSession.events.append(substitutionEvent)
        
        print("   Added substitution to timeline: \(eventName)")
        print("   Total events: \(gameSession.events.count)")
    }
    
    // MARK: - Live Mode UI Integration
    
    /// Get formatted live substitution status for UI
    func getLiveSubstitutionStatusForUI(in gameSession: GameSession) -> String {
        let totalSubs = gameSession.substitutions.count
        let liveSubs = gameSession.events.filter {
            $0.customEventName?.contains("Substitution") == true
        }.count
        
        if gameSession.isLiveMode {
            return "Live substitutions: \(liveSubs)/\(totalSubs) total"
        } else {
            return "Manual substitutions: \(totalSubs)"
        }
    }
    
    /// Check if more substitutions are allowed (typically 3-5 per team)
    func canMakeMoreSubstitutions(for team: Team, in gameSession: GameSession) -> Bool {
        let teamSubstitutions = gameSession.substitutions.filter { $0.team.id == team.id }
        return teamSubstitutions.count < 5 // FIFA allows up to 5 substitutions
    }
    
    /// Get remaining substitutions for a team
    func getRemainingSubstitutions(for team: Team, in gameSession: GameSession) -> Int {
        let teamSubstitutions = gameSession.substitutions.filter { $0.team.id == team.id }
        return max(0, 5 - teamSubstitutions.count)
    }
}

// MARK: - Supporting Types

enum SubstitutionSource {
    case manual      // User-initiated substitution
    case liveAPI     // API-driven substitution in live mode
    case automatic   // System-driven substitution (future use)
    
    var description: String {
        switch self {
        case .manual: return "Manual"
        case .liveAPI: return "Live API"
        case .automatic: return "Automatic"
        }
    }
}

// MARK: - Debug Extensions

#if DEBUG
extension SubstitutionManager {
    
    func debugSubstitutionState(in gameSession: GameSession) -> String {
        var debug = """
        🔄 Substitution Debug State:
        - Total substitutions: \(gameSession.substitutions.count)
        - Events with substitutions: \(gameSession.events.filter { $0.customEventName?.contains("Substitution") == true }.count)
        
        """
        
        for (index, participant) in gameSession.participants.enumerated() {
            debug += """
            Participant \(index + 1): \(participant.name)
            - Active players: \(participant.selectedPlayers.count)
            - Substituted players: \(participant.substitutedPlayers.count)
            
            """
        }
        
        if !gameSession.substitutions.isEmpty {
            debug += "Recent substitutions:\n"
            for sub in gameSession.substitutions.suffix(3) {
                let timeStr = sub.minute != nil ? " (\(sub.minute!)')" : ""
                debug += "- \(sub.from.name) → \(sub.to.name)\(timeStr)\n"
            }
        }
        
        return debug
    }
    
    @MainActor func testSubstitutionFlow(in gameSession: GameSession) -> Bool {
        guard gameSession.participants.count > 0,
              gameSession.selectedPlayers.count >= 2 else {
            print("❌ Not enough data for substitution test")
            return false
        }
        
        let playerOff = gameSession.selectedPlayers[0]
        let playerOn = gameSession.selectedPlayers[1]
        
        let initialSubCount = gameSession.substitutions.count
        let initialEventCount = gameSession.events.count
        
        // Test manual substitution
        processManualSubstitution(
            playerOff: playerOff,
            playerOn: playerOn,
            minute: 65,
            in: gameSession
        )
        
        let substitutionAdded = gameSession.substitutions.count == initialSubCount + 1
        let eventAdded = gameSession.events.count == initialEventCount + 1
        
        print("🧪 Substitution test results:")
        print("   Substitution recorded: \(substitutionAdded ? "✅" : "❌")")
        print("   Timeline event added: \(eventAdded ? "✅" : "❌")")
        
        return substitutionAdded && eventAdded
    }
}
#endif
