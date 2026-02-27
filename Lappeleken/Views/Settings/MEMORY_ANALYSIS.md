# Memory Usage Analysis - Lucky Football Slip

## Executive Summary

Based on analysis of the codebase, here are the primary sources of memory consumption and recommendations for optimization.

## 🔴 Critical Memory Issues

### 1. **GameSession Object Retention**
**Location:** `GameSession.swift`, `ContentView.swift`, various views  
**Impact:** HIGH

**Problem:**
- `GameSession` is passed as `@ObservedObject` to multiple views simultaneously
- Contains large arrays: `events`, `participants`, `availablePlayers`, `selectedPlayers`, `matchEvents`, `matchLineups`
- Each view holds a strong reference, preventing deallocation
- Long-running monitoring tasks (`matchMonitoringTask`, `matchMonitoringTasks`) continue even when not visible

**Memory Cost:** 
- Base GameSession: ~5-10 KB
- Per event: ~1-2 KB (can accumulate to 100+ KB in long games)
- Per player: ~500 bytes (20 players = ~10 KB)
- Match data: ~50-100 KB
- **Total potential: 200+ KB per active session**

**Recommendation:**
```swift
// Use @StateObject for ownership, @ObservedObject for observation only
struct GameView: View {
    @StateObject var gameSession = GameSession() // Owns lifecycle
    
    // Clean up when view disappears
    .onDisappear {
        gameSession.cleanup()
    }
}

// Add cleanup method to GameSession
func cleanup() {
    matchMonitoringTask?.cancel()
    matchMonitoringTasks.values.forEach { $0.cancel() }
    matchMonitoringTasks.removeAll()
}
```

### 2. **NSCache in UnifiedCacheManager**
**Location:** `UnifiedCacheManager.swift`  
**Impact:** MEDIUM-HIGH

