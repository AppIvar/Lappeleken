//
//  StatusComponents.swift
//  Lucky Football Slip
//
//  Reusable status indicators, badges, and pills
//

import SwiftUI

// MARK: - Status Badge

/// Compact badge for status indication (LIVE, FREE, PRO, etc.)
struct StatusBadge: View {
    let text: String
    let color: Color
    let style: Style
    
    enum Style {
        case filled      // Solid background, white text
        case soft        // Tinted background, colored text
        case outlined    // Border only, colored text
    }
    
    init(_ text: String, color: Color = AppDesignSystem.Colors.primary, style: Style = .soft) {
        self.text = text
        self.color = color
        self.style = style
    }
    
    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundColor(foregroundColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(background)
            .clipShape(Capsule())
    }
    
    private var foregroundColor: Color {
        switch style {
        case .filled: return .white
        case .soft, .outlined: return color
        }
    }
    
    @ViewBuilder
    private var background: some View {
        switch style {
        case .filled:
            Capsule().fill(color)
        case .soft:
            Capsule().fill(color.opacity(0.15))
        case .outlined:
            Capsule().stroke(color, lineWidth: 1)
        }
    }
}

// MARK: - Live Indicator

/// Animated live indicator with pulsing dot
struct LiveIndicator: View {
    let showText: Bool
    
    // Use a simpler animation approach
    @State private var isPulsing = false
    
    init(showText: Bool = true) {
        self.showText = showText
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(AppDesignSystem.Colors.live)
                .frame(width: 8, height: 8)
                .scaleEffect(isPulsing ? 1.15 : 1.0)
                .opacity(isPulsing ? 0.8 : 1.0)
                .animation(
                    .easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true),
                    value: isPulsing
                )
            
            if showText {
                Text("LIVE")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.live)
            }
        }
        .onAppear { isPulsing = true }
        .onDisappear { isPulsing = false }
    }
}

// MARK: - Match Status Indicator

/// Status indicator for match states
struct MatchStatusIndicator: View {
    let status: MatchStatus
    let style: StatusBadge.Style
    
    init(_ status: MatchStatus, style: StatusBadge.Style = .soft) {
        self.status = status
        self.style = style
    }
    
    var body: some View {
        Group {
            switch status {
            case .inProgress:
                LiveIndicator()
            default:
                StatusBadge(statusText, color: statusColor, style: style)
            }
        }
    }
    
    private var statusText: String {
        switch status {
        case .upcoming: return "UPCOMING"
        case .inProgress: return "LIVE"
        case .halftime: return "HT"
        case .completed, .finished: return "FT"
        case .postponed: return "POSTPONED"
        case .cancelled: return "CANCELLED"
        case .paused, .suspended: return "PAUSED"
        case .unknown: return "—"
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .upcoming: return AppDesignSystem.Colors.upcoming
        case .inProgress: return AppDesignSystem.Colors.live
        case .halftime: return AppDesignSystem.Colors.halftime
        case .completed, .finished: return AppDesignSystem.Colors.finished
        case .postponed, .cancelled: return AppDesignSystem.Colors.error
        case .paused, .suspended: return AppDesignSystem.Colors.warning
        case .unknown: return AppDesignSystem.Colors.secondaryText
        }
    }
}

// MARK: - League Badge

/// League badge with emoji and optional name
struct LeagueBadge: View {
    let code: String
    let showName: Bool
    let size: Size
    
    enum Size {
        case small, medium, large
        
        var emojiSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 24
            }
        }
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 10
            case .medium: return 12
            case .large: return 14
            }
        }
        
        var padding: CGFloat {
            switch self {
            case .small: return 4
            case .medium: return 6
            case .large: return 8
            }
        }
    }
    
    init(_ code: String, showName: Bool = false, size: Size = .medium) {
        self.code = code
        self.showName = showName
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Text(AppDesignSystem.Leagues.emoji(for: code))
                .font(.system(size: size.emojiSize))
            
            if showName {
                Text(AppDesignSystem.Leagues.name(for: code))
                    .font(.system(size: size.fontSize, weight: .medium, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
            }
        }
        .padding(.horizontal, size.padding)
        .padding(.vertical, size.padding / 2)
        .background(
            Capsule()
                .fill(AppDesignSystem.Colors.leagueColor(for: code).opacity(0.1))
        )
    }
}

// MARK: - Access Badge

/// Badge showing access status (Premium, Free, Locked, etc.)
struct AccessBadge: View {
    let status: LeagueAccessStatus
    
