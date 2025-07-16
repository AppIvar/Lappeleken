//
//  LineupError.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 16/07/2025.
//

import Foundation

enum LineupError: Error, LocalizedError {
    case notAvailableYet
    
    var errorDescription: String? {
        switch self {
        case .notAvailableYet:
            return "Lineup data not available yet"
        }
    }
}
