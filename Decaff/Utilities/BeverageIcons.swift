import Foundation

enum BeverageIcons {
    static func iconFor(name: String = "", type: BeverageType) -> String {
        switch type {
        case .coffee:
            return "cup.and.saucer.fill"
        case .tea:
            return "leaf.fill"
        case .energyDrink:
            return "bolt.fill"
        case .soda:
            return "bubbles.and.sparkles.fill"
        case .custom:
            // Use specific icons based on name if available
            let lowercasedName = name.lowercased()
            if lowercasedName.contains("coffee") {
                return "cup.and.saucer.fill"
            } else if lowercasedName.contains("tea") {
                return "leaf.fill"
            } else if lowercasedName.contains("energy") || lowercasedName.contains("monster") || lowercasedName.contains("red bull") {
                return "bolt.fill"
            } else if lowercasedName.contains("cola") || lowercasedName.contains("soda") || lowercasedName.contains("pepsi") {
                return "bubbles.and.sparkles.fill"
            }
            // Default icon for custom beverages
            return "cup.and.saucer.fill"
        }
    }
} 