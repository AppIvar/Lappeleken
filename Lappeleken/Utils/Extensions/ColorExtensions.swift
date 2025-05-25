//
//  ColorExtensions.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import SwiftUI

// Extension to SwiftUI Color to avoid NaN values
extension Color {
    /// Creates a safe color with validated RGB components
    static func safeRGB(red: Double, green: Double, blue: Double, opacity: Double = 1.0) -> Color {
        let validRed = red.isNaN ? 0 : max(0, min(1, red))
        let validGreen = green.isNaN ? 0 : max(0, min(1, green))
        let validBlue = blue.isNaN ? 0 : max(0, min(1, blue))
        let validOpacity = opacity.isNaN ? 1 : max(0, min(1, opacity))
        
        return Color(red: validRed, green: validGreen, blue: validBlue, opacity: validOpacity)
    }
}
