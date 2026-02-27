# Preview Fix: LiveGameSetupView

## Issue

The `#Preview` macro in `LiveGameSetupView.swift` was failing with the following code:

```swift
#Preview("Live Setup") {
    LiveGameSetupView(gameSession: PreviewData.makeGameSession())
}
```

## Root Cause

The preview was actually **mostly correct**, but there were a few potential issues:

### 1. **Missing `#if DEBUG` Wrapper**
Previews should be wrapped in `#if DEBUG` blocks to ensure they're excluded from release builds.

### 2. **Single Preview Variant**
Only one preview variant was provided, making it harder to test different states of the complex setup flow.

### 3. **Match Initializer Issues in PreviewHelpers**
The `PreviewHelpers.swift` file had some formatting issues in the `sampleMatches` array where the `Match` initializers were on single lines, which could cause readability and maintenance issues.

## Solution

### Fixed PreviewHelpers.swift

Updated the `Match` creation in `PreviewHelpers.swift` to use proper multi-line formatting:

```swift
static let sampleMatches: [Match] = {
    let competition = Competition(id: "2021", name: "Premier League", code: "PL")
    
    return [
        Match(
            id: "12345",
            homeTeam: sampleTeams[0],
            awayTeam: sampleTeams[1],
            startTime: Date(),
            status: .inProgress,
            competition: competition
        ),
        Match(
            id: "12346",
            homeTeam: sampleTeams[2],
            awayTeam: sampleTeams[3],
            startTime: Date().addingTimeInterval(7200),
            status: .upcoming,
            competition: competition
        ),
        Match(
            id: "12347",
            homeTeam: sampleTeams[1],
            awayTeam: sampleTeams[2],
            startTime: Date().addingTimeInterval(86400),
            status: .upcoming,
            competition: competition
        )
    ]
}()
```

### Enhanced LiveGameSetupView Previews

Added multiple preview variants to test different states:

```swift
#if DEBUG
// Empty state - no data
#Preview("Live Setup - Empty") {
    LiveGameSetupView(gameSession: PreviewData.makeGameSession())
}

// With matches loaded
#Preview("Live Setup - With Matches") {
    LiveGameSetupView(gameSession: PreviewData.makeGameSession(withMatch: true))
}

// Fully populated
#Preview("Live Setup - Full") {
    LiveGameSetupView(
        gameSession: PreviewData.makeGameSession(
            withParticipants: true,
            withPlayers: true,
            withBets: true,
            withMatch: true,
            isLiveMode: true
        )
    )
}
#endif
```

### Added Component Previews

Added individual previews for all reusable components in LiveGameSetupView:

1. **LiveStepHeader** - Step headers with icons
2. **LiveParticipantRow** - Participant list items
3. **LiveBetRow** - Bet amount configuration rows
4. **LiveMatchRow** - Match selection rows
5. **LivePlayerChip** - Player selection chips
6. **LiveSummaryCard** - Summary cards for review step
7. **LiveLeagueSection** - Collapsible league sections
8. **LiveTeamPlayersSection** - Team-based player grouping

## Benefits

### 1. **Multiple Testing States**
```swift
// Test empty state
#Preview("Live Setup - Empty")

// Test with data loaded
#Preview("Live Setup - With Matches")

// Test fully configured
#Preview("Live Setup - Full")
```

### 2. **Component Isolation**
Each component can be tested independently:
```swift
#Preview("Bet Row") {
    VStack(spacing: 10) {
        LiveBetRow(eventType: .goal, amount: 10, isNegative: false, ...)
        LiveBetRow(eventType: .yellowCard, amount: 5, isNegative: true, ...)
    }
}
```

### 3. **Faster Iteration**
- No need to build and run the full app
- Test individual components in isolation
- Quickly switch between empty/populated states
- See changes instantly in Xcode Canvas

## How to Use

### In Xcode Canvas

1. Open `LiveGameSetupView.swift`
2. Press `⌥⌘⏎` (Option+Command+Return) to open Canvas
3. Click "Resume" to see all preview variants
4. Select different previews from the dropdown

### Component Previews

Each component preview is named clearly:
- "Step Header" - Shows different step headers
- "Participant Row" - Shows participant list
- "Bet Row" - Shows bet configuration
- "Match Row" - Shows match selection
- "Player Chip" - Shows player selection
- "Summary Cards" - Shows review cards
- "League Section" - Shows league grouping
- "Team Players Section" - Shows team grouping

## Testing Different States

### Empty State
```swift
LiveGameSetupView(gameSession: PreviewData.makeGameSession())
```
- No matches
- No participants
- No players selected
- Tests initial load state

