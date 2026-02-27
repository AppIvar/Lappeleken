//
//  ButtonStyles.swift
//  Lucky Football Slip
//
//  Comprehensive button system
//

import SwiftUI

// MARK: - Primary Button Style

/// Main call-to-action button
struct PrimaryButtonStyle: ButtonStyle {
    let color: Color
    let fullWidth: Bool
    
    init(color: Color = AppDesignSystem.Colors.primary, fullWidth: Bool = true) {
        self.color = color
        self.fullWidth = fullWidth
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .fill(color)
                    .opacity(configuration.isPressed ? 0.85 : 1.0)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: configuration.isPressed)
    }
}

// MARK: - Secondary Button Style

/// Secondary action button with outline
struct SecondaryButtonStyle: ButtonStyle {
    let color: Color
    let fullWidth: Bool
    
    init(color: Color = AppDesignSystem.Colors.primary, fullWidth: Bool = true) {
        self.color = color
        self.fullWidth = fullWidth
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold, design: .rounded))
            .foregroundColor(color)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .fill(color.opacity(configuration.isPressed ? 0.15 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .stroke(color.opacity(0.5), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: configuration.isPressed)
    }
}

// MARK: - Ghost Button Style

/// Minimal button with no background
struct GhostButtonStyle: ButtonStyle {
    let color: Color
    
    init(color: Color = AppDesignSystem.Colors.primary) {
        self.color = color
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundColor(color.opacity(configuration.isPressed ? 0.6 : 1.0))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall)
                    .fill(configuration.isPressed ? color.opacity(0.08) : Color.clear)
            )
            .animation(AppDesignSystem.Animations.quick, value: configuration.isPressed)
    }
}

// MARK: - Pill Button Style

/// Compact pill-shaped button
struct PillButtonStyle: ButtonStyle {
    let color: Color
    let style: PillStyle
    
    enum PillStyle {
        case filled, soft, outlined
    }
    
    init(color: Color = AppDesignSystem.Colors.primary, style: PillStyle = .filled) {
        self.color = color
        self.style = style
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold, design: .rounded))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(background(isPressed: configuration.isPressed))
            .clipShape(Capsule())
            .overlay(overlay)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: configuration.isPressed)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .filled: return .white
        case .soft, .outlined: return color
        }
    }
    
    @ViewBuilder
    private func background(isPressed: Bool) -> some View {
        switch style {
        case .filled:
            Capsule().fill(color.opacity(isPressed ? 0.85 : 1.0))
        case .soft:
            Capsule().fill(color.opacity(isPressed ? 0.2 : 0.12))
        case .outlined:
            Capsule().fill(isPressed ? color.opacity(0.08) : Color.clear)
        }
    }
    
    @ViewBuilder
    private var overlay: some View {
        if style == .outlined {
            Capsule().stroke(color, lineWidth: 1.5)
        }
    }
}

// MARK: - Icon Button Style

/// Circular icon button
struct IconButtonStyle: ButtonStyle {
    let size: Size
    let color: Color
    let background: BackgroundStyle
    
    enum Size {
        case small, medium, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 32
            case .medium: return 44
            case .large: return 56
            }
        }
        
        var iconSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            }
        }
    }
    
    enum BackgroundStyle {
        case filled, soft, none
    }
    
    init(size: Size = .medium, color: Color = AppDesignSystem.Colors.primary, background: BackgroundStyle = .soft) {
        self.size = size
        self.color = color
        self.background = background
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size.iconSize, weight: .semibold))
            .foregroundColor(iconColor)
            .frame(width: size.dimension, height: size.dimension)
            .background(backgroundView(isPressed: configuration.isPressed))
            .clipShape(Circle())
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: configuration.isPressed)
    }
    
    private var iconColor: Color {
        switch background {
        case .filled: return .white
        case .soft, .none: return color
        }
    }
    
    @ViewBuilder
    private func backgroundView(isPressed: Bool) -> some View {
        switch background {
        case .filled:
            Circle().fill(color.opacity(isPressed ? 0.85 : 1.0))
        case .soft:
            Circle().fill(color.opacity(isPressed ? 0.2 : 0.12))
        case .none:
            Circle().fill(isPressed ? color.opacity(0.08) : Color.clear)
        }
    }
}

// MARK: - Scale Button Style

/// Simple scale effect on press
struct ScaleButtonStyle: ButtonStyle {
    let scale: CGFloat
    
    init(scale: CGFloat = 0.97) {
        self.scale = scale
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: configuration.isPressed)
    }
}

// MARK: - Card Button Style

/// Button that looks like a tappable card
struct CardButtonStyle: ButtonStyle {
    let isSelected: Bool
    let accentColor: Color
    
    init(isSelected: Bool = false, accentColor: Color = AppDesignSystem.Colors.primary) {
        self.isSelected = isSelected
        self.accentColor = accentColor
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .fill(
                        isSelected
                            ? accentColor.opacity(0.1)
                            : AppDesignSystem.Colors.cardBackground
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .stroke(
                        isSelected ? accentColor.opacity(0.5) : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: configuration.isPressed)
    }
}

// MARK: - Convenience Button Views

/// Primary action button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                    }
                    Text(title)
                }
            }
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isLoading)
    }
}

/// Secondary action button
struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
        }
        .buttonStyle(SecondaryButtonStyle())
    }
}

/// Icon-only button
struct IconButton: View {
    let icon: String
    let size: IconButtonStyle.Size
    let color: Color
    let action: () -> Void
    
    init(
        _ icon: String,
        size: IconButtonStyle.Size = .medium,
        color: Color = AppDesignSystem.Colors.primary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
        }
        .buttonStyle(IconButtonStyle(size: size, color: color))
    }
}

// MARK: - Purchase Button (Legacy Support)

struct PurchaseButton: View {
    let title: String
    let subtitle: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppDesignSystem.Typography.bodyFont.bold())
                        Text(subtitle)
                            .font(AppDesignSystem.Typography.captionFont)
                    }
                }
                
                Spacer()
                
                if !isLoading {
                    Image(systemName: "arrow.right")
                        .font(.title3)
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(AppDesignSystem.Colors.primary)
            .cornerRadius(AppDesignSystem.Layout.cornerRadius)
        }
        .disabled(isLoading)
    }
}

// MARK: - Button View Extensions

extension View {
    /// Apply primary button styling
    func primaryButtonStyle(color: Color = AppDesignSystem.Colors.primary) -> some View {
        self.buttonStyle(PrimaryButtonStyle(color: color))
    }
    
    /// Apply secondary button styling
    func secondaryButtonStyle(color: Color = AppDesignSystem.Colors.primary) -> some View {
        self.buttonStyle(SecondaryButtonStyle(color: color))
    }
    
    /// Apply ghost button styling
    func ghostButtonStyle(color: Color = AppDesignSystem.Colors.primary) -> some View {
        self.buttonStyle(GhostButtonStyle(color: color))
    }
    
    /// Apply pill button styling
    func pillButtonStyle(color: Color = AppDesignSystem.Colors.primary, style: PillButtonStyle.PillStyle = .filled) -> some View {
        self.buttonStyle(PillButtonStyle(color: color, style: style))
    }
}

// MARK: - Previews

#if DEBUG
struct ButtonStyles_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                PrimaryButton("Continue", icon: "arrow.right") {}
                SecondaryButton("Cancel") {}
                Button("Ghost") {}.buttonStyle(GhostButtonStyle())
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}
#endif
