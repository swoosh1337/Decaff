//
//  Untitled.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/12/24.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Query private var entries: [CaffeineEntry]
    @State private var selectedDate = Date()
    
    var body: some View {
        NavigationView {
            VStack {
                DatePicker(
                    "Selected Date",
                    selection: $selectedDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .padding()
                
                DailyEntriesList(
                    entries: entries.filter {
                        Calendar.current.isDate($0.timestamp, inSameDayAs: selectedDate)
                    }
                )
            }
            .navigationTitle("Calendar")
        }
    }
}

struct DailyEntriesList: View {
    let entries: [CaffeineEntry]
    @Environment(\.modelContext) private var modelContext
    
    var totalCaffeine: Double {
        entries.reduce(0) { $0 + $1.caffeineAmount }
    }
    
    var body: some View {
        List {
            if !entries.isEmpty {
                Section {
                    HStack {
                        Text("Total Caffeine")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(totalCaffeine))mg")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, 8)
                }
            }
            
            Section {
                ForEach(entries, id: \.id) { entry in
                    EntryRow(entry: entry)
                }
                .onDelete(perform: deleteEntries)
            }
        }
        .overlay {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Entries",
                    systemImage: "cup.and.saucer",
                    description: Text("No caffeine intake recorded for this day")
                )
            }
        }
    }
    
    private func deleteEntries(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(entries[index])
        }
        try? modelContext.save()
    }
}

struct EntryRow: View {
    let entry: CaffeineEntry
    
    var beverageIcon: String {
        switch entry.beverageType {
        case .coffee:
            return "cup.and.saucer.fill"
        case .tea:
            return "leaf.fill"
        case .energyDrink:
            return "bolt.fill"
        case .soda:
            return "bubbles.and.sparkles.fill"
        case .custom:
            return "cup.and.saucer"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: beverageIcon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.beverageName)
                    .font(.headline)
                
                HStack {
                    Text(entry.timestamp.formatted(.dateTime.hour().minute()))
                    Text("•")
                    Text("\(Int(entry.volume))ml")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(Int(entry.caffeineAmount))mg")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CalendarView()
        .modelContainer(for: [CaffeineEntry.self])
}
