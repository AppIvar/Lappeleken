//
//  CustomBetView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 14/05/2025.
//

import SwiftUI

struct CustomBetView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var gameSession: GameSession

    @State private var eventName = ""
    @State private var betAmount: Double = 1.0
    @State private var isNegativeBet = false
    @State private var showConfirmation = false

    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
    }

    private var amountFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    eventDetailsSection
                    summarySection
                    addEventButton
                    Spacer()
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Custom Event")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .alert(isPresented: $showConfirmation) {
            Alert(
                title: Text("Custom Event Added"),
                message: Text("\"\(eventName)\" has been added."),
                dismissButton: .default(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                }
            )
        }
    }
    
    // MARK: - Event Details Section
    private var eventDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Custom Event Details")
                .font(.title3)
                .fontWeight(.semibold)
                .padding(.bottom, 4)

            eventNameField
            eventTypeToggle
            amountField
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.primary.opacity(0.05), radius: 8, x: 0, y: 4)
        .padding(.horizontal)
    }
    
    // MARK: - Event Name Field
    private var eventNameField: some View {
        TextField("Event Name", text: $eventName)
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .textFieldStyle(.plain)
    }
    
    // MARK: - Event Type Toggle
    private var eventTypeToggle: some View {
        HStack {
            Text("Event Type")
                .font(.headline)
            Spacer()
            Button(action: {
                withAnimation(.spring()) {
                    isNegativeBet.toggle()
                }
            }) {
                eventTypeButton
            }
        }
    }
    
    private var eventTypeButton: some View {
        HStack {
            Image(systemName: isNegativeBet ? "minus.circle.fill" : "plus.circle.fill")
                .foregroundColor(isNegativeBet ? .red : .green)
                .font(.title2)
            Text(isNegativeBet ? "Negative" : "Positive")
                .foregroundColor(isNegativeBet ? .red : .green)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 16)
        .background((isNegativeBet ? Color.red : Color.green).opacity(0.15))
        .clipShape(Capsule())
    }
    
    // MARK: - Amount Field
    private var amountField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Amount")
                .font(.headline)
            amountInputField
        }
    }
    
    private var amountInputField: some View {
        HStack {
            Text(currencySymbol)
                .fontWeight(.semibold)
            TextField("Amount", value: $betAmount, formatter: amountFormatter)
                .keyboardType(.decimalPad)
                .textFieldStyle(.plain)
                .frame(minWidth: 60)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    
    // MARK: - Summary Section
    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Summary")
                .font(.headline)
                .padding(.bottom, 2)
            summaryContent
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .padding(.horizontal)
    }
    
    private var summaryContent: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Name: \(eventName.isEmpty ? "—" : eventName)")
            Text("Type: \(isNegativeBet ? "Negative" : "Positive")")
                .foregroundColor(isNegativeBet ? .red : .green)
            Text("Amount: \(currencySymbol)\(String(format: "%.2f", betAmount))")
        }
    }
    
    // MARK: - Add Event Button
    private var addEventButton: some View {
        Button(action: addCustomEvent) {
            Text("Add Custom Event")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .padding(.horizontal)
        .disabled(isAddButtonDisabled)
        .opacity(isAddButtonDisabled ? 0.7 : 1.0)
    }
    
    // MARK: - Helper Properties and Methods
    private var isAddButtonDisabled: Bool {
        eventName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || betAmount <= 0
    }
    
    private func addCustomEvent() {
        let trimmedName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalAmount = isNegativeBet ? -betAmount : betAmount
        gameSession.addCustomEvent(name: trimmedName, amount: finalAmount)
        showConfirmation = true
    }
}
