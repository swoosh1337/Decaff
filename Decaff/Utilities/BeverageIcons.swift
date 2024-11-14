import Foundation

enum BeverageIcons {
    static func iconFor(name: String, type: BeverageType) -> String {
        // Check for specific brands/drinks first
        let lowercaseName = name.lowercased()
        
        // Starbucks drinks
        if lowercaseName.contains("starbucks") {
            if lowercaseName.contains("frappuccino") {
                return "cup.and.saucer.fill"  // Could be custom SF Symbol for frappuccino
            }
            return "star.circle.fill"  // Starbucks general
        }
        
        // Energy Drinks
        if lowercaseName.contains("red bull") {
            return "bolt.shield.fill"
        }
        if lowercaseName.contains("monster") {
            return "bolt.circle.fill"
        }
        if lowercaseName.contains("5-hour") || lowercaseName.contains("5 hour") {
            return "clock.badge.checkmark.fill"
        }
        
        // Coffee varieties
        if lowercaseName.contains("espresso") {
            return "smallcup.fill"  // Custom name for espresso icon
        }
        if lowercaseName.contains("latte") {
            return "cup.and.saucer.fill"
        }
        if lowercaseName.contains("cappuccino") {
            return "cup.and.saucer.fill"
        }
        
        // Tea varieties
        if lowercaseName.contains("green tea") {
            return "leaf.circle.fill"
        }
        if lowercaseName.contains("black tea") {
            return "leaf.fill"
        }
        if lowercaseName.contains("matcha") {
            return "leaf.arrow.circlepath"
        }
        
        // Sodas
        if lowercaseName.contains("coca") || lowercaseName.contains("coke") {
            return "bubbles.and.sparkles.fill"
        }
        if lowercaseName.contains("pepsi") {
            return "circle.grid.cross.fill"
        }
        if lowercaseName.contains("dr pepper") {
            return "cross.circle.fill"
        }
        
        // Default icons based on type
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
} 