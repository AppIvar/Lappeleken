Lucky Football Slip — Project Context & Refactor Plan
What the app is
A SwiftUI iOS app ("Lappeleken"): participants are assigned real football players and
their virtual balances go up/down based on live match events (goals, cards, subs) from
the football-data.org v4 API. Two modes: Live (API-driven) and Manual.
Paid football-data.org plan (~€29/mo). Published; Bundle ID HovlandGames.Lucky-Football-Slip.
Core principles (do not regress these)

No fabricated data, ever. No random/mock event generation in production paths. Live
API events reference real player IDs/names; fake players break the core mechanic and
misattribute balances. Prefer a clear error over silent fallback to fake data.
Single source of truth. Payout math lives ONLY in GameLogicManager. Monitoring runs
through ONE system (EventDrivenManager). Player data duplication is a known risk.
The rate limiter must see every API call. All football-data.org calls go through
APIClient.footballDataRawData / footballDataRequest (which record calls). Never add
raw URLSession calls to the API — they bypass the limiter.
Incremental & verified. Build after each change. Prefer changed-function diffs over
whole-file rewrites. Explain scope/risk before large changes. Use AppConfig feature
flags for risky migrations.

Refactor status
DONE

Phase 0 — Removed all fabricated event generation (BackgroundTaskManager,
EventSyncManager). Made APIClient the single rate-limited path; the five raw-URLSession
methods in FootballDataMatchService now route through apiClient.footballDataRawData.
Phase 1 — Merged custom-event betting into GameLogicManager (single payout
calculator via resolveBet). Replaced recompute-based undo with a balance-snapshot stack
on GameSession (balanceSnapshots). Exact, immune to ownership changes.
Phase 2 (monitoring convergence) — EventDrivenManager is now the SINGLE foreground
monitor. Removed dead code (setupEventDrivenMode, startRealEventDrivenModeForAllMatches,
startMonitoringMatches, stopAllMonitoring, smart-monitoring + processMatchUpdate +
matchMonitoringTask). Added fetchMatchSnapshot (ONE fetch → match status/score + events,
fixing the old double-fetch). Monitor routes all events through processLiveEvent (dedup).
Killed the as! FootballDataMatchService force-cast in EventDrivenManager.init.
Phase 2a (notifications) — Real per-event local notifications (UNUserNotification)
fired from EventDrivenManager for tracked-player events (foreground + background window).
Real score/status diffing in BackgroundTaskManager (no fabrication).
API key — Removed hardcoded key from AppConfig; now loaded from Secrets.xcconfig
via Info.plist substitution; fatalError if missing. (Old key pending reissue from
football-data.org — do NOT make repo public until the new key is in and old one revoked.)

DONE — Cloudflare proxy
A Cloudflare Worker caches football-data.org responses so all devices share one cache
(fixes the shared-API-key rate-limit cliff). Worker files live in cloudflare-worker/
(worker.ts, wrangler.toml, SETUP.md), deployed at
https://lucky-football-slip-cache.ivarhovland.workers.dev — verified MISS then HIT.
Cache tiers: live match 15s, non-live match 5m, fixtures 10m, competitions/squads 24h;
stale-while-revalidate ON. iOS side: APIClient.buildRequestURL + AppConfig.CacheServer
route through the Worker; footballDataRawData falls back to a direct football-data.org
call if the cache server fails; fetchMatchSnapshot appends ?live=1 when
match.status.isLive so the Worker uses its 15s TTL; an optional X-Client-Secret
(CLIENT_SHARED_SECRET, stored via Secrets.xcconfig) is sent on cache-server requests.
AppConfig.CacheServer.baseURL points at the deployed *.workers.dev URL. The Worker
cache key strips ?live=1 (live + non-live reads of a match share one entry; live=1 only
picks the TTL); the client records the fallback as a second API call so the limiter stays
conservative during a Worker outage. (Removed the unused AppConfig.CacheServer.cacheTTL —
TTLs live only on the Worker.) Still needs: flip cacheServer_enabled on for real devices
once confirmed stable in testing.

TODO — Phase 3 (structure for longevity)

Introduce a ViewModel layer (views currently talk to GameSession directly).
Demote GameSession (god object: ~state + persistence + orchestration + stats) to
plain state + a small engine. Pair this with the full ServiceProvider → DataManager
consolidation (needs a game-data-service accessor on DataManager; rewrites GameSession
init paths). 12 ServiceProvider refs across 6 files; 2 remaining as! force-casts are in
debug harnesses.
Store players once by ID, reference everywhere else (kills 4–5x duplication + manual
stat-sync in updatePlayerStatsForEvent).
Add a real XCTest target (payout math + substitution ownership are the priorities).
No real tests exist yet; LiveModeTestRunner / DebugTestView are in-app harnesses that
should NOT ship in the production target.
Route ~500 print() calls through Debuglogger.

BACKLOG

Substitution undo: reverse roster swaps (move player from substitutedPlayers back to
selectedPlayers in participant + session lists, remove the substitution record + its
timeline event). Currently substitutions are intentionally non-undoable; undoLastEvent
only removes the timeline entry without touching rosters/balances.

Known gotchas

BackgroundTaskManager keys matches as Int (Int(selectedMatch.id) ?? 0) but match IDs
are String everywhere else. Works for numeric IDs; fragile. Has a TODO to compare
MatchStatus by rawValue instead of String(describing:).
MatchEvent initializer takes non-optional playerName: String though the stored property
is String?. FootballDataMatchService requires explicit apiClient + apiKey.
UserNotifications must be imported explicitly for UN-prefixed types.

Codebase orientation

Models (Codable structs): Player, Participant, Team, Bet, GameEvent,
Substitution, Match/MatchModels.
Central object: GameSession (ObservableObject; god object — being decomposed).
Logic: GameLogicManager (payouts/undo), SubstitutionManager.
Data: DataManager (preferred front door), ServiceProvider (legacy, to be removed),
APIClient, APIRateLimiter, UnifiedCacheManager (in-memory NSCache),
FootballDataMatchService.
Live monitoring: EventDrivenManager (the one foreground monitor) + BackgroundTaskManager.

Conventions to keep
Live Mode bets: the live API only produces goal/assist/yellow/red (own goals + penalties
arrive as goals; penaltyMissed/cleanSheet never fire). Live bet setup must list only
Bet.EventType.liveAPISupported — never surface API-unsupported types in the live flow.
Manual mode legitimately uses the full Bet.EventType set (hand-triggered).
Setup UI: new/edited setup screens should reuse the shared SetupComponents
(NewGameSetup style — SetupStepHeader, ParticipantRowNew, etc.) rather than defining
bespoke per-view structs. LiveGameSetupView has been partially migrated to these.
Match list: Live setup fetches upcoming matches over a 7-day window
(fetchUpcomingMatches(days:)); DataManager also merges the last 1 day of finished
matches, shown with their final score (Match now carries an optional score, populated
in APIMatch.toAppModel). Match reminders are owned by MatchReminderManager (singleton):
schedules a local notification 30 min before kickoff, persists reminder match ids in
UserDefaults, identifier match_reminder_<id>, reusing the app's existing
UNUserNotification auth/delegate. If permission is denied the bell stays off and the
setup view shows an enable-in-Settings hint.
