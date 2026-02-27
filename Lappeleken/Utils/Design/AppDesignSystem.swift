//
//  AppDesignSystem.swift
//  Lucky Football Slip
//
//  Design System v2.0 - Apple Sports inspired with personality
//  Maintains backward compatibility with existing views
//

import SwiftUI

// MARK: - App Design System

struct AppDesignSystem {
    
    // MARK: - Colors
    
    struct Colors {
        
        // === PRIMARY BRAND COLORS (from Asset Catalog) ===
        static let primary = Color("AppPrimary")           // #007AFF / #0A84FF
        static let secondary = Color("WarningOrange")      // #FF9500 / #FF9F0A
        static let accent = Color("Purple")                // #AF52DE / #BF5AF2
        
        // === BACKGROUNDS (from Asset Catalog) ===
        static let background = Color("AppBackground")     // #F2F2F7 / #000000
        static let cardBackground = Color("CardBackground") // #FFFFFF / #1C1C1E
        static let surfaceBackground = Color("CardBackground")
        static let groupedBackground = Color("AppBackground")
        static let cardSurface = Color("CardBackground")
        static let elevatedBackground = Color("CardBackground")
        
        // === TEXT COLORS (from Asset Catalog) ===
        static let primaryText = Color("PrimaryText")      // #000000 / #FFFFFF
        static let secondaryText = Color("SecondaryText")  // #8E8E93 / #8E8E93
        static let tertiaryText = Color("SecondaryText").opacity(0.7)
        static let invertedText = Color.white
        
        // === STATUS COLORS (from Asset Catalog) ===
        static let success = Color("GrassGreen")           // #34C759 / #30D158
        static let warning = Color("WarningOrange")        // #FF9500 / #FF9F0A
        static let error = Color("AccentColor")            // #FF3B30 / #FF453A
        static let info = Color("AppPrimary")              // #007AFF / #0A84FF
        
        // === SPORTS-SPECIFIC COLORS ===
        static let live = Color("AccentColor")             // #FF3B30 / #FF453A
        static let upcoming = Color("AppPrimary")          // #007AFF / #0A84FF
        static let finished = Color("SecondaryText")       // #8E8E93
        static let halftime = Color("WarningOrange")       // #FF9500 / #FF9F0A
        
        // Football-themed accents (from Asset Catalog)
        static let grassGreen = Color("GrassGreen")        // #34C759 / #30D158
        static let goalYellow = Color("GoldYellow")        // #FFCC00 / #FFD60A
        static let pitchGreen = Color("GrassGreen").opacity(0.8)
        
        // === INTERACTIVE STATES ===
        static let selected = Color("AppPrimary").opacity(0.12)
        static let selectedBorder = Color("AppPrimary").opacity(0.4)
        static let pressed = Color("SecondaryText").opacity(0.3)
        static let disabled = Color("SecondaryText").opacity(0.5)
        static let hover = Color("SecondaryText").opacity(0.1)
        
        // === LEAGUE COLORS ===
        // Quick access to league brand colors
        static func leagueColor(for code: String) -> Color {
            switch code {
            case "PL": return Color(red: 0.38, green: 0.15, blue: 0.60)  // Premier League purple
            case "BL1": return Color(red: 0.86, green: 0.08, blue: 0.24) // Bundesliga red
            case "PD": return Color(red: 1.0, green: 0.45, blue: 0.0)    // La Liga orange
            case "SA": return Color(red: 0.0, green: 0.44, blue: 0.75)   // Serie A blue
            case "FL1": return Color(red: 0.0, green: 0.24, blue: 0.44)  // Ligue 1 dark blue
            case "CL": return Color(red: 0.0, green: 0.13, blue: 0.42)   // Champions League navy
            case "TIP": return Color(red: 0.73, green: 0.0, blue: 0.15)  // Eliteserien red
            case "WC": return Color(red: 0.55, green: 0.0, blue: 0.35)   // World Cup maroon
            case "BSA": return Color(red: 0.0, green: 0.60, blue: 0.32)  // Brasileirão green
            default: return primary
            }
        }
    }
    
    // MARK: - Typography
    
