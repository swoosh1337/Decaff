//
//  DecaffApp.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/5/24.
//

import SwiftUI
import SwiftData

@main
struct DecaffApp: App {
    @StateObject private var profileManager = UserProfileManager.shared
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            UserProfile.self,
            CaffeineEntry.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            Group {
                if let profile = profileManager.currentProfile {
                    if profile.onboardingCompleted {
                        ContentView()
                    } else {
                        OnboardingView()
                    }
                } else {
                    OnboardingView()
                }
            }
            .modelContainer(sharedModelContainer)
            .onAppear {
                profileManager.setModelContainer(sharedModelContainer)
                if profileManager.currentProfile == nil {
                    profileManager.createInitialProfile()
                }
            }
        }
    }
}

// For testing and development
extension DecaffApp {
    static func resetToOnboarding() {
        UserProfileManager.shared.resetProfile()
    }
    
    static func togglePremium() {
        UserProfileManager.shared.togglePremium()
    }
}
