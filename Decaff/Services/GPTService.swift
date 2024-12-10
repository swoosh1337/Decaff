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
    
    func createAnalysisPrompt(caffeineEntries: [CaffeineEntry], sleepEntries: [SleepEntry]) -> String {
        let formattedCaffeineEntries = caffeineEntries.map { entry in
            "Caffeine: \(entry.caffeineAmount)mg at \(dateFormatter.string(from: entry.timestamp))"
        }.joined(separator: "\n")
        
        let formattedSleepEntries = sleepEntries.map { entry in
            "Sleep: \(entry.durationInHours) hours, quality: \(entry.value)/100, from \(dateFormatter.string(from: entry.startDate)) to \(dateFormatter.string(from: entry.endDate))"
        }.joined(separator: "\n")
        
        return """
        Analyze the following caffeine consumption and sleep data:
        
        \(formattedCaffeineEntries)
        
        \(formattedSleepEntries)
        
        Please provide:
        1. A brief summary of the week
        2. Three key insights about patterns and correlations
        3. Three specific recommendations for improvement
        4. Scores (0-100) for:
           - Sleep quality
           - Caffeine balance
           - Overall wellness
        
        Format the response as JSON with the following structure:
        {
            "summary": "...",
            "insights": ["...", "...", "..."],
            "recommendations": ["...", "...", "..."],
            "scores": {
                "sleepQuality": X,
                "caffeineBalance": Y,
                "overall": Z
            }
        }
        """
    }
    
    func analyzeData(caffeineEntries: [CaffeineEntry], sleepEntries: [SleepEntry]) async throws -> WeeklyAnalysis {
        await MainActor.run {
            self.isAnalyzing = true
        }
        defer {
            Task { @MainActor in
                self.isAnalyzing = false
            }
        }
        
        // Debug: Print API key (remove in production)
        print("API Key being used:", API.openAIKey)
        
        let prompt = createAnalysisPrompt(caffeineEntries: caffeineEntries, sleepEntries: sleepEntries)
        
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
        
        // Debug: Print request body (remove in production)
        if let requestBodyString = String(data: request.httpBody!, encoding: .utf8) {
            print("Request Body:", requestBodyString)
        }
        
        let (data, httpResponse) = try await URLSession.shared.data(for: request)
        
        // Debug: Print response (remove in production)
        if let responseString = String(data: data, encoding: .utf8) {
            print("Response:", responseString)
        }
        
        if let httpResponse = httpResponse as? HTTPURLResponse {
            print("HTTP Status Code:", httpResponse.statusCode)
            print("Response Headers:", httpResponse.allHeaderFields)
        }
        
        let gptResponse = try JSONDecoder().decode(GPTResponse.self, from: data)
        
        guard let content = gptResponse.choices.first?.message.content else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No response from GPT"])
        }
        
        // Parse the GPT response into WeeklyAnalysis
        return try parseGPTResponse(content)
    }
    
    private func parseGPTResponse(_ content: String) throws -> WeeklyAnalysis {
        guard let jsonData = content.data(using: .utf8),
              let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let summary = json["summary"] as? String,
              let insights = json["insights"] as? [String],
              let recommendations = json["recommendations"] as? [String],
              let scores = json["scores"] as? [String: Int] else {
            throw NSError(domain: "GPTService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse GPT response"])
        }
        
        return WeeklyAnalysis(
            summary: summary,
            insights: insights,
            recommendations: recommendations,
            sleepQualityScore: scores["sleepQuality"] ?? 0,
            caffeineBalanceScore: scores["caffeineBalance"] ?? 0,
            overallScore: scores["overall"] ?? 0
        )
    }
    
    // For testing and preview purposes
    func getMockAnalysis() -> WeeklyAnalysis {
        return WeeklyAnalysis.mockData
    }
}
