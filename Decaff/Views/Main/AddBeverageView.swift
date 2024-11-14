//
//  AddBeverageView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/12/24.
//

import SwiftUI
import SwiftData

struct AddBeverageView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var selectedBeverage = PresetBeverage.coffee
    @State private var customBeverageName = ""
    @State private var volume: Double = 250
    @State private var isCustomBeverage = false
    @State private var customCaffeineAmount: Double = 0
    @State private var searchText = ""
    
    private var filteredBeverages: [CSVBeverage] {
        CSVParser.shared.searchBeverages(searchText)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Search Beverages")) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("Search drinks...", text: $searchText)
                    }
                    
                    if !searchText.isEmpty {
                        if filteredBeverages.isEmpty {
                            HStack {
                                Image(systemName: "exclamationmark.circle")
                                    .foregroundColor(.secondary)
                                Text("No matches found")
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            ForEach(filteredBeverages) { beverage in
                                Button(action: { selectCSVBeverage(beverage) }) {
                                    HStack {
                                        Image(systemName: beverageIcon(for: beverage.type))
                                            .foregroundColor(.accentColor)
                                            .frame(width: 30)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(beverage.name)
                                                .foregroundColor(.primary)
                                            HStack {
                                                Text("\(beverage.caffeineContent) mg")
                                                    .foregroundColor(.secondary)
                                                Text("•")
                                                    .foregroundColor(.secondary)
                                                Text("\(Int(round(beverage.servingSizeML))) ml")
                                                    .foregroundColor(.secondary)
                                            }
                                            .font(.caption)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                
                if !isCustomBeverage && searchText.isEmpty {
                    Section(header: Text("Common Drinks")) {
                        ForEach(PresetBeverage.allCases) { beverage in
                            Button(action: { selectedBeverage = beverage }) {
                                HStack {
                                    Image(systemName: beverageIcon(for: beverage.type))
                                        .foregroundColor(.accentColor)
                                        .frame(width: 30)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(beverage.name)
                                            .foregroundColor(.primary)
                                        HStack {
                                            Text("\(Int(beverage.caffeineAmount)) mg")
                                                .foregroundColor(.secondary)
                                            Text("•")
                                                .foregroundColor(.secondary)
                                            Text("250 ml")
                                                .foregroundColor(.secondary)
                                        }
                                        .font(.caption)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedBeverage == beverage {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                if isCustomBeverage {
                    Section(header: Text("Custom Beverage")) {
                        HStack {
                            Image(systemName: "cup.and.saucer")
                                .foregroundColor(.accentColor)
                                .frame(width: 30)
                            TextField("Beverage Name", text: $customBeverageName)
                        }
                        
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.accentColor)
                                .frame(width: 30)
                            Text("Caffeine")
                            Spacer()
                            TextField("mg", value: $customCaffeineAmount, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                            Text("mg")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("Volume")) {
                    VStack {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.accentColor)
                                .frame(width: 30)
                            Text("Amount")
                            Spacer()
                            Text("\(Int(round(volume))) ml")
                                .foregroundColor(.secondary)
                        }
                        
                        Slider(value: $volume, in: 50...500, step: 50)
                    }
                }
                
                if searchText.isEmpty {
                    Section {
                        Toggle("Custom Beverage", isOn: $isCustomBeverage)
                    }
                }
            }
            .navigationTitle("Add Beverage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addEntry() }
                        .disabled(isCustomBeverage && customBeverageName.isEmpty)
                }
            }
        }
    }
    
    private func beverageIcon(for type: BeverageType) -> String {
        switch type {
        case .coffee:
            return "cup.and.saucer.fill"
        case .tea:
            return "leaf.fill"
        case .energyDrink:
            return "bolt.fill"
        case .soda:
            return "bubbles.and.sparkles"
        case .custom:
            return "cup.and.saucer"
        }
    }
    
    private func selectCSVBeverage(_ beverage: CSVBeverage) {
        customBeverageName = beverage.name
        customCaffeineAmount = Double(beverage.caffeineContent)
        volume = beverage.servingSizeML
        isCustomBeverage = true
        searchText = ""
    }
    
    private func addEntry() {
        let entry = CaffeineEntry(
            caffeineAmount: isCustomBeverage ? customCaffeineAmount : selectedBeverage.caffeineAmount,
            beverageName: isCustomBeverage ? customBeverageName : selectedBeverage.name,
            beverageType: isCustomBeverage ? .custom : selectedBeverage.type,
            customBeverage: isCustomBeverage,
            volume: volume
        )
        
        modelContext.insert(entry)
        dismiss()
    }
}

enum PresetBeverage: String, CaseIterable, Identifiable {
    case coffee
    case espresso
    case tea
    case energyDrink
    case soda
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .coffee: return "Coffee"
        case .espresso: return "Espresso"
        case .tea: return "Black Tea"
        case .energyDrink: return "Energy Drink"
        case .soda: return "Cola"
        }
    }
    
    var caffeineAmount: Double {
        switch self {
        case .coffee: return 95
        case .espresso: return 63
        case .tea: return 47
        case .energyDrink: return 80
        case .soda: return 40
        }
    }
    
    var type: BeverageType {
        switch self {
        case .coffee, .espresso: return .coffee
        case .tea: return .tea
        case .energyDrink: return .energyDrink
        case .soda: return .soda
        }
    }
}

#Preview {
    AddBeverageView()
}
