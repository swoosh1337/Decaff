import Foundation
import HealthKit

struct DailyCaffeineData {
    let date: Date
    let totalAmount: Double
    let lastIntakeTime: Date?
    let lastIntakeAmount: Double?
    let estimatedBloodLevelAtSleep: Double?
}

struct DailySleepData {
    let date: Date
    let totalHours: Double
    let bedTime: Date?
    let wakeTime: Date?
}

class MockDataService {
    static let shared = MockDataService()
    
    func generateMockSleepData(for days: Int) -> [DailySleepData] {
        let calendar = Calendar.current
        var sleepData: [DailySleepData] = []
        
        for day in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else { continue }
            
            // Generate random sleep duration between 5 and 9 hours
            let sleepHours = Double.random(in: 5...9)
            
            // Generate random bedtime between 9 PM and 12 AM
            let bedTimeHour = Int.random(in: 21...23)
            let bedTime = calendar.date(bySettingHour: bedTimeHour, minute: Int.random(in: 0...59), second: 0, of: date)
            
            // Calculate wake time based on sleep duration
            let wakeTime = bedTime?.addingTimeInterval(sleepHours * 3600)
            
            sleepData.append(DailySleepData(
                date: date,
                totalHours: sleepHours,
                bedTime: bedTime,
                wakeTime: wakeTime
            ))
        }
        
        return sleepData.sorted { $0.date < $1.date }
    }
    
    func generateMockCaffeineData(for days: Int) -> [DailyCaffeineData] {
        let calendar = Calendar.current
        var caffeineData: [DailyCaffeineData] = []
        
        for day in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -day, to: Date()) else { continue }
            
            // Generate 2-4 coffee drinks per day
            let drinksCount = Int.random(in: 2...4)
            var dailyCaffeine = 0.0
            var lastIntakeTime: Date? = nil
            var lastIntakeAmount: Double? = nil
            
            for _ in 0..<drinksCount {
                // Random caffeine amount per drink (65-120mg)
                let amount = Double.random(in: 65...120)
                dailyCaffeine += amount
                
                // Generate random intake time between 7 AM and 6 PM
                let hour = Int.random(in: 7...18)
                let intakeTime = calendar.date(bySettingHour: hour, minute: Int.random(in: 0...59), second: 0, of: date)
                
                if let time = intakeTime {
                    if lastIntakeTime == nil || time > lastIntakeTime! {
                        lastIntakeTime = time
                        lastIntakeAmount = amount
                    }
                }
            }
            
            // Calculate estimated caffeine in blood at typical bedtime (11 PM)
            var estimatedBloodLevel: Double? = nil
            if let lastIntake = lastIntakeTime {
                guard let bedtime = calendar.date(bySettingHour: 23, minute: 0, second: 0, of: date) else { continue }
                let hoursSinceLastIntake = calendar.dateComponents([.hour], from: lastIntake, to: bedtime).hour ?? 0
                // Caffeine half-life is about 5 hours
                let halfLifeCycles = Double(hoursSinceLastIntake) / 5.0
                estimatedBloodLevel = (lastIntakeAmount ?? 0) * pow(0.5, halfLifeCycles)
            }
            
            caffeineData.append(DailyCaffeineData(
                date: date,
                totalAmount: dailyCaffeine,
                lastIntakeTime: lastIntakeTime,
                lastIntakeAmount: lastIntakeAmount,
                estimatedBloodLevelAtSleep: estimatedBloodLevel
            ))
        }
        
        return caffeineData.sorted { $0.date < $1.date }
    }
}
