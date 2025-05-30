//
//  Enhanced EventsTimelineView.swift
//  Lucky Football Slip
//
//  Enhanced with vibrant design patterns and smooth animations
//

import SwiftUI

struct EventsTimelineView: View {
    @ObservedObject var gameSession: GameSession
    @State private var animateGradient = false
    @State private var showingFilters = false
    @State private var selectedFilter: EventFilter = .all
    @State private var animationOffsets: [UUID: CGFloat] = [:]
    
    enum EventFilter: String, CaseIterable {
        case all = "All Events"
        case goals = "Goals & Assists"
        case cards = "Cards"
        case custom = "Custom"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .goals: return "soccerball"
            case .cards: return "square.fill"
            case .custom: return "star"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return AppDesignSystem.Colors.primary
            case .goals: return AppDesignSystem.Colors.success
            case .cards: return AppDesignSystem.Colors.warning
            case .custom: return AppDesignSystem.Colors.accent
            }
        }
    }
    
    private var filteredEvents: [GameEvent] {
        let allEvents = gameSession.events.sorted(by: { $0.timestamp > $1.timestamp })
        
        switch selectedFilter {
        case .all:
            return allEvents
        case .goals:
            return allEvents.filter { $0.eventType == .goal || $0.eventType == .assist || $0.eventType == .penalty }
        case .cards:
            return allEvents.filter { $0.eventType == .yellowCard || $0.eventType == .redCard }
        case .custom:
            return allEvents.filter { $0.eventType == .custom }
        }
    }
    
    var body: some View {
        ZStack {
            // Enhanced background
            backgroundView
            
            VStack(spacing: 0) {
                // Enhanced header with filters
                headerSection
                
                if gameSession.events.isEmpty {
                    emptyStateView
                } else {
                    timelineScrollView
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
            initializeAnimations()
        }
        .onChange(of: filteredEvents.count) { _ in
            initializeAnimations()
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        LinearGradient(
            colors: [
                Color(red: 0.95, green: 0.98, blue: 1.0),
                Color(red: 0.98, green: 0.96, blue: 1.0),
                Color(red: 0.96, green: 0.98, blue: 0.95)
            ],
            startPoint: animateGradient ? .topLeading : .bottomTrailing,
            endPoint: animateGradient ? .bottomTrailing : .topLeading
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Match Timeline")
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
                    
                    Text("Live events as they happen")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                // Stats badge
                VStack(spacing: 4) {
                    Text("\(gameSession.events.count)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    
                    Text("Events")
                        .font(AppDesignSystem.Typography.captionFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                .padding(12)
                .background(
                    Circle()
                        .fill(AppDesignSystem.Colors.primary.opacity(0.1))
                        .overlay(
                            Circle()
                                .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Filter pills
            if !gameSession.events.isEmpty {
                filterPills
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
    
    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(EventFilter.allCases, id: \.self) { filter in
                    FilterPill(
                        filter: filter,
                        isSelected: selectedFilter == filter,
                        count: countForFilter(filter)
                    ) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
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
                Text("No Events Yet")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text("Match events will appear here as they happen during the game. Goals, cards, and substitutions will be tracked automatically.")
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Waiting animation
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppDesignSystem.Colors.accent)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animateGradient ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: animateGradient
                        )
                }
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Timeline Scroll View
    
    private var timelineScrollView: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 0) {
                ForEach(Array(filteredEvents.enumerated()), id: \.element.id) { index, event in
                    TimelineEventRow(
                        event: event,
                        gameSession: gameSession,
                        index: index,
                        isLast: index == filteredEvents.count - 1
                    )
                    .offset(x: animationOffsets[event.id] ?? 300)
                    .animation(
                        AppDesignSystem.Animations.bouncy.delay(Double(index) * 0.1),
                        value: animationOffsets[event.id]
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Helper Methods
    
    private func initializeAnimations() {
        for (index, event) in filteredEvents.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    animationOffsets[event.id] = 0
                }
            }
        }
    }
    
    private func countForFilter(_ filter: EventFilter) -> Int {
        switch filter {
        case .all:
            return gameSession.events.count
        case .goals:
            return gameSession.events.filter { $0.eventType == .goal || $0.eventType == .assist || $0.eventType == .penalty }.count
        case .cards:
            return gameSession.events.filter { $0.eventType == .yellowCard || $0.eventType == .redCard }.count
        case .custom:
            return gameSession.events.filter { $0.eventType == .custom }.count
        }
    }
}

// MARK: - Filter Pill Component

struct FilterPill: View {
    let filter: EventsTimelineView.EventFilter
    let isSelected: Bool
    let count: Int
    let action: () -> Void
    
    @State private var isPressed = false
    
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
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isSelected ? .white : filter.color)
                
                Text(filter.rawValue)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(isSelected ? .white : filter.color)
                
                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? filter.color : .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(isSelected ? .white : filter.color)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        LinearGradient(
                            colors: [filter.color, filter.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [filter.color.opacity(0.1), filter.color.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Capsule()
                            .stroke(filter.color.opacity(isSelected ? 0 : 0.3), lineWidth: 1)
                    )
            )
            .shadow(
                color: isSelected ? filter.color.opacity(0.3) : Color.clear,
                radius: isSelected ? 6 : 0,
                x: 0,
                y: isSelected ? 3 : 0
            )
            .scaleEffect(isPressed ? 0.95 : (isSelected ? 1.02 : 1.0))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Timeline Event Row

struct TimelineEventRow: View {
    let event: GameEvent
    let gameSession: GameSession
    let index: Int
    let isLast: Bool
    
    @State private var showDetails = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline connector
            VStack(spacing: 0) {
                // Event dot with enhanced styling
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    eventColor.opacity(0.3),
                                    eventColor.opacity(0.1)
                                ],
                                center: .center,
                                startRadius: 8,
                                endRadius: 20
                            )
                        )
                        .frame(width: 40, height: 40)
                    
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [eventColor, eventColor.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 20, height: 20)
                        .overlay(
                            Image(systemName: eventIcon)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                        )
                        .shadow(
                            color: eventColor.opacity(0.4),
                            radius: 4,
                            x: 0,
                            y: 2
                        )
                }
                
                // Connecting line
                if !isLast {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppDesignSystem.Colors.secondaryText.opacity(0.3),
                                    AppDesignSystem.Colors.secondaryText.opacity(0.1)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2)
                        .padding(.top, 8)
                }
            }
            
            // Event content
            VStack(alignment: .leading, spacing: 0) {
                eventContentCard
                
                if !isLast {
                    Spacer()
                        .frame(height: 24)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private var eventContentCard: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                showDetails.toggle()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Main event info
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(eventTitle)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        HStack(spacing: 8) {
                            Text(event.player.name)
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(eventColor)
                            
                            Text("•")
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            
                            Text(event.player.team.name)
                                .font(AppDesignSystem.Typography.bodyFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(formatTimestamp(event.timestamp))
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        if let participant = participantForPlayer(event.player) {
                            VibrantStatusBadge(participant.name, color: AppDesignSystem.Colors.primary)
                        }
                    }
                }
                
                // Expanded details
                if showDetails {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                            .background(eventColor.opacity(0.3))
                        
                        HStack(spacing: 16) {
                            DetailItem(
                                icon: "person.fill",
                                title: "Position",
                                value: event.player.position.rawValue
                            )
                            
                            DetailItem(
                                icon: "number",
                                title: "Event #",
                                value: "\(index + 1)"
                            )
                            
                            if let bet = gameSession.bets.first(where: { $0.eventType == event.eventType }) {
                                DetailItem(
                                    icon: "dollarsign.circle",
                                    title: "Value",
                                    value: formatCurrency(abs(bet.amount))
                                )
                            }
                        }
                        
                        if let participant = participantForPlayer(event.player) {
                            Text("Owned by \(participant.name) - affects \(gameSession.participants.count - 1) other participants")
                                .font(AppDesignSystem.Typography.captionFont)
                                .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                .padding(.top, 4)
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
                
                // Expand/collapse hint
                HStack {
                    Spacer()
                    
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(eventColor)
                    
                    Text(showDetails ? "Less details" : "More details")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(eventColor)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        eventColor.opacity(0.3),
                                        eventColor.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
            .shadow(
                color: eventColor.opacity(0.1),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Helper Properties and Methods
    
    private var eventColor: Color {
        switch event.eventType {
        case .goal, .penalty: return AppDesignSystem.Colors.success
        case .assist: return AppDesignSystem.Colors.primary
        case .yellowCard: return AppDesignSystem.Colors.goalYellow
        case .redCard: return AppDesignSystem.Colors.error
        case .ownGoal, .penaltyMissed: return AppDesignSystem.Colors.warning
        case .cleanSheet: return AppDesignSystem.Colors.info
        case .custom: return AppDesignSystem.Colors.accent
        }
    }
    
    private var eventIcon: String {
        switch event.eventType {
        case .goal: return "soccerball"
        case .assist: return "arrow.up.forward"
        case .yellowCard, .redCard: return "square.fill"
        case .penalty: return "p.circle"
        case .ownGoal: return "arrow.uturn.backward"
        case .penaltyMissed: return "p.circle.fill"
        case .cleanSheet: return "lock.shield"
        case .custom: return "star"
        }
    }
    
    private var eventTitle: String {
        switch event.eventType {
        case .goal: return "Goal Scored!"
        case .assist: return "Assist Made!"
        case .yellowCard: return "Yellow Card"
        case .redCard: return "Red Card"
        case .ownGoal: return "Own Goal"
        case .penalty: return "Penalty Scored"
        case .penaltyMissed: return "Penalty Missed"
        case .cleanSheet: return "Clean Sheet"
        case .custom:
            let customBetName = gameSession.customBetNames.values.first ?? "Custom Event"
            return customBetName
        }
    }
    
    private func participantForPlayer(_ player: Player) -> Participant? {
        return gameSession.participants.first { participant in
            participant.selectedPlayers.contains { $0.id == player.id } ||
            participant.substitutedPlayers.contains { $0.id == player.id }
        }
    }
    
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
}

// MARK: - Detail Item Component

struct DetailItem: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(AppDesignSystem.Colors.primary)
            
            Text(title)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(AppDesignSystem.Colors.primaryText)
        }
        .frame(maxWidth: .infinity)
    }
}
