import Foundation

enum Configuration {
    enum Error: Swift.Error {
        case missingKey, invalidValue
    }

    static func value<T>(for key: String) throws -> T where T: LosslessStringConvertible {
        guard let object = Bundle.main.object(forInfoDictionaryKey: key) else {
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
    
    static func value(for key: String) -> String? {
        Bundle.main.object(forInfoDictionaryKey: key) as? String
    }
}

enum API {
    static var nutritionixAppId: String {
        do {
            return try Configuration.value(for: "NUTRITIONIX_APP_ID")
        } catch {
            fatalError("NUTRITIONIX_APP_ID not set in plist")
        }
    }
    
    static var nutritionixApiKey: String {
        do {
            return try Configuration.value(for: "NUTRITIONIX_API_KEY")
        } catch {
            fatalError("NUTRITIONIX_API_KEY not set in plist")
        }
    }
    
    static var openAIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String,
              !key.isEmpty else {
            print("Error: OPENAI_API_KEY is missing or empty in Info.plist")
            print("Bundle path:", Bundle.main.bundlePath)
            print("Info Dictionary:", Bundle.main.infoDictionary ?? [:])
            print("Available keys:", Bundle.main.infoDictionary?.keys.joined(separator: ", ") ?? "")
            fatalError("OPENAI_API_KEY not set in plist")
        }
        return key
    }
}
