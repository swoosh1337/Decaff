import Foundation

class GPTService: ObservableObject {
    static let shared = GPTService()
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    private var apiKey: String {
        return API.openAIKey
    }
    
    @Published var isAnalyzing = false
    
    func analyzeWeeklyData(caffeineEntries: [CaffeineEntry], sleepEntries: [SleepEntry]) async throws -> WeeklyAnalysis {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        let prompt = createAnalysisPrompt(caffeineEntries: caffeineEntries, sleepEntries: sleepEntries)
        
        var request = URLRequest(url: URL(string: baseURL)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-4",
            "messages": [
                ["role": "system", "content": "You are an expert in analyzing caffeine consumption and sleep patterns. Provide insights in a clear, concise manner with specific recommendations."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7,
            "max_tokens": 1000
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GPTError.apiError
        }
        
        let gptResponse = try JSONDecoder().decode(GPTResponse.self, from: data)
        return parseGPTResponse(gptResponse.choices.first?.message.content ?? "")
    }
    
    private func createAnalysisPrompt(caffeineEntries: [CaffeineEntry], sleepEntries: [SleepEntry]) -> String {
        var prompt = "Analyze the following week of caffeine consumption and sleep data:\n\nCaffeine Consumption:\n"
        
        // Format caffeine data
        for entry in caffeineEntries {
            prompt += "- \(entry.timestamp.formatted()): \(entry.beverageName) (\(Int(entry.caffeineAmount))mg)\n"
        }
        
        prompt += "\nSleep Data:\n"
        // Format sleep data
        for entry in sleepEntries {
            prompt += "- \(entry.startDate.formatted()) to \(entry.endDate.formatted()): \(entry.durationInHours) hours\n"
        }
        
        prompt += "\nPlease provide:\n1. Overall patterns\n2. Impact on sleep quality\n3. Specific recommendations\n4. Areas of concern\n5. Positive habits"
        
        return prompt
    }
    
    private func parseGPTResponse(_ response: String) -> WeeklyAnalysis {
        // For now, return a simple analysis structure
        // In the future, we could parse the response more intelligently
        return WeeklyAnalysis(
            summary: response,
            date: Date()
        )
    }
}

enum GPTError: Error {
    case apiError
    case parsingError
}

struct GPTResponse: Decodable {
    let choices: [Choice]
    
    struct Choice: Decodable {
        let message: Message
    }
    
    struct Message: Decodable {
        let content: String
    }
}

struct WeeklyAnalysis: Identifiable {
    let id = UUID()
    let summary: String
    let date: Date
    
    // Mock data for testing
    static var mockData: WeeklyAnalysis {
        WeeklyAnalysis(
            summary: """
            Overall Patterns:
            - Average daily caffeine intake: 280mg
            - Peak consumption: 10am-2pm
            - Consistent morning coffee routine
            
            Impact on Sleep:
            - Sleep latency increased on high caffeine days
            - Average sleep duration: 7.2 hours
            - Sleep quality affected by late afternoon consumption
            
            Recommendations:
            1. Limit caffeine intake after 2pm
            2. Consider reducing afternoon energy drink consumption
            3. Maintain consistent morning routine
            4. Stay hydrated throughout the day
            
            Areas of Concern:
            - Late afternoon energy drinks may affect sleep
            - Some days exceed recommended daily limit
            
            Positive Habits:
            - Regular morning routine
            - Good hydration with tea
            - No caffeine before bedtime
            """,
            date: Date()
        )
    }
}
