//
//  EventCard.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//
/*
import SwiftUI

struct EventCard: View {
    let event: GameEvent
    let dateFormatter: DateFormatter
    
    init(event: GameEvent) {
        self.event = event
        
        dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .none
        dateFormatter.timeStyle = .short
    }
    
    var body: some View {
        CardView {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.player.name)
                        .font(AppDesignSystem.Typography.subheadingFont)
                    
                    Text("\(event.eventType.rawValue) (\(event.player.team.name))")
                        .font(AppDesignSystem.Typography.bodyFont)
                }
                
                Spacer()
                
                Text(dateFormatter.string(from: event.timestamp))
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
        }
    }
}
*/
