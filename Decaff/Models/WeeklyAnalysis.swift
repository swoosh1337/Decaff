import Foundation

struct WeeklyAnalysis {
    let summary: String
    let insights: [String]
    let recommendations: [String]
    let sleepQualityScore: Int
    let caffeineBalanceScore: Int
    let physicalActivityScore: Int
    let overallScore: Int
    
    static let empty = WeeklyAnalysis(
        summary: "",
        insights: [],
        recommendations: [],
        sleepQualityScore: 0,
        caffeineBalanceScore: 0,
        physicalActivityScore: 0,
        overallScore: 0
    )
}

struct GPTResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}

// Mock data for testing
extension WeeklyAnalysis {
    static var mockData: WeeklyAnalysis {
        WeeklyAnalysis(
            summary: "Your caffeine consumption has been moderate this week, with good sleep patterns.",
            insights: [
                "Average daily caffeine intake: 200mg",
                "Sleep quality improved on days with less caffeine",
                "Morning coffee routine is consistent"
            ],
            recommendations: [
                "Consider reducing afternoon caffeine",
                "Maintain consistent sleep schedule",
                "Stay hydrated throughout the day"
            ],
            sleepQualityScore: 85,
            caffeineBalanceScore: 75,
            physicalActivityScore: 70,
            overallScore: 80
        )
    }
}
