//
//  NotificationDelegate.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 05/08/2025.
//

import Foundation
import UserNotifications

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
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
            
            // Navigate to the game
            DispatchQueue.main.async {
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
