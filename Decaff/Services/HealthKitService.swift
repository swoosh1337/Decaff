import HealthKit
import Foundation

class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let caffeineType = HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!
    
    @Published var isAuthorized = false
    
    private let requiredTypes: Set<HKSampleType> = [
        HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
        HKObjectType.quantityType(forIdentifier: .heartRate)!,
        HKObjectType.quantityType(forIdentifier: .stepCount)!,
        HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!
    ]
    
    func requestAuthorization() async throws {
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToShare, read: requiredTypes)
        await MainActor.run { isAuthorized = true }
        print("HealthKit authorization status: \(isAuthorized)")
    }
    
    func saveCaffeineEntry(_ entry: CaffeineEntry) async throws {
        let caffeineQuantity = HKQuantity(unit: .gramUnit(with: .milli), doubleValue: entry.caffeineAmount)
        let sample = HKQuantitySample(
            type: caffeineType,
            quantity: caffeineQuantity,
            start: entry.timestamp,
            end: entry.timestamp // For dietary items, start and end time are the same
        )
        
        try await healthStore.save(sample)
        print("Saved caffeine entry to HealthKit: \(entry.caffeineAmount)mg at \(entry.timestamp)")
    }
    
    func fetchCaffeineData(for date: Date) async throws -> Double {
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: date),
            end: Calendar.current.startOfDay(for: date.addingTimeInterval(86400)),
            options: .strictStartDate
        )
        
        let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
            let query = HKStatisticsQuery(
                quantityType: caffeineType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    print("Error fetching caffeine: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: statistics)
            }
            healthStore.execute(query)
        }
        
        let caffeine = statistics?.sumQuantity()?.doubleValue(for: .gramUnit(with: .milli)) ?? 0
        print("Caffeine for \(date): \(caffeine)mg")
        return caffeine
    }
    
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [SleepEntry] {
        print("Fetching sleep data from \(startDate) to \(endDate)")
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )
        
        // Include all sleep states
        let sleepPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [
            HKQuery.predicateForCategorySamples(with: .equalTo, value: HKCategoryValueSleepAnalysis.inBed.rawValue),
            HKQuery.predicateForCategorySamples(with: .equalTo, value: HKCategoryValueSleepAnalysis.asleep.rawValue),
            HKQuery.predicateForCategorySamples(with: .equalTo, value: HKCategoryValueSleepAnalysis.asleepCore.rawValue),
            HKQuery.predicateForCategorySamples(with: .equalTo, value: HKCategoryValueSleepAnalysis.asleepDeep.rawValue),
            HKQuery.predicateForCategorySamples(with: .equalTo, value: HKCategoryValueSleepAnalysis.asleepREM.rawValue)
        ])
        
        let finalPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [predicate, sleepPredicate])
        
        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKCategorySample], Error>) in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: finalPredicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error = error {
                    print("Error fetching sleep data: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                
                let categorySamples = samples as? [HKCategorySample] ?? []
                print("Found \(categorySamples.count) raw sleep samples")
                continuation.resume(returning: categorySamples)
            }
            healthStore.execute(query)
        }
        
        // Merge sleep samples into sessions
        let mergedSessions = mergeSleepSamples(samples)
        print("Merged into \(mergedSessions.count) sleep sessions")
        
        // Convert to SleepEntry objects with heart rate data
        return try await mergedSessions.asyncMap { session in
            let heartRate = try await fetchHeartRate(during: session.startDate, to: session.endDate)
            print("Complete sleep session: \(session.startDate) to \(session.endDate), Duration: \(session.endDate.timeIntervalSince(session.startDate)/3600) hours, Heart rate: \(heartRate)")
            return SleepEntry(
                startDate: session.startDate,
                endDate: session.endDate,
                value: session.value,
                heartRate: heartRate
            )
        }
    }
    
    private func mergeSleepSamples(_ samples: [HKCategorySample]) -> [HKCategorySample] {
        guard !samples.isEmpty else { return [] }
        
        let calendar = Calendar.current
        var mergedSessions: [HKCategorySample] = []
        var currentSession = samples[0]
        
        for sample in samples.dropFirst() {
            // If the gap between samples is less than 45 minutes, consider them part of the same session
            if sample.startDate.timeIntervalSince(currentSession.endDate) <= 45 * 60 {
                // Merge the sessions
                currentSession = HKCategorySample(
                    type: sleepType,
                    value: max(currentSession.value, sample.value),
                    start: currentSession.startDate,
                    end: sample.endDate
                )
            } else {
                // If the gap is too large, start a new session
                if currentSession.endDate.timeIntervalSince(currentSession.startDate) >= 30 * 60 {
                    // Only keep sessions longer than 30 minutes
                    mergedSessions.append(currentSession)
                }
                currentSession = sample
            }
        }
        
        // Add the last session if it's long enough
        if currentSession.endDate.timeIntervalSince(currentSession.startDate) >= 30 * 60 {
            mergedSessions.append(currentSession)
        }
        
        return mergedSessions
    }
    
    func fetchHeartRate(during start: Date, to end: Date) async throws -> Double {
        print("Fetching heart rate from \(start) to \(end)")
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        
        let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
            let query = HKStatisticsQuery(
                quantityType: heartRateType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, statistics, error in
                if let error = error {
                    print("Error fetching heart rate: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: statistics)
            }
            healthStore.execute(query)
        }
        
        let heartRate = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) ?? 0
        print("Average heart rate: \(heartRate) BPM")
        return heartRate
    }
    
    func fetchSteps(for date: Date) async throws -> Int {
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: date),
            end: Calendar.current.startOfDay(for: date.addingTimeInterval(86400)),
            options: .strictStartDate
        )
        
        let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    print("Error fetching steps: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: statistics)
            }
            healthStore.execute(query)
        }
        
        let steps = Int(statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0)
        print("Steps for \(date): \(steps)")
        return steps
    }
    
    func fetchCalories(for date: Date) async throws -> Double {
        let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let predicate = HKQuery.predicateForSamples(
            withStart: Calendar.current.startOfDay(for: date),
            end: Calendar.current.startOfDay(for: date.addingTimeInterval(86400)),
            options: .strictStartDate
        )
        
        let statistics = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<HKStatistics?, Error>) in
            let query = HKStatisticsQuery(
                quantityType: caloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, error in
                if let error = error {
                    print("Error fetching calories: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume(returning: statistics)
            }
            healthStore.execute(query)
        }
        
        let calories = statistics?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()) ?? 0
        print("Calories for \(date): \(calories)")
        return calories
    }
}

extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async throws -> [T] {
        var values = [T]()
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }
}

enum HealthError: Error {
    case healthDataUnavailable
    case unauthorized
    case fetchError(String)
}
