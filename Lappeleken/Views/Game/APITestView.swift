//
//  APITestView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import SwiftUI

struct APITestView: View {
    @State private var isLoading = false
    @State private var result: String = ""
    @AppStorage("isLiveMode") private var isLiveMode = false
    
    var body: some View {
        VStack {
            Toggle("Live Mode", isOn: $isLiveMode)
                .padding()
            
            Button("Test API Connection") {
                testAPI()
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isLoading)
            
            if isLoading {
                ProgressView()
                    .padding()
            }
            
            ScrollView {
                Text(result)
                    .font(.system(.body, design: .monospaced))
                    .padding()
            }
        }
        .padding()
    }
    
    func testAPIKeyValidity() async {
        do {
            print("Testing API key with competitions endpoint...")
            let url = URL(string: "https://api.football-data.org/v4/competitions")!
            var request = URLRequest(url: url)
            request.addValue(AppConfig.footballDataAPIKey, forHTTPHeaderField: "X-Auth-Token")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("API Key Test Response: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    print("✅ API Key is valid!")
                    
                    // Print a sample of the response
                    if let jsonString = String(data: data, encoding: .utf8) {
                        print("Sample response: \(String(jsonString.prefix(200)))...")
                    }
                } else {
                    print("❌ API Key validation failed with status: \(httpResponse.statusCode)")
                    if let errorText = String(data: data, encoding: .utf8) {
                        print("Error response: \(errorText)")
                    }
                }
            }
        } catch {
            print("❌ API Key test error: \(error)")
        }
    }
    
    private func testAPI() {
        isLoading = true
        result = "Testing API connection...\n"
        result += "Mode: \(isLiveMode ? "Live" : "Offline")\n"
        
        Task {
            do {
                let service = ServiceProvider.shared.getGameDataService()
                
                // Test players fetch
                result += "Fetching players...\n"
                let players = try await service.fetchPlayers()
                result += "✅ Successfully fetched \(players.count) players\n"
                
                // Test teams fetch
                result += "Fetching teams...\n"
                let teams = try await service.fetchTeams()
                result += "✅ Successfully fetched \(teams.count) teams\n"
                
                // Final status
                result += "\nAll tests completed successfully!\n"
                
                DispatchQueue.main.async {
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    result += "❌ Error: \(error)\n"
                    isLoading = false
                }
            }
        }
    }
}

struct APITestView_Previews: PreviewProvider {
    static var previews: some View {
        APITestView()
    }
}
