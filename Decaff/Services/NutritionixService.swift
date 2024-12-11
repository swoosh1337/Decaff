import Foundation

enum NutritionixError: Error {
    case invalidResponse
    case networkError(Error)
    case apiError(String)
    case productNotFound
}

struct NutritionixProduct: Decodable, Identifiable {
    let id: String
    let foodName: String
    let brandName: String?
    let servingQuantity: Double
    let servingUnit: String
    let servingWeightGrams: Double?
    let nfCaffeine: Double?
    let photoURL: String?
    let upc: String?
    let fullNutrients: [Nutrient]?
    
    var displayName: String {
        let capitalizedFoodName = foodName.split(separator: " ")
            .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
            .joined(separator: " ")
        
        if let brand = brandName, !brand.isEmpty {
            let capitalizedBrandName = brand.split(separator: " ")
                .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
                .joined(separator: " ")
            return "\(capitalizedBrandName) \(capitalizedFoodName)"
        }
        return capitalizedFoodName
    }
    
    var caffeine: Double? {
        // Check nf_caffeine first
        if let caffeine = nfCaffeine {
            return caffeine
        }
        // If not found, check full_nutrients for attr_id 262 (caffeine)
        return fullNutrients?.first(where: { $0.attrId == 262 })?.value
    }
    
    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case brandName = "brand_name"
        case servingQuantity = "serving_qty"
        case servingUnit = "serving_unit"
        case servingWeightGrams = "serving_weight_grams"
        case nfCaffeine = "nf_caffeine"
        case photoURL = "photo"
        case upc
        case fullNutrients = "full_nutrients"
    }
    
    enum PhotoCodingKeys: String, CodingKey {
        case thumb
        case highres
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        foodName = try container.decode(String.self, forKey: .foodName)
        id = UUID().uuidString
        brandName = try container.decodeIfPresent(String.self, forKey: .brandName)
        servingQuantity = try container.decode(Double.self, forKey: .servingQuantity)
        servingUnit = try container.decode(String.self, forKey: .servingUnit)
        servingWeightGrams = try container.decodeIfPresent(Double.self, forKey: .servingWeightGrams)
        nfCaffeine = try container.decodeIfPresent(Double.self, forKey: .nfCaffeine)
        upc = try container.decodeIfPresent(String.self, forKey: .upc)
        fullNutrients = try container.decodeIfPresent([Nutrient].self, forKey: .fullNutrients)
        
        // Handle nested photo object
        if let photoContainer = try? container.nestedContainer(keyedBy: PhotoCodingKeys.self, forKey: .photoURL) {
            // Try highres first, fallback to thumb
            if let highres = try? photoContainer.decodeIfPresent(String.self, forKey: .highres),
               !highres.isEmpty {
                photoURL = highres
            } else {
                photoURL = try? photoContainer.decodeIfPresent(String.self, forKey: .thumb)
            }
        } else {
            photoURL = nil
        }
    }
}

struct Nutrient: Decodable {
    let attrId: Int
    let value: Double
    
    enum CodingKeys: String, CodingKey {
        case attrId = "attr_id"
        case value
    }
}

struct NutritionixSearchResponse: Decodable {
    let common: [NutritionixProduct]
    let branded: [NutritionixProduct]
}

class NutritionixService {
    static let shared = NutritionixService()
    
    private let baseURL = "https://trackapi.nutritionix.com/v2"
    
    private var headers: [String: String] {
        let appId = API.nutritionixAppId
        let appKey = API.nutritionixAppKey
        
        print("Debug - Using Nutritionix credentials:")
        print("App ID:", appId)
        print("App Key:", String(appKey.prefix(8)) + "...")
        
        return [
            "x-app-id": appId,
            "x-app-key": appKey,
            "x-remote-user-id": "0",
            "Content-Type": "application/json"
        ]
    }
    
    func searchProducts(query: String) async throws -> [NutritionixProduct] {
        guard let url = URL(string: "\(baseURL)/search/instant") else {
            throw NutritionixError.apiError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let queryItems = [URLQueryItem(name: "query", value: query)]
        request.url?.append(queryItems: queryItems)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NutritionixError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                throw NutritionixError.apiError("API returned status code \(httpResponse.statusCode)")
            }
            
            let searchResponse = try JSONDecoder().decode(NutritionixSearchResponse.self, from: data)
            return searchResponse.common + searchResponse.branded
        } catch {
            if let nutritionixError = error as? NutritionixError {
                throw nutritionixError
            }
            throw NutritionixError.networkError(error)
        }
    }
    
    func searchByUPC(_ upc: String) async throws -> NutritionixProduct {
        guard let url = URL(string: "\(baseURL)/search/item") else {
            throw NutritionixError.apiError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let queryItems = [URLQueryItem(name: "upc", value: upc)]
        request.url?.append(queryItems: queryItems)
        
        // Debug logging
        print("🔍 Searching UPC:", upc)
        print("📡 Request URL:", request.url?.absoluteString ?? "nil")
        print("🔑 Headers:", headers)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NutritionixError.invalidResponse
            }
            
            // Debug logging
            print("📥 Response Status Code:", httpResponse.statusCode)
            if let responseString = String(data: data, encoding: .utf8) {
                print("📄 Response Data:", responseString)
            }
            
            if httpResponse.statusCode == 404 {
                throw NutritionixError.productNotFound
            }
            
            if httpResponse.statusCode != 200 {
                throw NutritionixError.apiError("API returned status code \(httpResponse.statusCode)")
            }
            
            struct SearchResponse: Decodable {
                let foods: [NutritionixProduct]
            }
            
            let searchResponse = try JSONDecoder().decode(SearchResponse.self, from: data)
            guard let product = searchResponse.foods.first else {
                throw NutritionixError.productNotFound
            }
            
            // Check if caffeine content is present in the product
            if product.nfCaffeine == nil {
                // If no caffeine content, get detailed nutrient information
                print("⚠️ No caffeine content found in UPC response, fetching detailed nutrients...")
                return try await getNutrientInfo(query: "\(product.brandName ?? "") \(product.foodName)")
            }
            
            // Return the product if it already has caffeine content
            return product
        } catch {
            if let nutritionixError = error as? NutritionixError {
                throw nutritionixError
            }
            throw NutritionixError.networkError(error)
        }
    }
    
    func getNutrientInfo(query: String) async throws -> NutritionixProduct {
        guard let url = URL(string: "\(baseURL)/natural/nutrients") else {
            throw NutritionixError.apiError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["query": query]
        request.httpBody = try? JSONEncoder().encode(body)
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NutritionixError.invalidResponse
            }
            
            if httpResponse.statusCode != 200 {
                throw NutritionixError.apiError("API returned status code \(httpResponse.statusCode)")
            }
            
            struct NutrientsResponse: Decodable {
                let foods: [NutritionixProduct]
            }
            
            let nutrientsResponse = try JSONDecoder().decode(NutrientsResponse.self, from: data)
            guard let product = nutrientsResponse.foods.first else {
                throw NutritionixError.productNotFound
            }
            
            return product
        } catch {
            if let nutritionixError = error as? NutritionixError {
                throw nutritionixError
            }
            throw NutritionixError.networkError(error)
        }
    }
}
