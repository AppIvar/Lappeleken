//
//  Match+Hashable.swift
//  Lucky Football Slip
//
//  Make Match conform to Hashable for Set operations
//

import Foundation

extension Match: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Match, rhs: Match) -> Bool {
        return lhs.id == rhs.id
    }
}
