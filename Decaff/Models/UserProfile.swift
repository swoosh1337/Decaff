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
    var bedTime: Date?
    var notificationsEnabled: Bool
    var notificationTime: Date?
    var onboardingCompleted: Bool
    
    init(
        id: UUID = UUID(),
        name: String = "",
        bedTime: Date? = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()),
        notificationsEnabled: Bool = false,
        notificationTime: Date? = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()),
        onboardingCompleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.bedTime = bedTime
        self.notificationsEnabled = notificationsEnabled
        self.notificationTime = notificationTime
        self.onboardingCompleted = onboardingCompleted
    }
}
