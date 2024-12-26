import Foundation

class GPTService: ObservableObject {
    static let shared = GPTService()
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private let dateFormatter: DateFormatter
    
    @Published var isAnalyzing = false
    
    private init() {
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateStyle = .medium
        self.dateFormatter.timeStyle = .short
    }
    
    func analyzeData(caffeineEntries: [CaffeineEntry], sleepEntries: [SleepEntry], dailyMetrics: [(date: Date, steps: Int, calories: Double)]) async throws -> WeeklyAnalysis {
        let formattedCaffeineEntries = caffeineEntries.map { entry in
            "Caffeine: \(entry.caffeineAmount)mg at \(dateFormatter.string(from: entry.timestamp))"
        }.joined(separator: "\n")
        
        let formattedSleepEntries = sleepEntries.map { entry in
            "Sleep: \(entry.durationInHours) hours, heart rate: \(entry.heartRate) BPM, from \(dateFormatter.string(from: entry.startDate)) to \(dateFormatter.string(from: entry.endDate))"
        }.joined(separator: "\n")
        
        let formattedDailyMetrics = dailyMetrics.map { metric in
            "Activity on \(dateFormatter.string(from: metric.date)): Steps: \(metric.steps), Calories burned: \(Int(metric.calories)) kcal"
        }.joined(separator: "\n")
        
        await MainActor.run {
            self.isAnalyzing = true
        }
        defer {
            Task { @MainActor in
                self.isAnalyzing = false
            }
        }
        
        let userName = await MainActor.run { UserProfileManager.shared.currentProfile?.name ?? "User" }
        
        let prompt = """
        Analyze the following health data for \(userName):
        
        Caffeine Consumption:
        \(formattedCaffeineEntries)
        
        Sleep Patterns:
        \(formattedSleepEntries)
        
        Daily Activity:
        \(formattedDailyMetrics)
        
        Please provide a personalized analysis for \(userName):
        1. A comprehensive summary analyzing the relationship between:
           - Caffeine consumption patterns
           - Sleep quality and duration
           - Physical activity levels
           - Heart rate during sleep
        2. Three key insights about patterns and correlations
        3. Three specific recommendations for improving:
           - Caffeine consumption timing
           - Sleep quality
           - Overall daily activity
        4. Scores (0-100) for:
           - Sleep quality
           - Caffeine balance
           - Physical activity
           - Overall wellness
        """
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(API.openAIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a friendly and helpful AI assistant analyzing caffeine consumption and sleep patterns.In your respone address the user as your are talking to him/her.Please provide your response in JSON format with the following structure: {\"summary\": \"string\", \"insights\": [\"string\"], \"recommendations\": [\"string\"], \"scores\": {\"sleepQuality\": number, \"caffeineBalance\": number, \"overall\": number}}"],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let gptResponse = try JSONDecoder().decode(GPTResponse.self, from: data)
        
        guard let content = gptResponse.choices.first?.message.content else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response from GPT"])
        }
        
        return try parseGPTResponse(content)
    }
    
    func generateDailySummary(caffeineEntries: [CaffeineEntry]) async throws -> String {
        let userName = await MainActor.run { UserProfileManager.shared.currentProfile?.name ?? "User" }
        let totalCaffeine = caffeineEntries.reduce(0.0) { $0 + $1.caffeineAmount }
        let lastIntake = caffeineEntries.max(by: { $0.timestamp < $1.timestamp })
        
        let timeFormatter = Date.FormatStyle().hour().minute()
        let lastIntakeTime = lastIntake?.timestamp.formatted(timeFormatter) ?? "None"
        
        let prompt = """
        Generate a brief, friendly daily caffeine summary for \(userName).
        
        Today's data:
        - Total caffeine: \(Int(totalCaffeine))mg
        - Number of drinks: \(caffeineEntries.count)
        - Last intake: \(lastIntakeTime)
        
        Please provide a concise, personalized summary (max 150 characters) that includes:
        1. Total caffeine intake
        2. Comparison to daily recommended limit (400mg)
        3. A friendly tip or observation
        
        Make it conversational and friendly.
        """
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(API.openAIKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let requestBody: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are a friendly assistant providing brief, personalized caffeine consumption summaries."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 100
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(GPTResponse.self, from: data)
        
        return response.choices.first?.message.content ?? "Unable to generate summary"
    }
    
    private func parseGPTResponse(_ content: String) throws -> WeeklyAnalysis {
        guard let jsonData = content.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let summary = json["summary"] as? String,
              let insights = json["insights"] as? [String],
              let recommendations = json["recommendations"] as? [String],
              let scores = json["scores"] as? [String: Int] else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid GPT response format"])
        }
        
        return WeeklyAnalysis(
            summary: summary,
            insights: insights,
            recommendations: recommendations,
            sleepQualityScore: scores["sleepQuality"] ?? 0,
            caffeineBalanceScore: scores["caffeineBalance"] ?? 0,
            physicalActivityScore: scores["physicalActivity"] ?? 0,
            overallScore: scores["overall"] ?? 0
        )
    }
    
    // For testing and preview purposes
    func getMockAnalysis() -> WeeklyAnalysis {
        return WeeklyAnalysis.mockData
    }
}