    var body: some View {
        switch status {
        case .unlocked(let reason):
            unlockedBadge(reason: reason)
        case .limitedFree(let remaining):
            StatusBadge("\(remaining) left", color: .orange, style: .soft)
        case .locked(_):
            StatusBadge("LOCKED", color: AppDesignSystem.Colors.error, style: .soft)
        }
    }
    
    @ViewBuilder
    private func unlockedBadge(reason: LeagueAccessStatus.UnlockReason) -> some View {
        switch reason {
        case .premium:
            HStack(spacing: 2) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 8))
                Text("PRO")
                    .font(.system(size: 9, weight: .bold))
            }
            .foregroundColor(.yellow)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.yellow.opacity(0.15)))
            
        case .leagueSubscription:
            StatusBadge("SUB", color: .green, style: .soft)
               
        case .freeLeague:
            StatusBadge("FREE", color: .blue, style: .soft)
               
        case .testingMode:
            StatusBadge("TEST", color: .purple, style: .soft)
               
        case .freeMatch:
            StatusBadge("FREE", color: .green, style: .soft)
               
        case .worldCupPurchase:
            StatusBadge("PURCHASED", color: .green, style: .soft)
        }
    }
}

// MARK: - Score Display

/// Large score display for match scores
struct ScoreDisplay: View {
    let homeScore: Int
    let awayScore: Int
    let size: Size
    
    enum Size {
        case small, medium, large
        
        var font: Font {
            switch self {
            case .small: return AppDesignSystem.Typography.scoreSmall
            case .medium: return AppDesignSystem.Typography.scoreMedium
            case .large: return AppDesignSystem.Typography.scoreLarge
            }
        }
        
        var separatorSize: CGFloat {
            switch self {
            case .small: return 14
            case .medium: return 18
            case .large: return 22
            }
        }
    }
    
    init(_ homeScore: Int, _ awayScore: Int, size: Size = .medium) {
        self.homeScore = homeScore
        self.awayScore = awayScore
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(homeScore)")
                .font(size.font)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("-")
                .font(.system(size: size.separatorSize, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.tertiaryText)
            
            Text("\(awayScore)")
                .font(size.font)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
        }
    }
}

// MARK: - Minute Display

/// Match minute indicator
struct MinuteDisplay: View {
    let minute: Int
    let injuryTime: Int?
    
    var body: some View {
        HStack(spacing: 2) {
            Text("\(minute)'")
                .font(AppDesignSystem.Typography.timeDisplay)
                .foregroundColor(AppDesignSystem.Colors.live)
            
            if let injury = injuryTime, injury > 0 {
                Text("+\(injury)")
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(AppDesignSystem.Colors.live.opacity(0.8))
            }
        }
    }
}

// MARK: - Count Badge

/// Numeric count badge (for notifications, selections, etc.)
struct CountBadge: View {
    let count: Int
    let color: Color
    
    init(_ count: Int, color: Color = AppDesignSystem.Colors.primary) {
        self.count = count
        self.color = color
    }
    
    var body: some View {
        Text("\(count)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .frame(minWidth: 22, minHeight: 22)
            .background(Circle().fill(color))
    }
}

// MARK: - Progress Ring

/// Circular progress indicator
struct ProgressRing: View {
    let progress: Double  // 0.0 to 1.0
    let color: Color
    let lineWidth: CGFloat
    
    init(progress: Double, color: Color = AppDesignSystem.Colors.primary, lineWidth: CGFloat = 4) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: lineWidth)
            
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(AppDesignSystem.Animations.smooth, value: progress)
        }
    }
}

// MARK: - Connection Status

/// Network/live connection status indicator
struct ConnectionStatus: View {
    let isConnected: Bool
    let showText: Bool
    
    init(isConnected: Bool, showText: Bool = true) {
        self.isConnected = isConnected
        self.showText = showText
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isConnected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                .frame(width: 8, height: 8)
            
            if showText {
                Text(isConnected ? "Connected" : "Offline")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isConnected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
            }
        }
    }
}

// MARK: - Empty State

/// Empty state placeholder
struct EmptyState: View {
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
                .font(AppDesignSystem.Typography.headline)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text(message)
                .font(AppDesignSystem.Typography.subheadline)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppDesignSystem.Colors.primary)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
    }
}

// MARK: - Previews

#if DEBUG
struct StatusComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                StatusBadge("LIVE", color: .red, style: .filled)
                LiveIndicator()
                CountBadge(3)
            }
            .padding()
        }
    }
}
#endif
