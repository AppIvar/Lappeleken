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

    @State private var betName = ""
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
                    // Card-style Section
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Custom Bet Details")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .padding(.bottom, 4)

                        // Modern TextField
                        TextField("Bet Name", text: $betName)
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            .textFieldStyle(.plain)

                        // Modern Toggle Button
                        HStack {
                            Text("Bet Type")
                                .font(.headline)
                            Spacer()
                            Button(action: {
                                withAnimation(.spring()) {
                                    isNegativeBet.toggle()
                                }
                            }) {
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
                                .shadow(color: (isNegativeBet ? Color.red : Color.green).opacity(0.08), radius: 8, x: 0, y: 2)
                            }
                        }

                        // Amount Field
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Amount")
                                .font(.headline)
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
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .shadow(color: Color.primary.opacity(0.05), radius: 8, x: 0, y: 4)
                    .padding(.horizontal)

                    // Summary Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Summary")
                            .font(.headline)
                            .padding(.bottom, 2)
                        Text("Name: \(betName.isEmpty ? "—" : betName)")
                        Text("Type: \(isNegativeBet ? "Negative" : "Positive")")
                            .foregroundColor(isNegativeBet ? .red : .green)
                        Text("Amount: \(currencySymbol)\(String(format: "%.2f", betAmount))")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .padding(.horizontal)

                    // Add Custom Bet Button
                    Button(action: {
                        let trimmedName = betName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let finalAmount = isNegativeBet ? -betAmount : betAmount
                        gameSession.addCustomBet(name: trimmedName, amount: finalAmount)
                        showConfirmation = true
                    }) {
                        Text("Add Custom Bet")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(LinearGradient(gradient: Gradient(colors: [Color.blue, Color.green]), startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .shadow(color: Color.green.opacity(0.15), radius: 10, x: 0, y: 6)
                    }
                    .padding(.horizontal)
                    .disabled(betName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || betAmount <= 0)
                    .opacity(betName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || betAmount <= 0 ? 0.7 : 1.0)
                    .alert(isPresented: $showConfirmation) {
                        Alert(
                            title: Text("Custom Bet Added"),
                            message: Text("\"\(betName)\" has been added."),
                            dismissButton: .default(Text("OK")) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        )
                    }

                    Spacer()
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Custom Bet")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

