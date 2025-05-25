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
        guard let url = URL(string: "\(baseURL)/\(endpoint)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(AppConfig.footballDataAPIKey, forHTTPHeaderField: "X-Auth-Token")
        
        // Only log in debug mode
        if AppConfig.enableDetailedLogging {
            print("📡 API Request: \(url.absoluteString)")
            print("🔑 Using API Key: \(AppConfig.footballDataAPIKey.prefix(8))...")
        }
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.unknown
            }
            
            if AppConfig.enableDetailedLogging {
                print("📥 API Response: Status \(httpResponse.statusCode)")
                
                // Print response headers for debugging
                if let headers = httpResponse.allHeaderFields as? [String: String] {
                    for (key, value) in headers {
                        if key.lowercased().contains("limit") || key.lowercased().contains("remaining") {
                            print("  \(key): \(value)")
                        }
                    }
                }
            }
            
            if httpResponse.statusCode == 429 {
                throw APIError.rateLimited
            }
            
            if (200...299).contains(httpResponse.statusCode) {
                do {
                    // Only log raw JSON in debug mode
                    if AppConfig.enableDetailedLogging {
                        if let jsonString = String(data: data, encoding: .utf8) {
                            print("📄 Response JSON (first 200 chars): \(String(jsonString.prefix(200)))...")
                        }
                    }
                    
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    decoder.dateDecodingStrategy = .iso8601
                    
                    return try decoder.decode(T.self, from: data)
                } catch {
                    if AppConfig.enableDetailedLogging {
                        print("❌ Decoding Error: \(error)")
                    }
                    throw APIError.decodingError(error)
                }
            } else {
                let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
                if AppConfig.enableDetailedLogging {
                    print("❌ Server Error \(httpResponse.statusCode): \(errorBody)")
                }
                throw APIError.serverError(httpResponse.statusCode, errorBody)
            }
        } catch {
            if let apiError = error as? APIError {
                throw apiError
            }
            if AppConfig.enableDetailedLogging {
                print("❌ Network Error: \(error)")
            }
            throw APIError.networkError(error)
        }
    }
}
