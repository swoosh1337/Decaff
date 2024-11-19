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
    @Query(sort: \CaffeineEntry.timestamp, order: .reverse) private var entries: [CaffeineEntry]
    @State private var showingAddEntry = false
    @State private var showingBarcodeScanner = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Quick Add Buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 15) {
                            QuickAddButton(title: "Coffee", icon: "cup.and.saucer.fill") {
                                quickAdd(.coffee)
                            }
                            QuickAddButton(title: "Tea", icon: "leaf.fill") {
                                quickAdd(.tea)
                            }
                            QuickAddButton(title: "Energy Drink", icon: "bolt.fill") {
                                quickAdd(.energyDrink)
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    CaffeineStatsCard(entries: todayEntries)
                    CaffeineMetabolismGraph(entries: todayEntries)
                    
                    // Add Beverage Buttons
                    HStack {
                        Button(action: { showingAddEntry = true }) {
                            Label("Add Beverage", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        }
                        
                        Button(action: { showingBarcodeScanner = true }) {
                            Image(systemName: "barcode.viewfinder")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(width: 50)
                                .padding()
                                .background(Color.accentColor)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    TodayEntriesList(entries: todayEntries)
                }
                .padding()
            }
            .navigationTitle("Today")
            .sheet(isPresented: $showingAddEntry) {
                AddBeverageView()
            }
            .sheet(isPresented: $showingBarcodeScanner) {
                BarcodeScannerView()
            }
        }
    }
    
    private var todayEntries: [CaffeineEntry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return entries.filter { calendar.startOfDay(for: $0.timestamp) == today }
    }
    
    private func quickAdd(_ beverageType: PresetBeverage) {
        let entry = CaffeineEntry(
            caffeineAmount: beverageType.caffeineAmount,
            beverageName: beverageType.name,
            beverageType: beverageType.type,
            volume: 250
        )
        modelContext.insert(entry)
        do {
            try modelContext.save()
            print("✅ Quick added: \(beverageType.name) with \(beverageType.caffeineAmount)mg caffeine")
        } catch {
            print("❌ Failed to save Quick Add entry: \(error.localizedDescription)")
        }
    }
}

struct QuickAddButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: icon)
                    .font(.system(size: 24))
                Text(title)
                    .font(.caption)
            }
            .frame(width: 80, height: 80)
            .background(Color.accentColor.opacity(0.1))
            .cornerRadius(15)
        }
        .foregroundColor(.accentColor)
    }
}

struct CaffeineStatsCard: View {
    let entries: [CaffeineEntry]
    
    var totalCaffeine: Double {
        entries.reduce(0) { $0 + $1.caffeineAmount }
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
    @Environment(\.modelContext) private var modelContext
    let entries: [CaffeineEntry]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Beverages")
                .font(.headline)
                .padding(.horizontal)
            
            if entries.isEmpty {
                Text("No beverages logged today")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                List {
                    ForEach(entries) { entry in
                        EntryRow(entry: entry)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteEntry(entry)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .frame(minHeight: CGFloat(entries.count * 60))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func deleteEntry(_ entry: CaffeineEntry) {
        withAnimation {
            modelContext.delete(entry)
            try? modelContext.save()
        }
    }
}

#Preview {
    MainView()
        .modelContainer(for: [CaffeineEntry.self])
}
