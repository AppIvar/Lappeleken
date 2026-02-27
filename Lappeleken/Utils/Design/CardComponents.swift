//
//  CardComponents.swift
//  Lucky Football Slip
//
//  Reusable card components for consistent UI
//

import SwiftUI

// MARK: - Base Card

/// Generic card container with consistent styling
struct Card<Content: View>: View {
    let style: CardStyle
    let padding: CGFloat
    @ViewBuilder let content: () -> Content
    
    enum CardStyle {
        case standard       // Default card background
        case elevated       // With shadow
        case outlined       // Border only
        case grouped        // Grouped background
    }
    
    init(
        style: CardStyle = .standard,
        padding: CGFloat = AppDesignSystem.Layout.spacing16,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.style = style
        self.padding = padding
        self.content = content
    }
    
    var body: some View {
        content()
            .padding(padding)
            .background(cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium))
            .overlay(cardOverlay)
            .shadow(color: shadowColor, radius: shadowRadius, x: 0, y: shadowY)
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        switch style {
        case .standard, .elevated:
            AppDesignSystem.Colors.cardBackground
        case .outlined:
            Color.clear
        case .grouped:
            AppDesignSystem.Colors.groupedBackground
        }
    }
    
    @ViewBuilder
    private var cardOverlay: some View {
        if style == .outlined {
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .stroke(AppDesignSystem.Colors.secondaryText.opacity(0.2), lineWidth: 1)
        }
    }
    
    private var shadowColor: Color {
        style == .elevated ? Color.black.opacity(0.08) : Color.clear
    }
    
    private var shadowRadius: CGFloat {
        style == .elevated ? 8 : 0
    }
    
    private var shadowY: CGFloat {
        style == .elevated ? 4 : 0
    }
}

// MARK: - Selectable Card

/// Card with selection state
struct SelectableCard<Content: View>: View {
    let isSelected: Bool
    let accentColor: Color
    let onTap: () -> Void
    @ViewBuilder let content: () -> Content
    
    @State private var isPressed = false
    
    init(
        isSelected: Bool,
        accentColor: Color = AppDesignSystem.Colors.primary,
        onTap: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isSelected = isSelected
        self.accentColor = accentColor
        self.onTap = onTap
        self.content = content
    }
    
    var body: some View {
        Button(action: onTap) {
            content()
                .padding(AppDesignSystem.Layout.spacing16)
                .background(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                        .fill(isSelected ? accentColor.opacity(0.1) : AppDesignSystem.Colors.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                        .stroke(
                            isSelected ? accentColor.opacity(0.5) : Color.clear,
                            lineWidth: 1.5
                        )
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(AppDesignSystem.Animations.instant) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(AppDesignSystem.Animations.quick) { isPressed = false }
                }
        )
    }
}

// MARK: - Section Card

/// Card with header for grouped content
struct SectionCard<Content: View>: View {
    let title: String
    let icon: String?
    let iconColor: Color
    let action: (() -> Void)?
    let actionLabel: String?
    @ViewBuilder let content: () -> Content
    
    init(
        title: String,
        icon: String? = nil,
        iconColor: Color = AppDesignSystem.Colors.primary,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.action = action
        self.actionLabel = actionLabel
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppDesignSystem.Layout.spacing12) {
            // Header
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(AppDesignSystem.Typography.headline)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                if let action = action, let label = actionLabel {
                    Button(action: action) {
                        Text(label)
                            .font(AppDesignSystem.Typography.subheadline)
                            .foregroundColor(AppDesignSystem.Colors.primary)
                    }
                }
            }
            
            // Content
            content()
        }
        .padding(AppDesignSystem.Layout.spacing16)
        .background(AppDesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium))
    }
}

// MARK: - Info Card

/// Card for displaying info/stats
struct InfoCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: Trend?
    
    enum Trend {
        case up, down, neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return AppDesignSystem.Colors.success
            case .down: return AppDesignSystem.Colors.error
            case .neutral: return AppDesignSystem.Colors.secondaryText
            }
        }
    }
    
    init(
        title: String,
        value: String,
        icon: String,
        color: Color = AppDesignSystem.Colors.primary,
        trend: Trend? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.trend = trend
    }
    
    var body: some View {
        HStack(spacing: AppDesignSystem.Layout.spacing12) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppDesignSystem.Typography.subheadline)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                HStack(spacing: 4) {
                    Text(value)
                        .font(AppDesignSystem.Typography.headline)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    if let trend = trend {
                        Image(systemName: trend.icon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(trend.color)
                    }
                }
            }
            
            Spacer()
        }
        .padding(AppDesignSystem.Layout.spacing16)
        .background(AppDesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium))
    }
}

// MARK: - Action Card

/// Card with a primary action
struct ActionCard: View {
    let title: String
    let subtitle: String?
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        color: Color = AppDesignSystem.Colors.primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppDesignSystem.Layout.spacing16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall)
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppDesignSystem.Typography.headline)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(AppDesignSystem.Typography.subheadline)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.tertiaryText)
            }
            .padding(AppDesignSystem.Layout.spacing16)
            .background(AppDesignSystem.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium))
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(AppDesignSystem.Animations.instant) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(AppDesignSystem.Animations.quick) { isPressed = false }
                }
        )
    }
}

// MARK: - Feature Card

/// Card highlighting a feature with icon
struct FeatureCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let isEnabled: Bool
    
    init(
        title: String,
        description: String,
        icon: String,
        color: Color = AppDesignSystem.Colors.primary,
        isEnabled: Bool = true
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.isEnabled = isEnabled
    }
    
    var body: some View {
        HStack(spacing: AppDesignSystem.Layout.spacing16) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(isEnabled ? color : AppDesignSystem.Colors.disabled)
                .frame(width: 32)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppDesignSystem.Typography.headline)
                    .foregroundColor(
                        isEnabled ? AppDesignSystem.Colors.primaryText : AppDesignSystem.Colors.secondaryText
                    )
                
                Text(description)
                    .font(AppDesignSystem.Typography.subheadline)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // Status
            if isEnabled {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppDesignSystem.Colors.success)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(AppDesignSystem.Colors.disabled)
            }
        }
        .padding(AppDesignSystem.Layout.spacing16)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .fill(isEnabled ? color.opacity(0.08) : AppDesignSystem.Colors.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .stroke(
                    isEnabled ? color.opacity(0.2) : AppDesignSystem.Colors.disabled.opacity(0.2),
                    lineWidth: 1
                )
        )
        .opacity(isEnabled ? 1.0 : 0.7)
    }
}

// MARK: - Expandable Card

/// Card that expands to show more content
struct ExpandableCard<Header: View, Content: View>: View {
    @Binding var isExpanded: Bool
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content
    
    init(
        isExpanded: Binding<Bool>,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isExpanded = isExpanded
        self.header = header
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header (always visible)
            Button(action: {
                withAnimation(AppDesignSystem.Animations.standard) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    header()
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.tertiaryText)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(AppDesignSystem.Layout.spacing16)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            // Expandable content
            if isExpanded {
                Divider()
                    .padding(.horizontal, AppDesignSystem.Layout.spacing16)
                
                content()
                    .padding(AppDesignSystem.Layout.spacing16)
                    .padding(.top, AppDesignSystem.Layout.spacing8)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppDesignSystem.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium))
    }
}

// MARK: - Preview

#if DEBUG
struct CardComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 20) {
                Card { Text("Standard Card") }
                Card(style: .elevated) { Text("Elevated Card") }
            }
            .padding()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
}
#endif
