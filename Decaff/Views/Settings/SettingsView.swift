//
//  SettingsView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/12/24.
//

import SwiftUI
import SwiftData
import UserNotifications

struct SettingsView: View {
    @Query private var userProfile: [UserProfile]
    @Environment(\.modelContext) private var modelContext
    
    // State for binding to profile values
    @State private var notificationsEnabled = false
    @State private var notificationTime = Date()
    @State private var bedTime = Date()
    
    private var profile: UserProfile? {
        userProfile.first
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Sleep Schedule")) {
                    DatePicker(
                        "Bedtime",
                        selection: $bedTime,
                        displayedComponents: [.hourAndMinute]
                    )
                }
                
                Section(header: Text("Notifications")) {
                    Toggle("Daily Summary", isOn: $notificationsEnabled)
                    
                    if notificationsEnabled {
                        DatePicker(
                            "Summary Time",
                            selection: $notificationTime,
                            displayedComponents: [.hourAndMinute]
                        )
                    }
                }
                
                Section(header: Text("About")) {
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    Text("Version 1.0.0")
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadProfileSettings()
            }
            .onChange(of: bedTime) { saveProfileSettings() }
            .onChange(of: notificationsEnabled) { saveProfileSettings() }
            .onChange(of: notificationTime) { saveProfileSettings() }
        }
    }
    
    private func loadProfileSettings() {
        guard let profile = profile else { return }
        bedTime = profile.bedTime!
        notificationsEnabled = profile.notificationsEnabled
        notificationTime = profile.notificationTime!
    }
    
    private func saveProfileSettings() {
        if let profile = profile {
            profile.bedTime = bedTime
            profile.notificationsEnabled = notificationsEnabled
            profile.notificationTime = notificationTime
            try? modelContext.save()
            
            if notificationsEnabled {
                scheduleNotification()
            } else {
                cancelNotification()
            }
        }
    }
    
    private func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Daily Caffeine Summary"
        
        // Generate summary using GPT
        Task {
            do {
                let summary = try await generateDailySummary()
                content.body = summary
                
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: notificationTime)
                
                let trigger = UNCalendarNotificationTrigger(
                    dateMatching: components,
                    repeats: true
                )
                
                let request = UNNotificationRequest(
                    identifier: "dailySummary",
                    content: content,
                    trigger: trigger
                )
                
                try await UNUserNotificationCenter.current().add(request)
            } catch {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailySummary"])
    }
    
    private func generateDailySummary() async throws -> String {
        // Use GPTService to generate a concise daily summary
        // This should be implemented in GPTService
        return "Your daily caffeine summary will appear here"
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserProfile.self])
}
