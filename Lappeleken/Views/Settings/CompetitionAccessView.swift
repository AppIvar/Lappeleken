//
//  CompetitionAccessView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 22/05/2025.
//

import SwiftUI

struct CompetitionAccessView: View {
    let competition: Competition
    let onAccessGranted: () -> Void
    
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var purchaseManager = AppPurchaseManager.shared
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Competition info
                VStack(spacing: 16) {
                    Image(systemName: competitionIcon)
                        .font(.system(size: 80))
                        .foregroundColor(AppDesignSystem.Colors.primary)
                    
                    Text(competition.name)
                        .font(AppDesignSystem.Typography.titleFont)
                        .multilineTextAlignment(.center)
                    
                    Text("Premium Competition")
                        .font(AppDesignSystem.Typography.subheadingFont)
                        .foregroundColor(AppDesignSystem.Colors.secondary)
                }
                
                // Access info
                CardView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("This competition requires a separate purchase")
                            .font(AppDesignSystem.Typography.bodyFont.bold())
                        
                        Text("The \(competition.name) is a premium competition that includes:")
                            .font(AppDesignSystem.Typography.bodyFont)
                        
                        ForEach(competitionFeatures, id: \.self) { feature in
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppDesignSystem.Colors.success)
                                Text(feature)
                                    .font(AppDesignSystem.Typography.bodyFont)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Purchase options
                VStack(spacing: 16) {
                    if let productID = getProductID(for: competition.code) {
                        if let product = purchaseManager.availableProducts.first(where: { $0.id == productID.rawValue }) {
                            PurchaseButton(
                                title: "Purchase \(competition.name)",
                                subtitle: product.displayPrice,
                                isLoading: purchaseManager.isLoading
                            ) {
                                Task {
                                    await purchaseCompetition(productID)
                                }
                            }
                        } else {
                            PurchaseButton(
                                title: "Purchase \(competition.name)",
                                subtitle: getEstimatedPrice(for: productID),
                                isLoading: purchaseManager.isLoading
                            ) {
                                Task {
                                    await purchaseCompetition(productID)
                                }
                            }
                        }
                    }
                    
                    Button("Maybe Later") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                }
            }
            .padding()
            .navigationTitle("Premium Access")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private func getEstimatedPrice(for productID: AppPurchaseManager.ProductID) -> String {
        switch productID {
        case .premium: return "$4.99"
        case .championsLeague: return "$2.99"
        case .worldCup: return "$3.99"
        case .euroChampionship: return "$2.99"
        case .nationsCup: return "$1.99"
        }
    }
    
    // MARK: - Helper Properties
    
    private var competitionIcon: String {
        switch competition.code {
        case "CL": return "star.circle.fill"
        case "WC": return "globe"
        case "EC": return "flag.circle.fill"
        case "NC": return "trophy.circle.fill"
        default: return "sportscourt.fill"
        }
    }
    
    private var competitionFeatures: [String] {
        switch competition.code {
        case "CL":
            return [
                "Live Champions League matches",
                "Group stage and knockout rounds",
                "Real-time player statistics",
                "Match lineups and substitutions"
            ]
        case "WC":
            return [
                "All World Cup matches live",
                "Group stage through final",
                "National team lineups",
                "Tournament statistics"
            ]
        case "EC":
            return [
                "European Championship matches",
                "Qualifying and final tournament",
                "National team data",
                "Live match updates"
            ]
        default:
            return [
                "Live match coverage",
                "Player statistics",
                "Real-time updates",
                "Premium features"
            ]
        }
    }
    
    // MARK: - Helper Methods
    
    private func getProductID(for competitionCode: String) -> AppPurchaseManager.ProductID? {
        switch competitionCode {
        case "CL": return .championsLeague
        case "WC": return .worldCup
        case "EC": return .euroChampionship
        case "NC": return .nationsCup
        default: return nil
        }
    }
    
    private func purchaseCompetition(_ productID: AppPurchaseManager.ProductID) async {
        do {
            let success = try await purchaseManager.purchase(productID)
            if success {
                await MainActor.run {
                    onAccessGranted()
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } catch {
            print("Purchase failed: \(error)")
        }
    }
}
