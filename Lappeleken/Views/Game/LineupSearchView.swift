//
//  LineupSearchView.swift
//  Lucky Football Slip
//
//  Search for team lineups from football-data.org
//

import SwiftUI

struct LineupSearchView: View {
    @ObservedObject var gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    
    @State private var searchResults: [Match] = []
    @State private var selectedMatch: Match?
    @State private var lineup: Lineup?
    @State private var searchPhase: SearchPhase = .initial
    @State private var selectedPlayers: Set<UUID> = []
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var showFeatureInfo = false
    
    enum SearchPhase {
        case initial
        case loadingMatches
        case matchSelection
        case loadingLineup
        case playerSelection
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                
                Group {
                    switch searchPhase {
                    case .initial:
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
                
                if searchPhase == .playerSelection {
                    bottomActionButton
                }
            }
            .navigationTitle("Search Lineups")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if searchPhase == .playerSelection {
                        if #available(iOS 16.0, *) {
                            Button("Add") {
                                addSelectedPlayers()
                            }
                            .disabled(selectedPlayers.isEmpty)
                            .fontWeight(.semibold)
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .sheet(isPresented: $showFeatureInfo) {
                featureInfoSheet
            }
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lineup Search")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("Import real team lineups")
                        .font(.caption)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                Button(action: { showFeatureInfo = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(AppDesignSystem.Colors.primary)
                        .font(.title3)
                }
            }
            
            // Feature status
            featureStatusBanner
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(AppDesignSystem.Colors.cardBackground)
    }
    
    @ViewBuilder
    private var featureStatusBanner: some View {
        if AppConfig.canAccessLineupSearch {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Available during testing")
            }
            .font(.subheadline)
            .foregroundColor(AppDesignSystem.Colors.success)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppDesignSystem.Colors.success.opacity(0.1))
            .cornerRadius(8)
        } else {
            HStack(spacing: 8) {
                Image(systemName: "lock.circle.fill")
                Text("Premium feature - Coming soon")
            }
            .font(.subheadline)
            .foregroundColor(AppDesignSystem.Colors.warning)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(AppDesignSystem.Colors.warning.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Initial View
    
    private var initialView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "sportscourt.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Search Team Lineups")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Find today's matches and import real team lineups into your game.")
                    .font(.subheadline)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 12) {
                if AppConfig.canAccessLineupSearch {
                    Button(action: searchForMatches) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                            Text("Search Today's Matches")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(AppDesignSystem.Colors.primary)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    
                    Text("Powered by football-data.org")
                        .font(.caption)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                } else {
                    Button(action: { showFeatureInfo = true }) {
                        Text("Feature Not Available")
                            .font(.headline)
                    }
                    .buttonStyle(.bordered)
                    .disabled(true)
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Match Selection
    
    private var matchSelectionView: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Select a Match")
                    .font(.headline)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                Button("Back") {
                    withAnimation { searchPhase = .initial }
                }
                .font(.subheadline)
                .foregroundColor(AppDesignSystem.Colors.primary)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            if searchResults.isEmpty {
                emptyMatchesView
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(searchResults, id: \.id) { match in
                            LineupMatchCard(match: match) {
                                selectMatch(match)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private var emptyMatchesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("No matches found for today")
                .font(.headline)
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Button("Try Again") {
                searchForMatches()
            }
            .font(.subheadline)
            .foregroundColor(AppDesignSystem.Colors.primary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Player Selection
    
    private var playerSelectionView: some View {
        VStack(spacing: 0) {
            if let lineup = lineup, let match = selectedMatch {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Select Players")
                            .font(.headline)
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Text("\(match.homeTeam.shortName) vs \(match.awayTeam.shortName)")
                            .font(.subheadline)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    VibrantStatusBadge("\(selectedPlayers.count) selected", color: AppDesignSystem.Colors.success)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Home team
                        LineupTeamSection(
                            team: lineup.homeTeam.team,
                            players: lineup.homeTeam.startingXI + lineup.homeTeam.substitutes,
                            selectedPlayers: $selectedPlayers
                        )
                        
                        Divider().padding(.horizontal, 20)
                        
                        // Away team
                        LineupTeamSection(
                            team: lineup.awayTeam.team,
                            players: lineup.awayTeam.startingXI + lineup.awayTeam.substitutes,
                            selectedPlayers: $selectedPlayers
                        )
                    }
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    // MARK: - Bottom Action
    
    private var bottomActionButton: some View {
        VStack(spacing: 0) {
            Divider()
            
            Button(action: addSelectedPlayers) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add \(selectedPlayers.count) Players")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    selectedPlayers.isEmpty ?
                    Color.gray : AppDesignSystem.Colors.success
                )
                .cornerRadius(12)
            }
            .disabled(selectedPlayers.isEmpty)
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(AppDesignSystem.Colors.cardBackground)
        }
    }
    
    // MARK: - Feature Info Sheet
    
    private var featureInfoSheet: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Lineup Search")
                    .font(.title2)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 16) {
                    featureRow("1", "Search", "Find today's football matches")
                    featureRow("2", "Select", "Choose a match to view lineups")
                    featureRow("3", "Import", "Add professional players to your game")
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppDesignSystem.Colors.cardBackground)
                )
                
                if AppConfig.canAccessLineupSearch {
                    Text("This feature is free during our testing period!")
                        .font(.subheadline)
                        .foregroundColor(AppDesignSystem.Colors.success)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
            }
            .padding(24)
            .navigationTitle("Feature Info")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { showFeatureInfo = false }
                }
            }
        }
    }
    
