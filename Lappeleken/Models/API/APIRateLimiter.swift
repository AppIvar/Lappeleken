//
//  APIRateLimiter.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 02/06/2025.
//

import Foundation

class APIRateLimiter {
    static let shared = APIRateLimiter()
    
    private let maxCallsPerMinute = 25
    private let timeWindow: TimeInterval = 60
    private var callTimestamps: [Date] = []
    private let queue = DispatchQueue(label: "rate.limiter", qos: .utility)
    
    private init() {}
    
    func canMakeCall() -> Bool {
        return queue.sync {
            cleanOldTimestamps()
            return callTimestamps.count < maxCallsPerMinute
        }
    }
    
    func recordCall() {
        queue.sync {
            callTimestamps.append(Date())
            cleanOldTimestamps()
        }
    }
    
    func timeUntilNextCall() -> TimeInterval {
        return queue.sync {
            cleanOldTimestamps()
            
            if callTimestamps.count < maxCallsPerMinute {
                return 0
            }
            
            let oldestCall = callTimestamps.first ?? Date()
            let timeToWait = timeWindow - Date().timeIntervalSince(oldestCall)
            
            return max(0, timeToWait)
        }
    }
    
    private func cleanOldTimestamps() {
        let cutoffTime = Date().addingTimeInterval(-timeWindow)
        callTimestamps.removeAll { $0 < cutoffTime }
    }
    
    func getUsageStats() -> (current: Int, max: Int, resetTime: Date?) {
        return queue.sync {
            cleanOldTimestamps()
            let resetTime = callTimestamps.first?.addingTimeInterval(timeWindow)
            return (callTimestamps.count, maxCallsPerMinute, resetTime)
        }
    }
}
