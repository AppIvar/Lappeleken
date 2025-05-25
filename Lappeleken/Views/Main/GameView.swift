//
//  GameView.swift
//  Lappeleken
//
//  Created by Ivar Hovland on 08/05/2025.
//

//
//  GameView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 08/05/2025.
//

import SwiftUI

struct GameView: View {
    @ObservedObject var gameSession: GameSession
    @State private var selectedPlayer: Player? = nil
    @State private var selectedEventType: Bet.EventType? = nil
    @State private var showingEventSheet = false
    @State private var showingSubstitutionSheet = false
    
    var body: some View {
        TabView {
            participantsView
                .tabItem {
                    Label("Participants", systemImage: "person.3")
                }
            
            playersView
                .tabItem {
                    Label("Players", systemImage: "sportscourt")
                }
            
            eventsView
                .tabItem {
                    Label("Events", systemImage: "list.bullet")
                }
            
            TimelineView(gameSession: gameSession)
                .tabItem {
                    Label("Timeline", systemImage: "clock")
                }
            
            StatsView(gameSession: gameSession)
                .tabItem {
                    Label("Stats", systemImage: "chart.bar.fill")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .navigationTitle("Lucky Football Slip")
        .accentColor(AppDesignSystem.Colors.primary)
        .sheet(isPresented: $showingEventSheet) {
            recordEventView
        }
        .sheet(isPresented: $showingSubstitutionSheet) {
            SubstitutionView(gameSession: gameSession)
        }
    }
    
    // MARK: - Tab Views
    
    private var participantsView: some View {
        ScrollView {
            VStack(spacing: AppDesignSystem.Layout.standardPadding) {
                HStack {
                    HStack(spacing: 10) {
                        Button(action: {
                            showingSubstitutionSheet = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                Text("Sub")
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button(action: {
                            showingEventSheet = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Event")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                
                ForEach(gameSession.participants) { participant in
                    ParticipantCard(participant: participant)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
    }
    
    private var playersView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                HStack {
                    Text("Assigned Players")
                        .font(AppDesignSystem.Typography.headingFont)
                    
                    Spacer()
                    
                    Button(action: {
                        showingEventSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Event")
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                
                if gameSession.participants.flatMap({ $0.selectedPlayers}).isEmpty &&
                    gameSession.participants.flatMap({ $0.substitutedPlayers}).isEmpty {
                    VStack {
                        Text("No players assigned yet")
                            .font(AppDesignSystem.Typography.bodyFont)
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .padding(.top, 40)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    ForEach(gameSession.participants) { participant in
                        VStack(alignment: .leading) {
                            Text(participant.name)
                                .font(AppDesignSystem.Typography.subheadingFont)
                                .padding(.top)
                            
                            if participant.selectedPlayers.isEmpty && participant.substitutedPlayers.isEmpty {
                                Text("No players assigned")
                                    .font(AppDesignSystem.Typography.bodyFont)
                                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    .padding(.vertical, 8)
                            } else {
                                // Active players
                                if !participant.selectedPlayers.isEmpty {
                                    Text("Active Players")
                                        .font(AppDesignSystem.Typography.bodyFont.bold())
                                        .foregroundColor(AppDesignSystem.Colors.primary)
                                        .padding(.top, 4)
                                    
                                    ForEach(participant.selectedPlayers) { player in
                                        PlayerStatsCard(gameSession: gameSession, player: player)
                                            .padding(.vertical, 4)
                                            .id("\(player.id)-\(gameSession.events.count)")
                                    }
                                }
                                
                                // Substituted players
                                if !participant.substitutedPlayers.isEmpty {
                                    Text("Substituted Players")
                                        .font(AppDesignSystem.Typography.bodyFont.bold())
                                        .foregroundColor(AppDesignSystem.Colors.secondary)
                                        .padding(.top, 12)
                                    
                                    ForEach(participant.substitutedPlayers) { player in
                                        PlayerStatsCard(gameSession: gameSession, player: player, isSubstituted: true)
                                            .padding(.vertical, 4)
                                            .id("\(player.id)-subbed-\(gameSession.events.count)")
                                    }
                                }
                            }
                        }
                        .padding(.bottom, AppDesignSystem.Layout.standardPadding)
                    }
                }
            }
            .padding()
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
        .id("players-view-\(gameSession.events.count)-\(gameSession.substitutions.count)")
    }
    
    private var eventsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                HStack {
                    Text("Game Events")
                        .font(AppDesignSystem.Typography.headingFont)
                    
                    Spacer()
                    
                    Button(action: {
                        showingEventSheet = true
                    }) {
                        Label("Record Event", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                
                if gameSession.events.isEmpty {
                    Text("No events recorded yet")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else {
                    ForEach(gameSession.events.sorted(by: { $0.timestamp > $1.timestamp })) { event in
                        EventCard(event: event)
                    }
                }
            }
            .padding()
        }
        .background(AppDesignSystem.Colors.background.ignoresSafeArea())
    }
    
    // MARK: - Record Event Sheet
    
    private var recordEventView: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Select Player")) {
                        if gameSession.participants.flatMap({ $0.selectedPlayers + $0.substitutedPlayers }).isEmpty {
                            Text("No players assigned yet")
                                .foregroundColor(AppDesignSystem.Colors.error)
                        } else {
                            ForEach(gameSession.participants) { participant in
                                Section(header: Text(participant.name)) {
                                    // Active players
                                    ForEach(participant.selectedPlayers) { player in
                                        playerSelectionRow(player: player)
                                    }
                                    
                                    // Including substituted players
                                    ForEach(participant.substitutedPlayers) { player in
                                        playerSelectionRow(player: player, isSubstituted: true)
                                    }
                                }
                            }
                        }
                    }
                    
                    Section(header: Text("Select Event Type")) {
                        ForEach(Bet.EventType.allCases, id: \.self) { eventType in
                            Button(action: {
                                selectedEventType = eventType
                            }) {
                                HStack {
                                    Text(eventType.rawValue)
                                    Spacer()
                                    if selectedEventType == eventType {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(AppDesignSystem.Colors.primary)
                                    }
                                }
                            }
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        }
                    }
                    
                    if let player = selectedPlayer, let eventType = selectedEventType {
                        Section {
                            Button("Record \(eventType.rawValue) for \(player.name)") {
                                gameSession.recordEvent(player: player, eventType: eventType)
                                showingEventSheet = false
                                selectedPlayer = nil
                                selectedEventType = nil
                            }
                            .foregroundColor(AppDesignSystem.Colors.primary)
                        }
                    }
                }
            }
            .navigationTitle("Record Event")
            .navigationBarItems(trailing: Button("Cancel") {
                showingEventSheet = false
            })
        }
    }
    
    // Helper function for player selection row
    private func playerSelectionRow(player: Player, isSubstituted: Bool = false) -> some View {
        Button(action: {
            selectedPlayer = player
        }) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(player.name)
                            .font(.body)
                        
                        if isSubstituted {
                            Text("(Subbed Off)")
                                .font(.caption)
                                .foregroundColor(AppDesignSystem.Colors.error)
                        }
                    }
                    
                    Text("\(player.team.name) · \(player.position.rawValue)")
                        .font(.caption)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                if selectedPlayer?.id == player.id {
                    Image(systemName: "checkmark")
                        .foregroundColor(AppDesignSystem.Colors.primary)
                }
            }
        }
        .foregroundColor(AppDesignSystem.Colors.primaryText)
        .opacity(isSubstituted ? 0.8 : 1.0)
    }
}
