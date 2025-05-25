//
//  ButtonStyles.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding()
            .background(
                AppDesignSystem.Colors.primary
                    .opacity(configuration.isPressed ? 0.8 : 1.0)
            )
            .cornerRadius(AppDesignSystem.Layout.cornerRadius)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(AppDesignSystem.Colors.primary)
            .padding()
            .background(
                AppDesignSystem.Colors.primary
                    .opacity(0.1)
                    .opacity(configuration.isPressed ? 0.2 : 1.0)
            )
            .cornerRadius(AppDesignSystem.Layout.cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: AppDesignSystem.Layout.cornerRadius)
                    .stroke(AppDesignSystem.Colors.primary, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(AppDesignSystem.Animations.quick, value: configuration.isPressed)
    }
}

struct PurchaseButton: View {
    let title: String
    let subtitle: String
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .tint(.white)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(AppDesignSystem.Typography.bodyFont.bold())
                        Text(subtitle)
                            .font(AppDesignSystem.Typography.captionFont)
                    }
                }
                
                Spacer()
                
                if !isLoading {
                    Image(systemName: "arrow.right")
                        .font(.title3)
                }
            }
            .foregroundColor(.white)
            .padding()
            .background(AppDesignSystem.Colors.primary)
            .cornerRadius(AppDesignSystem.Layout.cornerRadius)
        }
        .disabled(isLoading)
    }
}
