//
//  ServiceProvider.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
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
    }
    
    func getGameDataService() -> GameDataService {
        let isLiveMode = UserDefaults.standard.bool(forKey: "isLiveMode")
        return isLiveMode ? liveService : offlineService
    }
    
    func getMatchService() -> MatchService {
        return footballDataService
    }
}
