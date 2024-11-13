//
//  UserProfile.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/13/24.
//

import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID
    var name: String
    var onboardingCompleted: Bool
    var trialStartDate: Date?
    var isPremium: Bool
    var healthKitEnabled: Bool
    var notificationsEnabled: Bool
    var notificationTime: Date?
    
    init(
        id: UUID = UUID(),
        name: String = "",
        onboardingCompleted: Bool = false,
        trialStartDate: Date? = nil,
        isPremium: Bool = false,
        healthKitEnabled: Bool = false,
        notificationsEnabled: Bool = false,
        notificationTime: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.onboardingCompleted = onboardingCompleted
        self.trialStartDate = trialStartDate
        self.isPremium = isPremium
        self.healthKitEnabled = healthKitEnabled
        self.notificationsEnabled = notificationsEnabled
        self.notificationTime = notificationTime
    }
}
