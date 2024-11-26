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
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    
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
            ZStack {
                if onboardingCompleted {
                    ContentView(isOnboarding: Binding(
                        get: { !onboardingCompleted },
                        set: { onboardingCompleted = !$0 }
                    ))
                    .onAppear {
                        print("DEBUG: Showing ContentView")
                    }
                } else {
                    OnboardingView(isOnboarding: Binding(
                        get: { !onboardingCompleted },
                        set: { onboardingCompleted = !$0 }
                    ))
                    .onAppear {
                        print("DEBUG: Showing OnboardingView")
                    }
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
