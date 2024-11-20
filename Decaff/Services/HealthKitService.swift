import HealthKit
import Foundation

class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    
    @Published var isAuthorized = false
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthError.healthDataUnavailable
        }
        
        let typesToRead: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        let typesToShare: Set<HKSampleType> = []
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        await MainActor.run {
            isAuthorized = true
        }
    }
    
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [SleepEntry] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: sleepType,
                                    predicate: predicate,
                                    limit: HKObjectQueryNoLimit,
                                    sortDescriptors: [sortDescriptor]) { (_, samples, error) in
                if let error = error {
                    continuation.resume(throwing: HealthError.fetchError(error.localizedDescription))
                    return
                }
                
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                // Process sleep samples
                let sleepEntries = samples.map { sample in
                    return SleepEntry(
                        startDate: sample.startDate,
                        endDate: sample.endDate,
                        value: sample.value
                    )
                }
                
                continuation.resume(returning: sleepEntries)
            }
            
            healthStore.execute(query)
        }
    }
}

enum HealthError: Error {
    case healthDataUnavailable
    case unauthorized
    case fetchError(String)
}
