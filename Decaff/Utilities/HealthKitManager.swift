//
//  HealthKitManager.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/13/24.
//

import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    private let healthStore = HKHealthStore()
    
    private init() {}
    
    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        
        let typesToRead: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        ]
        
        let typesToWrite: Set<HKSampleType> = [
            HKObjectType.quantityType(forIdentifier: .dietaryCaffeine)!
        ]
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
    }
    
    func saveCaffeineIntake(_ amount: Double, date: Date) async throws {
        guard let caffeineType = HKObjectType.quantityType(forIdentifier: .dietaryCaffeine) else {
            throw HealthKitError.caffeineTypeNotAvailable
        }
        
        let quantity = HKQuantity(unit: .gramUnit(with: .milli), doubleValue: amount)
        let sample = HKQuantitySample(type: caffeineType,
                                    quantity: quantity,
                                    start: date,
                                    end: date)
        
        try await healthStore.save(sample)
    }
}

enum HealthKitError: Error {
    case notAvailable
    case caffeineTypeNotAvailable
    case unauthorized
}
