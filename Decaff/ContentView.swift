//
//  ContentView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/5/24.
//
import SwiftUI
import SwiftData

struct ContentView: View {
    @Binding var isOnboarding: Bool
    
    var body: some View {
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

#Preview {
    ContentView(isOnboarding: .constant(false))
        .modelContainer(for: UserProfile.self)
}
