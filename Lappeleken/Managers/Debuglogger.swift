//
//  DebugLogger.swift
//  Lucky Football Slip
//
//  Debug-only logging to reduce memory usage in release builds
//

import Foundation

/// Debug-only logging utility
/// Prints are completely eliminated in release builds
enum DebugLogger {
    
    /// Log a message (debug builds only)
    static func log(_ message: String, file: String = #file, function: String = #function) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("[\(fileName)] \(message)")
        #endif
    }
    
    /// Log with emoji prefix (debug builds only)
    static func log(_ emoji: String, _ message: String) {
        #if DEBUG
        print("\(emoji) \(message)")
        #endif
    }
    
    /// Log an error (debug builds only)
    static func error(_ message: String, error: Error? = nil) {
        #if DEBUG
        if let error = error {
            print("❌ \(message): \(error.localizedDescription)")
        } else {
            print("❌ \(message)")
        }
        #endif
    }
    
    /// Log success (debug builds only)
    static func success(_ message: String) {
        #if DEBUG
        print("✅ \(message)")
        #endif
    }
    
    /// Log API-related messages (controlled by AppConfig)
    static func api(_ message: String) {
        #if DEBUG
        if AppConfig.enableDetailedLogging {
            print("📡 \(message)")
        }
        #endif
    }
    
    /// Log cache-related messages
    static func cache(_ message: String) {
        #if DEBUG
        if AppConfig.enableDetailedLogging {
            print("📦 \(message)")
        }
        #endif
    }
}

// MARK: - Convenience Global Function

/// Quick debug log (use instead of print)
func dlog(_ message: String) {
    DebugLogger.log(message)
}
