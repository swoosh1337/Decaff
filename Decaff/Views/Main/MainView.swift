//
//  MainView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/12/24.
//
import SwiftUI
import SwiftData

struct MainView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [CaffeineEntry]
    @State private var showingAddEntry = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    CaffeineStatsCard(entries: entries)
                    CaffeineMetabolismGraph(entries: entries)
                    
                    Button(action: { showingAddEntry = true }) {
                        Label("Add Beverage", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                    
                    TodayEntriesList(entries: entries)
                }
                .padding()
            }
            .navigationTitle("Today")
            .sheet(isPresented: $showingAddEntry) {
                AddBeverageView()
            }
        }
    }
}

struct CaffeineStatsCard: View {
    let entries: [CaffeineEntry]
    
    var totalCaffeine: Double {
        entries.filter { Calendar.current.isDateInToday($0.timestamp) }
            .reduce(0) { $0 + $1.caffeineAmount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today's Caffeine")
                .font(.headline)
            
            Text("\(Int(totalCaffeine)) mg")
                .font(.system(size: 36, weight: .bold))
            
            ProgressView(value: totalCaffeine, total: 400)
                .tint(totalCaffeine > 400 ? .red : .accentColor)
            
            Text(totalCaffeine > 400 ? "Above recommended daily limit" : "Within safe limits")
                .font(.caption)
                .foregroundColor(totalCaffeine > 400 ? .red : .secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct TodayEntriesList: View {
    let entries: [CaffeineEntry]
    
    private var todayEntries: [CaffeineEntry] {
        entries.filter { Calendar.current.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp > $1.timestamp }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Beverages")
                .font(.headline)
                .padding(.horizontal)
            
            if todayEntries.isEmpty {
                Text("No beverages logged today")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(todayEntries) { entry in
                    EntryRow(entry: entry)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

//struct EntryRow: View {
//    let entry: CaffeineEntry
//    
//    var body: some View {
//        HStack {
//            VStack(alignment: .leading) {
//                Text(entry.beverageName)
//                    .font(.headline)
//                Text(entry.timestamp.formatted(date: .omitted, time: .shortened))
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//            
//            Spacer()
//            
//            VStack(alignment: .trailing) {
//                Text("\(Int(entry.caffeineAmount)) mg")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                Text("\(Int(entry.volume)) ml")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//            }
//        }
//        .padding(.vertical, 8)
//    }
//}

#Preview {
    MainView()
        .modelContainer(for: [CaffeineEntry.self])
}
