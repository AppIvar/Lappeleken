//
//  EventDrivenManager.swift
//  Lucky Football Slip
//
//  Simplified event-driven system with clean API integration
//

import Foundation
import UserNotifications

// MARK: - Live Match Event

struct LiveMatchEvent {
    let id: String
    let type: LiveEventType
    let minute: Int
    let player: Player?
    let team: Team
    let timestamp: Date
    let description: String
    let substitutePlayer: Player?
    
    enum LiveEventType: String, CaseIterable {
        case goal = "GOAL"
        case assist = "ASSIST"
        case yellowCard = "YELLOW_CARD"
        case redCard = "RED_CARD"
        case substitution = "SUBSTITUTION"
        case penaltyMissed = "PENALTY_MISSED"
        case ownGoal = "OWN_GOAL"
        case penalty = "PENALTY"
        case kickoff = "KICKOFF"        // Add this
        case fulltime = "FULLTIME"      // Add this
        case unknown = "UNKNOWN"
    }
}

struct LiveMatchUpdate {
    let match: Match
    let newEvents: [LiveMatchEvent]
    let statusChanged: Bool
    let timestamp: Date
    
    init(match: Match, newEvents: [LiveMatchEvent], statusChanged: Bool = false) {
        self.match = match
        self.newEvents = newEvents
        self.statusChanged = statusChanged
        self.timestamp = Date()
    }
}

// MARK: - Event-Driven Manager

@MainActor
class EventDrivenManager: ObservableObject {
    static let shared = EventDrivenManager()
    
    private var activeGames: [String: GameEventMonitor] = [:]
    private let footballService: FootballDataMatchService
    
    private init() {
        let footballDataAPIClient = APIClient(baseURL: "https://api.football-data.org/v4")
        self.footballService = FootballDataMatchService(
            apiClient: footballDataAPIClient,
            apiKey: AppConfig.footballDataAPIKey
        )
        print("🎯 EventDrivenManager initialized")
    }
    
    func startMonitoring(for gameSession: GameSession) {
        guard gameSession.isLiveMode else {
            print("⚠️ Cannot start monitoring: not in live mode")
            return
        }
        
        print("🎯 Starting event monitoring for game \(gameSession.id)")
        
        // Stop any existing monitoring for this game session first
        stopMonitoring(for: gameSession)
        
        // Start monitoring for ALL selected matches
        for match in gameSession.selectedMatches {
            let monitorKey = "\(gameSession.id.uuidString)_\(match.id)"
            
            let monitor = GameEventMonitor(
                gameSession: gameSession,
                match: match,
                footballService: footballService,
                onUpdate: { [weak self] update in
                    Task { @MainActor in
                        self?.processEventUpdate(update, for: gameSession)
                    }
                }
            )
            
            activeGames[monitorKey] = monitor
            monitor.start()
            
            print("✅ Event monitoring started for match \(match.homeTeam.shortName) vs \(match.awayTeam.shortName)")
        }
    }
    
    func stopMonitoring(for gameSession: GameSession) {
        // Stop all monitors for this game session
        let keysToRemove = activeGames.keys.filter { $0.starts(with: gameSession.id.uuidString) }
        
        for key in keysToRemove {
            if let monitor = activeGames[key] {
                print("🛑 Stopping event monitoring for key: \(key)")
                monitor.stop()
                activeGames.removeValue(forKey: key)
            }
        }
    }
    
    private func processEventUpdate(_ update: LiveMatchUpdate, for gameSession: GameSession) {
        print("📡 Processing event update: \(update.newEvents.count) new events")

        for liveEvent in update.newEvents {
            // Build a MatchEvent and funnel EVERYTHING through processLiveEvent,
            // which owns dedup (processedEventIds) and substitution handling.
            let matchEvent = MatchEvent(
                id: liveEvent.id,
                type: liveEvent.type.rawValue,
                playerId: liveEvent.player?.apiId ?? "",
                playerName: liveEvent.player?.name ?? "",
                minute: liveEvent.minute,
                teamId: liveEvent.team.id.uuidString,
                playerOffId: liveEvent.type == .substitution ? liveEvent.player?.apiId : nil,
                playerOnId: liveEvent.type == .substitution ? liveEvent.substitutePlayer?.apiId : nil
            )

            gameSession.processLiveEvent(matchEvent)

            // In-app banner (foreground only) + real local notification (foreground + background window).
            if liveEvent.type != .substitution, liveEvent.player != nil {
                showMissedEventNotification(liveEvent, in: gameSession)
                scheduleEventNotification(liveEvent, in: gameSession)
            }
        }

        // Score/status now ride on the same update (statusChanged set by the monitor).
        if update.statusChanged {
            gameSession.selectedMatch = update.match
        }

        gameSession.objectWillChange.send()
    }
    
