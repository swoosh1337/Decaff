import Foundation

enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
            print("Missing key in Info.plist: \(key)")
            print("Available keys:", Bundle.main.infoDictionary?.keys.joined(separator: ", ") ?? "")
            throw Error.missingKey
        }

        switch object {
        case let value as T:
            return value
        case let string as String:
            guard let value = T(string) else { fallthrough }
            return value
        default:
            throw Error.invalidValue
        }
    }
    
    static func getConfigValue(for key: String) -> String? {
        // First try Info.plist
        if let value = Bundle.main.object(forInfoDictionaryKey: key) as? String,
           !value.isEmpty,
           !value.hasPrefix("$(") { // Make sure we're not getting the variable placeholder
            return value
        }
        
        // Then try reading from Config.xcconfig
        if let configPath = Bundle.main.path(forResource: "Config", ofType: "xcconfig"),
           let contents = try? String(contentsOfFile: configPath, encoding: .utf8) {
            let lines = contents.components(separatedBy: .newlines)
            for line in lines {
                let parts = line.components(separatedBy: "=").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count == 2 && parts[0] == key {
                    return parts[1]
                }
            }
        }
        
        return nil
    }
}

enum API {
    static var openAIKey: String {
        if let key = Configuration.getConfigValue(for: "OPENAI_API_KEY"),
           !key.isEmpty {
            return key
        }
        printDebugInfo(for: "OPENAI_API_KEY")
        fatalError("OPENAI_API_KEY not found")
    }
    
    static var nutritionixAppId: String {
        if let id = Configuration.getConfigValue(for: "NUTRITIONIX_APP_ID"),
           !id.isEmpty {
            print("Using Nutritionix App ID:", id)  // Debug print
            return id
        }
        printDebugInfo(for: "NUTRITIONIX_APP_ID")
        fatalError("NUTRITIONIX_APP_ID not found")
    }
    
    static var nutritionixAppKey: String {
        if let key = Configuration.getConfigValue(for: "NUTRITIONIX_APP_KEY"),
           !key.isEmpty {
            print("Using Nutritionix App Key:", String(key.prefix(8)) + "...")  // Debug print (only show first 8 chars)
            return key
        }
        printDebugInfo(for: "NUTRITIONIX_APP_KEY")
        fatalError("NUTRITIONIX_APP_KEY not found")
    }
    
    private static func printDebugInfo(for key: String) {
        print("🔑 Checking for key:", key)
        print("📦 Bundle path:", Bundle.main.bundlePath)
        print("📝 Available Info.plist keys:", Bundle.main.infoDictionary?.keys.joined(separator: ", ") ?? "")
        print("🔍 Current value for \(key):", Bundle.main.infoDictionary?[key] ?? "nil")
        
        if let configPath = Bundle.main.path(forResource: "Config", ofType: "xcconfig"),
           let contents = try? String(contentsOfFile: configPath, encoding: .utf8) {
            print("📄 Config.xcconfig contents:")
            print(contents)
        }
    }
}
