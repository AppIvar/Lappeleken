//
//  MatchReminderManager.swift
//  Lucky Football Slip
//
//  Owns per-match kickoff reminders: schedules a local notification ~30 minutes
//  before a match starts, persists which matches have a reminder, and cancels on
//  toggle-off. Reuses the app-wide UNUserNotification setup (auth requested at
//  launch in LappelekenApp; NotificationDelegate handles presentation/taps).
//

import Foundation
import UserNotifications

@MainActor
final class MatchReminderManager: ObservableObject {
    static let shared = MatchReminderManager()

    /// How long before kickoff the reminder fires.
    static let leadTime: TimeInterval = 30 * 60

    private static let storageKey = "matchReminderIds"
    private let identifierPrefix = "match_reminder_"

    /// Match ids that currently have a reminder scheduled. Drives the bell UI.
    @Published private(set) var reminderMatchIds: Set<String>

    private init() {
        let stored = UserDefaults.standard.stringArray(forKey: Self.storageKey) ?? []
        reminderMatchIds = Set(stored)
    }

    func hasReminder(_ matchId: String) -> Bool {
        reminderMatchIds.contains(matchId)
    }

    /// Toggles a reminder for the match. Returns the new state (true = reminder set).
    /// Returns false (and sets nothing) if notification permission is denied.
    func toggleReminder(for match: Match) async -> Bool {
        if reminderMatchIds.contains(match.id) {
            cancelReminder(matchId: match.id)
            return false
        }

        guard await ensureAuthorized() else { return false }
        scheduleReminder(for: match)
        return reminderMatchIds.contains(match.id)
    }

    func cancelReminder(matchId: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier(for: matchId)])
        reminderMatchIds.remove(matchId)
        persist()
    }

    // MARK: - Private

    private func scheduleReminder(for match: Match) {
        // A reminder only makes sense before kickoff.
        guard match.startTime > Date() else { return }

        // Normally 30 min before; if the match is already inside that window but
        // hasn't started, fire almost immediately rather than skipping it.
        let idealFire = match.startTime.addingTimeInterval(-Self.leadTime)
        let fireDate = max(idealFire, Date().addingTimeInterval(5))

        let content = UNMutableNotificationContent()
        content.title = "⏰ Match starting soon"
        content.body = "\(match.homeTeam.shortName) vs \(match.awayTeam.shortName) kicks off in 30 minutes"
        content.sound = .default
        content.userInfo = [
            "type": "match_reminder",
            "matchId": match.id
        ]

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: identifier(for: match.id),
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule match reminder: \(error)")
            }
        }

        reminderMatchIds.insert(match.id)
        persist()
    }

    /// Requests authorization if undetermined; returns whether notifications are allowed.
    private func ensureAuthorized() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    private func identifier(for matchId: String) -> String {
        identifierPrefix + matchId
    }

    private func persist() {
        UserDefaults.standard.set(Array(reminderMatchIds), forKey: Self.storageKey)
    }
}
