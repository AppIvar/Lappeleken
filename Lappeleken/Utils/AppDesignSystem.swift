//
//  AppDesignSystem.swift
//  Lucky Football Slip
//
//  Enhanced version with vibrant colors - simple replacement
//

import SwiftUI

struct AppDesignSystem {
    // MARK: - Enhanced Colors (keeping same property names)
    struct Colors {
        // Primary colors - now more vibrant
        static let primary = Color(red: 0.0, green: 0.48, blue: 1.0) // Bright blue
        static let secondary = Color(red: 1.0, green: 0.45, blue: 0.0) // Vibrant orange
        static let accent = Color(red: 0.85, green: 0.0, blue: 0.65) // Magenta
        
        // Background colors - warmer and more inviting
        static let background = Color(red: 0.98, green: 0.98, blue: 1.0) // Very light blue tint
        static let cardBackground = Color.white
        
        // Text Colors - same names, enhanced contrast
        static let primaryText = Color(red: 0.15, green: 0.15, blue: 0.2)
        static let secondaryText = Color(red: 0.4, green: 0.4, blue: 0.5)
        
        // Status colors - more vibrant
        static let success = Color(red: 0.0, green: 0.8, blue: 0.4) // Bright green
        static let warning = Color(red: 1.0, green: 0.6, blue: 0.0) // Bright orange
        static let error = Color(red: 1.0, green: 0.2, blue: 0.3) // Bright red
        
        // New additions for enhanced UI
        static let info = Color(red: 0.0, green: 0.7, blue: 1.0) // Bright cyan
        static let selected = primary.opacity(0.15)
        static let pressed = Color.black.opacity(0.1)
        static let disabled = Color.gray.opacity(0.3)
        
        // Football-themed colors
        static let grassGreen = Color(red: 0.2, green: 0.8, blue: 0.2)
        static let goalYellow = Color(red: 1.0, green: 0.9, blue: 0.0)
    }
    
    // MARK: - Typography (enhanced but same names)
    struct Typography {
        static let titleFont = Font.system(.largeTitle, design: .rounded).bold()
        static let headingFont = Font.system(.title, design: .rounded).bold()
        static let subheadingFont = Font.system(.title3, design: .rounded).bold()
        static let bodyFont = Font.system(.body, design: .rounded)
        static let captionFont = Font.system(.caption, design: .rounded)
        
        // New additions for better hierarchy
        static let bodyBold = Font.system(.body, design: .rounded).bold()
        static let callout = Font.system(.callout, design: .rounded).weight(.medium)
    }
    
    // MARK: - Layout (same names, some enhancements)
    struct Layout {
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 16
        
        // New additions for enhanced shadows
        static let shadowRadius: CGFloat = 8
        static let shadowOffset = CGSize(width: 0, height: 4)
    }
    
    // MARK: - Enhanced Animations (keeping same names)
    struct Animations {
        static let standard = Animation.spring(response: 0.5, dampingFraction: 0.8)
        static let quick = Animation.spring(response: 0.3, dampingFraction: 0.7)
        
        // New additions
        static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let smooth = Animation.easeInOut(duration: 0.3)
    }
}

// MARK: - Enhanced Team Colors (keeping same structure)
extension AppDesignSystem {
    struct TeamColors {
        static func getColor(for team: Team) -> Color {
            let colorHex = team.primaryColor.trimmingCharacters(in: .whitespaces)
            
            if colorHex.hasPrefix("#") && colorHex.count == 7 {
                let scanner = Scanner(string: String(colorHex.dropFirst()))
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    let r = Double((hexNumber & 0xFF0000) >> 16) / 255.0
                    let g = Double((hexNumber & 0x00FF00) >> 8) / 255.0
                    let b = Double(hexNumber & 0x0000FF) / 255.0
                    
                    let validRed = r.isNaN ? 0 : max(0, min(1, r))
                    let validGreen = g.isNaN ? 0 : max(0, min(1, g))
                    let validBlue = b.isNaN ? 0 : max(0, min(1, b))
                    
                    return Color(red: validRed, green: validGreen, blue: validBlue)
                }
            }
            
            // Enhanced fallback with more vibrant colors
            let nameHash = abs(team.name.hashValue)
            let vibrantColors: [Color] = [
                AppDesignSystem.Colors.primary,
                AppDesignSystem.Colors.secondary,
                AppDesignSystem.Colors.accent,
                AppDesignSystem.Colors.success,
                AppDesignSystem.Colors.warning,
                AppDesignSystem.Colors.info,
                AppDesignSystem.Colors.grassGreen,
                AppDesignSystem.Colors.goalYellow
            ]
            
            return vibrantColors[nameHash % vibrantColors.count]
        }
        
        static func getAccentColor(for team: Team) -> Color {
            return getColor(for: team).opacity(0.15)
        }
        
        // New addition: gradients for team colors
        static func getGradient(for team: Team) -> LinearGradient {
            let baseColor = getColor(for: team)
            return LinearGradient(
                colors: [baseColor, baseColor.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

// MARK: - Enhanced View Extensions (additions to your existing ones)
extension View {
    // Enhanced card style with better shadows and colors
    func enhancedCard(isSelected: Bool = false, team: Team? = nil) -> some View {
        self
            .padding(AppDesignSystem.Layout.standardPadding)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                    .fill(
                        isSelected ?
                        (team != nil ?
                         AppDesignSystem.TeamColors.getAccentColor(for: team!) :
                         AppDesignSystem.Colors.selected) :
                        AppDesignSystem.Colors.cardBackground
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                            .stroke(
                                isSelected ?
                                (team != nil ?
                                 AppDesignSystem.TeamColors.getColor(for: team!) :
                                 AppDesignSystem.Colors.primary) :
                                Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2 : 0.5
                            )
                    )
            )
            .shadow(
                color: isSelected ?
                (team != nil ?
                 AppDesignSystem.TeamColors.getColor(for: team!).opacity(0.2) :
                 AppDesignSystem.Colors.primary.opacity(0.2)) :
                Color.black.opacity(0.05),
                radius: isSelected ? 8 : 2,
                x: 0,
                y: isSelected ? 4 : 1
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: isSelected)
    }
    
    // Vibrant button effect
    func vibrantButton(color: Color = AppDesignSystem.Colors.primary) -> some View {
        self
            .shadow(
                color: color.opacity(0.4),
                radius: 8,
                x: 0,
                y: 4
            )
    }
    
    // Glass effect for modern look
    func glassEffect() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                    .fill(Color.white.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 20,
                x: 0,
                y: 10
            )
    }
}

// MARK: - New Vibrant Components

struct VibrantStatusBadge: View {
    let text: String
    let color: Color
    
    init(_ text: String, color: Color = AppDesignSystem.Colors.primary) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(AppDesignSystem.Typography.captionFont)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.smallCornerRadius)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(
                color: color.opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
    }
}
