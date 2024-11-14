import Foundation

struct CSVBeverage: Identifiable {
    let id = UUID()
    let name: String
    let caffeineContent: Int
    let servingSize: String
    let servingSizeML: Double
    let type: BeverageType
}

class CSVParser {
    static let shared = CSVParser()
    private var beverages: [CSVBeverage] = []
    
    private init() {
        loadBeverages()
    }
    
    func loadBeverages() {
        guard let path = Bundle.main.path(forResource: "caffeine", ofType: "csv") else {
            print("Failed to find caffeine.csv in bundle")
            return
        }
        
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let rows = content.components(separatedBy: .newlines)
            
            // Skip header row
            for row in rows.dropFirst() where !row.isEmpty {
                let columns = row.components(separatedBy: ",")
                guard columns.count >= 4 else { continue }
                
                // Clean and parse data
                let name = columns[0].trimmingCharacters(in: .whitespacesAndNewlines)
                let servingSize = columns[1].trimmingCharacters(in: .whitespacesAndNewlines)
                let caffeineContent = Int(columns[2]) ?? 0
                let typeString = columns[3].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                // Parse serving size to ML
                let servingSizeML = parseServingSize(servingSize)
                
                // Determine beverage type
                let type = determineBeverageType(typeString)
                
                let beverage = CSVBeverage(
                    name: name,
                    caffeineContent: caffeineContent,
                    servingSize: servingSize,
                    servingSizeML: servingSizeML,
                    type: type
                )
                beverages.append(beverage)
            }
            print("Loaded \(beverages.count) beverages from CSV")
        } catch {
            print("Failed to load CSV: \(error)")
        }
    }
    
    private func parseServingSize(_ size: String) -> Double {
        // Remove all whitespace and convert to lowercase
        let cleanSize = size.lowercased().replacingOccurrences(of: " ", with: "")
        
        // Extract number and unit
        let numbers = cleanSize.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        guard let value = Double(numbers) else { return 0 }
        
        // Convert to ML based on unit
        if cleanSize.contains("oz") {
            return value * 29.5735 // 1 oz = 29.5735 ml
        } else if cleanSize.contains("ml") {
            return value
        } else if cleanSize.contains("cup") {
            return value * 236.588 // 1 cup = 236.588 ml
        }
        
        return value // default to ml if no unit specified
    }
    
    private func determineBeverageType(_ type: String) -> BeverageType {
        if type.contains("coffee") {
            return .coffee
        } else if type.contains("tea") {
            return .tea
        } else if type.contains("energy") {
            return .energyDrink
        } else if type.contains("soda") {
            return .soda
        }
        return .custom
    }
    
    func searchBeverages(_ query: String) -> [CSVBeverage] {
        guard !query.isEmpty else { return [] }
        return beverages.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    func getAllBeverages() -> [CSVBeverage] {
        return beverages
    }
} 