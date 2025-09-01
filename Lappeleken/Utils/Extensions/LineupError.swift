//
//  LineupError.swift
//  Lucky Football Slip
//
//  Custom error types for lineup handling
//

import Foundation

enum LineupError: Error, LocalizedError, Equatable {
    case notAvailableYet
    case invalidData
    case fetchFailed(String)
    case noPlayersFound
    
    var errorDescription: String? {
        switch self {
        case .notAvailableYet:
            return "Lineup data not available yet"
        case .invalidData:
            return "Invalid lineup data received"
        case .fetchFailed(let reason):
            return "Failed to fetch lineup: \(reason)"
        case .noPlayersFound:
            return "No players found in lineup data"
        }
    }
    
    // Implement Equatable conformance
    static func == (lhs: LineupError, rhs: LineupError) -> Bool {
        switch (lhs, rhs) {
        case (.notAvailableYet, .notAvailableYet),
             (.invalidData, .invalidData),
             (.noPlayersFound, .noPlayersFound):
            return true
        case (.fetchFailed(let lhsReason), .fetchFailed(let rhsReason)):
            return lhsReason == rhsReason
        default:
            return false
        }
    }
}

// MARK: - Extension to help with error checking
extension Error {
    var isLineupNotAvailable: Bool {
        if let lineupError = self as? LineupError {
            return lineupError == .notAvailableYet
        }
        return localizedDescription.contains("Lineup data not available yet")
    }
}
