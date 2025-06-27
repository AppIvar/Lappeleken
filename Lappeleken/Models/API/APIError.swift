//
//  APIError.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import Foundation

enum APIError: Error, Equatable {
    case invalidURL
    case networkError(Error)
    case decodingError(Error)
    case serverError(Int, String)
    case unknown
    case rateLimited
    
    static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL, .invalidURL),
             (.unknown, .unknown),
             (.rateLimited, .rateLimited):
            return true
        case (.serverError(let lhsCode, _), .serverError(let rhsCode, _)):
            return lhsCode == rhsCode
        case (.networkError, .networkError),
             (.decodingError, .decodingError):
            return true
        default:
            return false
        }
    }
}
