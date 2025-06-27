//
//  Enhanced MatchSelectionView.swift
//  Lucky Football Slip
//
//  Enhanced with vibrant design patterns
//

import SwiftUI


struct MatchSelectionView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false
    @State private var isSelectingMatch = false
    @State private var selectedMatchId: String? = nil
    @State private var error: String? = nil
    @State private var animateGradient = false
    @StateObject private var networkMonitor = NetworkMonitor()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background
                backgroundView
                
                VStack(spacing: 0) {
                    if isLoading {
                        loadingView
                    } else if let errorMessage = error {
                        errorView(errorMessage)
                    } else if gameSession.availableMatches.isEmpty {
                        emptyStateView
                    } else {
                        matchesListView
                    }
                }
            }
            .navigationTitle("Live Matches")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppDesignSystem.Colors.primary)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    animateGradient = true
                }
                
                if gameSession.availableMatches.isEmpty {
                    loadMatches()
                }
            }
        }
        .withMinimalBanner()
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.97, blue: 1.0),
                Color(red: 0.98, green: 0.95, blue: 1.0)
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppDesignSystem.Colors.primary))
                    .scaleEffect(1.5)
            }
            
            VStack(spacing: 8) {
                Text("Loading matches...")
                    .font(AppDesignSystem.Typography.headingFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                if isSelectingMatch, let matchId = selectedMatchId {
                    Text("Preparing match details...")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Error View
    
    private func errorView(_ errorMessage: String) -> some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(AppDesignSystem.Colors.error.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppDesignSystem.Colors.error)
                }
                
                VStack(spacing: 12) {
                    Text("Connection Problem")
                        .font(AppDesignSystem.Typography.headingFont)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(errorMessage)
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            VStack(spacing: 16) {
                Button("Try Again") {
                    withAnimation(AppDesignSystem.Animations.bouncy) {
                        loadMatches()
                    }
                }
                .buttonStyle(EnhancedPrimaryButtonStyle())
                
                Button("Switch to Manual Mode") {
                    withAnimation(AppDesignSystem.Animations.smooth) {
                        UserDefaults.standard.set(false, forKey: "isLiveMode")
                        NotificationCenter.default.post(
                            name: Notification.Name("AppModeChanged"),
                            object: nil
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .buttonStyle(EnhancedSecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Connection info
    
    private var liveConnectionInfo: some View {
        VStack(spacing: 8) {
            HStack {
                LiveConnectionStatus(isConnected: networkMonitor.isConnected)
                
                Spacer()
                
                if gameSession.availableMatches.isEmpty && !isLoading {
                    Button("Refresh") {
                        loadMatches()
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
            
            if networkMonitor.isConnected && !gameSession.availableMatches.isEmpty {
                HStack {
                    Image(systemName: "clock")
                        .foregroundColor(AppDesignSystem.Colors.info)
                    Text("Matches update automatically")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    Spacer()
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(AppDesignSystem.Colors.secondary.opacity(0.1))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "sportscourt")
                        .font(.system(size: 40))
                        .foregroundColor(AppDesignSystem.Colors.secondary)
                }
                
                VStack(spacing: 12) {
                    Text("No Matches Available")
                        .font(AppDesignSystem.Typography.headingFont)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("There are no live or upcoming matches at the moment. Check back later or switch to manual mode.")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            VStack(spacing: 16) {
                Button("Refresh") {
                    withAnimation(AppDesignSystem.Animations.bouncy) {
                        loadMatches()
                    }
                }
                .buttonStyle(EnhancedPrimaryButtonStyle())
                
                Button("Switch to Manual Mode") {
                    withAnimation(AppDesignSystem.Animations.smooth) {
                        UserDefaults.standard.set(false, forKey: "isLiveMode")
                        NotificationCenter.default.post(
                            name: Notification.Name("AppModeChanged"),
                            object: nil
                        )
                        NotificationCenter.default.post(
                            name: Notification.Name("ShowAssignment"),
                            object: nil
                        )
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                .buttonStyle(EnhancedSecondaryButtonStyle())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Matches List View
    
    private var matchesListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                // Header
                VStack(spacing: 8) {
                    Text("Select a Match")
                        .font(AppDesignSystem.Typography.headingFont)
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("\(gameSession.availableMatches.count) matches available")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                // Matches
                ForEach(Array(gameSession.availableMatches.enumerated()), id: \.element.id) { index, match in
                    EnhancedMatchCard(
                        match: match,
                        index: index
                    ) {
                        selectMatch(match)
                    }
                    .animation(
                        AppDesignSystem.Animations.bouncy.delay(Double(index) * 0.1),
                        value: gameSession.availableMatches.count
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Methods (keeping your existing logic)
    
    private func loadMatches() {
        isLoading = true
        error = nil
        
        if AppConfig.footballDataAPIKey.isEmpty {
            isLoading = false
            error = "Missing API key for football data service. Please check app settings."
            return
        }
        
        Task {
            do {
                try await gameSession.fetchAvailableMatches()
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    self.error = "There was a problem connecting to the football data service: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func selectMatch(_ match: Match) {
        isLoading = true
        isSelectingMatch = true
        selectedMatchId = match.id
        
        Task {
            do {
                try await gameSession.selectMatch(match)
                
                await MainActor.run {
                    isLoading = false
                    isSelectingMatch = false
                    
                    if gameSession.selectedMatch != nil {
                        presentationMode.wrappedValue.dismiss()
                        
                        NotificationCenter.default.post(
                            name: Notification.Name("StartGameWithSelectedMatch"),
                            object: nil
                        )
                    } else {
                        self.error = "Failed to load match details. Please try another match or switch to manual mode."
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    isSelectingMatch = false
                    self.error = "Error selecting match: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Enhanced Match Card

struct EnhancedMatchCard: View {
    let match: Match
    let index: Int
    let action: () -> Void
    
    @State private var isPressed = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Button(action: {
            withAnimation(AppDesignSystem.Animations.quick) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(AppDesignSystem.Animations.quick) {
                    isPressed = false
                }
                action()
            }
        }) {
            VStack(spacing: 20) {
                // Header with competition and status
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(match.competition.name)
                            .font(AppDesignSystem.Typography.callout)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Text("Match \(index + 1)")
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    enhancedStatusBadge
                }
                
                // Main match content
                HStack(spacing: 20) {
                    // Home team
                    VStack(spacing: 8) {
                        teamIcon(for: match.homeTeam)
                        
                        Text(match.homeTeam.name)
                            .font(AppDesignSystem.Typography.bodyBold)
                            .foregroundColor(AppDesignSystem.TeamColors.getColor(for: match.homeTeam))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text(match.homeTeam.shortName)
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // VS or Score
                    VStack(spacing: 8) {
                        if match.status == .inProgress || match.status == .halftime || match.status == .completed {
                            scoreDisplay
                        } else {
                            Text("VS")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                        }
                        
                        Text(formatMatchTime())
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    // Away team
                    VStack(spacing: 8) {
                        teamIcon(for: match.awayTeam)
                        
                        Text(match.awayTeam.name)
                            .font(AppDesignSystem.Typography.bodyBold)
                            .foregroundColor(AppDesignSystem.TeamColors.getColor(for: match.awayTeam))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                        
                        Text(match.awayTeam.shortName)
                            .font(AppDesignSystem.Typography.captionFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Action hint
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    
                    Text("Tap to select this match")
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.Colors.primary.opacity(0.3),
                                        AppDesignSystem.Colors.secondary.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: AppDesignSystem.Colors.primary.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Sub-components
    
    private func teamIcon(for team: Team) -> some View {
        Circle()
            .fill(
                LinearGradient(
                    colors: [
                        AppDesignSystem.TeamColors.getColor(for: team),
                        AppDesignSystem.TeamColors.getColor(for: team).opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .frame(width: 50, height: 50)
            .overlay(
                Text(team.shortName.prefix(2))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            )
            .shadow(
                color: AppDesignSystem.TeamColors.getColor(for: team).opacity(0.3),
                radius: 4,
                x: 0,
                y: 2
            )
    }
    
    private var scoreDisplay: some View {
        HStack(spacing: 8) {
            Text("0")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("-")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("0")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
        }
    }
    
    private var enhancedStatusBadge: some View {
        let (text, color) = matchStatusInfo
        
        return VibrantStatusBadge(text, color: color)
    }
    
    private var matchStatusInfo: (String, Color) {
        switch match.status {
        case .upcoming:
            return ("Upcoming", AppDesignSystem.Colors.primary)
        case .inProgress:
            return ("LIVE", AppDesignSystem.Colors.success)
        case .halftime:
            return ("Half-time", AppDesignSystem.Colors.warning)
        case .completed:
            return ("Finished", AppDesignSystem.Colors.secondary)
        case .unknown:
            return ("Unknown", AppDesignSystem.Colors.error)
        case .finished:
            return ("Finished", AppDesignSystem.Colors.accent)
        case .postponed:
            return ("Postponed", AppDesignSystem.Colors.error)
        case .cancelled:
            return ("Cancelled", AppDesignSystem.Colors.error)
        case .paused:
            return ("Paused", AppDesignSystem.Colors.warning)
        case .suspended:
            return ("Suspended", AppDesignSystem.Colors.warning)
        }
    }
    
    private func formatMatchTime() -> String {
        switch match.status {
        case .upcoming:
            return dateFormatter.string(from: match.startTime)
        case .inProgress:
            return "In Progress"
        case .halftime:
            return "Half-time"
        case .completed:
            return "Full-time"
        case .unknown:
            return "Unknown"
        case .finished:
            return "Finished"
        case .postponed:
            return "Postponed"
        case .cancelled:
            return "Cancelled"
        case .paused:
            return "Paused"
        case .suspended:
            return "Suspended"
        }
    }
}

// MARK: - Enhanced Button Styles

struct EnhancedPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppDesignSystem.Typography.bodyBold)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.primary,
                                AppDesignSystem.Colors.primary.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .shadow(
                color: AppDesignSystem.Colors.primary.opacity(0.4),
                radius: configuration.isPressed ? 4 : 8,
                x: 0,
                y: configuration.isPressed ? 2 : 4
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: configuration.isPressed)
    }
}

struct EnhancedSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(AppDesignSystem.Typography.bodyBold)
            .foregroundColor(AppDesignSystem.Colors.primary)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppDesignSystem.Colors.primary, lineWidth: 2)
                    )
            )
            .shadow(
                color: AppDesignSystem.Colors.primary.opacity(0.2),
                radius: configuration.isPressed ? 2 : 4,
                x: 0,
                y: configuration.isPressed ? 1 : 2
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: configuration.isPressed)
    }
}