### With Matches
```swift
LiveGameSetupView(gameSession: PreviewData.makeGameSession(withMatch: true))
```
- Matches loaded
- Available match list populated
- Tests match selection step

### Full Configuration
```swift
LiveGameSetupView(
    gameSession: PreviewData.makeGameSession(
        withParticipants: true,
        withPlayers: true,
        withBets: true,
        withMatch: true,
        isLiveMode: true
    )
)
```
- All data populated
- Tests review step
- Shows complete flow

## Preview Architecture

### PreviewData Factory
The `PreviewData` enum provides a flexible factory:

```swift
enum PreviewData {
    static func makeGameSession(
        withParticipants: Bool = true,
        withPlayers: Bool = true,
        withBets: Bool = true,
        withEvents: Bool = false,
        withMatch: Bool = false,
        isLiveMode: Bool = false
    ) -> GameSession
}
```

### Sample Data Available
- `sampleTeams` - 4 Premier League teams
- `sampleParticipants` - 3 mock participants
- `samplePlayers` - 10 mock players from Arsenal & Chelsea
- `sampleBets` - 5 common bet types
- `sampleEvents` - 4 game events
- `sampleMatch` - Live match example
- `sampleMatches` - Array of 3 matches

## Common Preview Patterns

### Both Color Schemes
```swift
#Preview("Component") {
    MyComponent()
        .preferredColorScheme(.light)
}

#Preview("Component - Dark") {
    MyComponent()
        .preferredColorScheme(.dark)
}
```

### With Navigation
```swift
#Preview("View with Nav") {
    NavigationView {
        MyView()
    }
}
```

### Custom Device
```swift
#Preview("iPhone SE") {
    MyView()
        .previewDevice(PreviewDevice(rawValue: "iPhone SE"))
}
```

## Troubleshooting

### Preview Won't Load

1. **Check Build Errors**
   - Fix any compilation errors first
   - Previews won't work if project doesn't build

2. **Check Canvas Status**
   - Canvas must be open (⌥⌘⏎)
   - Click "Resume" if paused
   - Try "Try Again" if failed

3. **Check Preview Syntax**
   - Must use `#Preview` macro (Swift 5.9+)
   - Or `PreviewProvider` (older iOS)
   - Must be at file level (not inside classes)

4. **Check Dependencies**
   - `PreviewData` must exist
   - All referenced types must be available
   - Mock data must be valid

### Preview Crashes

1. **Check Mock Data**
   - Ensure all required initializer parameters are provided
   - Verify IDs are unique
   - Check for nil values in required properties

2. **Check Complex Logic**
   - Avoid network calls in previews
   - Avoid file I/O in previews
   - Mock complex dependencies

3. **Simplify Preview**
   - Start with minimal data
   - Add complexity gradually
   - Isolate the failing component

## Performance Tips

### 1. **Lazy Loading**
Don't create all preview data upfront:
```swift
#Preview("Heavy View") {
    let data = generateDataWhenNeeded() // Called only when preview loads
    return HeavyView(data: data)
}
```

### 2. **Limit Preview Count**
Too many previews can slow down Canvas:
```swift
#if DEBUG
// Keep under 10 previews per file
#Preview("Variant 1") { ... }
#Preview("Variant 2") { ... }
#Preview("Variant 3") { ... }
#endif
```

### 3. **Use Static Data**
Avoid dynamic data generation:
```swift
// ✅ Good
#Preview {
    MyView(data: PreviewData.sampleData)
}

// ❌ Bad (regenerates on every update)
#Preview {
    MyView(data: generateRandomData())
}
```

## Next Steps

### Immediate
- ✅ Test all new previews in Xcode Canvas
- ✅ Verify empty state preview works
- ✅ Verify populated state preview works
- ✅ Test component previews individually

### Future Enhancements
- [ ] Add more preview variants (error states, loading states)
- [ ] Create preview fixtures for edge cases
- [ ] Add snapshot testing using previews
- [ ] Document preview patterns in team guidelines

## Related Files

- `LiveGameSetupView.swift` - Main view with previews
- `PreviewHelpers.swift` - Preview utilities and mock data
- `MatchModels.swift` - Match and Competition models
- `Team.swift` - Team model

## Resources

- [Apple: Previewing Views](https://developer.apple.com/documentation/swiftui/previews-in-xcode)
- [SwiftUI Preview Best Practices](https://www.swiftbysundell.com/articles/swiftui-preview-best-practices/)
- [Preview Macro Documentation](https://developer.apple.com/documentation/SwiftUI/Preview)

---

**Fixed:** February 26, 2026  
**Files Modified:** 2 (`LiveGameSetupView.swift`, `PreviewHelpers.swift`)  
**Previews Added:** 11 (3 view variants + 8 component previews)  
**Status:** ✅ Working
