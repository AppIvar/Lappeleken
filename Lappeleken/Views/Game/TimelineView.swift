//
//  TimelineView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 16/05/2025.
//

// Create TimelineView.swift
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
                Text("Match Timeline")
                    .font(AppDesignSystem.Typography.headingFont)
                    .padding()
                
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
                                        
                                        Text(item.label)
                                            .font(AppDesignSystem.Typography.bodyFont.bold())
                                            .foregroundColor(item.color)
                                    }
                                    
                                    Text(item.description)
                                        .font(AppDesignSystem.Typography.bodyFont)
                                    
                                    // Event details
                                    Text(item.detail)
                                        .font(AppDesignSystem.Typography.captionFont)
                                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                                }
                                .padding(.vertical, 8)
                                .padding(.trailing, 16)
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
    }
    
    // Timeline item model
    private struct TimelineItem {
        let timestamp: Date
        let label: String
        let description: String
        let detail: String
        let color: Color
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
            
            // Fixed version of the previously problematic code
            items.append(TimelineItem(
                timestamp: event.timestamp,
                label: event.eventType.rawValue,
                description: "\(event.player.name) (\(event.player.team.name))",
                detail: "Recorded by \(getParticipantName(for: event.player))",
                color: color
            ))
        }
        
        // Add substitution items
        for sub in substitutions {
            items.append(TimelineItem(
                timestamp: sub.timestamp,
                label: "Substitution",
                description: "\(sub.from.name) ➝ \(sub.to.name)",
                detail: "\(sub.team.name)",
                color: AppDesignSystem.Colors.secondary
            ))
        }
        
        // Sort by timestamp
        return items.sorted(by: { $0.timestamp < $1.timestamp })
    }
}
