import Foundation

struct SleepEntry: Identifiable {
    let id = UUID()
    let startDate: Date
    let endDate: Date
    let value: Int  // Sleep quality value (0-100)
    
    var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }
    
    var durationInHours: Double {
        duration / 3600  // Convert seconds to hours
    }
}
