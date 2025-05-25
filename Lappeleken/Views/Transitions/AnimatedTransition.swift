//
//  AnimatedTransition.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 16/05/2025.
//
import SwiftUI

struct SlideTransition: ViewModifier {
    let isActive: Bool
    let direction: Edge
    
    func body(content: Content) -> some View {
        content
            .offset(
                x: isActive ? (direction == .leading ? -UIScreen.main.bounds.width :
                              (direction == .trailing ? UIScreen.main.bounds.width : 0)) : 0,
                y: isActive ? (direction == .top ? -UIScreen.main.bounds.height :
                              (direction == .bottom ? UIScreen.main.bounds.height : 0)) : 0
            )
            .animation(.easeInOut, value: isActive)
    }
}

