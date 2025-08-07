//
//  UnifiedSaveGameSheet.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 06/08/2025.
//

import Foundation
import SwiftUI

struct UnifiedSaveGameSheet: View {
    @ObservedObject var gameSession: GameSession
    @Binding var isPresented: Bool
    let onSaveComplete: (() -> Void)?
    
    @State private var gameName: String
    @State private var saveMode: SaveMode = .newSave
    @State private var showingOverwriteConfirmation = false
    @State private var selectedExistingSave: SavedGameSession? = nil
    @State private var existingSaves: [SavedGameSession] = []
    
    enum SaveMode {
        case newSave
        case updateCurrent
        case overwriteExisting
    }
    
    init(gameSession: GameSession, isPresented: Binding<Bool>, onSaveComplete: (() -> Void)? = nil) {
        self.gameSession = gameSession
        self._isPresented = isPresented
        self.onSaveComplete = onSaveComplete
        self._gameName = State(initialValue: gameSession.currentSaveName ?? "")
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "externaldrive.badge.plus")
                            .font(.system(size: 60))
                            .foregroundColor(AppDesignSystem.Colors.primary)
                        
                        Text("Save Game")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                    }
                    
                    // Current save info (if exists)
                    if gameSession.hasBeenSaved, let currentName = gameSession.currentSaveName {
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppDesignSystem.Colors.success)
                                Text("Previously saved as: \"\(currentName)\"")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppDesignSystem.Colors.primaryText)
                            }
                            .padding()
                            .background(AppDesignSystem.Colors.success.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    
                    // Game name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Game Name")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppDesignSystem.Colors.primaryText)
                        
                        TextField("Enter game name", text: $gameName)
                            .font(.system(size: 16))
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppDesignSystem.Colors.cardBackground)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppDesignSystem.Colors.primary.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    
                    // Save options
                    VStack(spacing: 12) {
                        // Update current save (if exists)
                        if gameSession.hasBeenSaved, let currentName = gameSession.currentSaveName {
                            SaveOptionCard(
                                title: "Update \"\(currentName)\"",
                                subtitle: "Overwrite your previous save",
                                icon: "arrow.clockwise",
                                color: AppDesignSystem.Colors.primary,
                                isSelected: saveMode == .updateCurrent
                            ) {
                                saveMode = .updateCurrent
                                gameName = currentName
                                selectedExistingSave = nil
                            }
                        }
                        
                        // Save as new
                        SaveOptionCard(
                            title: "Save as New",
                            subtitle: "Create a separate save file",
                            icon: "plus.circle",
                            color: AppDesignSystem.Colors.success,
                            isSelected: saveMode == .newSave
                        ) {
                            saveMode = .newSave
                            selectedExistingSave = nil
                            if gameSession.hasBeenSaved {
                                gameName = ""
                            }
                        }
                        
                        // Overwrite existing save (if there are other saves)
                        if !existingSaves.isEmpty {
                            SaveOptionCard(
                                title: "Overwrite Existing Save",
                                subtitle: "Replace one of your saved games",
                                icon: "arrow.triangle.2.circlepath",
                                color: AppDesignSystem.Colors.warning,
                                isSelected: saveMode == .overwriteExisting
                            ) {
                                saveMode = .overwriteExisting
                                selectedExistingSave = nil
                            }
                        }
                    }
                    
                    // Existing saves list (shown when overwrite mode is selected)
                    if saveMode == .overwriteExisting && !existingSaves.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Choose Save to Overwrite")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppDesignSystem.Colors.primaryText)
                                .padding(.top, 8)
                            
                            ForEach(existingSaves) { save in
                                ExistingSaveCard(
                                    save: save,
                                    isSelected: selectedExistingSave?.id == save.id,
                                    onSelect: {
                                        selectedExistingSave = save
                                        gameName = save.name
                                    }
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    // Save button
                    Button(action: {
                        handleSave()
                    }) {
                        HStack {
                            Image(systemName: saveButtonIcon)
                            Text(saveButtonText)
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(
                                    canSave ? saveButtonColor : AppDesignSystem.Colors.secondaryText
                                )
                        )
                    }
                    .disabled(!canSave)
                }
                .padding(24)
            }
            .navigationTitle("Save Game")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                }
            )
        }
        .onAppear {
            loadExistingSaves()
        }
        .alert("Confirm Overwrite", isPresented: $showingOverwriteConfirmation) {
            Button("Overwrite", role: .destructive) {
                performSave()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            if let selectedSave = selectedExistingSave {
                Text("Are you sure you want to overwrite \"\(selectedSave.name)\"? This action cannot be undone.")
            } else {
                Text("A save with the name \"\(gameName)\" already exists. Do you want to overwrite it?")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canSave: Bool {
        let hasValidName = !gameName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        switch saveMode {
        case .newSave, .updateCurrent:
            return hasValidName
        case .overwriteExisting:
            return hasValidName && selectedExistingSave != nil
        }
    }
    
    private var saveButtonIcon: String {
        switch saveMode {
        case .updateCurrent:
            return "arrow.clockwise"
        case .overwriteExisting:
            return "arrow.triangle.2.circlepath"
        case .newSave:
            return "externaldrive.badge.plus"
        }
    }
    
    private var saveButtonText: String {
        switch saveMode {
        case .updateCurrent:
            return "Update Save"
        case .overwriteExisting:
            return "Overwrite Selected Save"
        case .newSave:
            return "Save Game"
        }
    }
    
    private var saveButtonColor: Color {
        switch saveMode {
        case .updateCurrent:
            return AppDesignSystem.Colors.primary
        case .overwriteExisting:
            return AppDesignSystem.Colors.warning
        case .newSave:
            return AppDesignSystem.Colors.success
        }
    }
    
    // MARK: - Methods
    
    private func loadExistingSaves() {
        existingSaves = GameHistoryManager.shared.getSavedGameSessions()
            .filter { $0.id != gameSession.saveId } // Exclude current save
            .sorted { $0.timestamp > $1.timestamp } // Most recent first - FIXED: using sorted(by:)
    }
    
    private func handleSave() {
        let trimmedName = gameName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        switch saveMode {
        case .updateCurrent:
            performSave()
            
        case .newSave:
            // Check if name already exists
            if gameSession.saveNameExists(trimmedName) {
                showingOverwriteConfirmation = true
            } else {
                performSave()
            }
            
        case .overwriteExisting:
            if selectedExistingSave != nil {
                showingOverwriteConfirmation = true
            }
        }
    }
    
    private func performSave() {
        switch saveMode {
        case .updateCurrent:
            gameSession.saveGame(name: gameName, isUpdate: true)
            
        case .newSave:
            gameSession.saveGame(name: gameName, isUpdate: false)
            
        case .overwriteExisting:
            if let existingSave = selectedExistingSave {
                // Set the save ID to the existing one so it gets overwritten
                gameSession.saveId = existingSave.id
                gameSession.saveGame(name: gameName, isUpdate: true)
            }
        }
        
        isPresented = false
        
        // Call completion callback if provided
        onSaveComplete?()
    }
}

// MARK: - Supporting Views

struct ExistingSaveCard: View {
    let save: SavedGameSession
    let isSelected: Bool
    let onSelect: () -> Void
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(save.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                        .lineLimit(1)
                    
                    HStack(spacing: 12) {
                        Text("\(save.participants.count) players")
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Text("•")
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Text("\(save.events.count) events")
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Text("•")
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                        
                        Text(dateFormatter.string(from: save.timestamp))
                            .font(.system(size: 12))
                            .foregroundColor(AppDesignSystem.Colors.secondaryText)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? AppDesignSystem.Colors.warning : AppDesignSystem.Colors.secondaryText)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppDesignSystem.Colors.warning.opacity(0.1) : AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? AppDesignSystem.Colors.warning : AppDesignSystem.Colors.secondaryText.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SaveOptionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppDesignSystem.Colors.primaryText)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(AppDesignSystem.Colors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? color : AppDesignSystem.Colors.secondaryText)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color.opacity(0.1) : AppDesignSystem.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? color : AppDesignSystem.Colors.secondaryText.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
