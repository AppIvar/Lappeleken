//
//  TestModeDebugView.swift
//  Lucky Football Slip
//
//  Debug interface for testing live mode functionality
//

import SwiftUI

#if DEBUG
struct TestModeDebugView: View {
    @StateObject private var testConfig = TestConfiguration.shared
    @State private var debugInfo = ""
    @State private var refreshTimer: Timer?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Test Mode Toggle
            HStack {
                Image(systemName: testConfig.isTestMode ? "flask.fill" : "flask")
                    .foregroundColor(testConfig.isTestMode ? .green : .gray)
                
                Text("Test Mode")
                    .font(.headline)
                
                Spacer()
                
                Toggle("", isOn: $testConfig.isTestMode)
                    .labelsHidden()
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(testConfig.isTestMode ? Color.green.opacity(0.1) : Color.gray.opacity(0.1))
            )
            
            if testConfig.isTestMode {
                VStack(alignment: .leading, spacing: 12) {
                    // Quick Actions
                    Text("Quick Actions")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        QuickActionButton("Reset Match", icon: "arrow.clockwise") {
                            testConfig.resetTestMatch()
                        }
                        
                        QuickActionButton("Simulate Goal", icon: "soccerball") {
                            testConfig.addTestEvent("goal")
                        }
                        
                        QuickActionButton("Yellow Card", icon: "square.fill") {
                            testConfig.addTestEvent("yellow_card")
                        }
                        
                        QuickActionButton("Substitution", icon: "arrow.left.arrow.right") {
                            testConfig.addTestEvent("substitution")
                        }
                        
                        QuickActionButton("Debug Match", icon: "eye") {
                            if let mockService = testConfig.mockService {
                                print("🔍 Current match debug:")
                                print("  - \(mockService.getDebugInfo())")
                                
                                // Try to manually trigger an event
                                mockService.addTestEvent("goal")
                                print("  - Added test goal")
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Test Scenarios
                    Text("Test Scenarios")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    ForEach(TestScenario.allCases, id: \.rawValue) { scenario in
                        TestScenarioButton(scenario: scenario) {
                            testConfig.runTestScenario(scenario)
                        }
                    }
                    
                    Divider()
                    
                    // Match State Controls
                    Text("Match State")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        MatchStateButton("Upcoming", state: .upcoming) {
                            testConfig.forceMatchState(.upcoming)
                        }
                        
                        MatchStateButton("Started", state: .justStarted) {
                            testConfig.forceMatchState(.justStarted)
                        }
                        
                        MatchStateButton("1st Half", state: .firstHalf) {
                            testConfig.forceMatchState(.firstHalf)
                        }
                        
                        MatchStateButton("Halftime", state: .halftime) {
                            testConfig.forceMatchState(.halftime)
                        }
                        
                        MatchStateButton("2nd Half", state: .secondHalf) {
                            testConfig.forceMatchState(.secondHalf)
                        }
                        
                        MatchStateButton("Finished", state: .finished) {
                            testConfig.forceMatchState(.finished)
                        }
                    }
                    
                    Divider()
                    
                    // Debug Info
                    Text("Debug Info")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    ScrollView {
                        Text(debugInfo.isEmpty ? "Enable test mode to see debug info" : debugInfo)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            startDebugRefresh()
        }
        .onDisappear {
            stopDebugRefresh()
        }
        .onChange(of: testConfig.isTestMode) { newValue in
            if newValue {
                startDebugRefresh()
            } else {
                stopDebugRefresh()
                debugInfo = ""
            }
        }
    }
    
    private func startDebugRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateDebugInfo()
        }
    }
    
    private func stopDebugRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func updateDebugInfo() {
        guard testConfig.isTestMode else { return }
        
        var info = ""
        
        // API Rate Limiter Info
        let apiStats = APIRateLimiter.shared.getUsageStats()
        info += "API Calls: \(apiStats.current)/\(apiStats.max)\n"
        
        // Cache Info
        let cacheStats = MatchCacheManager.shared.getCacheStats()
        info += "Cache: \(cacheStats.matches)M, \(cacheStats.lists)L, \(cacheStats.players)P\n"
        
        // Mock Service Info
        if let mockService = testConfig.mockService {
            info += mockService.getDebugInfo()
        }
        
        debugInfo = info
    }
}

// MARK: - Helper Views

struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    init(_ title: String, icon: String, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TestScenarioButton: View {
    let scenario: TestScenario
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(scenario.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
                
                Text(scenario.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.orange.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct MatchStateButton: View {
    let title: String
    let state: MockFootballDataService.MockMatchState
    let action: () -> Void
    
    init(_ title: String, state: MockFootballDataService.MockMatchState, action: @escaping () -> Void) {
        self.title = title
        self.state = state
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.bold())
                .foregroundColor(.white)
                .frame(height: 30)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(stateColor)
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var stateColor: Color {
        switch state {
        case .upcoming:
            return .gray
        case .justStarted:
            return .green
        case .firstHalf:
            return .blue
        case .halftime:
            return .orange
        case .secondHalf:
            return .purple
        case .finished:
            return .red
        }
    }
}
#endif
