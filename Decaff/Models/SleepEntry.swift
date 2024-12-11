import Foundation

struct SleepEntry {
    let startDate: Date
    let endDate: Date
    let value: Int
    let heartRate: Double
    
    var durationInHours: Double {
        endDate.timeIntervalSince(startDate) / 3600
    }
}
