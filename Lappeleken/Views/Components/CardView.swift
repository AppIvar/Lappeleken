//
//  CardView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import SwiftUI

// Card view
struct CardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(AppDesignSystem.Layout.standardPadding)
            .background(AppDesignSystem.Colors.cardBackground)
            .cornerRadius(AppDesignSystem.Layout.cornerRadius)
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

/*struct StatusCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppDesignSystem.Typography.bodyFont)
                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                
                Text(subtitle)
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(color)
            }
            
            Spacer()
        }
        .padding()
        .background(AppDesignSystem.Colors.cardBackground)
        .cornerRadius(AppDesignSystem.Layout.cornerRadius)
    }
}*/

struct CompetitionCard: View {
    let productID: AppPurchaseManager.ProductID
    let title: String
    let icon: String
    let description: String
    let isAvailable: Bool
    let availabilityMessage: String?
    
    @ObservedObject private var purchaseManager = AppPurchaseManager.shared
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showingError = false
    
    init(productID: AppPurchaseManager.ProductID, title: String, icon: String, description: String, isAvailable: Bool = true, availabilityMessage: String? = nil) {
        self.productID = productID
        self.title = title
        self.icon = icon
        self.description = description
        self.isAvailable = isAvailable
        self.availabilityMessage = availabilityMessage
    }
    
    var body: some View {
        CardView {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(isAvailable ? AppDesignSystem.Colors.primary : AppDesignSystem.Colors.secondary)
                
                Text(title)
                    .font(AppDesignSystem.Typography.subheadingFont)
                    .foregroundColor(isAvailable ? AppDesignSystem.Colors.primaryText : AppDesignSystem.Colors.secondaryText)
                
                Text(description)
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                
                if isAvailable {
                    purchaseStatusView
                } else {
                    unavailableView
                }
            }
            .padding()
        }
        .opacity(isAvailable ? 1.0 : 0.6)
        .alert(isPresented: $showingError) {
            Alert(
                title: Text("Purchase Error"),
                message: Text(errorMessage),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    @ViewBuilder
    private var purchaseStatusView: some View {
        if purchaseManager.hasAccess(to: productID) {
            // Already owned
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(AppDesignSystem.Colors.success)
                Text("Owned")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.success)
            }
        } else if let product = purchaseManager.availableProducts.first(where: { $0.id == productID.rawValue }) {
            // Purchase button with real price
            Button(action: {
                Task {
                    await purchaseCompetition()
                }
            }) {
                HStack {
                    if isLoading || purchaseManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(.white)
                    } else {
                        Text("Buy \(product.displayPrice)")
                            .font(AppDesignSystem.Typography.captionFont.bold())
                    }
                }
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                (isLoading || purchaseManager.isLoading) ?
                Color.gray : AppDesignSystem.Colors.primary
            )
            .cornerRadius(AppDesignSystem.Layout.smallCornerRadius)
            .disabled(isLoading || purchaseManager.isLoading)
        } else {
            // Loading state
            Text("Loading...")
                .font(AppDesignSystem.Typography.captionFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
        }
    }
    
    @ViewBuilder
    private var unavailableView: some View {
        VStack(spacing: 4) {
            Text("Coming Soon")
                .font(AppDesignSystem.Typography.captionFont)
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            if let message = availabilityMessage {
                Text(message)
                    .font(.system(size: 10))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private func purchaseCompetition() async {
        print("🛒 Competition card purchase tapped: \(productID.displayName)")
        
        isLoading = true
        errorMessage = ""
        
        do {
            try await purchaseManager.purchaseProduct(productID.rawValue)
            print("✅ Purchase completed successfully")
        } catch {
            print("❌ Purchase failed: \(error)")
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
            }
        }
        
        isLoading = false
    }
}
