//
//  APIUsageDebugView.swift
//  Lucky Football Slip
//
//  Created by Ivar Hovland on 03/06/2025.
//

import SwiftUI

#if DEBUG
struct APIUsageDebugView: View {
    @State private var timer: Timer?
    @State private var stats: (current: Int, max: Int, resetTime: Date?) = (0, 0, nil)
    @State private var cacheStats: (matches: Int, lists: Int, players: Int) = (0, 0, 0)
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🐛 API Debug Info")
                .font(.headline)
                .foregroundColor(.orange)
            
            Group {
                HStack {
                    Text("API Calls:")
                        .font(.caption)
                    
                    Spacer()
                    
                    Text("\(stats.current)/\(stats.max)")
                        .font(.caption.bold())
                        .foregroundColor(stats.current > stats.max * 80 / 100 ? .red : .primary)
                }
                
                if let resetTime = stats.resetTime {
                    HStack {
                        Text("Resets:")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(resetTime, formatter: timeFormatter)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("Cache:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(cacheStats.matches)M, \(cacheStats.lists)L, \(cacheStats.players)P")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Test buttons
                HStack(spacing: 8) {
                    Button("Test") {
                        Task {
                            if let footballService = ServiceProvider.shared.getMatchService() as? FootballDataMatchService {
                                await footballService.testLiveModeFlow()
                            }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                    
                    Button("Clear Cache") {
                        MatchCacheManager.shared.clearAllCache()
                        print("🧹 All cache cleared")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    
                    Button("Reset Rate") {
                        APIRateLimiter.shared.debugReset()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                }
            }
        }
        .padding(8)
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(8)
        .onAppear {
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            stats = APIRateLimiter.shared.getUsageStats()
            cacheStats = MatchCacheManager.shared.getCacheStats()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}
#endif

// Add this to your SettingsView debug section:
#if DEBUG
private var debugAPIMonitoring: some View {
    APIUsageDebugView()
}
#endif
