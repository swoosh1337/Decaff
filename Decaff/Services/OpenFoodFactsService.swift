import Foundation
import Combine

class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()
    private let baseURL = "https://world.openfoodfacts.org/api/v0/product"
    
    private init() {}
    
    func fetchProduct(barcode: String) -> AnyPublisher<OpenFoodFactsProduct, Error> {
        let url = URL(string: "\(baseURL)/\(barcode).json")!
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: OpenFoodFactsResponse.self, decoder: JSONDecoder())
            .tryMap { response in
                guard response.status == 1, let product = response.product else {
                    throw NSError(domain: "OpenFoodFacts",
                                code: 404,
                                userInfo: [NSLocalizedDescriptionKey: "Product not found"])
                }
                return product
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
}
