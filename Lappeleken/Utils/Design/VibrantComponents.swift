//
//  VibrantComponents.swift
//  Lucky Football Slip
//
//  Colorful, engaging UI components
//

import SwiftUI

// MARK: - Vibrant Mode Card

struct VibrantModeCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let features: [String]
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                // Colored header strip
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 6)
                
                VStack(alignment: .leading, spacing: 16) {
                    // Header row
                    HStack(spacing: 14) {
                        // Icon with gradient background
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [color, color.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 56, height: 56)
                            
                            Image(systemName: icon)
                                .font(.system(size: 26, weight: .medium))
                                .foregroundColor(.white)
                        }
                        .shadow(color: color.opacity(0.4), radius: 8, x: 0, y: 4)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(title)
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                
                                if let badge = badge {
                                    Text(badge)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(
                                            Capsule().fill(
                                                LinearGradient(
                                                    colors: [color, color.opacity(0.7)],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                )
                                            )
                                        )
                                }
                            }
                            
                            Text(subtitle)
                                .font(.system(size: 14))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .lineLimit(2)
                        }
                        
                        Spacer()
                    }
                    
                    // Colorful feature badges
                    featureBadges
                }
                .padding(16)
            }
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .fill(AppDesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2.5)
            )
            .shadow(
                color: isSelected ? color.opacity(0.3) : Color.black.opacity(0.08),
                radius: isSelected ? 12 : 6,
                x: 0,
                y: isSelected ? 6 : 3
            )
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium))
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    private var featureBadges: some View {
        // Colorful feature grid
        let featureColors: [Color] = [
            AppDesignSystem.Colors.success,
            AppDesignSystem.Colors.primary,
            AppDesignSystem.Colors.warning,
            AppDesignSystem.Colors.accent
        ]
        
        return LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
            ForEach(Array(features.prefix(4).enumerated()), id: \.offset) { index, feature in
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(featureColors[index % featureColors.count])
                    
                    Text(feature)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(featureColors[index % featureColors.count].opacity(0.1))
                )
            }
        }
    }
}

// MARK: - Vibrant Quick Action Card

