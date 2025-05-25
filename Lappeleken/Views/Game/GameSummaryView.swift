//
//  GameSummaryView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 09/05/2025.
//

import SwiftUI

struct GameSummaryView: View {
    let gameSession: GameSession
    @Environment(\.presentationMode) var presentationMode
    @State private var gameName: String = ""
    @State private var showingSaveDialog = false
    
    // Computed properties to break up complex expressions
    private var sortedEvents: [GameEvent] {
        return gameSession.events.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    private var sortedParticipants: [Participant] {
        return gameSession.participants.sorted(by: { $0.balance > $1.balance })
    }
    
    private var hasEvents: Bool {
        return !gameSession.events.isEmpty
    }
    
    private var canExportPDF: Bool {
        return AppPurchaseManager.shared.currentTier == .premium
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: AppDesignSystem.Layout.standardPadding) {
                    headerSection
                    
                    // Event Summary
                    if hasEvents {
                        eventsSection
                    } else {
                        noEventsSection
                    }
                    
                    // Final balances
                    balancesSection
                    
                    // Payments section
                    paymentsSection
                    
                    // Action buttons
                    actionButtonsSection
                    
                    // Return to home button
                    returnHomeButton
                }
                .padding()
            }
            .background(AppDesignSystem.Colors.background.ignoresSafeArea())
            .navigationTitle("Game Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingSaveDialog) {
                saveGameSheet
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        Text("Game Summary")
            .font(AppDesignSystem.Typography.headingFont)
            .padding(.bottom)
    }
    
    private var eventsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                Text("Events")
                    .font(AppDesignSystem.Typography.subheadingFont)
                
