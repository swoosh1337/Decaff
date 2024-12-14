import SwiftUI
import SwiftData

@MainActor
class TestingUtility {
    static let shared = TestingUtility()
    
    private init() {}
    
    func insertMockData(context: ModelContext) {
        // Sample beverages
        let beverages = [
            (name: "Coffee", type: BeverageType.coffee, caffeine: 95.0, volume: 240.0),
            (name: "Espresso", type: BeverageType.coffee, caffeine: 63.0, volume: 30.0),
            (name: "Green Tea", type: BeverageType.tea, caffeine: 28.0, volume: 240.0),
            (name: "Red Bull", type: BeverageType.energyDrink, caffeine: 80.0, volume: 250.0),
            (name: "Cola", type: BeverageType.soda, caffeine: 34.0, volume: 355.0)
        ]
        
        // Generate entries for the past week
        let calendar = Calendar.current
        let now = Date()
        
        for daysAgo in 0...7 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
            
            // Add 2-4 random entries per day
            let entriesCount = Int.random(in: 2...4)
            for _ in 0..<entriesCount {
                let beverage = beverages.randomElement()!
                let hourOffset = Double.random(in: 8...20) // Between 8 AM and 8 PM
                guard let timestamp = calendar.date(bySettingHour: Int(hourOffset),
                                                 minute: Int.random(in: 0...59),
                                                 second: 0,
                                                 of: date) else { continue }
                
                let entry = CaffeineEntry(
                    timestamp: timestamp,
                    caffeineAmount: beverage.caffeine,
                    beverageName: beverage.name,
                    beverageType: beverage.type,
                    volume: beverage.volume
                )
                context.insert(entry)
            }
        }
        
        try? context.save()
    }
    
    func generateSampleSleepData() -> [SleepEntry] {
        let calendar = Calendar.current
        let now = Date()
        var sleepEntries: [SleepEntry] = []
        
        for daysAgo in 0...7 {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: now) else { continue }
            
            // Generate sleep start time (previous day between 9 PM and 11 PM)
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: date),
                  let startTime = calendar.date(
                    bySettingHour: Int.random(in: 21...23),
                    minute: Int.random(in: 0...59),
                    second: 0,
                    of: previousDay
                  ) else { continue }
            
            // Generate sleep end time (between 6 AM and 8 AM)
            guard let endTime = calendar.date(
                bySettingHour: Int.random(in: 6...8),
                minute: Int.random(in: 0...59),
                second: 0,
                of: date
            ) else { continue }
            
            let sleepEntry = SleepEntry(
                startDate: startTime,
                endDate: endTime,
                value: Int.random(in: 60...100),
                heartRate: Double.random(in: 55...65)
            )
            sleepEntries.append(sleepEntry)
        }
        
        return sleepEntries
    }
    
    func clearAllData(context: ModelContext) {
        // Delete all CaffeineEntries
        let caffeineDescriptor = FetchDescriptor<CaffeineEntry>()
        if let entries = try? context.fetch(caffeineDescriptor) {
            entries.forEach { context.delete($0) }
        }
        
        try? context.save()
    }
}

// MARK: - Testing Menu
struct TestingMenu: View {
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @StateObject private var profileManager = UserProfileManager.shared
    
    var body: some View {
        NavigationView {
            List {
                
                
                Section("Test Data") {
                    Button("Insert Mock Data") {
                        TestingUtility.shared.insertMockData(context: modelContext)
                    }
                    
                    Button("Clear All Data", role: .destructive) {
                        TestingUtility.shared.clearAllData(context: modelContext)
                    }
                }
            }
            .navigationTitle("Testing Menu")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}