    /// Fire a real local notification for a detected, tracked-player event.
    /// Works in foreground (NotificationDelegate presents it) and the short background window.
    /// userInfo matches what NotificationDelegate reads (gameId, type) so taps open the game.
    private func scheduleEventNotification(_ event: LiveMatchEvent, in gameSession: GameSession) {
        guard let player = event.player else { return }

        let content = UNMutableNotificationContent()
        content.title = notificationTitle(for: event.type)
        let matchName = "\(gameSession.selectedMatch?.homeTeam.shortName ?? "")-\(gameSession.selectedMatch?.awayTeam.shortName ?? "")"
        content.body = matchName.isEmpty
            ? "\(player.name) — \(event.minute)'"
            : "\(player.name) — \(event.minute)' (\(matchName))"
        content.sound = .default
        content.userInfo = [
            "gameId": gameSession.id.uuidString,
            "type": event.type.rawValue
        ]

        // Stable identifier so the same event can't notify twice even across cycles.
        let identifier = "live_event_\(gameSession.id.uuidString)_\(event.id)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: nil)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule event notification: \(error)")
            }
        }
    }

    /// Short, event-appropriate notification title.
    private func notificationTitle(for type: LiveMatchEvent.LiveEventType) -> String {
        switch type {
        case .goal, .penalty:   return "⚽ GOAL!"
        case .ownGoal:          return "⚽ Own Goal"
        case .assist:           return "🅰️ Assist"
        case .yellowCard:       return "🟨 Yellow Card"
        case .redCard:          return "🟥 Red Card"
        case .penaltyMissed:    return "❌ Penalty Missed"
        default:                return "Match Update"
        }
    }
    
    private func showMissedEventNotification(_ event: LiveMatchEvent, in gameSession: GameSession) {
        let matchName = "\(gameSession.selectedMatch?.homeTeam.shortName ?? "HOME") vs \(gameSession.selectedMatch?.awayTeam.shortName ?? "AWAY")"
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NotificationCenter.default.post(
                name: Notification.Name("MissedEventsFound"),
                object: nil,
                userInfo: [
                    "eventCount": 1,
                    "matchName": matchName,
                    "eventType": event.type.rawValue,
                    "playerName": event.player?.name ?? "Unknown"
                ]
            )
        }
    }
    
    func getActiveGamesCount() -> Int {
        return activeGames.count
    }
    
    func getAllStats() -> String {
        return """
        Event-Driven Manager Stats:
        - Active Games: \(activeGames.count)
        - Game IDs: \(activeGames.keys.map { String($0.prefix(8)) }.joined(separator: ", "))
        - Monitoring: \(activeGames.values.map { "Match \(String($0.match.id.prefix(8)))" }.joined(separator: ", "))
        """
    }
}

// MARK: - Game Event Monitor

class GameEventMonitor {
    private let gameSession: GameSession
    var match: Match
    private let footballService: FootballDataMatchService
    private let onUpdate: (LiveMatchUpdate) -> Void
    
    private var monitoringTask: Task<Void, Never>?
    private var lastEventTime: Date?
    private var pollCount = 0
    private var previousEventIds: Set<String> = []
    
    init(gameSession: GameSession, match: Match, footballService: FootballDataMatchService, onUpdate: @escaping (LiveMatchUpdate) -> Void) {
        self.gameSession = gameSession
        self.match = match
        self.footballService = footballService
        self.onUpdate = onUpdate
    }
    
    func start() {
        print("▶️ Starting monitor for match \(match.id)")
        
        monitoringTask = Task {
            while !Task.isCancelled {
                await performMonitoringCycle()
            }
        }
    }
    
    func stop() {
        print("⏹️ Stopping monitor for match \(match.id)")
        monitoringTask?.cancel()
    }
    