                ForEach(sortedEvents) { event in
                    eventRow(event: event)
                }
            }
        }
    }
    
    private func eventRow(event: GameEvent) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(event.player.name)
                    .font(AppDesignSystem.Typography.bodyFont)
                
                Text("\(event.eventType.rawValue) (\(event.player.team.name))")
                    .font(AppDesignSystem.Typography.captionFont)
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    private var noEventsSection: some View {
        Text("No events recorded in this game")
            .font(AppDesignSystem.Typography.bodyFont)
            .foregroundColor(AppDesignSystem.Colors.secondaryText)
            .padding(.vertical, 20)
    }
    
    private var balancesSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                Text("Final Balances")
                    .font(AppDesignSystem.Typography.subheadingFont)
                
                ForEach(sortedParticipants) { participant in
                    balanceRow(participant: participant)
                }
            }
        }
    }
    
    private func balanceRow(participant: Participant) -> some View {
        HStack {
            Text(participant.name)
                .font(AppDesignSystem.Typography.bodyFont)
            
            Spacer()
            
            Text(formatCurrency(participant.balance))
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(participant.balance >= 0 ? AppDesignSystem.Colors.success : AppDesignSystem.Colors.error)
        }
        .padding(.vertical, 4)
    }
    
    private var paymentsSection: some View {
        CardView {
            VStack(alignment: .leading, spacing: AppDesignSystem.Layout.standardPadding) {
                Text("Payments")
                    .font(AppDesignSystem.Typography.subheadingFont)
                
                let payments = calculatePayments()
                
                if payments.isEmpty {
                    Text("No payments needed")
                        .font(AppDesignSystem.Typography.bodyFont)
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                } else {
                    ForEach(payments) { payment in
                        paymentRow(payment: payment)
                    }
                }
            }
        }
    }
    
    private func paymentRow(payment: Payment) -> some View {
        HStack {
            Text(payment.from)
                .font(AppDesignSystem.Typography.bodyFont)
            
            Image(systemName: "arrow.right")
                .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            Text(payment.to)
                .font(AppDesignSystem.Typography.bodyFont)
            
            Spacer()
            
            Text(formatCurrency(payment.amount))
                .font(AppDesignSystem.Typography.bodyFont)
                .foregroundColor(AppDesignSystem.Colors.primary)
        }
        .padding(.vertical, 4)
    }
    
    @ObservedObject private var adManager = AdManager.shared
    @State private var showingExportSheet = false

    private var actionButtonsSection: some View {
        HStack(spacing: 12) {
            Button("Save Game") {
                showingSaveDialog = true
            }
            .buttonStyle(SecondaryButtonStyle())
            
            Button("Export Summary") {
                handleExportTap()
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(.top)
        .sheet(isPresented: $showingExportSheet) {
            exportOptionsSheet
        }
    }
    
    private var exportOptionsSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Export Game Summary")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if AppPurchaseManager.shared.currentTier == .premium {
                    // Premium users get direct export options
                    VStack(spacing: 16) {
                        exportOptionButton(
                            title: "Export as PDF",
                            subtitle: "Share or save PDF summary",
                            icon: "doc.fill"
                        ) {
                            showingExportSheet = false
                            exportPDF()
                        }
                        
                        exportOptionButton(
                            title: "Share Text Summary",
                            subtitle: "Quick text version to share",
                            icon: "square.and.arrow.up"
                        ) {
                            showingExportSheet = false
                            shareTextSummary()
                        }
                    }
                } else {
                    // Free users need to watch ad or upgrade
                    VStack(spacing: 16) {
                        Text("Export is a premium feature")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        if adManager.isRewardedReady {
                            exportOptionButton(
                                title: "Watch Ad to Export",
                                subtitle: "Free with short video",
                                icon: "play.tv.fill",
                                color: .green
                            ) {
                                showRewardedAdForExport()
                            }
                        } else {
                            VStack {
                                Image(systemName: "clock")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                                Text("Ad not ready - try again in a moment")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        exportOptionButton(
                            title: "Upgrade to Premium",
                            subtitle: "Unlimited exports + more features",
                            icon: "crown.fill",
                            color: .blue
                        ) {
                            showingExportSheet = false
                            showUpgradePrompt()
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Export Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingExportSheet = false
                    }
                }
            }
        }
    }
    
    private func exportOptionButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color = .primary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func handleExportTap() {
        showingExportSheet = true
    }
    
    private func showRewardedAdForExport() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        showingExportSheet = false
        
        adManager.showRewardedAd(from: rootViewController) { success in
            DispatchQueue.main.async {
                if success {
                    // User watched ad successfully, now allow export
                    self.exportPDF()
                } else {
                    print("❌ Failed to show rewarded ad for export")
                    // You could show an error message here
                }
            }
        }
    }
    
    private func shareTextSummary() {
        let summary = createGameSummaryText()
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            return
        }
        
        let activityVC = UIActivityViewController(
            activityItems: [summary],
            applicationActivities: nil
        )
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = rootViewController.view
            popover.sourceRect = CGRect(
                x: rootViewController.view.bounds.midX,
                y: rootViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
        }
        
        rootViewController.present(activityVC, animated: true)
    }
    
    private func createGameSummaryText() -> String {
        var summary = "🏈 LUCKY FOOTBALL SLIP - GAME SUMMARY\n"
        summary += "Generated: \(DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .short))\n\n"
        
        // Events section
        summary += "📊 EVENTS\n"
        summary += String(repeating: "-", count: 40) + "\n"
        
        if hasEvents {
            for event in sortedEvents {
                summary += "• \(event.player.name) (\(event.player.team.name))\n"
                summary += "  \(event.eventType.rawValue) - \(DateFormatter.localizedString(from: event.timestamp, dateStyle: .none, timeStyle: .short))\n\n"
            }
        } else {
            summary += "No events recorded\n\n"
        }
        
        // Final balances
        summary += "💰 FINAL BALANCES\n"
        summary += String(repeating: "-", count: 40) + "\n"
        
        for participant in sortedParticipants {
            summary += "\(participant.name): \(formatCurrency(participant.balance))\n"
        }
        summary += "\n"
        
        // Payments
        summary += "💸 PAYMENTS NEEDED\n"
        summary += String(repeating: "-", count: 40) + "\n"
        
        let payments = calculatePayments()
        if payments.isEmpty {
            summary += "No payments needed\n"
        } else {
            for payment in payments {
                summary += "\(payment.from) → \(payment.to): \(formatCurrency(payment.amount))\n"
            }
        }
        
        summary += "\n---\nGenerated by Lucky Football Slip"
        return summary
    }
    
    private func showUpgradePrompt() {
        // Create a simple alert for now
        let alert = UIAlertController(
            title: "Premium Feature",
            message: "Export functionality is available for premium users. Would you like to upgrade?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Upgrade", style: .default) { _ in
            // Post notification to show upgrade view
            NotificationCenter.default.post(
                name: Notification.Name("ShowUpgradePrompt"),
                object: nil
            )
        })
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(alert, animated: true)
        }
    }

    
    private var returnHomeButton: some View {
        Button("Return to Home") {
            presentationMode.wrappedValue.dismiss()
        }
        .buttonStyle(PrimaryButtonStyle())
        .padding(.top, AppDesignSystem.Layout.largePadding)
    }
    
    private var saveGameSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Save Game Session")
                    .font(AppDesignSystem.Typography.headingFont)
                
                TextField("Game name", text: $gameName)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                Button("Save") {
                    let finalGameName = gameName.isEmpty ? "Game \(Date())" : gameName
                    gameSession.saveGame(name: finalGameName)
                    showingSaveDialog = false
                    gameName = ""
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top)
            }
            .padding()
            .navigationTitle("Save Game")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingSaveDialog = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func exportPDF() {
        PDFExporter.exportGameSummary(gameSession: gameSession) { fileURL in
            guard let url = fileURL else {
                print("Error exporting PDF")
                return
            }
            
            let activityVC = UIActivityViewController(
                activityItems: [url],
                applicationActivities: nil
            )
            
            // Present the share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                rootVC.present(activityVC, animated: true, completion: nil)
            }
        }
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        
        return formatter.string(from: NSNumber(value: value)) ?? "€0.00"
    }
    
    // Calculate who should pay whom
    private func calculatePayments() -> [Payment] {
        var payments: [Payment] = []
        
        // Create deep copies of participants to avoid modifying the originals
        var debtors = gameSession.participants.filter { $0.balance < 0 }
            .map { createParticipantCopy($0) }
            .sorted(by: { abs($0.balance) > abs($1.balance) })
        
        var creditors = gameSession.participants.filter { $0.balance > 0 }
            .map { createParticipantCopy($0) }
            .sorted(by: { $0.balance > $1.balance })
            
        // Process all debtors until they've paid off their debt
        while !debtors.isEmpty && !creditors.isEmpty {
            var debtor = debtors[0]
            var creditor = creditors[0]
            
            // Calculate payment amount
            let paymentAmount = min(abs(debtor.balance), creditor.balance)
            
            // Only create a payment if the amount is significant
            if paymentAmount > 0.01 {
                payments.append(Payment(
                    from: debtor.name,
                    to: creditor.name,
                    amount: paymentAmount
                ))
                
                // Update balances
                debtor.balance += paymentAmount
                creditor.balance -= paymentAmount
                
                // Update the collections
                debtors[0] = debtor
                creditors[0] = creditor
            }
            
            // Remove debtors who have paid off their debt
            if abs(debtor.balance) < 0.01 {
                debtors.remove(at: 0)
            }
            
            // Remove creditors who have been fully paid
            if creditor.balance < 0.01 {
                creditors.remove(at: 0)
            }
        }
        
        return payments
    }
    
    private func createParticipantCopy(_ participant: Participant) -> Participant {
        return Participant(
            id: participant.id,
            name: participant.name,
            selectedPlayers: participant.selectedPlayers,
            substitutedPlayers: participant.substitutedPlayers,
            balance: participant.balance
        )
    }
}

// MARK: - Payment Helper Struct

extension GameSummaryView {
    struct Payment: Identifiable {
        let id = UUID()
        let from: String
        let to: String
        let amount: Double
    }
}
