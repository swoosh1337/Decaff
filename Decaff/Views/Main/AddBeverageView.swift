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
    
    var body: some View {
        NavigationView {
            Form {
                if !isCustomBeverage {
                    Picker("Beverage Type", selection: $selectedBeverage) {
                        ForEach(PresetBeverage.allCases) { beverage in
                            Text(beverage.name).tag(beverage)
                        }
                    }
                }
                
                if isCustomBeverage {
                    TextField("Beverage Name", text: $customBeverageName)
                    
                    HStack {
                        Text("Caffeine Amount")
                        Spacer()
                        TextField("mg", value: $customCaffeineAmount, format: .number)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        Text("mg")
                    }
                }
                
                HStack {
                    Text("Volume")
                    Spacer()
                    TextField("ml", value: $volume, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                    Text("ml")
                }
                
                Toggle("Custom Beverage", isOn: $isCustomBeverage)
            }
            .navigationTitle("Add Beverage")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { addEntry() }
                }
            }
        }
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
