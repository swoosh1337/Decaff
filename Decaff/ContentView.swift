//
//  ContentView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/5/24.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    var body: some View {
        Group {
            if !hasSeenOnboarding {
                OnboardingView()
            } else {
                // Main app content
                TabView {
                    MainView()
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                    
                    CalendarView()
                        .tabItem {
                            Label("Calendar", systemImage: "calendar")
                        }
                    
                    AnalysisView()
                        .tabItem {
                            Label("Analysis", systemImage: "chart.bar.fill")
                        }
                    
                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gear")
                        }
                }
            }
        }
    }
}

