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
    @State private var showingSplash = true
    
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
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation {
                                showingSplash = false
                            }
                        }
                    }
            } else {
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
