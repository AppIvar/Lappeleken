//
//  AppDesignSystem.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 08/05/2025.
//

import SwiftUI

struct AppDesignSystem {
    // MARK: - Colors
    struct Colors {
        // Primary colors
        static let primary = Color("PrimaryColor")
        static let secondary = Color("SecondaryColor")
        static let accent = Color("AccentColor")
        
        // Background colors
        static let background = Color("BackgroundColor")
        static let cardBackground = Color("CardBackgroundColor")
        
        // Text Colors
        static let primaryText = Color("PrimaryTextColor")
        static let secondaryText = Color("SecondaryTextColor")
        
        // Status colors
        static let success = Color("SuccessColor")
        static let warning = Color("WarningColor")
        static let error = Color("ErrorColor")
    }
    
    // MARK: - Typography
    struct Typography {
        static let titleFont = Font.system(.largeTitle, design: .rounded).bold()
        static let headingFont = Font.system(.title, design: .rounded).bold()
        static let subheadingFont = Font.system(.title3, design: .rounded).bold()
        static let bodyFont = Font.system(.body, design: .rounded)
        static let captionFont = Font.system(.caption, design: .rounded)
    }
    
    // MARK: - Layout
    struct Layout {
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 16
    }
    
    // MARK: - Animations
    struct Animations {
        static let standard = Animation.easeInOut(duration: 0.3)
        static let quick = Animation.easeInOut(duration: 0.15)
    }
}
    
// MARK: - Team Colors
extension AppDesignSystem {
    struct TeamColors {
        static func getColor(for team: Team) -> Color {
            // Fixed conditional binding - removed the if let structure
            let colorHex = team.primaryColor.trimmingCharacters(in: .whitespaces)
            if colorHex.hasPrefix("#") && colorHex.count == 7 {
                let scanner = Scanner(string: String(colorHex.dropFirst()))
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    let r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
                    let g = Double((hexNumber & 0x00FF00) >> 8) / 255.0
                    let b = Double(hexNumber & 0x0000FF) / 255.0
                    
                    // Validate RGB values to prevent NaN
                    let validRed = r.isNaN ? 0 : max(0, min(1, r))
                    let validGreen = g.isNaN ? 0 : max(0, min(1, g))
                    let validBlue = b.isNaN ? 0 : max(0, min(1, b))
                    
                    return Color(red: validRed, green: validGreen, blue: validBlue)
                }
            }
            
            // Fallback to a default color based on team name
            let nameHash = abs(team.name.hashValue)
            let hue = Double(nameHash % 10) / 10.0
            
            // Use safe values for HSB color
            let validHue = hue.isNaN ? 0.5 : hue
            return Color(hue: validHue, saturation: 0.7, brightness: 0.8)
        }
        
        static func getAccentColor(for team: Team) -> Color {
            let baseColor = getColor(for: team)
            return baseColor.opacity(0.15)
        }
    }
}
