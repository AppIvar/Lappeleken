//
//  PDFExporter.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 16/05/2025.
//

import UIKit
import PDFKit
import SwiftUI

// Fixed PDFExporter class with proper error handling and debugging
class PDFExporter {
    /// Exports game summary as a PDF
    /// - Parameters:
    ///   - gameSession: The game session to export
    ///   - completion: Callback with the URL of the created PDF file or nil if failed
    static func exportGameSummary(gameSession: GameSession, completion: @escaping (URL?) -> Void) {
        // Debug output to help diagnose issues
        print("Starting PDF export process")
        
        // Create a PDF document
        let pdfMetaData = [
            kCGPDFContextCreator: "Lucky Football Slip",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "Game Summary"
        ]
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        // Set PDF size to A4
        let pageWidth = 8.27 * 72.0
        let pageHeight = 11.69 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        print("PDF renderer created")
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = UserDefaults.standard.string(forKey: "currencySymbol") ?? "€"
        
        do {
            let data = renderer.pdfData { (context) in
                context.beginPage()
                print("PDF page started")
                
                // Define styles
                let titleAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 22, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
                
                let headingAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 18, weight: .bold),
                    .foregroundColor: UIColor.black
                ]
                
                let subheadingAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 16, weight: .semibold),
                    .foregroundColor: UIColor.black
                ]
                
                let bodyAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                    .foregroundColor: UIColor.black
                ]
                
                let smallAttributes: [NSAttributedString.Key: Any] = [
                    .font: UIFont.systemFont(ofSize: 10, weight: .regular),
                    .foregroundColor: UIColor.darkGray
                ]
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .medium
                dateFormatter.timeStyle = .short
                
                // Add title
                let title = "Lucky Football Slip - Game Summary"
                drawText(title, attributes: titleAttributes, rect: CGRect(x: 50, y: 50, width: pageWidth - 100, height: 30))
                
                // Add date
                let dateString = "Generated on \(dateFormatter.string(from: Date()))"
                drawText(dateString, attributes: smallAttributes, rect: CGRect(x: 50, y: 80, width: pageWidth - 100, height: 20))
                
                // Add horizontal line
                drawLine(startPoint: CGPoint(x: 50, y: 100), endPoint: CGPoint(x: pageWidth - 50, y: 100))
                
                var yPosition = 120.0
                
                // Participants & Final Balances
                drawText("Final Balances", attributes: headingAttributes, rect: CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 30))
                yPosition += 35
                
                let sortedParticipants = gameSession.participants.sorted(by: { $0.balance > $1.balance })
                
                for participant in sortedParticipants {
                    let balanceString = formatter.string(from: NSNumber(value: participant.balance)) ?? "€0.00"
                    let isPositive = participant.balance >= 0
                    let participantText = "\(participant.name): \(balanceString)"
                    
                    let color: UIColor = isPositive ? UIColor.systemGreen : UIColor.systemRed
                    let participantAttributes: [NSAttributedString.Key: Any] = [
                        .font: UIFont.systemFont(ofSize: 12, weight: .regular),
                        .foregroundColor: color
                    ]
                    
                    drawText(participantText, attributes: participantAttributes, rect: CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 20))
                    yPosition += 25
                }
                
                yPosition += 10
                drawLine(startPoint: CGPoint(x: 50, y: yPosition), endPoint: CGPoint(x: pageWidth - 50, y: yPosition))
                yPosition += 20
                
                // Payments
                drawText("Payments", attributes: headingAttributes, rect: CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 30))
                yPosition += 35
                
                // Calculate payments (copied from GameSummaryView)
                func calculatePayments() -> [(from: String, to: String, amount: Double)] {
                    var payments: [(from: String, to: String, amount: Double)] = []
                    
                    // Make a copy of participants to work with
                    let participants = gameSession.participants.map { $0 }
                    
                    // Find participants with negative and positive balances
                    let debtors = participants.filter { $0.balance < 0 }
                    let creditors = participants.filter { $0.balance > 0 }
                    
                    // Return if either group is empty
                    if debtors.isEmpty || creditors.isEmpty {
                        return payments
                    }
                    
                    // Create mutable copies
                    var mutableDebtors = debtors
                    var mutableCreditors = creditors
                    
                    // Process each debtor
                    while !mutableDebtors.isEmpty && !mutableCreditors.isEmpty {
                        var debtor = mutableDebtors[0]
                        var creditor = mutableCreditors[0]
                        
                        // Calculate payment amount
                        let paymentAmount = min(abs(debtor.balance), creditor.balance)
                        
                        // Record payment
                        payments.append((from: debtor.name, to: creditor.name, amount: paymentAmount))
                        
                        // Update balances
                        debtor.balance += paymentAmount
                        creditor.balance -= paymentAmount
                        
                        // Remove or update participants
                        if abs(debtor.balance) < 0.01 {
                            mutableDebtors.removeFirst()
                        } else {
                            mutableDebtors[0] = debtor
                        }
                        
                        if abs(creditor.balance) < 0.01 {
                            mutableCreditors.removeFirst()
                        } else {
                            mutableCreditors[0] = creditor
                        }
                    }
                    
                    return payments
                }
                
                let payments = calculatePayments()
                
                if payments.isEmpty {
                    drawText("No payments needed", attributes: bodyAttributes, rect: CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 20))
                    yPosition += 25
                } else {
                    for payment in payments {
                        let paymentString = "\(payment.from) → \(payment.to): \(formatter.string(from: NSNumber(value: payment.amount)) ?? "€0.00")"
                        
                        drawText(paymentString, attributes: bodyAttributes, rect: CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 20))
                        yPosition += 25
                    }
                }
                
                yPosition += 10
                drawLine(startPoint: CGPoint(x: 50, y: yPosition), endPoint: CGPoint(x: pageWidth - 50, y: yPosition))
                yPosition += 20
                
                // Events
                drawText("Game Events", attributes: headingAttributes, rect: CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 30))
                yPosition += 35
                
                if gameSession.events.isEmpty {
                    drawText("No events recorded", attributes: bodyAttributes, rect: CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 20))
                    yPosition += 25
                } else {
                    let sortedEvents = gameSession.events.sorted(by: { $0.timestamp < $1.timestamp })
                    
                    for event in sortedEvents {
                        let timeFormatter = DateFormatter()
                        timeFormatter.dateStyle = .none
                        timeFormatter.timeStyle = .short
                        
                        let eventString = "\(timeFormatter.string(from: event.timestamp)): \(event.eventType.rawValue) - \(event.player.name) (\(event.player.team.name))"
                        
                        drawText(eventString, attributes: bodyAttributes, rect: CGRect(x: 50, y: yPosition, width: pageWidth - 100, height: 20))
                        yPosition += 25
                        
                        if yPosition > pageHeight - 100 {
                            context.beginPage()
                            yPosition = 50
                        }
                    }
                }
                
                // Add footer
                let footerY = pageHeight - 40
                drawText("Created with Lucky Football Slip App", attributes: smallAttributes,
                        rect: CGRect(x: 50, y: footerY, width: pageWidth - 100, height: 20))
                print("PDF content generated successfully")
            }
            
            // Save PDF to temporary file
            let tmpURL = FileManager.default.temporaryDirectory.appendingPathComponent("LuckyFootballSlip_Summary_\(Date().timeIntervalSince1970).pdf")
            
            try data.write(to: tmpURL)
            print("PDF written to file: \(tmpURL.path)")
            completion(tmpURL)
        } catch {
            print("Error generating or saving PDF: \(error)")
            completion(nil)
        }
    }
    
    // Helper function to draw text
    private static func drawText(_ text: String, attributes: [NSAttributedString.Key: Any], rect: CGRect) {
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        attributedString.draw(in: rect)
    }
    
    // Helper function to draw a line
    private static func drawLine(startPoint: CGPoint, endPoint: CGPoint) {
        let path = UIBezierPath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        path.lineWidth = 1.0
        UIColor.gray.setStroke()
        path.stroke()
    }
}