**Problem:**
- Cache limit set to 50 MB but stores Codable objects
- No automatic cleanup of expired entries (relies on NSCache's internal logic)
- Stores duplicate data (individual matches + match collections)
- Cache warming (`warmCache`) can pre-load unnecessary data

**Memory Cost:** Up to 50 MB

**Current Configuration:**
```swift
cache.countLimit = 1000 // Max 1000 entries
cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
```

**Recommendations:**
1. Reduce cache limit for non-iPad devices:
```swift
private init() {
    let isIPad = UIDevice.current.userInterfaceIdiom == .pad
    cache.countLimit = isIPad ? 1000 : 500
    cache.totalCostLimit = isIPad ? 50_000_000 : 25_000_000
    
    // More aggressive memory warning handling
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(handleMemoryWarning),
        name: UIApplication.didReceiveMemoryWarningNotification,
        object: nil
    )
}

@objc private func handleMemoryWarning() {
    cache.removeAllObjects()
    print("⚠️ Memory warning - cleared cache")
}
```

2. Implement smart cache invalidation:
```swift
func cleanupOldEntries() {
    // NSCache handles this internally, but we can be more aggressive
    let oldKeys = /* track keys older than 1 hour */
    oldKeys.forEach { clearCache(for: $0) }
}
```

### 3. **Multiple View Hierarchies**
**Location:** `ContentView.swift`, `GameView.swift`  
**Impact:** MEDIUM

**Problem:**
- `TabView` in `GameView` keeps all 5 tabs in memory simultaneously
- `NavigationView` in multiple sheets creates nested navigation stacks
- Complex view hierarchies with many `@State` variables

**Memory Cost:** ~50-100 KB per tab × 5 = 250-500 KB

**Recommendation:**
```swift
// Use lazy loading for tabs
TabView(selection: $selectedTab) {
    Group {
        if selectedTab == 0 {
            participantsWithStatsView
        }
    }
    .tabItem { Label("Participants", systemImage: "person.3.fill") }
    .tag(0)
    
    // Repeat for other tabs
}
```

## 🟡 Moderate Memory Issues

### 4. **Event Arrays and History**
**Location:** `GameSession.swift`, `TimelineView.swift`, `HistoryView.swift`

**Problem:**
- Events array grows unbounded during long games
- `HistoryView` loads all saved games at once
- Each `GameEvent` stores complete `Player` objects (not just IDs)

**Memory Cost:** 
- 100 events × 1 KB = 100 KB
- 50 saved games × 200 KB = 10 MB

**Recommendations:**
1. Implement event pagination:
```swift
// In TimelineView
let recentEvents = gameSession.events.suffix(50) // Only show last 50
```

2. Use player IDs instead of full objects:
```swift
struct GameEvent {
    let playerId: String  // Instead of player: Player
    let eventType: Bet.EventType
    // ...
}
```

3. Lazy load saved games in HistoryView:
```swift
@State private var visibleGames: [SavedGameSession] = []
@State private var loadedCount = 20

var body: some View {
    List {
        ForEach(visibleGames) { game in
            GameRow(game: game)
        }
        
        if visibleGames.count < savedGames.count {
            LoadMoreButton {
                loadMore()
            }
        }
    }
}
```

### 5. **Notification Observers**
**Location:** Throughout app (ContentView, GameSession, etc.)

**Problem:**
- Multiple `NotificationCenter` observers not always removed
- Can cause retain cycles if not properly managed

**Recommendation:**
```swift
class GameSession: ObservableObject {
    private var observers: [NSObjectProtocol] = []
    
    init() {
        let observer = NotificationCenter.default.addObserver(
            forName: Notification.Name("AppModeChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleModeChange()
        }
        observers.append(observer)
    }
    
    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }
}
```

### 6. **Published Properties Over-Publishing**
**Location:** `GameSession.swift`

**Problem:**
- 20+ `@Published` properties cause frequent UI updates
- Each update triggers view re-renders

**Recommendation:**
```swift
// Group related properties
struct GameState {
    var isLiveMode: Bool
    var canUndoLastEvent: Bool
    var hasBeenSaved: Bool
}

@Published var gameState = GameState()

// Or use manual objectWillChange
func updateBalance() {
    // Make changes
    participant.balance += amount
    
    // Manually trigger update once at the end
    objectWillChange.send()
}
```

## 🟢 Minor Optimization Opportunities

### 7. **View Body Complexity**
**Location:** `GameView.swift`, `HomeView.swift`

**Issue:** Complex computed properties recalculated on every render

**Recommendation:**
```swift
// Cache expensive computations
@State private var cachedStats: GameStats?

var body: some View {
    // ...
    .onReceive(gameSession.$events) { _ in
        cachedStats = calculateStats()
    }
}
```

### 8. **Image Loading**
**Location:** Team crests, player photos (if any)

**Recommendation:**
```swift
// Use AsyncImage with proper memory management
AsyncImage(url: URL(string: team.crest)) { phase in
    switch phase {
    case .success(let image):
        image
            .resizable()
            .scaledToFit()
    case .empty, .failure:
        Image(systemName: "photo")
    @unknown default:
        EmptyView()
    }
}
.frame(width: 40, height: 40)
```

### 9. **String Formatting Redundancy**
**Location:** Multiple views creating `NumberFormatter` instances

**Recommendation:**
```swift
// Create shared formatters
extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        return formatter
    }()
}

// Use: NumberFormatter.currency.string(from: NSNumber(value: amount))
```

## 📊 Estimated Memory Savings

| Optimization | Current | Optimized | Savings |
|--------------|---------|-----------|---------|
| GameSession cleanup | 200 KB | 50 KB | 150 KB |
| Cache limits | 50 MB | 25 MB | 25 MB |
| TabView lazy loading | 500 KB | 100 KB | 400 KB |
| Event pagination | 100 KB | 20 KB | 80 KB |
| History lazy loading | 10 MB | 2 MB | 8 MB |
| **Total** | **~60 MB** | **~27 MB** | **~33 MB (55%)** |

## 🎯 Priority Action Items

### Immediate (Do First)
1. ✅ Add `cleanup()` method to `GameSession` and call in `onDisappear`
2. ✅ Reduce cache limits based on device type
3. ✅ Fix notification observer retention with `weak self`

### Short Term (Next Week)
4. Implement lazy tab loading in `GameView`
5. Add event pagination to `TimelineView`
6. Implement lazy loading in `HistoryView`

### Long Term (Future)
7. Refactor `GameEvent` to use player IDs
8. Create shared formatter instances
9. Profile with Instruments to verify improvements

## 🔧 Monitoring Tools

Use these Xcode tools to verify improvements:

1. **Memory Graph Debugger**: Debug → Memory Graph (⌘+⇧+M)
   - Look for retain cycles
   - Check object allocation counts

2. **Instruments - Leaks**: Profile → Leaks
   - Detect memory leaks
   - Track leaked objects

3. **Instruments - Allocations**: Profile → Allocations
   - Monitor heap usage over time
   - Identify memory growth patterns

## 📝 Testing Checklist

Before/after each optimization:
- [ ] Launch app and navigate to GameView
- [ ] Record 50+ events
- [ ] Switch between all tabs
- [ ] Open and close HistoryView
- [ ] Start/stop live mode multiple times
- [ ] Check memory in Xcode Debug Navigator
- [ ] Verify no crashes under memory pressure

## 🎓 Best Practices Going Forward

1. **Use `@StateObject` for ownership, `@ObservedObject` for passing**
2. **Always implement cleanup in `onDisappear` or `deinit`**
3. **Limit published properties - batch updates when possible**
4. **Use lazy loading for lists > 20 items**
5. **Profile regularly with Instruments**
6. **Test on older devices (iPhone SE, iPad Mini)**

---

Generated: 2026-02-26  
Author: AI Code Analysis  
Next Review: After implementing top 3 priority items
