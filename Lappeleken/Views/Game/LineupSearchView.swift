//
//  LineupSearchView.swift
//  Lucky Football Slip
//
//  Search for team lineups from football-data.org with rewarded ad integration
//

import SwiftUI

struct LineupSearchView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var adManager = AdManager.shared
    
    @State private var searchResults: [Match] = []
    @State private var selectedMatch: Match?
    @State private var lineup: Lineup?
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var searchPhase: SearchPhase = .initial
    @State private var selectedPlayers: Set<UUID> = []
    @State private var showAdRequired = false
    
    enum SearchPhase {
        case initial
        case loadingMatches
        case matchSelection
        case loadingLineup
        case playerSelection
        case rewardRequired
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Main content
                Group {
                    switch searchPhase {
                    case .initial, .rewardRequired:
                        initialView
                    case .loadingMatches:
                        loadingView("Searching for today's matches...")
                    case .matchSelection:
                        matchSelectionView
                    case .loadingLineup:
                        loadingView("Loading team lineups...")
                    case .playerSelection:
                        playerSelectionView
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                // Bottom button
                if searchPhase == .playerSelection {
                    bottomActionButton
                }
            }
            .navigationTitle("Search Lineups")
            .navigationBarItems(
                leading: Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: searchPhase == .playerSelection ? Button("Add Players") {
                    addSelectedPlayers()
                }.disabled(selectedPlayers.isEmpty) : nil
            )
            .alert("Lineup Search", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .alert("Watch Ad to Continue", isPresented: $showAdRequired) {
                Button("Watch Ad") {
                    showRewardedAd()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Watch a short ad to unlock team lineup search and add professional players to your game!")
            }
        }
    }
    
    // MARK: - Views
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lineup Search")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Find real team lineups and add professional players")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if searchPhase == .rewardRequired {
                HStack {
                    Image(systemName: "gift.fill")
                        .foregroundColor(.orange)
                    
                    Text("Premium feature - Watch ad to unlock")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(UIColor.systemBackground))
    }
    
    private var initialView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Search Team Lineups")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Find today's matches and import real team lineups with professional players into your game.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            
            VStack(spacing: 12) {
                Button("Search Today's Matches") {
                    if searchPhase == .rewardRequired {
                        showAdRequired = true
                    } else {
                        searchForMatches()
                    }
                }
                .buttonStyle(.borderedProminent)
                .font(.headline)
                
                if searchPhase != .rewardRequired {
                    Text("Powered by football-data.org")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .onAppear {
            checkAdRequirement()
        }
    }
    
    private func loadingView(_ message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var matchSelectionView: some View {
        VStack(spacing: 16) {
            Text("Select a Match")
                .font(.headline)
                .padding(.top, 20)
            
            if searchResults.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    
                    Text("No matches found for today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Try Again") {
                        searchForMatches()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults, id: \.id) { match in
                            MatchCard(match: match) {
                                selectMatch(match)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private var playerSelectionView: some View {
        VStack(spacing: 0) {
            if let lineup = lineup {
                Text("Select Players to Add")
                    .font(.headline)
                    .padding(.vertical, 16)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Home team
                        TeamLineupSection(
                            team: lineup.homeTeam.team,
                            players: lineup.homeTeam.startingXI + lineup.homeTeam.substitutes,
                            selectedPlayers: $selectedPlayers
                        )
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        // Away team
                        TeamLineupSection(
                            team: lineup.awayTeam.team,
                            players: lineup.awayTeam.startingXI + lineup.awayTeam.substitutes,
                            selectedPlayers: $selectedPlayers
                        )
                    }
                    .padding(.bottom, 100) // Space for bottom button
                }
            }
        }
    }
    
    private var bottomActionButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button("Add \(selectedPlayers.count) Players") {
                addSelectedPlayers()
            }
            .disabled(selectedPlayers.isEmpty)
            .buttonStyle(.borderedProminent)
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(UIColor.systemBackground))
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkAdRequirement() {
        // Check if user needs to watch ad for this feature
        if AppPurchaseManager.shared.currentTier == .free {
            // For free users, require rewarded ad
            searchPhase = .rewardRequired
        } else {
            // Premium users get direct access
            searchPhase = .initial
        }
    }
    
    private func showRewardedAd() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            showErrorMessage(message: "Cannot show ad at this time")
            return
        }
        
        adManager.showRewardedAd(from: rootViewController) { [self] success in
            DispatchQueue.main.async {
                if success {
                    // Ad watched successfully, grant access
                    searchPhase = .initial
                    // Track the rewarded ad usage
                    adManager.trackAdImpression(type: "rewarded_lineup_search")
                } else {
                    showErrorMessage(message: "Ad failed to load. Please try again later.")
                }
            }
        }
    }
    
    private func searchForMatches() {
        searchPhase = .loadingMatches
        
        Task {
            do {
                // Use the football data service to fetch today's matches
                let matchService = ServiceProvider.shared.getMatchService()
                if let footballService = matchService as? FootballDataMatchService {
                    let matches = try await footballService.fetchTodaysMatchesForLineupSearch()
                    
                    DispatchQueue.main.async {
                        self.searchResults = matches
                        self.searchPhase = .matchSelection
                    }
                } else {
                    throw NSError(domain: "LineupSearch", code: 1, userInfo: [
                        NSLocalizedDescriptionKey: "Match service not available"
                    ])
                }
            } catch {
                DispatchQueue.main.async {
                    self.showErrorMessage(message: "Failed to load matches: \(error.localizedDescription)")
                    self.searchPhase = .initial
                }
            }
        }
    }
    
    private func selectMatch(_ match: Match) {
        selectedMatch = match
        searchPhase = .loadingLineup
        
        Task {
            do {
                let matchService = ServiceProvider.shared.getMatchService()
                if let footballService = matchService as? FootballDataMatchService {
                    let matchLineup = try await footballService.fetchMatchLineupForSearch(matchId: match.id)
                    
                    DispatchQueue.main.async {
                        self.lineup = matchLineup
                        self.searchPhase = .playerSelection
                    }
                } else {
                    throw NSError(domain: "LineupSearch", code: 2, userInfo: [
                        NSLocalizedDescriptionKey: "Cannot fetch lineup"
                    ])
                }
            } catch {
                DispatchQueue.main.async {
                    self.showErrorMessage(message: "Failed to load lineup: \(error.localizedDescription)")
                    self.searchPhase = .matchSelection
                }
            }
        }
    }
    
    private func addSelectedPlayers() {
        guard let lineup = lineup else { return }
        
        let allPlayers = lineup.homeTeam.startingXI + lineup.homeTeam.substitutes +
                        lineup.awayTeam.startingXI + lineup.awayTeam.substitutes
        
        let playersToAdd = allPlayers.filter { selectedPlayers.contains($0.id) }
        
        // Add players to game session (avoiding duplicates)
        for player in playersToAdd {
            if !gameSession.availablePlayers.contains(where: { $0.id == player.id }) {
                gameSession.availablePlayers.append(player)
            }
        }
        
        // Save the updated players list
        gameSession.saveCustomPlayers()
        
        // Track success
        print("✅ Added \(playersToAdd.count) players from lineup search")
        
        presentationMode.wrappedValue.dismiss()
    }
    
    private func showErrorMessage(message: String) {
        errorMessage = message
        showError = true
    }
}

// MARK: - Match Card Component

struct MatchCard: View {
    let match: Match
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(match.homeTeam.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("vs")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text(match.awayTeam.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text(match.competition.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(formatMatchTime(match.startTime))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatMatchTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Team Lineup Section Component

struct TeamLineupSection: View {
    let team: Team
    let players: [Player]
    @Binding var selectedPlayers: Set<UUID>
    
    @State private var isExpanded = true
    
    var body: some View {
        VStack(spacing: 12) {
            // Team header
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Circle()
                        .fill(AppDesignSystem.TeamColors.getColor(for: team))
                        .frame(width: 24, height: 24)
                    
                    Text(team.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text("(\(players.count) players)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // Select all/none button
                    Button(allPlayersSelected ? "Deselect All" : "Select All") {
                        if allPlayersSelected {
                            for player in players {
                                selectedPlayers.remove(player.id)
                            }
                        } else {
                            for player in players {
                                selectedPlayers.insert(player.id)
                            }
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.trailing, 8)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(AppDesignSystem.TeamColors.getColor(for: team).opacity(0.1))
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Players grid
            if isExpanded {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(players, id: \.id) { player in
                        LineupPlayerCard(
                            player: player,
                            isSelected: selectedPlayers.contains(player.id),
                            onToggleSelection: {
                                if selectedPlayers.contains(player.id) {
                                    selectedPlayers.remove(player.id)
                                } else {
                                    selectedPlayers.insert(player.id)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
    
    private var allPlayersSelected: Bool {
        players.allSatisfy { selectedPlayers.contains($0.id) }
    }
}

// MARK: - Lineup Player Card Component

struct LineupPlayerCard: View {
    let player: Player
    let isSelected: Bool
    let onToggleSelection: () -> Void
    
    var body: some View {
        Button(action: onToggleSelection) {
            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(player.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Text(player.position.rawValue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .green : .gray)
                        .font(.title3)
                }
                
                if isSelected {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        
                        Text("Will be added")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.green.opacity(0.1) : Color.gray.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
