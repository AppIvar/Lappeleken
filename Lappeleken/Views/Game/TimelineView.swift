//
//  TimelineView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 16/05/2025.
//

import SwiftUI

struct TimelineView: View {
    @ObservedObject var gameSession: GameSession
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with undo button
                HStack {
                    Text("Match Timeline")
                        .font(AppDesignSystem.Typography.headingFont)
                    
                    Spacer()
                    
                    // Undo button in timeline
                    if gameSession.canUndoLastEvent {
                        Button(action: {
                            showUndoConfirmation()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.uturn.backward.circle.fill")
                                    .font(.system(size: 16))
                                Text("Undo Last")
                                    .font(.caption.weight(.medium))
                            }
                            .foregroundColor(AppDesignSystem.Colors.error)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppDesignSystem.Colors.error.opacity(0.1))
                            .cornerRadius(16)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
                
                if gameSession.events.isEmpty {
                    VStack {
                        Text("No events recorded yet")
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                            .padding(.top, 40)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    let sortedEvents = gameSession.events.sorted(by: { $0.timestamp < $1.timestamp })
                    let substitutions = gameSession.substitutions.sorted(by: { $0.timestamp < $1.timestamp })
                    
                    // Merge events and substitutions into a single timeline
                    let timelineItems = createTimelineItems(events: sortedEvents, substitutions: substitutions)
                    
                    ForEach(timelineItems.indices, id: \.self) { index in
                        let item = timelineItems[index]
                        let isLastEvent = index == timelineItems.count - 1
                        
                        VStack(spacing: 0) {
                            // Timeline connector from previous item
                            if index > 0 {
                                Rectangle()
                                    .fill(AppDesignSystem.Colors.secondaryText.opacity(0.3))
                                    .frame(width: 2, height: 20)
                                    .padding(.leading, 8)
                            }
                            
                            // Timeline item
                            HStack(alignment: .top, spacing: 12) {
                                // Timeline dot and line
                                VStack(spacing: 0) {
                                    Circle()
                                        .fill(item.color)
                                        .frame(width: 16, height: 16)
                                        .overlay(
                                            // Highlight last event
                                            Circle()
                                                .stroke(isLastEvent ? AppDesignSystem.Colors.primary : Color.clear, lineWidth: 2)
                                                .frame(width: 20, height: 20)
                                        )
                                    
                                    if index < timelineItems.count - 1 {
                                        Rectangle()
                                            .fill(AppDesignSystem.Colors.secondaryText.opacity(0.3))
                                            .frame(width: 2)
                                    }
                                }
                                .padding(.top, 2)
                                
                                // Event content
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(dateFormatter.string(from: item.timestamp))
                                            .font(AppDesignSystem.Typography.captionFont)
                                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                        
                                        Spacer()
                                        
                                        HStack(spacing: 8) {
                                            Text(item.label)
                                                .font(AppDesignSystem.Typography.bodyFont.bold())
                                                .foregroundColor(item.color)
                                            
                                            // Show "LATEST" badge on last event
                                            if isLastEvent {
                                                Text("LATEST")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(AppDesignSystem.Colors.primary)
                                                    .cornerRadius(8)
                                            }
                                        }
                                    }
                                    
                                    Text(item.description)
                                        .font(AppDesignSystem.Typography.bodyFont)
                                    
                                    // Event details
                                    Text(item.detail)
                                        .font(AppDesignSystem.Typography.captionFont)
                                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                    
                                    // Show points impact for bets
                                    if let pointsImpact = item.pointsImpact {
                                        Text(pointsImpact)
                                            .font(AppDesignSystem.Typography.captionFont.bold())
                                            .foregroundColor(item.pointsImpact?.contains("+") == true ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
                                            .padding(.top, 2)
                                    }
                                }
                                .padding(.vertical, 8)
                                .padding(.trailing, 16)
                                .background(
                                    // Subtle highlight for last event
                                    isLastEvent ? AppDesignSystem.Colors.primary.opacity(0.05) : Color.clear
                                )
                                .cornerRadius(8)
                            }
                            .padding(.leading, 16)
                        }
                    }
                }
            }
            .padding(.bottom, 30)
            
            if AppPurchaseManager.shared.currentTier == .free {
                VStack(spacing: 0) {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    BannerAdView()
                        .frame(height: 50)
                        .background(Color.gray.opacity(0.05))
                }
            }
        }
        .alert("Undo Last Event", isPresented: $showingUndoConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Undo", role: .destructive) {
                gameSession.undoLastEvent()
            }
        } message: {
            if let lastEvent = gameSession.events.last {
                Text("This will undo '\(lastEvent.eventType.rawValue)' for \(lastEvent.player.name) and reverse all balance changes.")
            }
        }
    }
    
    @State private var showingUndoConfirmation = false
    
    private func showUndoConfirmation() {
        showingUndoConfirmation = true
    }
    
    // Enhanced Timeline item model
    private struct TimelineItem {
        let timestamp: Date
        let label: String
        let description: String
        let detail: String
        let color: Color
        let pointsImpact: String? // NEW: Show points won/lost
    }
    
    // Helper function to get participant name for a player
    private func getParticipantName(for player: Player) -> String {
        return gameSession.participants.first {
            $0.selectedPlayers.contains { $0.id == player.id } ||
            $0.substitutedPlayers.contains { $0.id == player.id }
        }?.name ?? "Unknown"
    }
    
    // Helper to combine events and substitutions
    private func createTimelineItems(events: [GameEvent], substitutions: [Substitution]) -> [TimelineItem] {
        var items: [TimelineItem] = []
        
        // Add event items
        for event in events {
            var color: Color = AppDesignSystem.Colors.primary
            
            switch event.eventType {
            case .goal, .penalty:
                color = AppDesignSystem.Colors.success
            case .yellowCard:
                color = AppDesignSystem.Colors.warning
            case .redCard, .penaltyMissed:
                color = AppDesignSystem.Colors.error
            default:
                color = AppDesignSystem.Colors.primary
            }
            
            // Calculate points impact
            let pointsImpact = calculatePointsImpact(for: event)
            
            items.append(TimelineItem(
                timestamp: event.timestamp,
                label: event.eventType.rawValue,
                description: "\(event.player.name) (\(event.player.team.name))",
                detail: "Recorded by \(getParticipantName(for: event.player))",
                color: color,
                pointsImpact: pointsImpact
            ))
        }
        
        // Add substitution items
        for sub in substitutions {
            items.append(TimelineItem(
                timestamp: sub.timestamp,
                label: "Substitution",
                description: "\(sub.from.name) ➝ \(sub.to.name)",
                detail: "\(sub.team.name)",
                color: AppDesignSystem.Colors.secondary,
                pointsImpact: nil
            ))
        }
        
        // Sort by timestamp
        return items.sorted(by: { $0.timestamp < $1.timestamp })
    }
    
    // Calculate points impact for an event
    private func calculatePointsImpact(for event: GameEvent) -> String? {
        guard let bet = gameSession.bets.first(where: { $0.eventType == event.eventType }) else {
            return nil
        }
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        
        if bet.amount >= 0 {
            return "+\(formatter.string(from: NSNumber(value: bet.amount)) ?? "€0")"
        } else {
            return "\(formatter.string(from: NSNumber(value: bet.amount)) ?? "€0")"
        }
    }
}
