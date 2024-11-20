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
        Configuration.value(for: "OPENAI_API_KEY") ?? ""
    }
}
