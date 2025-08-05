//
//  DebugTestView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 15/07/2025.
//

import SwiftUI

#if DEBUG
struct DebugTestView: View {
    @State private var isRunningTests = false
    @State private var testResults: TestResults?
    @State private var currentTest = ""
    @State private var showingResults = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                headerView
                
                if isRunningTests {
                    runningTestsView
                } else {
                    testButtonsView
                }
                
                if let results = testResults {
                    resultsView(results)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Live Mode Debug")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 12) {
            Image(systemName: "gear.badge.checkmark")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            
            Text("Live Mode Testing")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Debug and test the live mode functionality")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var testButtonsView: some View {
        VStack(spacing: 16) {
            // Quick tests
            GroupBox("Quick Tests") {
                VStack(spacing: 12) {
                    testButton(
                        title: "API Integration",
                        icon: "network",
                        action: { await runQuickAPITest() }
                    )
                    
                    testButton(
                        title: "Betting Flow",
                        icon: "dollarsign.circle",
                        action: { await runQuickBettingTest() }
                    )
                    
                    testButton(
                        title: "Player Selection",
                        icon: "person.3",
                        action: { await runQuickPlayerTest() }
                    )
                    
                    testButton(
                        title: "Substitution Flow",
                        icon: "arrow.triangle.2.circlepath",
                        action: { await runQuickSubstitutionTest() }
                    )
                    
                    testButton(
                        title: "Smoke Test",
                        icon: "flame",
                        action: { await runSmokeTest() }
                    )
                    
                    testButton(
                        title: "Notification System",
                        icon: "bell",
                        action: { await runQuickNotificationTest() }
                    )
                }
            }
            
            // Full test suite
            GroupBox("Complete Testing") {
                VStack(spacing: 12) {
                    testButton(
                        title: "Full Test Suite",
                        icon: "checkmark.circle.fill",
                        action: { await runFullTestSuite() },
                        isPrimary: true
                    )
                    
                    testButton(
                        title: "Match Simulation",
                        icon: "play.circle",
                        action: { await runMatchSimulation() }
                    )
                }
            }
        }
    }
    
    private var runningTestsView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Running Tests...")
                .font(.headline)
            
            if !currentTest.isEmpty {
                Text(currentTest)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 100)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func resultsView(_ results: TestResults) -> some View {
        GroupBox("Test Results") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Duration: \(String(format: "%.2f", results.totalDuration))s")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("View Details") {
                        showingResults = true
                    }
                    .font(.caption)
                }
                
                let tests = [
                    ("API Integration", results.apiIntegration),
                    ("Event Processing", results.eventProcessing),
                    ("Betting Flow", results.bettingFlow),
                    ("Player Selection", results.playerSelection),
                    ("Match Monitoring", results.matchMonitoring),
                    ("Full Simulation", results.fullSimulation)
                ]
                
                ForEach(tests, id: \.0) { name, result in
                    HStack {
                        Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.passed ? .green : .red)
                        
                        Text(name)
                            .font(.subheadline)
                        
                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $showingResults) {
            TestResultsDetailView(results: results)
        }
    }
    
    private func testButton(title: String, icon: String, action: @escaping () async -> Void, isPrimary: Bool = false) -> some View {
        Button(action: {
            Task {
                await action()
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .frame(width: 20)
                
                Text(title)
                    .fontWeight(isPrimary ? .semibold : .regular)
                
                Spacer()
            }
            .padding()
            .background(isPrimary ? Color.blue : Color.gray.opacity(0.1))
            .foregroundColor(isPrimary ? .white : .primary)
            .cornerRadius(8)
        }
        .disabled(isRunningTests)
    }
    
    // MARK: - Test Actions
    
    private func runQuickAPITest() async {
        isRunningTests = true
        currentTest = "Testing API Integration..."
        
        await LiveModeTestRunner.shared.quickAPITest()
        
        isRunningTests = false
        currentTest = ""
    }
    
    private func runQuickBettingTest() async {
        isRunningTests = true
        currentTest = "Testing Betting Flow..."
        
        await LiveModeTestRunner.shared.quickBettingTest()
        
        isRunningTests = false
        currentTest = ""
    }
    
    private func runQuickPlayerTest() async {
        isRunningTests = true
        currentTest = "Testing Player Selection..."
        
        await LiveModeTestRunner.shared.quickPlayerSelectionTest()
        
        isRunningTests = false
        currentTest = ""
    }
    
    private func runSmokeTest() async {
        isRunningTests = true
        currentTest = "Running Smoke Test..."
        
        await LiveModeTestRunner.shared.smokeTest()
        
        isRunningTests = false
        currentTest = ""
    }
    
    private func runQuickSubstitutionTest() async {
        isRunningTests = true
        currentTest = "Testing Substitution Flow..."
        
        await LiveModeTestRunner.shared.quickSubstitutionTest()
        
        isRunningTests = false
        currentTest = ""
    }
    
    private func runFullTestSuite() async {
        isRunningTests = true
        currentTest = "Running Full Test Suite..."
        
        let results = await LiveModeTestRunner.shared.runCompleteTestSuite()
        self.testResults = results
        
        isRunningTests = false
        currentTest = ""
    }
    
    private func runMatchSimulation() async {
        isRunningTests = true
        currentTest = "Running Match Simulation..."
        
        do {
            let footballService = ServiceProvider.shared.getMatchService() as! FootballDataMatchService
            let result = try await footballService.simulateCompleteMatch(duration: 120)
            print("Match simulation result: \(result)")
        } catch {
            print("Match simulation failed: \(error)")
        }
        
        isRunningTests = false
        currentTest = ""
    }
    
    private func runQuickNotificationTest() async {
        isRunningTests = true
        currentTest = "Testing Notification System..."
        
        await LiveModeTestRunner.shared.quickNotificationTest()
        
        isRunningTests = false
        currentTest = ""
    }
}

struct TestResultsDetailView: View {
    let results: TestResults
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Summary") {
                    HStack {
                        Text("Total Duration")
                        Spacer()
                        Text("\(String(format: "%.2f", results.totalDuration))s")
                            .foregroundColor(.secondary)
                    }
                    
                    let passedCount = getPassedCount()
                    HStack {
                        Text("Tests Passed")
                        Spacer()
                        Text("\(passedCount)/6")
                            .foregroundColor(passedCount == 6 ? .green : .red)
                    }
                }
                
                let tests = [
                    ("API Integration", results.apiIntegration),
                    ("Event Processing", results.eventProcessing),
                    ("Betting Flow", results.bettingFlow),
                    ("Player Selection", results.playerSelection),
                    ("Match Monitoring", results.matchMonitoring),
                    ("Full Simulation", results.fullSimulation)
                ]
                
                ForEach(tests, id: \.0) { name, result in
                    Section(name) {
                        HStack {
                            Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(result.passed ? .green : .red)
                            
                            Text(result.message)
                                .font(.subheadline)
                        }
                        
                        ForEach(result.details, id: \.self) { detail in
                            Text(detail)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                        }
                    }
                }
            }
            .navigationTitle("Test Results")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
    
    private func getPassedCount() -> Int {
        let tests = [
            results.apiIntegration,
            results.eventProcessing,
            results.bettingFlow,
            results.playerSelection,
            results.matchMonitoring,
            results.fullSimulation
        ]
        
        return tests.filter { $0.passed }.count
    }
}

// MARK: - Preview
struct DebugTestView_Previews: PreviewProvider {
    static var previews: some View {
        DebugTestView()
    }
}
#endif
