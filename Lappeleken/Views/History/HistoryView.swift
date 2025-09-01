//
//  Enhanced HistoryView.swift
//  Lucky Football Slip
//
//  Enhanced with vibrant design patterns and smooth interactions
//

import SwiftUI

struct HistoryView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var savedGames: [SavedGameSession] = []
    @State private var isLoading = true
    @State private var searchText = ""
    @State private var sortBy: SortOption = .newest
    @State private var showingSortOptions = false
    @State private var selectedGame: SavedGameSession?
    @State private var showingGameDetail = false

    
    
    enum SortOption: String, CaseIterable {
        case newest = "Newest First"
        case oldest = "Oldest First"
        case mostEvents = "Most Events"
        case mostParticipants = "Most Players"
        case alphabetical = "A-Z"
        
        var icon: String {
            switch self {
            case .newest: return "clock.arrow.circlepath"
            case .oldest: return "clock"
            case .mostEvents: return "list.number"
            case .mostParticipants: return "person.3"
            case .alphabetical: return "textformat.abc"
            }
        }
    }
    
    private var filteredAndSortedGames: [SavedGameSession] {
        let filtered = searchText.isEmpty ? savedGames : savedGames.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.participants.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return filtered.sorted { game1, game2 in
            switch sortBy {
            case .newest:
                return game1.dateSaved > game2.dateSaved
            case .oldest:
                return game1.dateSaved < game2.dateSaved
            case .mostEvents:
                return game1.events.count > game2.events.count
            case .mostParticipants:
                return game1.participants.count > game2.participants.count
            case .alphabetical:
                return game1.name < game2.name
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background
                backgroundView
                
                VStack(spacing: 0) {
                    if isLoading {
                        loadingView
                    } else if savedGames.isEmpty {
                        emptyStateView
                    } else {
                        contentView
                    }
                }
            }
            .navigationTitle("Game History")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarItems(trailing:
                                    Button("Done") {
                presentationMode.wrappedValue.dismiss()
            }
                .foregroundColor(AppDesignSystem.Colors.primary)
                .font(.system(size: 17, weight: .semibold))
            )
            .onAppear {
                loadSavedGames()
            }
            .sheet(isPresented: $showingGameDetail) {
                if let game = selectedGame {
                    GameDetailSheet(game: game)
                } else {
                    VStack {
                        Text("Error: No game selected")
                            .foregroundColor(.red)
                        Button("Close") {
                            showingGameDetail = false
                        }
                    }
                    .padding()
                    .onAppear {
                        // Debug: Check what's happening with selectedGame
                        print("❌ Sheet presented but selectedGame is nil")
                        print("❌ showingGameDetail: \(showingGameDetail)")
                        print("❌ savedGames count: \(savedGames.count)")
                    }
                }
            }
            .onChange(of: showingGameDetail) { isShowing in
                // Add this back - it's important for debugging
                print("🎭 Sheet state changed to: \(isShowing)")
                if isShowing {
                    print("🎭 Selected game: \(selectedGame?.name ?? "nil")")
                }
            }
        }
        .withSmartBanner()
        .withInterstitialAd(trigger: .historyView)
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        AppDesignSystem.Colors.background
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
                Text("Loading game history...")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Gathering your saved games")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppDesignSystem.Colors.accent.opacity(0.2),
                                    AppDesignSystem.Colors.accent.opacity(0.1),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 30,
                                endRadius: 80
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.accent,
                                    AppDesignSystem.Colors.secondary
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: AppDesignSystem.Colors.accent.opacity(0.3),
                            radius: 12,
                            x: 0,
                            y: 6
                        )
                }
                
                VStack(spacing: 12) {
                    Text("No Saved Games")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("Your saved game sessions will appear here. Start playing to create your first game history!")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Button("Start New Game") {
                presentationMode.wrappedValue.dismiss()
                NotificationCenter.default.post(
                    name: Notification.Name("StartNewGame"),
                    object: nil
                )
            }
            .buttonStyle(EnhancedPrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        VStack(spacing: 0) {
            // Header with stats and controls
            headerSection
            
            // Games list
            gamesListView
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Stats cards
            HStack(spacing: 16) {
                StatCard(
                    title: "Total Games",
                    value: "\(savedGames.count)",
                    icon: "gamecontroller.fill",
                    color: AppDesignSystem.Colors.primary
                )
                
                StatCard(
                    title: "Total Events",
                    value: "\(savedGames.reduce(0) { $0 + $1.events.count })",
                    icon: "list.bullet",
                    color: AppDesignSystem.Colors.success
                )
                
                StatCard(
                    title: "Players",
                    value: "\(uniqueParticipantCount)",
                    icon: "person.3.fill",
                    color: AppDesignSystem.Colors.accent
                )
            }
            
            // Search and sort controls
            HStack(spacing: 12) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    TextField("Search games or players...", text: $searchText)
                        .font(AppDesignSystem.Typography.bodyFont)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppDesignSystem.Colors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppDesignSystem.Colors.primary.opacity(0.2), lineWidth: 1)
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 4,
                    x: 0,
                    y: 2
                )
                
                // Sort button
                Button(action: {
                    showingSortOptions = true
                }) {
                    HStack {
                        Image(systemName: sortBy.icon)
                        Image(systemName: "chevron.down")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(AppDesignSystem.Colors.primary.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
                .actionSheet(isPresented: $showingSortOptions) {
                    ActionSheet(
                        title: Text("Sort Games By"),
                        buttons: SortOption.allCases.map { option in
                            .default(Text(option.rawValue)) {
                                withAnimation(.spring()) {
                                    sortBy = option
                                }
                            }
                        } + [.cancel()]
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
    
    private var gamesListView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                if filteredAndSortedGames.isEmpty {
                    searchEmptyState
                } else {
                    ForEach(Array(filteredAndSortedGames.enumerated()), id: \.element.id) { index, game in
                        EnhancedGameCard(
                            game: game,
                            index: index
                        ) {
                            selectedGame = game
                            showingGameDetail = true
                        }
                        .animation(
                            AppDesignSystem.Animations.bouncy.delay(Double(index) * 0.05),
                            value: filteredAndSortedGames.count
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    private var searchEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text("No games found")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text("Try adjusting your search or sort criteria")
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(.top, 60)
    }
    
    // MARK: - Helper Properties
    
    private var uniqueParticipantCount: Int {
        let allParticipants = savedGames.flatMap { $0.participants.map { $0.name } }
        return Set(allParticipants).count
    }
    
    // MARK: - Helper Methods
    
    private func loadSavedGames() {
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.savedGames = GameHistoryManager.shared.getSavedGameSessions()
            
            withAnimation(.spring()) {
                self.isLoading = false
            }
        }
    }
    
    private func deleteGames(at offsets: IndexSet) {
        for index in offsets {
            let gameToDelete = filteredAndSortedGames[index]
            GameHistoryManager.shared.deleteGameSession(gameToDelete.id)
        }
        
        withAnimation(.spring()) {
            savedGames = GameHistoryManager.shared.getSavedGameSessions()
        }
    }
}

// MARK: - Enhanced Game Card

struct EnhancedGameCard: View {
    let game: SavedGameSession
    let index: Int
    let action: () -> Void
    
    @State private var isPressed = false
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: game.dateSaved)
    }
    
    private var winner: Participant? {
        return game.participants.max(by: { $0.balance < $1.balance })
    }
    
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
            VStack(spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.name)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                            .lineLimit(2)
                        
                        Text(formattedDate)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    
                    Spacer()
                    
                    if let winner = winner, winner.balance > 0 {
                        VStack {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                                .foregroundColor(AppDesignSystem.Colors.goalYellow)
                            
                            Text("Winner")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.goalYellow)
                        }
                    }
                }
                
                // Stats row
                HStack(spacing: 20) {
                    GameStatItem(
                        icon: "person.2.fill",
                        value: "\(game.participants.count)",
                        label: "Players",
                        color: AppDesignSystem.Colors.primary
                    )
                    
                    GameStatItem(
                        icon: "list.bullet",
                        value: "\(game.events.count)",
                        label: "Events",
                        color: AppDesignSystem.Colors.success
                    )
                    
                    if let winner = winner, winner.balance > 0 {
                        GameStatItem(
                            icon: "dollarsign.circle",
                            value: formatCurrency(winner.balance),
                            label: "Top Score",
                            color: AppDesignSystem.Colors.goalYellow
                        )
                    } else {
                        GameStatItem(
                            icon: "equal.circle",
                            value: "Tied",
                            label: "Result",
                            color: AppDesignSystem.Colors.secondaryText
                        )
                    }
                }
                
                // Winner highlight or participant preview
                if let winner = winner, winner.balance > 0 {
                    HStack {
                        Text("🏆 \(winner.name) won with \(formatCurrency(winner.balance))")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.success)
                        
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppDesignSystem.Colors.success.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(AppDesignSystem.Colors.success.opacity(0.3), lineWidth: 1)
                            )
                    )
                } else {
                    Text("Players: \(game.participants.map { $0.name }.joined(separator: ", "))")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Action hint
                HStack {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    
                    Text("Tap to view details")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                winner?.balance ?? 0 > 0 ?
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.Colors.goalYellow.opacity(0.3),
                                        AppDesignSystem.Colors.success.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ) :
                                LinearGradient(
                                    colors: [
                                        AppDesignSystem.Colors.primary.opacity(0.2),
                                        AppDesignSystem.Colors.secondary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: (winner?.balance ?? 0 > 0 ? AppDesignSystem.Colors.goalYellow : AppDesignSystem.Colors.primary).opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        formatter.maximumFractionDigits = 0
        
        return formatter.string(from: NSNumber(value: value)) ?? "€0"
    }
}
// MARK: - Game Stat Item

struct GameStatItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text(label)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Game Detail Sheet

struct GameDetailSheet: View {
    let game: SavedGameSession
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = true
    @State private var showingFullSummary = false
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppDesignSystem.Colors.primary))
                            .scaleEffect(1.2)
                        
                        Text("Loading game details...")
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    gameDetailContent
                }
            }
            .navigationTitle("Game Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing:
                Button("Close") {
                    presentationMode.wrappedValue.dismiss()
                }
                .foregroundColor(AppDesignSystem.Colors.primary)
            )
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isLoading = false
                    }
                }
            }
            .sheet(isPresented: $showingFullSummary) {
                SavedGameSummaryView(savedGame: game)
            }
        }
    }
    
    private var gameDetailContent: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Game header
                VStack(spacing: 12) {
                    Text(game.name)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Saved on \(DateFormatter.localizedString(from: game.dateSaved, dateStyle: .full, timeStyle: .short))")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                // Quick stats
                HStack(spacing: 20) {
                    StatCard(
                        title: "Participants",
                        value: "\(game.participants.count)",
                        icon: "person.3.fill",
                        color: AppDesignSystem.Colors.primary
                    )
                    
                    StatCard(
                        title: "Events",
                        value: "\(game.events.count)",
                        icon: "list.bullet",
                        color: AppDesignSystem.Colors.success
                    )
                }
                
                // Final standings
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppDesignSystem.Colors.goalYellow)
                        
                        Text("Final Standings")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        Spacer()
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(Array(game.participants.sorted(by: { $0.balance > $1.balance }).enumerated()), id: \.element.id) { index, participant in
                            HStack {
                                ZStack {
                                    Circle()
                                        .fill(positionColor(index + 1))
                                        .frame(width: 28, height: 28)
                                    
                                    Text("\(index + 1)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                                
                                Text(participant.name)
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                                
                                Spacer()
                                
                                Text(formatCurrency(participant.balance))
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppDesignSystem.Colors.cardBackground)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                
                // Recent events preview
                if !game.events.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 20))
                                .foregroundColor(AppDesignSystem.Colors.accent)
                            
                            Text("Recent Events")
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                            
                            Spacer()
                            
                            VibrantStatusBadge("\(game.events.count)", color: AppDesignSystem.Colors.accent)
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(Array(game.events.suffix(3).reversed().enumerated()), id: \.element.id) { index, event in
                                HStack {
                                    Circle()
                                        .fill(eventColor(event.eventType))
                                        .frame(width: 8, height: 8)
                                    
                                    Text(event.player.name)
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                                    
                                    Text("•")
                                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    
                                    Text(event.eventType.rawValue)
                                        .font(.system(size: 14, weight: .medium, design: .rounded))
                                        .foregroundColor(eventColor(event.eventType))
                                    
                                    Spacer()
                                    
                                    Text(formatTime(event.timestamp))
                                        .font(.system(size: 12, weight: .medium, design: .rounded))
                                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        
                        if game.events.count > 3 {
                            Text("... and \(game.events.count - 3) more events")
                                .font(.system(size: 12, weight: .medium, design: .rounded))
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .italic()
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppDesignSystem.Colors.cardBackground)
                            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                    )
                }
                
                // Action buttons
                VStack(spacing: 16) {
                    Button("Continue This Game") {
                        continueGame()
                    }
                    .buttonStyle(EnhancedPrimaryButtonStyle())
                    
                    Button("View Full Summary") {
                        showingFullSummary = true
                    }
                    .buttonStyle(EnhancedSecondaryButtonStyle())

                    // Remove the export-related code and keep the sheet for full summary:
                    .sheet(isPresented: $showingFullSummary) {
                        SavedGameSummaryView(savedGame: game)
                    }
                }
                
                Spacer(minLength: 40)
            }
            .padding(20)
        }
    }
    
    // MARK: - Helper Methods
    
    private func positionColor(_ position: Int) -> Color {
        switch position {
        case 1: return AppDesignSystem.Colors.goalYellow
        case 2: return AppDesignSystem.Colors.secondary
        case 3: return AppDesignSystem.Colors.warning
        default: return AppDesignSystem.Colors.secondaryText.opacity(0.6)
        }
    }
    
    private func eventColor(_ eventType: Bet.EventType) -> Color {
        switch eventType {
        case .goal, .penalty: return AppDesignSystem.Colors.success
        case .assist: return AppDesignSystem.Colors.primary
        case .yellowCard: return AppDesignSystem.Colors.goalYellow
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.warning
        default: return AppDesignSystem.Colors.accent
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    @MainActor private func continueGame() {
        if AppPurchaseManager.shared.currentTier == .free &&
            AdManager.shared.shouldShowInterstitialForSettings() {
            showInterstitialThenContinueGame()
        } else {
            loadAndContinueGame()
        }
    }
    
    private func showInterstitialThenContinueGame() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            loadAndContinueGame()
            return
        }
        
        AdManager.shared.showInterstitialAd(from: rootViewController) { success in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.loadAndContinueGame()
            }
        }
    }
    
    private func loadAndContinueGame() {
        let gameHistoryManager = GameHistoryManager.shared
        let freshGames = gameHistoryManager.getSavedGameSessions()
        
        guard let freshGame = freshGames.first(where: { $0.id == game.id }) else {
            return
        }
        
        let restoredGameSession = GameSession()
        
        restoredGameSession.selectedPlayers = freshGame.selectedPlayers
        restoredGameSession.availablePlayers = freshGame.selectedPlayers
        
        restoredGameSession.participants.removeAll()
        for savedParticipant in freshGame.participants {
            let freshParticipant = Participant(
                name: savedParticipant.name,
                selectedPlayers: savedParticipant.selectedPlayers,
                substitutedPlayers: savedParticipant.substitutedPlayers,
                balance: 0.0
            )
            restoredGameSession.participants.append(freshParticipant)
        }
        
        var allUniquePlayersFromParticipants: [Player] = []
        for participant in restoredGameSession.participants {
            allUniquePlayersFromParticipants.append(contentsOf: participant.selectedPlayers)
            allUniquePlayersFromParticipants.append(contentsOf: participant.substitutedPlayers)
        }
        
        let uniquePlayers = Array(Set(allUniquePlayersFromParticipants.map { $0.id })).compactMap { playerId in
            allUniquePlayersFromParticipants.first { $0.id == playerId }
        }
        
        if !uniquePlayers.isEmpty {
            restoredGameSession.availablePlayers = uniquePlayers
            restoredGameSession.selectedPlayers = uniquePlayers
        }
        
        if !freshGame.bets.isEmpty {
            restoredGameSession.bets = freshGame.bets
        } else {
            restoredGameSession.addBet(eventType: .goal, amount: 10.0)
            restoredGameSession.addBet(eventType: .assist, amount: 5.0)
            restoredGameSession.addBet(eventType: .yellowCard, amount: -3.0)
            restoredGameSession.addBet(eventType: .redCard, amount: -10.0)
        }
        
        restoredGameSession.events = freshGame.events
        
        if !freshGame.events.isEmpty {
            GameLogicManager.shared.recalculateBalances(in: restoredGameSession)
        }
        
        restoredGameSession.canUndoLastEvent = false
        restoredGameSession.objectWillChange.send()
        
        let totalPlayerAssignments = restoredGameSession.participants.reduce(0) { total, participant in
            total + participant.selectedPlayers.count + participant.substitutedPlayers.count
        }
        
        if totalPlayerAssignments == 0 && !restoredGameSession.selectedPlayers.isEmpty {
            GameLogicManager.shared.assignPlayersRandomly(in: restoredGameSession)
        }
        
        guard !restoredGameSession.participants.isEmpty else {
            return
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            NotificationCenter.default.post(
                name: Notification.Name("ContinueSavedGame"),
                object: nil,
                userInfo: ["gameSession": restoredGameSession, "gameName": freshGame.name]
            )
            
            self.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Saved Game Summary View

struct SavedGameSummaryView: View {
    let savedGame: SavedGameSession
    @Environment(\.presentationMode) var presentationMode
    @State private var showAllEvents = false
    
    // Computed properties
    private var sortedEvents: [GameEvent] {
        return savedGame.events.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    private var sortedParticipants: [Participant] {
        return savedGame.participants.sorted(by: { $0.balance > $1.balance })
    }
    
    private var winner: Participant? {
        return sortedParticipants.first { $0.balance > 0 }
    }
    
    private var hasEvents: Bool {
        return !savedGame.events.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Enhanced background
                backgroundView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Enhanced header
                        headerSection
                        
                        // Winner spotlight
                        if let winner = winner {
                            winnerSpotlightSection(winner)
                        }
                        
                        // Game stats overview
                        gameStatsSection
                        
                        // Final standings
                        standingsSection
                        
                        // Events timeline
                        if hasEvents {
                            eventsSection
                        }
                        
                        // Payments section
                        paymentsSection
                        
                        // Action buttons
                        actionButtonsSection
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Game Summary")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(AppDesignSystem.Colors.primary)
                    .font(.system(size: 17, weight: .semibold))
                }
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        AppDesignSystem.Colors.background
            .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Game icon with celebration effect
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppDesignSystem.Colors.success.opacity(0.2),
                                AppDesignSystem.Colors.success.opacity(0.1),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: winner != nil ? "trophy.fill" : "flag.checkered")
                    .font(.system(size: 50, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: winner != nil ? [
                                AppDesignSystem.Colors.goalYellow,
                                AppDesignSystem.Colors.success
                            ] : [
                                AppDesignSystem.Colors.primary,
                                AppDesignSystem.Colors.secondary
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: (winner != nil ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.primary).opacity(0.3),
                        radius: 12,
                        x: 0,
                        y: 6
                    )
            }
            
            VStack(spacing: 12) {
                Text(savedGame.name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.primaryText,
                                AppDesignSystem.Colors.primary
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .multilineTextAlignment(.center)
                
                Text("Saved on \(formatDate(savedGame.dateSaved))")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Game Stats Section
    
    private var gameStatsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Participants",
                value: "\(savedGame.participants.count)",
                icon: "person.3.fill",
                color: AppDesignSystem.Colors.primary
            )
            
            StatCard(
                title: "Events",
                value: "\(savedGame.events.count)",
                icon: "list.bullet",
                color: AppDesignSystem.Colors.success
            )
            
            StatCard(
                title: "Duration",
                value: calculateGameDuration(),
                icon: "clock.fill",
                color: AppDesignSystem.Colors.info
            )
        }
    }
    
    // MARK: - Winner Spotlight
    
    private func winnerSpotlightSection(_ winner: Participant) -> some View {
        VStack(spacing: 16) {
            Text("🏆 Champion")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.goalYellow)
            
            VStack(spacing: 12) {
                Text(winner.name)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(formatCurrency(winner.balance))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                AppDesignSystem.Colors.success,
                                AppDesignSystem.Colors.grassGreen
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Final winnings")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
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
                                        AppDesignSystem.Colors.goalYellow,
                                        AppDesignSystem.Colors.success
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
            )
            .shadow(
                color: AppDesignSystem.Colors.success.opacity(0.2),
                radius: 12,
                x: 0,
                y: 6
            )
        }
    }
    
    // MARK: - Standings Section
    
    private var standingsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "list.number")
                    .font(.system(size: 20))
                    .foregroundColor(AppDesignSystem.Colors.primary)
                
                Text("Final Standings")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(Array(sortedParticipants.enumerated()), id: \.element.id) { index, participant in
                    participantRow(participant: participant, position: index + 1)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
    
    private func participantRow(participant: Participant, position: Int) -> some View {
        HStack(spacing: 16) {
            // Position badge
            ZStack {
                Circle()
                    .fill(positionColor(position))
                    .frame(width: 32, height: 32)
                
                Text("\(position)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(participant.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("\(participant.selectedPlayers.count + participant.substitutedPlayers.count) players")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Text(formatCurrency(participant.balance))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    participant.balance > 0 ?
                    AppDesignSystem.Colors.success.opacity(0.1) :
                    Color.clear
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            participant.balance > 0 ?
                            AppDesignSystem.Colors.success.opacity(0.3) :
                            Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
        )
    }
    
    private func positionColor(_ position: Int) -> Color {
        switch position {
        case 1: return AppDesignSystem.Colors.goalYellow
        case 2: return AppDesignSystem.Colors.secondary
        case 3: return AppDesignSystem.Colors.warning
        default: return AppDesignSystem.Colors.secondaryText.opacity(0.6)
        }
    }
    
    // MARK: - Events Section
    
    private var eventsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "list.bullet.clipboard")
                    .font(.system(size: 20))
                    .foregroundColor(AppDesignSystem.Colors.accent)
                
                Text("Game Events")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
                
                VibrantStatusBadge("\(sortedEvents.count)", color: AppDesignSystem.Colors.accent)
            }
            
            VStack(spacing: 12) {
                let eventsToShow = showAllEvents ? sortedEvents : Array(sortedEvents.prefix(5))
                
                ForEach(Array(eventsToShow.enumerated()), id: \.element.id) { index, event in
                    enhancedEventRow(event: event)
                        .animation(
                            AppDesignSystem.Animations.bouncy.delay(Double(index) * 0.05),
                            value: showAllEvents
                        )
                }
                
                if sortedEvents.count > 5 {
                    Button(showAllEvents ? "Show Less" : "Show All \(sortedEvents.count) Events") {
                        withAnimation(AppDesignSystem.Animations.bouncy) {
                            showAllEvents.toggle()
                        }
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.accent)
                    .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
    
    private func enhancedEventRow(event: GameEvent) -> some View {
        HStack(spacing: 12) {
            // Event icon
            Circle()
                .fill(eventColor(event.eventType).opacity(0.2))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: eventIcon(event.eventType))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(eventColor(event.eventType))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.player.name)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                HStack(spacing: 8) {
                    Text(event.eventType.rawValue)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(eventColor(event.eventType))
                    
                    Text("•")
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    
                    Text(event.player.team.name)
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            
            Spacer()
            
            Text(formatTime(event.timestamp))
                .font(AppDesignSystem.Typography.captionFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(eventColor(event.eventType).opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(eventColor(event.eventType).opacity(0.1), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Payments Section
    
    private var paymentsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "creditcard")
                    .font(.system(size: 20))
                    .foregroundColor(AppDesignSystem.Colors.info)
                
                Text("Payments")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Spacer()
            }
            
            let payments = calculatePayments()
            
            if payments.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppDesignSystem.Colors.success)
                    
                    Text("All Even!")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text("No payments needed between participants")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppDesignSystem.Colors.success.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(AppDesignSystem.Colors.success.opacity(0.3), lineWidth: 1)
                        )
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(payments.enumerated()), id: \.element.id) { index, payment in
                        paymentRow(payment: payment)
                    }
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }
    
    private func paymentRow(payment: Payment) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.from)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Pays")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Image(systemName: "arrow.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppDesignSystem.Colors.info)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(payment.to)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Receives")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
            
            Text(formatCurrency(payment.amount))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.info)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.info.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppDesignSystem.Colors.info.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Action Buttons
    
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            Button("Close") {
                presentationMode.wrappedValue.dismiss()
            }
            .buttonStyle(EnhancedPrimaryButtonStyle())
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateGameDuration() -> String {
        guard let firstEvent = savedGame.events.min(by: { $0.timestamp < $1.timestamp }),
              let lastEvent = savedGame.events.max(by: { $0.timestamp < $1.timestamp }) else {
            return "N/A"
        }
        
        let duration = lastEvent.timestamp.timeIntervalSince(firstEvent.timestamp)
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func calculatePayments() -> [Payment] {
        var payments: [Payment] = []
        
        var debtors = savedGame.participants.filter { $0.balance < 0 }
            .map { createParticipantCopy($0) }
            .sorted(by: { abs($0.balance) > abs($1.balance) })
        
        var creditors = savedGame.participants.filter { $0.balance > 0 }
            .map { createParticipantCopy($0) }
            .sorted(by: { $0.balance > $1.balance })
            
        while !debtors.isEmpty && !creditors.isEmpty {
            var debtor = debtors[0]
            var creditor = creditors[0]
            
            let paymentAmount = min(abs(debtor.balance), creditor.balance)
            
            if paymentAmount > 0.01 {
                payments.append(Payment(
                    from: debtor.name,
                    to: creditor.name,
                    amount: paymentAmount
                ))
                
                debtor.balance += paymentAmount
                creditor.balance -= paymentAmount
                
                debtors[0] = debtor
                creditors[0] = creditor
            }
            
            if abs(debtor.balance) < 0.01 {
                debtors.remove(at: 0)
            }
            
            if creditor.balance < 0.01 {
                creditors.remove(at: 0)
            }
        }
        
        return payments
    }
    
    private func createParticipantCopy(_ participant: Participant) -> Participant {
        return Participant(
            id: participant.id,
            name: participant.name,
            selectedPlayers: participant.selectedPlayers,
            substitutedPlayers: participant.substitutedPlayers,
            balance: participant.balance
        )
    }
    
    private func eventColor(_ eventType: Bet.EventType) -> Color {
        switch eventType {
        case .goal, .penalty: return AppDesignSystem.Colors.success
        case .assist: return AppDesignSystem.Colors.primary
        case .yellowCard: return AppDesignSystem.Colors.goalYellow
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.warning
        default: return AppDesignSystem.Colors.accent
        }
    }
    
    private func eventIcon(_ eventType: Bet.EventType) -> String {
        switch eventType {
        case .goal: return "soccerball"
        case .assist: return "arrow.up.forward"
        case .yellowCard, .redCard: return "square.fill"
        case .penalty: return "p.circle"
        case .ownGoal: return "arrow.uturn.backward"
        default: return "star"
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Payment Helper Struct
extension SavedGameSummaryView {
    struct Payment: Identifiable {
        let id = UUID()
        let from: String
        let to: String
        let amount: Double
    }
}

// MARK: - Enhanced Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(color)
            
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
            
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppDesignSystem.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(
            color: color.opacity(0.1),
            radius: 4,
            x: 0,
            y: 2
        )
    }
}