    struct Typography {
        // Display - Large titles, hero text
        static let largeTitle = Font.system(.largeTitle, design: .rounded).weight(.bold)
        static let title = Font.system(.title, design: .rounded).weight(.bold)
        static let title2 = Font.system(.title2, design: .rounded).weight(.semibold)
        static let title3 = Font.system(.title3, design: .rounded).weight(.semibold)
        
        // Body text
        static let headline = Font.system(.headline, design: .rounded)
        static let body = Font.system(.body, design: .default)
        static let bodyRounded = Font.system(.body, design: .rounded)
        static let callout = Font.system(.callout, design: .rounded)
        static let subheadline = Font.system(.subheadline, design: .rounded)
        static let footnote = Font.system(.footnote, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded)
        static let caption2 = Font.system(.caption2, design: .rounded)
        
        // Scores & Numbers - Monospaced for alignment
        static let scoreDisplay = Font.system(size: 32, weight: .bold, design: .rounded)
        static let scoreLarge = Font.system(size: 28, weight: .bold, design: .rounded)
        static let scoreMedium = Font.system(size: 22, weight: .bold, design: .rounded)
        static let scoreSmall = Font.system(size: 17, weight: .semibold, design: .rounded)
        static let timeDisplay = Font.system(size: 15, weight: .medium, design: .monospaced)
        
        // === LEGACY NAMES (backward compatibility) ===
        static let titleFont = largeTitle
        static let headingFont = title
        static let subheadingFont = title3
        static let bodyFont = bodyRounded
        static let captionFont = caption
        static let bodyBold = Font.system(.body, design: .rounded).bold()
    }
    
    // MARK: - Layout & Spacing
    
    struct Layout {
        // Spacing scale (4-point grid)
        static let spacing2: CGFloat = 2
        static let spacing4: CGFloat = 4
        static let spacing6: CGFloat = 6
        static let spacing8: CGFloat = 8
        static let spacing12: CGFloat = 12
        static let spacing16: CGFloat = 16
        static let spacing20: CGFloat = 20
        static let spacing24: CGFloat = 24
        static let spacing32: CGFloat = 32
        static let spacing40: CGFloat = 40
        
        // Corner radius scale
        static let radiusSmall: CGFloat = 6
        static let radiusMedium: CGFloat = 10
        static let radiusLarge: CGFloat = 14
        static let radiusXL: CGFloat = 20
        static let radiusFull: CGFloat = 9999  // For pills/capsules
        
        // === LEGACY NAMES (backward compatibility) ===
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let largeCornerRadius: CGFloat = 16
        static let shadowRadius: CGFloat = 8
        static let shadowOffset = CGSize(width: 0, height: 4)
    }
    
    // MARK: - Shadows
    
    struct Shadows {
        static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
        
        static let small = Shadow(
            color: Color.black.opacity(0.06),
            radius: 3,
            x: 0,
            y: 1
        )
        
        static let medium = Shadow(
            color: Color.black.opacity(0.08),
            radius: 8,
            x: 0,
            y: 4
        )
        
        static let large = Shadow(
            color: Color.black.opacity(0.12),
            radius: 16,
            x: 0,
            y: 8
        )
        
        // Colored shadows for emphasis
        static func colored(_ color: Color, intensity: Double = 0.25) -> Shadow {
            Shadow(color: color.opacity(intensity), radius: 12, x: 0, y: 6)
        }
    }
    
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    // MARK: - Animations
    
    struct Animations {
        static let instant = Animation.easeOut(duration: 0.1)
        static let quick = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let standard = Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let smooth = Animation.easeInOut(duration: 0.3)
        static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
        static let gentle = Animation.easeInOut(duration: 0.5)
        
        // For list items
        static func staggered(index: Int, baseDelay: Double = 0.05) -> Animation {
            Animation.spring(response: 0.4, dampingFraction: 0.75)
                .delay(Double(index) * baseDelay)
        }
    }
    
    // MARK: - League Branding
    
