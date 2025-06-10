//
//  TestConfiguration.swift
//  Lucky Football Slip
//
//  Test configuration for switching between real and mock services
//

import Foundation
import SwiftUI

class TestConfiguration: ObservableObject {
    static let shared = TestConfiguration()
    
    @Published var isTestMode: Bool {
        didSet {
            UserDefaults.standard.set(isTestMode, forKey: "isTestMode")
            NotificationCenter.default.post(
                name: Notification.Name("TestModeChanged"),
                object: nil
            )
        }
    }
    
    @Published var mockService: MockFootballDataService?
    
    private init() {
        self.isTestMode = UserDefaults.standard.bool(forKey: "isTestMode")
        
        if isTestMode {
            self.mockService = MockFootballDataService()
        }
    }
    
    func enableTestMode() {
        isTestMode = true
        mockService = MockFootballDataService()
        print("🧪 Test mode enabled - using mock football service")
    }
    
    func disableTestMode() {
        isTestMode = false
        mockService = nil
        print("🌐 Test mode disabled - using real football API")
    }
    
    func resetTestMatch() {
        mockService?.resetMatch()
        print("🔄 Test match reset")
    }
    
    func forceMatchState(_ state: MockFootballDataService.MockMatchState) {
        mockService?.forceMatchState(state)
        print("🎯 Forced match state to: \(state)")
    }
    
    func simulateGoal(for teamName: String) {
        // This would need to be called with proper team reference
        print("⚽ Simulating goal for \(teamName)")
    }
    
    // MARK: - Test Scenarios
    
    func runTestScenario(_ scenario: TestScenario) {
        guard let mockService = mockService else {
            print("❌ Mock service not available - Test mode might not be properly enabled")
            return
        }
        
        print("🎬 Running test scenario: \(scenario.rawValue)")
        
        switch scenario {
        case .matchStarting:
            mockService.forceMatchState(.justStarted)
            
        case .firstHalfAction:
            mockService.forceMatchState(.firstHalf)
            mockService.addTestEvent("goal")
            mockService.addTestEvent("yellow_card")
            
        case .halftime:
            mockService.forceMatchState(.halftime)
            
        case .secondHalfDrama:
            mockService.forceMatchState(.secondHalf)
            mockService.addTestEvent("goal")
            mockService.addTestEvent("red_card")
            mockService.addTestEvent("substitution")
            
        case .matchFinished:
            mockService.forceMatchState(.finished)
        }
        
        print("✅ Test scenario '\(scenario.rawValue)' executed")
    }
    
    // MARK: - Test Actions
    
    func addTestEvent(_ eventType: String) {
        guard let mockService = mockService else {
            print("❌ Mock service not available")
            return
        }
        
        // Ensure we have a current match for testing
        ensureCurrentMatchForTesting()
        
        // Add event to mock service
        mockService.addTestEvent(eventType)
        print("🎯 Added test event to mock service: \(eventType)")
        
        // DON'T trigger the bridge here - let the monitoring handle it naturally
    }
    
    func simulateRandomGoal() {
        addTestEvent("goal")
    }
    
    // Direct test event triggering for the bridge
    func triggerTestEventDirectly(_ eventType: String) {
#if DEBUG
        print("🚀 Direct bridge trigger: \(eventType)")
        TestMonitoringBridge.shared.triggerTestEventManually(eventType)
#endif
    }
    
    // Helper to ensure we have an active match for testing
    private func ensureCurrentMatchForTesting() {
        guard let mockService = mockService else { return }
        
        // Check if we need to set a default current match for testing
        let debugInfo = mockService.getDebugInfo()
        if debugInfo.contains("Current Match: None") {
            print("🔧 No current match set, initializing test match...")
            // This will trigger the mock service to use the first available match
            mockService.addTestEvent("test_init") // This will set up the current match
        }
    }
}

enum TestScenario: String, CaseIterable {
    case matchStarting = "Match Starting"
    case firstHalfAction = "First Half Action"
    case halftime = "Halftime"
    case secondHalfDrama = "Second Half Drama"
    case matchFinished = "Match Finished"
    
    var description: String {
        switch self {
        case .matchStarting:
            return "Simulate a match that's just kicked off"
        case .firstHalfAction:
            return "First half with goal and yellow card"
        case .halftime:
            return "Match at halftime break"
        case .secondHalfDrama:
            return "Second half with goal, red card, and substitution"
        case .matchFinished:
            return "Match completed"
        }
    }
}
