//
//  BackgroundSetupGuideView.swift
//  Lucky Football Slip
//

import SwiftUI
import UserNotifications

struct BackgroundSetupGuideView: View {
    @StateObject private var permissionsManager = BackgroundPermissionsManager()
    @Environment(\.presentationMode) var presentationMode
    @State private var currentInstructionIndex = 0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Benefits section
                    benefitsSection
                    
                    // Setup instructions
                    if permissionsManager.needsSetup {
                        setupInstructionsSection
                    } else {
                        allSetSection
                    }
                    
                    // Action buttons
                    actionButtonsSection
                    
                    Spacer(minLength: 40)
                }
                .padding(20)
            }
            .navigationTitle("Background Monitoring")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear {
            permissionsManager.checkAllPermissions()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppDesignSystem.Colors.primary.opacity(0.3),
                                AppDesignSystem.Colors.primary.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 30,
                            endRadius: 80
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "bell.badge.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppDesignSystem.Colors.primary, AppDesignSystem.Colors.info],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("Stay Updated on Live Matches")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("Get notified instantly when events happen in your live games, even when the app is closed.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var benefitsSection: some View {
        VStack(spacing: 16) {
            Text("What You'll Get")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            VStack(spacing: 12) {
                BenefitRow(
                    icon: "bell.fill",
                    title: "Instant Notifications",
                    description: "Get notified as soon as goals, cards, and other events happen"
                )
                
                BenefitRow(
                    icon: "clock.fill",
                    title: "Real-time Updates",
                    description: "Stay updated even when you're not actively using the app"
                )
                
                BenefitRow(
                    icon: "battery.100.bolt.fill",
                    title: "Battery Optimized",
                    description: "Smart monitoring that doesn't drain your battery"
                )
            }
        }
        .enhancedCard()
    }
    
    private var setupInstructionsSection: some View {
        VStack(spacing: 20) {
            Text("Quick Setup Required")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            ForEach(permissionsManager.setupInstructions, id: \.title) { instruction in
                InstructionCard(instruction: instruction)
            }
        }
    }
    
    private var allSetSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 50))
                .foregroundColor(AppDesignSystem.Colors.success)
            
            Text("You're All Set!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.success)
            
            Text("Background monitoring is enabled and ready to keep you updated on live match events.")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .enhancedCard()
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button("Open Settings") {
                openAppSettings()
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppDesignSystem.Colors.primary)
            )
            
            Button("Check Again") {
                permissionsManager.checkAllPermissions()
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(AppDesignSystem.Colors.primary)
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppDesignSystem.Colors.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct InstructionCard: View {
    let instruction: PermissionInstruction
    @State private var isExpanded = false
    
    var body: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isExpanded.toggle()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: instruction.systemIcon)
                        .font(.system(size: 20))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(instruction.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text(instruction.description)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(instruction.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 24, height: 24)
                                .background(Circle().fill(AppDesignSystem.Colors.primary))
                            
                            Text(step)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - Background Permissions Manager

class BackgroundPermissionsManager: ObservableObject {
    @Published var backgroundRefreshStatus: UIBackgroundRefreshStatus = .denied
    @Published var notificationStatus: UNAuthorizationStatus = .notDetermined
    @Published var isLowPowerModeEnabled: Bool = false
    
    func checkAllPermissions() {
        checkBackgroundRefreshStatus()
        checkNotificationStatus()
        checkLowPowerMode()
    }
    
    private func checkBackgroundRefreshStatus() {
        backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
    }
    
    private func checkNotificationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationStatus = settings.authorizationStatus
            }
        }
    }
    
    private func checkLowPowerMode() {
        isLowPowerModeEnabled = ProcessInfo.processInfo.isLowPowerModeEnabled
    }
    
    var needsSetup: Bool {
        return backgroundRefreshStatus != .available ||
               notificationStatus != .authorized ||
               isLowPowerModeEnabled
    }
    
    var setupInstructions: [PermissionInstruction] {
        var instructions: [PermissionInstruction] = []
        
        if backgroundRefreshStatus != .available {
            instructions.append(.backgroundRefresh)
        }
        
        if notificationStatus != .authorized {
            instructions.append(.notifications)
        }
        
        if isLowPowerModeEnabled {
            instructions.append(.lowPowerMode)
        }
        
        return instructions
    }
}

enum PermissionInstruction: CaseIterable {
    case backgroundRefresh
    case notifications
    case lowPowerMode
    
    var title: String {
        switch self {
        case .backgroundRefresh: return "Enable Background App Refresh"
        case .notifications: return "Allow Notifications"
        case .lowPowerMode: return "Disable Low Power Mode"
        }
    }
    
    var description: String {
        switch self {
        case .backgroundRefresh:
            return "Allows the app to check for match events when closed"
        case .notifications:
            return "Get notified when goals and events happen"
        case .lowPowerMode:
            return "Low Power Mode prevents background monitoring"
        }
    }
    
    var steps: [String] {
        switch self {
        case .backgroundRefresh:
            return [
                "Open Settings app",
                "Tap 'General'",
                "Tap 'Background App Refresh'",
                "Turn ON 'Background App Refresh'",
                "Find 'Lucky Football Slip' and turn it ON"
            ]
        case .notifications:
            return [
                "Open Settings app",
                "Tap 'Notifications'",
                "Find 'Lucky Football Slip'",
                "Turn ON 'Allow Notifications'"
            ]
        case .lowPowerMode:
            return [
                "Open Settings app",
                "Tap 'Battery'",
                "Turn OFF 'Low Power Mode'"
            ]
        }
    }
    
    var systemIcon: String {
        switch self {
        case .backgroundRefresh: return "arrow.clockwise.circle"
        case .notifications: return "bell.circle"
        case .lowPowerMode: return "battery.100.circle"
        }
    }
}
