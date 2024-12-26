//
//  SettingsView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/12/24.
//

import SwiftUI
import SwiftData
import UserNotifications
import BackgroundTasks

struct SettingsView: View {
    @Query private var userProfile: [UserProfile]
    @Query(sort: \CaffeineEntry.timestamp) private var caffeineEntries: [CaffeineEntry]
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
        // Request notification permission if needed
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Error requesting notification permission: \(error)")
            }
        }
        
        Task {
            do {
                // Get today's entries
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: Date())
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let todayEntries = caffeineEntries.filter { entry in
                    entry.timestamp >= startOfDay && entry.timestamp < endOfDay
                }
                
                // Generate summary using GPT
                let summary = try await GPTService.shared.generateDailySummary(caffeineEntries: todayEntries)
                
                // Create notification content
                let content = UNMutableNotificationContent()
                content.title = "Daily Caffeine Summary"
                content.body = summary
                
                // Schedule notification
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
                print("Daily summary notification scheduled for \(notificationTime)")
                
                // Schedule the background refresh
                let taskRequest = BGAppRefreshTaskRequest(identifier: "com.decaff.dailySummary")
                taskRequest.earliestBeginDate = calendar.date(byAdding: .day, value: 1, to: Date())
                try BGTaskScheduler.shared.submit(taskRequest)
                
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
