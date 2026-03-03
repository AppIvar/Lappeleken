//
//  APIClient.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

class APIClient {
    private let baseURL: String
    private let session: URLSession
    
    init(baseURL: String, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }
    
    func get<T: Decodable>(endpoint: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    return try JSONDecoder().decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            } else {
                throw APIError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
            }
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.networkError(error)
        }
    }
    
    func post<T: Encodable, U: Decodable>(endpoint: String, body: T) async throws -> U {
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONEncoder().encode(body)
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    return try JSONDecoder().decode(U.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }
            } else {
                throw APIError.serverError(httpResponse.statusCode, String(data: data, encoding: .utf8) ?? "")
            }
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.networkError(error)
        }
    }
    
    func footballDataRequest<T: Decodable>(endpoint: String) async throws -> T {
        // Check rate limit before making calls
        if !APIRateLimiter.shared.canMakeCall() {
            let waitTime = APIRateLimiter.shared.timeUntilNextCall()
            if AppConfig.enableDetailedLogging {
                print("🚨 Rate limit reached, waiting \(waitTime) seconds")
            }
            
            if waitTime > 0 && waitTime < 60 { // Don't wait more than 1 minute
                try await Task.sleep(nanoseconds: UInt64(waitTime * 1_000_000_000))
                
                // Check again after waiting
                guard APIRateLimiter.shared.canMakeCall() else {
                    throw APIError.rateLimited
                }
            } else {
                throw APIError.rateLimited
            }
        }
        
        // Record the API call
        APIRateLimiter.shared.recordCall()
        
        // Determine URL based on cache server configuration
        let (requestURL, usesCacheServer) = buildRequestURL(for: endpoint)
        
        guard let url = requestURL else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        
        // Only add API key for direct football-data.org calls
        // Cache server handles its own authentication
        if !usesCacheServer {
            request.addValue(AppConfig.footballDataAPIKey, forHTTPHeaderField: "X-Auth-Token")
        } else {
            // Add app identifier for cache server analytics
            request.addValue("LuckyFootballSlip/1.0", forHTTPHeaderField: "X-Client-ID")
        }
        
        if AppConfig.enableDetailedLogging {
            let stats = APIRateLimiter.shared.getUsageStats()
            let source = usesCacheServer ? "CACHE" : "DIRECT"
            print("📡 [\(source)] API Request (\(stats.current)/\(stats.max)): \(url.absoluteString)")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            
            if httpResponse.statusCode == 429 {
                throw APIError.rateLimited
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                decoder.dateDecodingStrategy = .iso8601
                
                return try decoder.decode(T.self, from: data)
            } else {
                let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                throw APIError.serverError(httpResponse.statusCode, errorBody)
            }
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.networkError(error)
        }
    }
    
    /// Build request URL, routing through cache server if enabled
    private func buildRequestURL(for endpoint: String) -> (URL?, Bool) {
        // Check if cache server is enabled and endpoint is cacheable
        if AppConfig.CacheServer.enabled {
            let endpointBase = endpoint.components(separatedBy: "?").first ?? endpoint
            
            if AppConfig.CacheServer.cachedEndpoints.contains(where: { endpointBase.hasPrefix($0) }) {
                // Route through cache server
                let cacheURL = URL(string: "\(AppConfig.CacheServer.baseURL)/api/football/\(endpoint)")
                return (cacheURL, true)
            }
        }
        
        // Direct call to football-data.org
        let directURL = URL(string: "\(baseURL)/\(endpoint)")
        return (directURL, false)
    }
}
