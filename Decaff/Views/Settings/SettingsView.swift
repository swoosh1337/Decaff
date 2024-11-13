//
//  SettingsView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/12/24.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Query private var userProfile: [UserProfile]
    @State private var notificationsEnabled = false
    @State private var notificationTime = Date()
    @State private var healthKitEnabled = false
    
    var body: some View {
        NavigationView {
            Form {
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
                
                Section(header: Text("Health")) {
                    Toggle("Apple Health Integration", isOn: $healthKitEnabled)
                }
                
                Section(header: Text("Account")) {
                    if let profile = userProfile.first {
                        if profile.isPremium {
                            Label("Premium Account", systemImage: "checkmark.seal.fill")
                                .foregroundColor(.green)
                        } else {
                            NavigationLink("Upgrade to Premium") {
                                PremiumUpgradeView(showingUpgrade: .constant(true))
                            }
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    Text("Version 1.0.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserProfile.self])
}
