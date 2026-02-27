//
//  MatchSelectionView.swift
//  Lucky Football Slip
//
//  Live match selection - Football themed
//

import SwiftUI

struct MatchSelectionView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var isLoading = false
    @State private var isSelectingMatch = false
    @State private var selectedMatches: [Match] = []
    @State private var error: String? = nil
    @StateObject private var networkMonitor = NetworkMonitor()
    
    var body: some View {
        NavigationView {
            ZStack {
                footballBackground
                
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
            .navigationTitle("Live Matches")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .onAppear {
                if gameSession.availableMatches.isEmpty { loadMatches() }
            }
        }
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            
            VStack {
                LinearGradient(
                    colors: [AppDesignSystem.Colors.grassGreen.opacity(colorScheme == .dark ? 0.15 : 0.08), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 200)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.grassGreen.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: AppDesignSystem.Colors.grassGreen))
                    .scaleEffect(1.3)
            }
            
            VStack(spacing: 6) {
                Text(isSelectingMatch ? "Preparing match..." : "Loading matches...")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Fetching live data")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
    
    // MARK: - Error View
    
    private func errorView(_ message: String) -> some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.error.opacity(0.15))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "wifi.exclamationmark")
                    .font(.system(size: 36))
                    .foregroundColor(AppDesignSystem.Colors.error)
            }
            
            VStack(spacing: 8) {
                Text("Connection Problem")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(message)
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                Button(action: { loadMatches() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Try Again")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AppDesignSystem.Colors.grassGreen))
                }
                
                Button(action: { switchToManualMode() }) {
                    Text("Use Manual Mode")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppDesignSystem.Colors.secondaryText.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sportscourt")
                    .font(.system(size: 36))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            VStack(spacing: 8) {
                Text("No Matches Available")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("There are no live or upcoming matches right now. Check back later.")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                Button(action: { loadMatches() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AppDesignSystem.Colors.grassGreen))
                }
                
                Button(action: { switchToManualMode() }) {
                    Text("Use Manual Mode")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
        }
    }
    
    // MARK: - Matches List
    
    private var matchesListView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // Stats header
                matchesHeader
                
                // Group by competition
                let grouped = Dictionary(grouping: gameSession.availableMatches) { $0.competition.name }
                
                ForEach(Array(grouped.keys).sorted(), id: \.self) { competition in
                    if let matches = grouped[competition] {
                        CompetitionSection(
                            competitionName: competition,
                            matches: matches,
                            selectedMatches: $selectedMatches,
                            onSelectMatch: selectMatch
                        )
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(16)
        }
    }
    
    private var matchesHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(gameSession.availableMatches.count) matches")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                let liveCount = gameSession.availableMatches.filter { $0.status == .inProgress }.count
                if liveCount > 0 {
                    Text("\(liveCount) live now")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
            
            Spacer()
            
            Button(action: { loadMatches() }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 14))
                    .foregroundColor(AppDesignSystem.Colors.grassGreen)
                    .padding(8)
                    .background(Circle().fill(AppDesignSystem.Colors.grassGreen.opacity(0.1)))
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Actions
    
    private func loadMatches() {
        isLoading = true
        error = nil
        
        Task {
            do {
                try await gameSession.fetchAvailableMatches()
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }

    private func selectMatch(_ match: Match) {
        isSelectingMatch = true
        isLoading = true
        
        Task {
            await gameSession.selectMatch(match)
            await MainActor.run {
                isLoading = false
                isSelectingMatch = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
    
    private func switchToManualMode() {
        UserDefaults.standard.set(false, forKey: "isLiveMode")
        NotificationCenter.default.post(name: Notification.Name("AppModeChanged"), object: nil)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Competition Section

struct CompetitionSection: View {
    let competitionName: String
    let matches: [Match]
    @Binding var selectedMatches: [Match]
    let onSelectMatch: (Match) -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Competition header
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 12))
                    .foregroundColor(AppDesignSystem.Colors.goalYellow)
                
                Text(competitionName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                Text("\(matches.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(AppDesignSystem.Colors.grassGreen))
            }
            .padding(.horizontal, 4)
            
            // Matches
            VStack(spacing: 8) {
                ForEach(matches, id: \.id) { match in
                    MatchCard(
                        match: match,
                        isSelected: selectedMatches.contains { $0.id == match.id },
                        onSelect: { onSelectMatch(match) }
                    )
                }
            }
        }
    }
}

// MARK: - Match Card

struct MatchCard: View {
    let match: Match
    let isSelected: Bool
    let onSelect: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    private var statusInfo: (text: String, color: Color) {
        switch match.status {
        case .inProgress: return ("LIVE", AppDesignSystem.Colors.grassGreen)
        case .halftime: return ("HT", AppDesignSystem.Colors.goalYellow)
        case .upcoming: return ("Upcoming", AppDesignSystem.Colors.info)
        case .completed, .finished: return ("FT", AppDesignSystem.Colors.secondaryText)
        default: return ("—", AppDesignSystem.Colors.secondaryText)
        }
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) { isPressed = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) { isPressed = false }
                onSelect()
            }
        }) {
            VStack(spacing: 12) {
                // Status badge
                HStack {
                    statusBadge
                    Spacer()
                    Text(formatTime())
                        .font(.system(size: 11))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                // Teams
                HStack(spacing: 12) {
                    teamColumn(match.homeTeam)
                    
                    // Score or VS
                    VStack(spacing: 2) {
                        if match.status == .inProgress || match.status == .halftime || match.status == .completed || match.status == .finished {
                            HStack(spacing: 6) {
                                Text("0")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                Text("-")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                Text("0")
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        } else {
                            Text("vs")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                    }
                    .frame(width: 70)
                    
                    teamColumn(match.awayTeam)
                }
                
                // Select prompt
                HStack {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 11))
                    Text("Tap to select")
                        .font(.system(size: 11))
                }
                .foregroundColor(AppDesignSystem.Colors.grassGreen)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                match.status == .inProgress ? AppDesignSystem.Colors.grassGreen.opacity(0.4) : Color.clear,
                                lineWidth: 1.5
                            )
                    )
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05),
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusBadge: some View {
        HStack(spacing: 4) {
            if match.status == .inProgress {
                Circle()
                    .fill(statusInfo.color)
                    .frame(width: 6, height: 6)
            }
            Text(statusInfo.text)
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Capsule().fill(statusInfo.color))
    }
    
    private func teamColumn(_ team: Team) -> some View {
        VStack(spacing: 6) {
            Circle()
                .fill(AppDesignSystem.TeamColors.getColor(for: team))
                .frame(width: 36, height: 36)
                .overlay(
                    Text(team.shortName.prefix(2))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                )
            
            Text(team.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func formatTime() -> String {
        if match.status == .upcoming {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: match.startTime)
        }
        return ""
    }
}