    private func featureRow(_ number: String, _ title: String, _ desc: String) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(AppDesignSystem.Colors.primary)
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Loading View
    
    private func loadingView(_ message: String) -> some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .tint(AppDesignSystem.Colors.primary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    
    private func searchForMatches() {
        guard AppConfig.canAccessLineupSearch else {
            showFeatureInfo = true
            return
        }
        
        searchPhase = .loadingMatches
        
        Task {
            do {
                let matches = try await DataManager.shared.fetchMatches()
                
                await MainActor.run {
                    self.searchResults = matches
                    self.searchPhase = .matchSelection
                    
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load matches: \(error.localizedDescription)"
                    self.showError = true
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
                var players: [Player] = []
                
                // Try official lineup first
                do {
                    players = try await DataManager.shared.fetchPlayers(for: match.id)
                    print("✅ Got official lineup: \(players.count) players")
                } catch LineupError.notAvailableYet {
                    // Fallback to full squad
                    print("⚠️ Lineup not available, fetching full squad...")
                    players = try await DataManager.shared.fetchSquad(for: match.id)
                    print("✅ Got squad fallback: \(players.count) players")
                }
                
                guard !players.isEmpty else {
                    await MainActor.run {
                        self.errorMessage = "No players found for this match."
                        self.showError = true
                        self.searchPhase = .matchSelection
                    }
                    return
                }
                
                // Group players by team
                let homePlayers = players.filter { $0.team.id == match.homeTeam.id }
                let awayPlayers = players.filter { $0.team.id == match.awayTeam.id }
                
                // Create lineup from fetched players
                let matchLineup = Lineup(
                    homeTeam: TeamLineup(team: match.homeTeam, formation: nil, startingXI: homePlayers, substitutes: [], coach: nil),
                    awayTeam: TeamLineup(team: match.awayTeam, formation: nil, startingXI: awayPlayers, substitutes: [], coach: nil)
                )
                
                await MainActor.run {
                    self.lineup = matchLineup
                    self.searchPhase = .playerSelection
                    
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load lineup: \(error.localizedDescription)"
                    self.showError = true
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
        
        // Add players avoiding duplicates
        var addedCount = 0
        for player in playersToAdd {
            if !gameSession.availablePlayers.contains(where: { $0.id == player.id }) {
                gameSession.availablePlayers.append(player)
                addedCount += 1
            }
        }
        
        // Save and dismiss
        gameSession.saveCustomPlayers()
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
        
        print("✅ Added \(addedCount) players from lineup search")
        
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Lineup Match Card

struct LineupMatchCard: View {
    let match: Match
    let onSelect: () -> Void
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(match.homeTeam.name)
                            .fontWeight(.medium)
                        
                        Text("vs")
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Text(match.awayTeam.name)
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    HStack {
                        Text(match.competition.name)
                        Spacer()
                        Text(timeFormatter.string(from: match.startTime))
                    }
                    .font(.caption)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppDesignSystem.Colors.primary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppDesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Lineup Team Section

struct LineupTeamSection: View {
    let team: Team
    let players: [Player]
    @Binding var selectedPlayers: Set<UUID>
    
    @State private var isExpanded = true
    
    private var allSelected: Bool {
        players.allSatisfy { selectedPlayers.contains($0.id) }
    }
    
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
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("(\(players.count))")
                        .font(.subheadline)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Spacer()
                    
                    Button(allSelected ? "Deselect All" : "Select All") {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        
                        if allSelected {
                            players.forEach { selectedPlayers.remove($0.id) }
                        } else {
                            players.forEach { selectedPlayers.insert($0.id) }
                        }
                    }
                    .font(.caption)
                    .foregroundColor(AppDesignSystem.Colors.primary)
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppDesignSystem.TeamColors.getAccentColor(for: team))
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 20)
            
            // Players grid
            if isExpanded {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 10) {
                    ForEach(players, id: \.id) { player in
                        LineupPlayerSelectCard(
                            player: player,
                            isSelected: selectedPlayers.contains(player.id)
                        ) {
                            let impact = UIImpactFeedbackGenerator(style: .light)
                            impact.impactOccurred()
                            
                            if selectedPlayers.contains(player.id) {
                                selectedPlayers.remove(player.id)
                            } else {
                                selectedPlayers.insert(player.id)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Lineup Player Card

struct LineupPlayerSelectCard: View {
    let player: Player
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(player.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    Text(player.position.rawValue)
                        .font(.caption)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.secondaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? AppDesignSystem.Colors.success.opacity(0.1) : AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isSelected ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.secondaryText.opacity(0.2),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