    struct Leagues {
        static func emoji(for code: String) -> String {
            switch code {
            case "PL": return "🏴󠁧󠁢󠁥󠁮󠁧󠁿"
            case "BL1": return "🇩🇪"
            case "PD": return "🇪🇸"
            case "SA": return "🇮🇹"
            case "FL1": return "🇫🇷"
            case "CL": return "🏆"
            case "TIP": return "🇳🇴"
            case "WC": return "🌍"
            case "BSA": return "🇧🇷"
            case "ELC": return "🏴󠁧󠁢󠁥󠁮󠁧󠁿"
            case "DED": return "🇳🇱"
            case "PPL": return "🇵🇹"
            default: return "⚽"
            }
        }
        
        static func name(for code: String) -> String {
            switch code {
            case "PL": return "Premier League"
            case "BL1": return "Bundesliga"
            case "PD": return "La Liga"
            case "SA": return "Serie A"
            case "FL1": return "Ligue 1"
            case "CL": return "Champions League"
            case "TIP": return "Eliteserien"
            case "WC": return "World Cup"
            case "BSA": return "Brasileirão"
            default: return code
            }
        }
    }
}

// MARK: - Team Colors

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
                    
                    return Color(
                        red: r.isNaN ? 0 : max(0, min(1, r)),
                        green: g.isNaN ? 0 : max(0, min(1, g)),
                        blue: b.isNaN ? 0 : max(0, min(1, b))
                    )
                }
            }
            
            // Fallback colors based on name hash
            let nameHash = abs(team.name.hashValue)
            let fallbackColors: [Color] = [
                .blue, .red, .green, .orange, .purple, .teal, .indigo, .pink
            ]
            return fallbackColors[nameHash % fallbackColors.count]
        }
        
        static func getAccentColor(for team: Team) -> Color {
            return getColor(for: team).opacity(0.15)
        }
        
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

// MARK: - View Extensions

extension View {
    
    // MARK: - Card Styles
    
    /// Standard card with optional selection state
    func standardCard(isSelected: Bool = false) -> some View {
        self
            .padding(AppDesignSystem.Layout.spacing16)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .fill(isSelected ? AppDesignSystem.Colors.selected : AppDesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .stroke(
                        isSelected ? AppDesignSystem.Colors.selectedBorder : Color.clear,
                        lineWidth: 1.5
                    )
            )
    }
    
    /// Elevated card with shadow
    func elevatedCard() -> some View {
        self
            .padding(AppDesignSystem.Layout.spacing16)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .shadow(
                        color: Color.black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
    }
    
    /// Interactive card with press animation
    func interactiveCard(isSelected: Bool = false, isPressed: Bool = false) -> some View {
        self
            .padding(AppDesignSystem.Layout.spacing16)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .fill(isSelected ? AppDesignSystem.Colors.selected : AppDesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .stroke(
                        isSelected ? AppDesignSystem.Colors.primary.opacity(0.4) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: isPressed)
    }
    
    // MARK: - Legacy Card Styles (backward compatibility)
    
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
                AppDesignSystem.Colors.primary.opacity(0.2) :
                Color.black.opacity(0.05),
                radius: isSelected ? 8 : 2,
                x: 0,
                y: isSelected ? 4 : 1
            )
            .scaleEffect(isSelected ? 1.02 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: isSelected)
    }
    
    func vibrantButton(color: Color = AppDesignSystem.Colors.primary) -> some View {
        self.shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
    }
    
    func glassEffect() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                    .fill(AppDesignSystem.Colors.cardBackground.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// MARK: - Beta Badge

extension AppDesignSystem {
    struct BetaBadge: View {
        var body: some View {
            HStack(spacing: 4) {
                Text("BETA")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(AppDesignSystem.Colors.warning)
                    )
                
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(AppDesignSystem.Colors.warning)
            }
        }
    }
}

// MARK: - Vibrant Status Badge (Legacy)

struct VibrantStatusBadge: View {
    let text: String
    let color: Color
    
    init(_ text: String, color: Color = AppDesignSystem.Colors.primary) {
        self.text = text
        self.color = color
    }
    
    var body: some View {
        Text(text)
            .font(AppDesignSystem.Typography.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall)
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
    }
}
