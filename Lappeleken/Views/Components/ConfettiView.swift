//
//  ConfettiView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 19/05/2025.
//

import SwiftUI

// Simple confetti animation
struct ConfettiView: View {
    let pieceCount = 100
    @State private var pieces: [ConfettiPiece] = []
    
    init() {
        // Generate random confetti pieces
        var initialPieces: [ConfettiPiece] = []
        for _ in 0..<pieceCount {
            initialPieces.append(ConfettiPiece())
        }
        _pieces = State(initialValue: initialPieces)
    }
    
    var body: some View {
        ZStack {
            ForEach(0..<pieces.count, id: \.self) { index in
                ConfettiPieceView(piece: pieces[index])
            }
        }
    }
    
    struct ConfettiPiece {
        let color = [Color.red, Color.blue, Color.green, Color.yellow, Color.purple,
                     Color.orange].randomElement()!
        let size = CGFloat.random(in: 5...12)
        let x = CGFloat.random(in: 0...UIScreen.main.bounds.width)
        let rotation = Double.random(in: 0...360)
        let speed = Double.random(in: 2...6)
    }
    
    struct ConfettiPieceView: View {
        let piece: ConfettiPiece
        @State private var yPosition = -100.0
        
        var body: some View {
            Rectangle()
                .fill(piece.color)
                .frame(width: piece.size, height: piece.size)
                .rotationEffect(Angle(degrees: piece.rotation))
                .position(x: piece.x, y: yPosition)
                .onAppear {
                    withAnimation(.linear(duration: piece.speed)) {
                        yPosition = UIScreen.main.bounds.height + 100
                    }
                }
        }
    }
}
