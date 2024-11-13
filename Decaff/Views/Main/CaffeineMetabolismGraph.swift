//
//  CaffeineMetabolismGraph.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/12/24.
//

import SwiftUI
import Charts

struct CaffeineMetabolismGraph: View {
    let entries: [CaffeineEntry]
    
    private var metabolismData: [MetabolismPoint] {
        calculateMetabolismPoints()
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Caffeine Metabolism")
                .font(.headline)
            
            Chart(metabolismData) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value("Caffeine", point.amount)
                )
                .foregroundStyle(Color.accentColor)
            }
            .frame(height: 200)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func calculateMetabolismPoints() -> [MetabolismPoint] {
        let halfLife: TimeInterval = 5 * 3600 // 5 hours in seconds
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        var points: [MetabolismPoint] = []
        
        // Generate points every 30 minutes
        let interval: TimeInterval = 1800 // 30 minutes
        var currentTime = startOfDay
        
        while currentTime <= now + 3600 * 4 { // Show prediction 4 hours into future
            var totalCaffeine: Double = 0
            
            for entry in entries {
                if entry.timestamp <= currentTime {
                    let timeSinceIntake = currentTime.timeIntervalSince(entry.timestamp)
                    let halfLives = timeSinceIntake / halfLife
                    let remainingCaffeine = entry.caffeineAmount * pow(0.5, halfLives)
                    totalCaffeine += remainingCaffeine
                }
            }
            
            points.append(MetabolismPoint(time: currentTime, amount: totalCaffeine))
            currentTime += interval
        }
        
        return points
    }
}

struct MetabolismPoint: Identifiable {
    let id = UUID()
    let time: Date
    let amount: Double
}

