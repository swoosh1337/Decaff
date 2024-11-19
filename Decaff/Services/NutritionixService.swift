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
    
    enum CodingKeys: String, CodingKey {
        case foodName = "food_name"
        case brandName = "brand_name"
        case servingQuantity = "serving_qty"
        case servingUnit = "serving_unit"
        case servingWeightGrams = "serving_weight_grams"
        case nfCaffeine = "nf_caffeine"
        case photoURL = "photo"
        case full = "full"
        case upc
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        foodName = try container.decode(String.self, forKey: .foodName)
        id = UUID().uuidString  // Generate a unique ID since we don't need to encode it back
        brandName = try container.decodeIfPresent(String.self, forKey: .brandName)
        servingQuantity = try container.decode(Double.self, forKey: .servingQuantity)
        servingUnit = try container.decode(String.self, forKey: .servingUnit)
        servingWeightGrams = try container.decodeIfPresent(Double.self, forKey: .servingWeightGrams)
        nfCaffeine = try container.decodeIfPresent(Double.self, forKey: .nfCaffeine)
        upc = try container.decodeIfPresent(String.self, forKey: .upc)
        
        if let photoContainer = try? container.nestedContainer(keyedBy: CodingKeys.self, forKey: .photoURL) {
            photoURL = try photoContainer.decodeIfPresent(String.self, forKey: .full)
        } else {
            photoURL = nil
        }
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
        [
            "x-app-id": API.nutritionixAppId,
            "x-app-key": API.nutritionixApiKey,
            "x-remote-user-id": "0"  // 0 for development
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
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NutritionixError.invalidResponse
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
            
            // Get detailed nutrient information
            return try await getNutrientInfo(query: "\(product.brandName ?? "") \(product.foodName)")
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