    private func performMonitoringCycle() async {
        pollCount += 1

        do {
            guard APIRateLimiter.shared.canMakeCall() else {
                let waitTime = APIRateLimiter.shared.timeUntilNextCall()
                if AppConfig.enableDetailedLogging { print("⏳ Rate limited, waiting \(waitTime)s") }
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                return
            }

            // ONE call returns both the fresh match (status/score) and its events.
            let snapshot = try await footballService.fetchMatchSnapshot(matchId: match.id)
            let liveEvents = snapshot.events.compactMap { convertAPIEventToLiveEvent($0) }
            let newEvents = filterNewEvents(liveEvents)

            let statusChanged = snapshot.match.status != match.status
            self.match = snapshot.match   // keep status/score fresh for interval + next compare

            if !newEvents.isEmpty || statusChanged {
                let update = LiveMatchUpdate(
                    match: snapshot.match,
                    newEvents: newEvents,
                    statusChanged: statusChanged
                )
                onUpdate(update)
                if !newEvents.isEmpty {
                    lastEventTime = Date()
                    print("🎯 Found \(newEvents.count) new event(s) for \(match.homeTeam.shortName) vs \(match.awayTeam.shortName)")
                }
            }

            let interval = calculatePollingInterval()
            if AppConfig.enableDetailedLogging { print("⏰ Poll \(pollCount): next check in \(Int(interval))s") }
            try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))

        } catch {
            print("❌ Error in monitoring cycle: \(error)")
            try? await Task.sleep(nanoseconds: 300_000_000_000)
        }
    }
    
    private func convertAPIEventToLiveEvent(_ apiEvent: MatchEvent) -> LiveMatchEvent? {
        if apiEvent.type.lowercased() == "substitution" {
            // For substitutions, check if either player is in our tracked players
            let playerOffInSelection = gameSession.selectedPlayers.first { player in
                player.apiId == apiEvent.playerId ||
                player.name.lowercased() == (apiEvent.playerName ?? "").lowercased()
            }
            
            // Log only if the player going OFF is one we're tracking
            if playerOffInSelection == nil {
                // This is expected - we don't track all players, just selected ones
                // Substitution will still be processed by the game's substitution system
                return nil
            }
            
            guard let playerOnId = apiEvent.playerOnId else {
                print("⚠️ Substitution missing playerOnId for tracked player \(apiEvent.playerName ?? "unknown")")
                return nil
            }
            
            // Find the substitute player (might be in availablePlayers as a reserve)
            let playerOn = gameSession.availablePlayers.first { $0.apiId == playerOnId }
            
            return LiveMatchEvent(
                id: apiEvent.id,
                type: .substitution,
                minute: apiEvent.minute,
                player: playerOffInSelection,
                team: playerOffInSelection!.team,
                timestamp: Date(),
                description: "Substitution: \(playerOffInSelection!.name) OFF → \(playerOn?.name ?? "Unknown") ON",
                substitutePlayer: playerOn
            )
        }
        
        // Handle regular events...
        guard let player = findPlayerForEvent(apiEvent) else {
            return nil
        }
        
        let eventType = mapAPIEventTypeToLive(apiEvent.type)
        
        return LiveMatchEvent(
            id: apiEvent.id,
            type: eventType,
            minute: apiEvent.minute,
            player: player,
            team: player.team,
            timestamp: Date(),
            description: "\(player.name) - \(eventType.rawValue)",
            substitutePlayer: nil
        )
    }

    
    private func findPlayerForEvent(_ apiEvent: MatchEvent) -> Player? {
        return gameSession.selectedPlayers.first { player in
            player.apiId == apiEvent.playerId ||
            player.name.lowercased() == (apiEvent.playerName ?? "").lowercased()
        }
    }
    
    private func mapAPIEventTypeToLive(_ apiType: String) -> LiveMatchEvent.LiveEventType {
        switch apiType.uppercased() {
        case "REGULAR", "PENALTY", "OWN": return .goal
        case "ASSIST": return .assist // Custom type we create from goal assist data
        case "YELLOW": return .yellowCard
        case "RED": return .redCard
        case "SUBSTITUTION": return .substitution
        default: return .unknown
        }
    }
    
    private func filterNewEvents(_ events: [LiveMatchEvent]) -> [LiveMatchEvent] {
        let newEvents = events.filter { !previousEventIds.contains($0.id) }
        
        for event in newEvents {
            previousEventIds.insert(event.id)
        }
        
        return newEvents
    }
    
    
    private func calculatePollingInterval() -> TimeInterval {
        // NOTE: For launch, using 30s interval to stay well under API rate limits
        // With 30 calls/min limit: 30s interval = 2 calls/match/min
        // Can support 10+ simultaneous matches per user safely
        // TODO: When cache server is ready, can reduce to 15s via server-side caching
        
        switch match.status {
        case .inProgress, .halftime:
            return 30  // Poll every 30 seconds during match
        case .upcoming:
            let timeUntilStart = match.startTime.timeIntervalSinceNow
            return timeUntilStart < 300 ? 60 : 180  // More conservative pre-match
        case .completed, .finished:
            return 300  // 5 minutes after match ends
        case .postponed, .cancelled:
            return 600  // 10 minutes for postponed
        case .paused, .suspended:
            return 90   // 90 seconds for paused
        case .unknown:
            return 120  // 2 minutes for unknown status
        }
    }
}
