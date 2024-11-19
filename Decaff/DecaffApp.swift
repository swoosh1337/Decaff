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
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
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
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
