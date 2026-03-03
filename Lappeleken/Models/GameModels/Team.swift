//
//  Team.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import Foundation

struct Team: Identifiable, Hashable, Codable {
    let id: UUID
    let name: String
    let shortName: String
    let logoName: String
    let primaryColor: String
    
    /// The original API ID (e.g., "57" for Arsenal) - used for API calls
    let apiId: String?
    
    init(id: UUID = UUID(), name: String, shortName: String, logoName: String, primaryColor: String, apiId: String? = nil) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.logoName = logoName
        self.primaryColor = primaryColor
        self.apiId = apiId
    }
    
    /// Extract API ID from synthetic UUID or use stored apiId
    var effectiveApiId: String {
        if let apiId = apiId, !apiId.isEmpty {
            return apiId
        }
        // Extract from synthetic UUID format: 00000000-0000-0000-0000-000000000057 → "57"
        let uuidString = id.uuidString
        if uuidString.hasPrefix("00000000-0000-0000-0000-") {
            let suffix = uuidString.replacingOccurrences(of: "00000000-0000-0000-0000-", with: "")
            if let intValue = Int(suffix) {
                return String(intValue)
            }
        }
        return id.uuidString
    }
    
    // Implement Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Implement Equatable
    static func == (lhs: Team, rhs: Team) -> Bool {
        return lhs.id == rhs.id
    }
}
