//
//  SetupSharedStyles.swift
//  Lucky Football Slip
//
//  Shared styling components for setup views - ensures visual consistency
//  between NewGameSetupView and LiveGameSetupView
//

import SwiftUI

// MARK: - Setup Container Background

/// Use this as the background for both setup views
struct SetupBackground: View {
    @Environment(\.colorScheme) var colorScheme
    
    private var isDark: Bool { colorScheme == .dark }
    
    var body: some View {
        ZStack {
            // Base - slightly tinted green instead of pure gray
            Color(isDark ? UIColor(red: 0.05, green: 0.09, blue: 0.07, alpha: 1) : UIColor(red: 0.95, green: 0.97, blue: 0.95, alpha: 1))
            
            // Strong green gradient at top
            VStack {
                LinearGradient(
                    colors: [
                        AppDesignSystem.Colors.grassGreen.opacity(isDark ? 0.2 : 0.1),
                        AppDesignSystem.Colors.grassGreen.opacity(isDark ? 0.05 : 0.02),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 250)
                
                Spacer()
            }
            
            // Subtle side accents (like pitch sidelines)
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.grassGreen.opacity(isDark ? 0.08 : 0.04),
                                Color.clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 40)
                
                Spacer()
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.grassGreen.opacity(isDark ? 0.08 : 0.04),
                                Color.clear
                            ],
                            startPoint: .trailing,
                            endPoint: .leading
                        )
                    )
                    .frame(width: 40)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Setup Navigation Bar Style

struct SetupNavigationStyle: ViewModifier {
    let title: String
    let onCancel: () -> Void
    var trailingContent: AnyView? = nil
    
    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onCancel()
                }
                .foregroundColor(AppDesignSystem.Colors.grassGreen),
                trailing: trailingContent
            )
    }
}

// MARK: - Setup Progress Bar (Football themed)

struct SetupProgressBar: View {
    let steps: [String]
    let currentStep: Int
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Progress track
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                        .frame(height: 6)
                    
                    // Progress fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppDesignSystem.Colors.grassGreen)
                        .frame(width: progressWidth(for: geo.size.width), height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
                }
            }
            .frame(height: 6)
            
            // Step indicators
            HStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    VStack(spacing: 4) {
                        // Step dot
                        ZStack {
                            Circle()
                                .fill(index <= currentStep ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.3))
                                .frame(width: 24, height: 24)
                            
                            if index < currentStep {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(index == currentStep ? .white : AppDesignSystem.Colors.secondaryText)
                            }
                        }
                        
                        // Step label
                        Text(step)
                            .font(.system(size: 10, weight: index == currentStep ? .semibold : .regular))
                            .foregroundColor(index == currentStep ? AppDesignSystem.Colors.primaryText : AppDesignSystem.Colors.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                    radius: 4,
                    x: 0,
                    y: 2
                )
        )
    }
    
    private func progressWidth(for totalWidth: CGFloat) -> CGFloat {
        guard steps.count > 1 else { return totalWidth }
        let progress = CGFloat(currentStep) / CGFloat(steps.count - 1)
        return totalWidth * progress
    }
}

// MARK: - Setup Step Header

struct SetupStepHeaderNew: View {
    let icon: String
    let title: String
    let subtitle: String
    var accentColor: Color = AppDesignSystem.Colors.grassGreen
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(accentColor.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(accentColor)
            }
            
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Setup Card (with green accent)

struct SetupCard<Content: View>: View {
    var accentColor: Color = AppDesignSystem.Colors.grassGreen
    var showAccentStrip: Bool = true
    @ViewBuilder let content: () -> Content
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if showAccentStrip {
                Rectangle()
                    .fill(accentColor)
                    .frame(height: 3)
            }
            
            content()
                .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(
            color: colorScheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.06),
            radius: 6,
            x: 0,
            y: 3
        )
    }
}

// MARK: - Setup Section Header

struct SetupSectionHeader: View {
    let title: String
    var icon: String? = nil
    var action: (() -> Void)? = nil
    var actionLabel: String? = nil
    
    var body: some View {
        HStack {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
    }
}

// MARK: - Setup Bottom Button Bar

struct SetupBottomBar: View {
    let showBack: Bool
    let nextTitle: String
    let canProceed: Bool
    let onBack: () -> Void
    let onNext: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Divider
            Rectangle()
                .fill(AppDesignSystem.Colors.secondaryText.opacity(0.2))
                .frame(height: 1)
            
            HStack(spacing: 12) {
                // Back button
                if showBack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 16, weight: .semibold))
                        }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppDesignSystem.Colors.grassGreen, lineWidth: 2)
                        )
                    }
                }
                
                // Next/Start button
                Button(action: onNext) {
                    HStack(spacing: 6) {
                        Text(nextTitle)
                            .font(.system(size: 16, weight: .bold))
                        
                        if nextTitle != "Start Game" {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        } else {
                            Image(systemName: "play.fill")
                                .font(.system(size: 14, weight: .semibold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(canProceed ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.4))
                    )
                    .shadow(
                        color: canProceed ? AppDesignSystem.Colors.grassGreen.opacity(0.4) : Color.clear,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
                }
                .disabled(!canProceed)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                Rectangle()
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.3) : Color.black.opacity(0.08),
                        radius: 8,
                        x: 0,
                        y: -4
                    )
            )
        }
    }
}

// MARK: - Setup Empty State

struct SetupEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(0.1))
                    .frame(width: 72, height: 72)
                
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen.opacity(0.6))
            }
            
            VStack(spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(AppDesignSystem.Colors.grassGreen.opacity(0.1))
                        )
                }
            }
        }
        .padding(32)
    }
}

// MARK: - Setup Info Banner

struct SetupInfoBanner: View {
    let message: String
    var icon: String = "info.circle.fill"
    var color: Color = AppDesignSystem.Colors.primary
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

// MARK: - Participant Row (shared style)

struct SetupParticipantRow: View {
    let participant: Participant
    let onDelete: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Text(participant.name.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
            }
            
            Text(participant.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: colorScheme == .dark ? Color.black.opacity(0.15) : Color.black.opacity(0.04),
                    radius: 3,
                    x: 0,
                    y: 1
                )
        )
    }
}

// MARK: - Add Participant Input

struct SetupAddParticipantInput: View {
    @Binding var name: String
    let onAdd: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "person.fill")
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                TextField("Enter name", text: $name)
                    .font(.system(size: 16))
                    .submitLabel(.done)
                    .onSubmit {
                        if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                            onAdd()
                        }
                    }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppDesignSystem.Colors.secondaryText.opacity(0.2), lineWidth: 1)
                    )
            )
            
            Button(action: onAdd) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(name.trimmingCharacters(in: .whitespaces).isEmpty ? AppDesignSystem.Colors.secondaryText.opacity(0.4) : AppDesignSystem.Colors.grassGreen)
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }
}
