//
//  ActiveGameStore.swift
//  Lucky Football Slip
//
//  Crash/termination recovery for the game currently being played.
//

import Foundation
import Combine
import UIKit

/// Keeps a single always-current snapshot of the in-progress game on disk, so a
/// game survives the app being terminated in the background (which iOS does
/// routinely once the phone has been asleep for a while).
///
/// This is deliberately separate from `GameHistoryManager`:
///
///  - History is a *user* action — named saves the player chose to keep, and a
///    growing list of them. This is one slot, overwritten constantly, invisible
///    until it's needed.
///  - History lives in `UserDefaults`. That's the wrong home for this: UserDefaults
///    is read into memory wholesale, and its writes are flushed lazily, so the
///    write you care about — the one right before iOS kills you — is exactly the
///    one that can be lost. This writes a file atomically instead, so a snapshot
///    is durable the moment `saveNow()` returns and a kill mid-write can never
///    leave a half-written file behind.
@MainActor
final class ActiveGameStore: ObservableObject {
    static let shared = ActiveGameStore()

    /// Bump when the snapshot format changes in a way older builds can't read.
    private static let currentSchemaVersion = 1

    /// A snapshot older than this is treated as stale and dropped on launch — a
    /// half-finished game from last month isn't something to offer to resume.
    private static let maxSnapshotAge: TimeInterval = 24 * 60 * 60

    /// How long to coalesce rapid changes before writing. Events arrive in bursts
    /// (a goal updates balances, stats and the timeline in the same tick); this
    /// keeps that to one write.
    private static let debounceInterval: TimeInterval = 2.0

    struct Snapshot: Codable {
        let schemaVersion: Int
        let savedAt: Date
        let gameName: String?
        let session: GameSession

        var isLiveMode: Bool { session.isLiveMode }
        var participantNames: [String] { session.participants.map { $0.name } }
        var eventCount: Int { session.events.count }
    }

    @Published private(set) var lastSavedAt: Date?

    private var trackedSession: GameSession?
    private var changeSubscription: AnyCancellable?
    private var debounceTask: Task<Void, Never>?

    private let fileManager = FileManager.default
    /// Serialises writes so a debounced save and a lifecycle save can't interleave.
    private let writeQueue = DispatchQueue(label: "com.luckyfootballslip.activegamestore", qos: .utility)

    private init() {}

    // MARK: - File location

    private var storeDirectory: URL? {
        guard let base = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let directory = base.appendingPathComponent("ActiveGame", isDirectory: true)

        if !fileManager.fileExists(atPath: directory.path) {
            do {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                // The in-progress game is recreatable state, not user documents.
                var mutable = directory
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try? mutable.setResourceValues(values)
            } catch {
                print("❌ ActiveGameStore: could not create store directory: \(error)")
                return nil
            }
        }
        return directory
    }

    private var snapshotURL: URL? {
        storeDirectory?.appendingPathComponent("active-game.json")
    }

    // MARK: - Tracking

    /// Start autosaving `session`. Every change to the session schedules a
    /// debounced write; call this when a game actually starts being played.
    func beginTracking(_ session: GameSession, gameName: String? = nil) {
        trackedSession = session

        changeSubscription = session.objectWillChange
            .sink { [weak self] _ in
                self?.scheduleSave()
            }

        // Write one immediately so a game that is killed before its first event
        // still comes back.
        saveNow(name: gameName)
        print("💾 ActiveGameStore: tracking game \(session.id)")
    }

    /// Stop autosaving and remove the snapshot. Call this when a game legitimately
    /// ends — the player finished it, reset it, or discarded the recovered copy.
    func endTracking() {
        debounceTask?.cancel()
        debounceTask = nil
        changeSubscription = nil
        trackedSession = nil
        clear()
        print("💾 ActiveGameStore: stopped tracking")
    }

    private func scheduleSave() {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(Self.debounceInterval * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self?.saveNow()
        }
    }

    // MARK: - Writing

    /// Write the tracked session to disk immediately. Safe to call when nothing is
    /// being tracked — it just does nothing.
    func saveNow(name: String? = nil) {
        guard let session = trackedSession else { return }
        guard isWorthSaving(session) else { return }

        debounceTask?.cancel()
        debounceTask = nil

        let snapshot = Snapshot(
            schemaVersion: Self.currentSchemaVersion,
            savedAt: Date(),
            gameName: name ?? session.currentSaveName,
            session: session
        )

        // Encode on the main actor — the session's @Published properties belong to
        // it — then hand the finished bytes off so the disk write never blocks UI.
        let data: Data
        do {
            data = try JSONEncoder().encode(snapshot)
        } catch {
            print("❌ ActiveGameStore: encode failed: \(error)")
            return
        }

        guard let url = snapshotURL else { return }

        writeQueue.async {
            do {
                try data.write(to: url, options: [.atomic])
            } catch {
                print("❌ ActiveGameStore: write failed: \(error)")
            }
        }

        lastSavedAt = snapshot.savedAt
    }

    /// A game with no participants is a half-built setup, not something to resume.
    private func isWorthSaving(_ session: GameSession) -> Bool {
        !session.participants.isEmpty
    }

    // MARK: - Reading

    /// The recoverable game, if there is a usable one. Returns nil (and cleans up)
    /// for a missing, stale, corrupt, or future-schema snapshot.
    func loadSnapshot() -> Snapshot? {
        guard let url = snapshotURL, fileManager.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let snapshot = try JSONDecoder().decode(Snapshot.self, from: data)

            guard snapshot.schemaVersion <= Self.currentSchemaVersion else {
                print("⚠️ ActiveGameStore: snapshot from a newer build, ignoring")
                return nil
            }

            guard Date().timeIntervalSince(snapshot.savedAt) < Self.maxSnapshotAge else {
                print("🕒 ActiveGameStore: snapshot is stale, discarding")
                clear()
                return nil
            }

            guard !snapshot.session.participants.isEmpty else {
                clear()
                return nil
            }

            return snapshot
        } catch {
            // A snapshot we can't read is worse than none — drop it so the app
            // doesn't offer a broken resume on every launch.
            print("❌ ActiveGameStore: could not read snapshot, discarding: \(error)")
            clear()
            return nil
        }
    }

    var hasResumableGame: Bool {
        loadSnapshot() != nil
    }

    func clear() {
        guard let url = snapshotURL else { return }
        try? fileManager.removeItem(at: url)
        lastSavedAt = nil
    }
}
