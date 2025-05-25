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
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Custom Bet Details")) {
                    TextField("Bet Name", text: $betName)
                    
                    HStack {
                        Text("Bet Type")
                        Spacer()
                        
                        // Toggle for positive/negative bet type
                        Button(action: {
                            isNegativeBet.toggle()
                        }) {
                            HStack {
                                Text(isNegativeBet ? "Negative" : "Positive")
                                    .foregroundColor(isNegativeBet ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                                
                                Image(systemName: isNegativeBet ? "minus.circle.fill" : "plus.circle.fill")
                                    .foregroundColor(isNegativeBet ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success)
                            }
                            .padding(6)
                            .background(
                                (isNegativeBet ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.success).opacity(0.1)
                            )
                            .cornerRadius(8)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Amount")
                        
                        HStack {
                            Text(UserDefaults.standard.string(forKey: "currencySymbol") ?? "€")
                            
                            TextField("Amount", value: $betAmount, formatter: NumberFormatter())
                                .keyboardType(.decimalPad)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(AppDesignSystem.Layout.cornerRadius)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
                
                Section(header: Text("Description")) {
                    let currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
                    
                    if isNegativeBet {
                        Text("When a player has this event, they will pay \(currencySymbol)\(String(format: "%.2f", betAmount)) to participants who don't have the player.")
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    } else {
                        Text("When a player has this event, participants who don't have the player will pay \(currencySymbol)\(String(format: "%.2f", betAmount)) to those who do.")
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                
                Section {
                    Button(action: {
                        let finalAmount = isNegativeBet ? -betAmount : betAmount
                        gameSession.addCustomBet(name: betName, amount: finalAmount)
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Add Custom Bet")
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.headline)
                    }
                    .disabled(betName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || betAmount <= 0)
                }
            }
            .navigationTitle("Custom Bet")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
}

struct CustomBetView_Previews: PreviewProvider {
    static var previews: some View {
        CustomBetView(gameSession: GameSession())
    }
}
