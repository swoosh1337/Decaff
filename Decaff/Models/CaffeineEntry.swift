//
//  CaffeineEntry.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/12/24.
//

import Foundation
import SwiftData

@Model
final class CaffeineEntry: Identifiable {
    var id: UUID
    var timestamp: Date
    var caffeineAmount: Double // in mg
    var beverageName: String
    var beverageType: BeverageType
    var customBeverage: Bool
    var volume: Double // in ml
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        caffeineAmount: Double,
        beverageName: String,
        beverageType: BeverageType,
        customBeverage: Bool = false,
        volume: Double
    ) {
        self.id = id
        self.timestamp = timestamp
        self.caffeineAmount = caffeineAmount
        self.beverageName = beverageName
        self.beverageType = beverageType
        self.customBeverage = customBeverage
        self.volume = volume
    }
    
    func saveToHealthKit() async {
        do {
            try await HealthKitService.shared.saveCaffeineEntry(self)
            print("Successfully saved caffeine entry to HealthKit")
        } catch {
            print("Failed to save caffeine to HealthKit: \(error.localizedDescription)")
        }
    }
}

enum BeverageType: String, Codable {
    case coffee
    case tea
    case energyDrink
    case soda
    case custom
}
