//
//  NotificationDelegate.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 05/08/2025.
//

import Foundation
import UserNotifications
import SwiftUI

class NotificationDelegate: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    @Published var lastNotificationGameId: String?
    @Published var lastNotificationType: String?
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let gameId = userInfo["gameId"] as? String,
           let type = userInfo["type"] as? String {
            
            // Update published properties for SwiftUI navigation
            DispatchQueue.main.async {
                self.lastNotificationGameId = gameId
                self.lastNotificationType = type
                
                // Also post notification for backward compatibility
                NotificationCenter.default.post(
                    name: Notification.Name("OpenGameFromNotification"),
                    object: nil,
                    userInfo: ["gameId": gameId, "type": type]
                )
            }
        }
        
        completionHandler()
    }
}
