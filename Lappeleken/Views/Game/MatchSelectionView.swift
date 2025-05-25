//
//  MatchSelectionView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 20/05/2025.
//

import SwiftUI

struct MatchSelectionView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false
    @State private var isSelectingMatch = false
    @State private var selectedMatchId: String? = nil
    @State private var error: String? = nil
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("Loading matches...")
                        .padding()
                    
                    if isSelectingMatch, let matchId = selectedMatchId {
                        Text("Preparing match details for \(matchId)...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                    }
                } else if let errorMessage = error {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(AppDesignSystem.Colors.error)
                        
                        Text("Error Loading Matches")
                            .font(AppDesignSystem.Typography.headingFont)
                        
                        Text(errorMessage)
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Try Again") {
                            loadMatches()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button("Go to Manual Mode") {
                            UserDefaults.standard.set(false, forKey: "isLiveMode")
                            NotificationCenter.default.post(
                                name: Notification.Name("AppModeChanged"),
                                object: nil
                            )
                            presentationMode.wrappedValue.dismiss()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                } else if gameSession.availableMatches.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "sportscourt")
                            .font(.system(size: 60))
                            .foregroundColor(AppDesignSystem.Colors.secondary)
                        
                        Text("No matches available")
                            .font(AppDesignSystem.Typography.headingFont)
                        
                        Text("There are no live or upcoming matches at the moment. Check back later or switch to manual mode.")
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Refresh") {
                            loadMatches()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        
                        Button("Switch to Manual Mode") {
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
                        .buttonStyle(SecondaryButtonStyle())
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            Text("Select a Match")
                                .font(AppDesignSystem.Typography.headingFont)
                                .padding(.top)
                            
                            ForEach(gameSession.availableMatches) { match in
                                MatchCard(match: match)
                                    .onTapGesture {
                                        selectMatch(match)
                                    }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Live Matches")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                // Don't reload if we already have matches
                if gameSession.availableMatches.isEmpty {
                    loadMatches()
                }
            }
        }
    }
    
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
                    
                    // Only dismiss if we successfully selected a match
                    if gameSession.selectedMatch != nil {
                        // This will dismiss the sheet and ContentView will handle starting the game
                        presentationMode.wrappedValue.dismiss()
                        
                        // PostNotification to start the game
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

struct MatchCard: View {
    let match: Match
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        CardView {
            VStack {
                HStack {
                    Text(match.competition.name)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    matchStatusBadge
                }
                
                HStack(spacing: 20) {
                    TeamView(team: match.homeTeam)
                    
                    Text("vs")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    TeamView(team: match.awayTeam)
                }
                .padding(.vertical, 8)
                
                Text(dateFormatter.string(from: match.startTime))
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            .padding(.horizontal, 4)
        }
    }
    
    private var matchStatusBadge: some View {
        let (text, color) = matchStatusInfo
        
        return Text(text)
            .font(AppDesignSystem.Typography.captionFont)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(8)
    }
    
    private var matchStatusInfo: (String, Color) {
        switch match.status {
        case .upcoming:
            return ("Upcoming", AppDesignSystem.Colors.primary)
        case .inProgress:
            return ("Live", AppDesignSystem.Colors.success)
        case .halftime:
            return ("Half-time", AppDesignSystem.Colors.primary)
        case .completed:
            return ("Finished", AppDesignSystem.Colors.secondary)
        case .unknown:
            return ("Unknown", AppDesignSystem.Colors.error)
        }
    }
}

struct TeamView: View {
    let team: Team
    
    var body: some View {
        VStack {
            Text(team.name)
                .font(AppDesignSystem.Typography.bodyFont.bold())
                .foregroundColor(AppDesignSystem.TeamColors.getColor(for: team))
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
    }
}
