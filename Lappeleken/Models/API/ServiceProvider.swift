//
//  ServiceProvider.swift
//  Lucky Football Slip
//
//  Updated to support test mode
//

import Foundation

class ServiceProvider {
    static let shared = ServiceProvider()
    
    private let offlineService: OfflineGameDataService
    private let liveService: LiveGameDataService
    private let apiClient: APIClient
    private let footballDataService: FootballDataMatchService
    
    private init() {
        // Init API client
        apiClient = APIClient(baseURL: AppConfig.apiBaseURL)
        
        // Init game data services
        offlineService = OfflineGameDataService()
        liveService = LiveGameDataService(apiClient: apiClient)
        
        // Init football data service
        let footballDataAPIClient = APIClient(baseURL: "https://api.football-data.org/v4")
        footballDataService = FootballDataMatchService(
            apiClient: footballDataAPIClient,
            apiKey: AppConfig.footballDataAPIKey
        )
        
        // Listen for test mode changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTestModeChange),
            name: Notification.Name("TestModeChanged"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func handleTestModeChange() {
        print("🔄 ServiceProvider: Test mode changed")
    }
    
    func getGameDataService() -> GameDataService {
        let isLiveMode = UserDefaults.standard.bool(forKey: "isLiveMode")
        return isLiveMode ? liveService : offlineService
    }
    
    func getMatchService() -> MatchService {
        // Check if we're in test mode
        if TestConfiguration.shared.isTestMode,
           let mockService = TestConfiguration.shared.mockService {
            print("🧪 Using mock football service")
            return mockService
        }
        
        print("🌐 Using real football API service")
        return footballDataService
    }
}

// MARK: - Test Mode Extensions

#if DEBUG
extension ServiceProvider {
    func enableTestMode() {
        TestConfiguration.shared.enableTestMode()
    }
    
    func disableTestMode() {
        TestConfiguration.shared.disableTestMode()
    }
    
    func getTestService() -> MockFootballDataService? {
        return TestConfiguration.shared.mockService
    }
    
    func runTestScenario(_ scenario: TestScenario) {
        TestConfiguration.shared.runTestScenario(scenario)
    }
}
#endif
