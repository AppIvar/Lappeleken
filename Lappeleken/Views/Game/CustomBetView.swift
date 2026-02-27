//
//  CustomBetView.swift
//  Lucky Football Slip
//
//  Add custom betting events - Football themed
//

import SwiftUI

struct CustomBetView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var gameSession: GameSession

    @State private var eventName = ""
    @State private var betAmount: Double = 1.0
    @State private var isNegativeBet = false
    @State private var showConfirmation = false

    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
    }

    var body: some View {
        NavigationView {
            ZStack {
                footballBackground
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerIcon
                        eventDetailsCard
                        previewCard
                        addButton
                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Custom Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { presentationMode.wrappedValue.dismiss() }
                        .foregroundColor(AppDesignSystem.Colors.grassGreen)
                }
            }
        }
        .alert("Event Added!", isPresented: $showConfirmation) {
            Button("OK") { presentationMode.wrappedValue.dismiss() }
        } message: {
            Text("\"\(eventName)\" has been added.")
        }
    }
    
    // MARK: - Background
    
    private var footballBackground: some View {
        ZStack {
            Color(colorScheme == .dark ? UIColor(red: 0.05, green: 0.08, blue: 0.06, alpha: 1) : UIColor(red: 0.96, green: 0.98, blue: 0.96, alpha: 1))
            VStack {
                LinearGradient(colors: [AppDesignSystem.Colors.accent.opacity(colorScheme == .dark ? 0.15 : 0.08), Color.clear], startPoint: .top, endPoint: .bottom)
                    .frame(height: 150)
                Spacer()
            }
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var headerIcon: some View {
        ZStack {
            Circle()
                .fill(AppDesignSystem.Colors.accent.opacity(0.15))
                .frame(width: 64, height: 64)
            Image(systemName: "star.fill")
                .font(.system(size: 28))
                .foregroundColor(AppDesignSystem.Colors.accent)
        }
    }
    
    // MARK: - Event Details Card
    
    private var eventDetailsCard: some View {
        VStack(spacing: 18) {
            // Event name
            VStack(alignment: .leading, spacing: 6) {
                Text("Event Name")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                HStack {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    TextField("e.g., Hat-trick, Penalty save...", text: $eventName)
                        .font(.system(size: 14))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(AppDesignSystem.Colors.accent.opacity(0.2), lineWidth: 1))
                )
            }
            
            // Event type
            VStack(alignment: .leading, spacing: 6) {
                Text("Event Type")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                HStack(spacing: 10) {
                    EventTypeButton(
                        title: "Positive",
                        subtitle: "Earns money",
                        icon: "plus.circle.fill",
                        color: AppDesignSystem.Colors.grassGreen,
                        isSelected: !isNegativeBet
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isNegativeBet = false }
                    }
                    
                    EventTypeButton(
                        title: "Negative",
                        subtitle: "Loses money",
                        icon: "minus.circle.fill",
                        color: AppDesignSystem.Colors.error,
                        isSelected: isNegativeBet
                    ) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isNegativeBet = true }
                    }
                }
            }
            
            // Amount
            VStack(alignment: .leading, spacing: 6) {
                Text("Amount")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppDesignSystem.Colors.secondaryText)
                
                HStack {
                    Text(currencySymbol)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    TextField("0.00", value: $betAmount, format: .number.precision(.fractionLength(2)))
                        .font(.system(size: 16, weight: .medium))
                        .keyboardType(.decimalPad)
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        ForEach([1.0, 5.0, 10.0], id: \.self) { amount in
                            QuickAmountButton(amount: amount, isSelected: betAmount == amount) {
                                betAmount = amount
                            }
                        }
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(colorScheme == .dark ? Color.white.opacity(0.05) : Color.black.opacity(0.03)))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(AppDesignSystem.Colors.cardBackground)
                .shadow(color: colorScheme == .dark ? Color.black.opacity(0.2) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        )
    }
    
    // MARK: - Preview Card
    
    private var previewCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "eye")
                    .font(.system(size: 12))
                Text("Preview")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(AppDesignSystem.Colors.secondaryText)
            
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppDesignSystem.Colors.accent.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "star.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppDesignSystem.Colors.accent)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(eventName.isEmpty ? "Event Name" : eventName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(eventName.isEmpty ? AppDesignSystem.Colors.secondaryText : AppDesignSystem.Colors.primaryText)
                    Text("Custom Event")
                        .font(.system(size: 11))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: isNegativeBet ? "minus.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 14))
                    Text("\(currencySymbol)\(String(format: "%.2f", betAmount))")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(isNegativeBet ? AppDesignSystem.Colors.error : AppDesignSystem.Colors.grassGreen)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 8).fill(colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02)))
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 14).fill(AppDesignSystem.Colors.cardBackground))
    }
    
    // MARK: - Add Button
    
    private var addButton: some View {
        Button(action: addCustomEvent) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                Text("Add Custom Event")
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isAddButtonDisabled ? AppDesignSystem.Colors.secondaryText.opacity(0.4) : AppDesignSystem.Colors.grassGreen)
            )
            .shadow(color: isAddButtonDisabled ? Color.clear : AppDesignSystem.Colors.grassGreen.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(isAddButtonDisabled)
    }
    
    private var isAddButtonDisabled: Bool {
        eventName.trimmingCharacters(in: .whitespaces).isEmpty || betAmount <= 0
    }
    
    private func addCustomEvent() {
        let name = eventName.trimmingCharacters(in: .whitespaces)
        let amount = isNegativeBet ? -betAmount : betAmount
        gameSession.addCustomEvent(name: name, amount: amount)
        showConfirmation = true
    }
}

// MARK: - Event Type Button

struct EventTypeButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? color : AppDesignSystem.Colors.secondaryText)
                
                VStack(spacing: 1) {
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? color : AppDesignSystem.Colors.primaryText)
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? color.opacity(0.1) : colorScheme == .dark ? Color.white.opacity(0.03) : Color.black.opacity(0.02))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? color : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Quick Amount Button

struct QuickAmountButton: View {
    let amount: Double
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text("\(Int(amount))")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isSelected ? .white : AppDesignSystem.Colors.secondaryText)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? AppDesignSystem.Colors.grassGreen : AppDesignSystem.Colors.secondaryText.opacity(0.15))
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
