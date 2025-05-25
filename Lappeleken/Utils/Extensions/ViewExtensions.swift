//
//  ViewExtensions.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import SwiftUI

extension View {
    func slideTransition(isActive: Bool, direction: Edge = .trailing) -> some View {
        modifier(SlideTransition(isActive: isActive, direction: direction))
    }
    
    func withSuccessFeedback() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticManager.shared.playSuccess()
            }
        )
    }
    
    func withSelectionFeedback() -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                HapticManager.shared.playSelection()
            }
        )
    }
}
