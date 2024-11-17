import Foundation

struct OpenFoodFactsResponse: Codable {
    let status: Int
    let product: OpenFoodFactsProduct?
    let statusVerbose: String
    
    enum CodingKeys: String, CodingKey {
        case status
        case product
        case statusVerbose = "status_verbose"
    }
}

struct OpenFoodFactsProduct: Codable, Identifiable {
    let id: String // Will be set to barcode
    let productName: String?
    let brands: String?
    let imageUrl: String?
    let nutriscoreGrade: String?
    let ingredients: String?
    let quantity: String?
    let nutritionGrades: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "code"
        case productName = "product_name"
        case brands
        case imageUrl = "image_url"
        case nutriscoreGrade = "nutriscore_grade"
        case ingredients = "ingredients_text"
        case quantity
        case nutritionGrades = "nutrition_grades"
    }
}