struct VibrantQuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Gradient icon background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 54, height: 54)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                .shadow(color: color.opacity(0.4), radius: 6, x: 0, y: 3)
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                            .stroke(color.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Colorful Progress Indicator

struct ColorfulProgressIndicator: View {
    let steps: [String]
    let currentStep: Int
    let accentColor: Color
    
    private let stepColors: [Color] = [
        Color(red: 0.0, green: 0.48, blue: 1.0),   // Blue
        Color(red: 0.2, green: 0.78, blue: 0.35),  // Green
        Color(red: 1.0, green: 0.62, blue: 0.04),  // Orange
        Color(red: 0.85, green: 0.0, blue: 0.65),  // Magenta
        Color(red: 0.55, green: 0.23, blue: 0.87)  // Purple
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Step circles with connecting lines
            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack(spacing: 0) {
                        // Step circle
                        stepCircle(for: index)
                        
                        // Connecting line
                        if index < steps.count - 1 {
                            connectingLine(after: index)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Current step info
            VStack(spacing: 4) {
                Text(steps[currentStep])
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(stepColors[currentStep % stepColors.count])
                
                Text("Step \(currentStep + 1) of \(steps.count)")
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .fill(
                    LinearGradient(
                        colors: [
                            stepColors[currentStep % stepColors.count].opacity(0.08),
                            AppDesignSystem.Colors.cardBackground
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }
    
    private func stepCircle(for index: Int) -> some View {
        let color = stepColors[index % stepColors.count]
        let isCompleted = index < currentStep
        let isCurrent = index == currentStep
        
        return ZStack {
            Circle()
                .fill(
                    isCompleted || isCurrent ?
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ) :
                    LinearGradient(
                        colors: [AppDesignSystem.Colors.disabled, AppDesignSystem.Colors.disabled],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrent ? .white : AppDesignSystem.Colors.secondaryText)
            }
        }
        .shadow(
            color: (isCompleted || isCurrent) ? color.opacity(0.4) : Color.clear,
            radius: 4,
            x: 0,
            y: 2
        )
    }
    
    private func connectingLine(after index: Int) -> some View {
        let isCompleted = index < currentStep
        let color = stepColors[index % stepColors.count]
        
        return Rectangle()
            .fill(
                isCompleted ?
                LinearGradient(
                    colors: [color, stepColors[(index + 1) % stepColors.count]],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [AppDesignSystem.Colors.disabled, AppDesignSystem.Colors.disabled],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 3)
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Gradient Section Header

struct GradientSectionHeader: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let color: Color
    
    init(_ title: String, subtitle: String? = nil, icon: String? = nil, color: Color = AppDesignSystem.Colors.primary) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Colored accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 4, height: 40)
            
            if let icon = icon {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(color)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Colorful Info Card

struct ColorfulInfoCard: View {
    let title: String
    let message: String
    let icon: String
    let color: Color
    let action: (() -> Void)?
    let actionLabel: String?
    
    init(
        title: String,
        message: String,
        icon: String,
        color: Color,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.color = color
        self.action = action
        self.actionLabel = actionLabel
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            }
            .shadow(color: color.opacity(0.3), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let action = action, let label = actionLabel {
                    Button(action: action) {
                        Text(label)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(color)
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .overlay(
            // Top color accent
            VStack {
                HStack {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(color)
                        .frame(width: 40, height: 3)
                    Spacer()
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 0)
        )
    }
}

// MARK: - Vibrant Stat Card

struct VibrantStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: Trend?
    
    enum Trend {
        case up, down, neutral
    }
    
    init(_ title: String, value: String, icon: String, color: Color, trend: Trend? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
    }
    
    var body: some View {
        VStack(spacing: 10) {
            // Icon with gradient
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.2), color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(color)
            }
            
            // Value
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                if let trend = trend {
                    Image(systemName: trend == .up ? "arrow.up" : trend == .down ? "arrow.down" : "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(trend == .up ? AppDesignSystem.Colors.success : trend == .down ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.secondaryText)
                }
            }
            
            // Title
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    // Bottom color accent
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [color, color.opacity(0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 3)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium))
                )
        )
    }
}

// MARK: - Colorful Step Card (for setup wizards)

struct ColorfulStepCard: View {
    let stepNumber: Int
    let title: String
    let description: String
    let icon: String
    let isCompleted: Bool
    let isCurrent: Bool
    
    private var color: Color {
        let colors: [Color] = [
            AppDesignSystem.Colors.primary,
            AppDesignSystem.Colors.success,
            AppDesignSystem.Colors.warning,
            AppDesignSystem.Colors.accent,
            AppDesignSystem.Colors.info
        ]
        return colors[(stepNumber - 1) % colors.count]
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Step number circle
            ZStack {
                Circle()
                    .fill(
                        isCompleted || isCurrent ?
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [AppDesignSystem.Colors.disabled, AppDesignSystem.Colors.disabled],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isCurrent ? .white : AppDesignSystem.Colors.secondaryText)
                }
            }
            .shadow(
                color: (isCompleted || isCurrent) ? color.opacity(0.4) : Color.clear,
                radius: 6,
                x: 0,
                y: 3
            )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Step \(stepNumber)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isCurrent ? color : AppDesignSystem.Colors.secondaryText)
                
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(isCurrent ? AppDesignSystem.Colors.primaryText : AppDesignSystem.Colors.secondaryText)
                
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.tertiaryText)
            }
            
            Spacer()
            
            if isCurrent {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .fill(isCurrent ? color.opacity(0.08) : AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                        .stroke(isCurrent ? color.opacity(0.3) : Color.clear, lineWidth: 1.5)
                )
        )
    }
}

// MARK: - Gradient Button

struct GradientButton: View {
    let title: String
    let icon: String?
    let colors: [Color]
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, colors: [Color] = [AppDesignSystem.Colors.primary, AppDesignSystem.Colors.primary.opacity(0.7)], action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.colors = colors
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: colors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium))
            .shadow(color: colors[0].opacity(0.4), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Feature Badge Row

struct FeatureBadgeRow: View {
    let features: [String]
    let color: Color
    
    var body: some View {
        let badgeColors: [Color] = [
            AppDesignSystem.Colors.success,
            AppDesignSystem.Colors.primary,
            AppDesignSystem.Colors.warning,
            AppDesignSystem.Colors.accent
        ]
        
        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(Array(features.enumerated()), id: \.offset) { index, feature in
                    let badgeColor = badgeColors[index % badgeColors.count]
                    
                    HStack(spacing: 5) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                        Text(feature)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(badgeColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(badgeColor.opacity(0.12))
                    )
                }
            }
            .padding(.horizontal, 4)
        }
    }
}
