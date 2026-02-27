//
//  NavigationComponents.swift
//  Lucky Football Slip
//
//  Apple Sports-inspired navigation and header components
//

import SwiftUI

// MARK: - Screen Header

struct ScreenHeader: View {
    let title: String
    let subtitle: String?
    let showBack: Bool
    let backAction: (() -> Void)?
    let trailingContent: AnyView?
    
    init(
        _ title: String,
        subtitle: String? = nil,
        showBack: Bool = false,
        backAction: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBack = showBack
        self.backAction = backAction
        self.trailingContent = AnyView(trailing())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Back button
            if showBack {
                Button(action: { backAction?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
            
            // Title
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            // Trailing content
            trailingContent
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Section Header

struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionLabel: String?
    
    init(
        _ title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.actionLabel = actionLabel
    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
        }
    }
}

// MARK: - Mode Selection Card

struct ModeCard: View {
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
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(spacing: 14) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 52, height: 52)
                        
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(color)
                    }
                    
                    // Title & subtitle
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            if let badge = badge {
                                Text(badge)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(color)
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(color)
                    }
                }
                
                // Features
                if !features.isEmpty {
                    HStack(spacing: 8) {
                        ForEach(features.prefix(4), id: \.self) { feature in
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                Text(feature)
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .fill(AppDesignSystem.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// Legacy alias
typealias EnhancedModeCard = ModeCard

// MARK: - Quick Action Card



// MARK: - Navigation Row

struct NavigationRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let showChevron: Bool
    let action: () -> Void
    
    init(
        _ title: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = AppDesignSystem.Colors.primary,
        showChevron: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.showChevron = showChevron
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.12))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor)
                }
                
                // Title & subtitle
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.system(size: 13))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                // Chevron
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.tertiaryText)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall)
                    .fill(AppDesignSystem.Colors.cardBackground)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Row

struct SettingsRow<Trailing: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    let trailing: Trailing
    
    init(
        _ title: String,
        icon: String,
        iconColor: Color = AppDesignSystem.Colors.primary,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.icon = icon
        self.iconColor = iconColor
        self.trailing = trailing()
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(iconColor)
            }
            
            // Title
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            // Trailing
            trailing
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Tab Bar Item

struct TabBarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? icon : icon)
                    .font(.system(size: 22, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.secondaryText)
                
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .medium))
                    .foregroundColor(isSelected ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.secondaryText)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Segmented Control

struct SegmentedControl: View {
    @Binding var selection: Int
    let options: [String]
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(options.enumerated()), id: \.offset) { index, option in
                Button(action: {
                    withAnimation(AppDesignSystem.Animations.quick) {
                        selection = index
                    }
                }) {
                    Text(option)
                        .font(.system(size: 14, weight: selection == index ? .semibold : .medium))
                        .foregroundColor(selection == index ? .white : AppDesignSystem.Colors.secondaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusSmall)
                                .fill(selection == index ? AppDesignSystem.Colors.primary : Color.clear)
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: AppDesignSystem.Layout.radiusMedium)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppDesignSystem.Colors.tertiaryText)
            
            Text(title)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppDesignSystem.Colors.primary)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String
    
    init(_ message: String = "Loading...") {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
