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
        
        // Init football data service with proper API client
        let footballDataAPIClient = APIClient(baseURL: "https://api.football-data.org/v4")
        footballDataService = FootballDataMatchService(
            apiClient: footballDataAPIClient,
            apiKey: AppConfig.footballDataAPIKey
        )
    }
    
    func getGameDataService() -> GameDataService {
        let isLiveMode = UserDefaults.standard.bool(forKey: "isLiveMode")
        return isLiveMode ? liveService : offlineService
    }
    
    // Updated to return FootballDataMatchService for event-driven monitoring
    func getMatchService() -> MatchService {
        return footballDataService
    }
    
    func getAPIClient() -> APIClient {
        return apiClient
    }
    
    // Also add a method to get the football data API client specifically
    func getFootballDataAPIClient() -> APIClient {
        let footballDataAPIClient = APIClient(baseURL: "https://api.football-data.org/v4")
        return footballDataAPIClient
    }
}
