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
    @State private var showingSplash = true
    @State private var showingOnboarding = false
    
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

    init() {
        // Set the window background color to match launch screen
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            windowScene.windows.first?.backgroundColor = UIColor(named: "F5E6D3")
        }
    }

    var body: some Scene {
        WindowGroup {
            if showingSplash {
                SplashScreen()
                    .onAppear {
                        // Show splash for 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showingSplash = false
                            }
                        }
                    }
            } else {
                if let profile = profileManager.currentProfile,
                   profile.onboardingCompleted {
                    ContentView(isOnboarding: $showingOnboarding)
                        .modelContainer(sharedModelContainer)
                } else {
                    OnboardingView(isOnboarding: $showingOnboarding)
                        .modelContainer(sharedModelContainer)
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
}
