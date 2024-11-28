//
//  AnalysisView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/12/24.
//

import SwiftUI
import SwiftData
import Charts

struct AnalysisView: View {
    @Query private var userProfile: [UserProfile]
    @Query(sort: \CaffeineEntry.timestamp) private var caffeineEntries: [CaffeineEntry]
    @StateObject private var healthKitService = HealthKitService.shared
    @StateObject private var gptService = GPTService.shared
    @State private var weeklyAnalysis: WeeklyAnalysis?
    @State private var healthKitSleepData: [SleepEntry] = []
    @State private var sleepData: [DailySleepData] = []
    @State private var caffeineData: [DailyCaffeineData] = []
    @State private var showingHealthKitPermission = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingTestingMenu = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    WeeklyConsumptionChart(caffeineData: caffeineData.map { ($0.date, $0.totalAmount) })
                        .frame(height: 300)
                        .padding(.horizontal)
                    
                    SleepCorrelationView(sleepData: sleepData, caffeineData: caffeineData)
                        .padding(.horizontal)
                    
                    if let analysis = weeklyAnalysis {
                        AnalysisSummaryView(analysis: analysis)
                            .padding(.horizontal)
                    }
                    
                    AIInsightsButton(
                        isGeneratingInsights: gptService.isAnalyzing,
                        action: generateWeeklyAnalysis
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .padding(.vertical)
            }
            .navigationTitle("Analysis")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingTestingMenu.toggle() }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .onAppear {
                // Load mock data immediately
                sleepData = MockDataService.shared.generateMockSleepData(for: 7)
                caffeineData = MockDataService.shared.generateMockCaffeineData(for: 7)
            }
            .sheet(isPresented: $showingTestingMenu) {
                TestingMenu(isPresented: $showingTestingMenu)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
    }
    
    private func generateWeeklyAnalysis() {
        Task {
            do {
                let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                let endDate = Date()
                
                let recentEntries = caffeineEntries.filter { entry in
                    Calendar.current.isDate(entry.timestamp, inSameDayAs: startDate) ||
                    (entry.timestamp > startDate && entry.timestamp <= endDate)
                }
                
                // Convert sleep data for GPT analysis
                let sleepEntries = convertToSleepEntries(from: sleepData)
                
                let analysis = try await gptService.analyzeData(
                    caffeineEntries: recentEntries,
                    sleepEntries: sleepEntries
                )
                
                await MainActor.run {
                    self.weeklyAnalysis = analysis
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Error generating analysis: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }
    
    private func loadMockData() {
        // Always load mock data initially
        sleepData = MockDataService.shared.generateMockSleepData(for: 7)
        caffeineData = MockDataService.shared.generateMockCaffeineData(for: 7)
    }
    
    private func requestHealthKitPermission() async {
        do {
            try await healthKitService.requestAuthorization()
        } catch {
            await MainActor.run {
                errorMessage = "Unable to access HealthKit: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func fetchSleepData() async {
        guard healthKitService.isAuthorized else {
            showingHealthKitPermission = true
            return
        }
        
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else { return }
        
        do {
            let fetchedSleepData = try await healthKitService.fetchSleepData(from: startDate, to: endDate)
            await MainActor.run {
                healthKitSleepData = fetchedSleepData
                // Convert HealthKit sleep data to our DailySleepData format
                sleepData = convertToDailySleepData(from: fetchedSleepData)
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error fetching sleep data: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func convertToDailySleepData(from entries: [SleepEntry]) -> [DailySleepData] {
        let calendar = Calendar.current
        
        // Group sleep entries by day
        let groupedEntries = Dictionary(grouping: entries) { entry in
            calendar.startOfDay(for: entry.startDate)
        }
        
        return groupedEntries.map { date, entries in
            let totalHours = entries.reduce(0.0) { $0 + $1.durationInHours }
            let bedTime = entries.map { $0.startDate }.min()
            let wakeTime = entries.map { $0.endDate }.max()
            
            return DailySleepData(
                date: date,
                totalHours: totalHours,
                bedTime: bedTime,
                wakeTime: wakeTime
            )
        }.sorted { $0.date < $1.date }
    }
    
    private func convertToSleepEntries(from dailyData: [DailySleepData]) -> [SleepEntry] {
        let calendar = Calendar.current
        let now = Date()
        
        return dailyData.map { daily in
            let bedTime = daily.bedTime ?? calendar.date(byAdding: .day, value: -1, to: now)!
            let wakeTime = daily.wakeTime ?? now
            
            return SleepEntry(
                startDate: bedTime,
                endDate: wakeTime,
                value: Int(daily.totalHours * 3600) // Convert hours to seconds
            )
        }
    }
}

struct WeeklyConsumptionChart: View {
    let caffeineData: [(Date, Double)]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Caffeine Consumption")
                .font(.headline)
                .padding(.bottom, 5)
            
            if caffeineData.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Chart {
                    ForEach(caffeineData, id: \.0) { date, amount in
                        BarMark(
                            x: .value("Day", date, unit: .day),
                            y: .value("Caffeine", amount)
                        )
                        .foregroundStyle(Color.brown.gradient)
                    }
                    
                    RuleMark(y: .value("Max Recommended", 400))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .foregroundStyle(.red)
                        .annotation(position: .top, alignment: .leading) {
                            Text("400mg")
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.leading, 4)
                        }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday())
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        let mgValue = value.as(Double.self) ?? 0
                        AxisValueLabel("\(Int(mgValue))mg")
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}

struct SleepCorrelationView: View {
    let sleepData: [DailySleepData]
    let caffeineData: [DailyCaffeineData]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sleep & Caffeine Analysis")
                .font(.headline)
                .padding(.bottom, 5)
            
            if sleepData.isEmpty || caffeineData.isEmpty {
                Text("No data available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(Array(zip(sleepData, caffeineData)), id: \.0.date) { sleep, caffeine in
                            DailyAnalysisCard(sleep: sleep, caffeine: caffeine)
                        }
                    }
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Summary section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Weekly Summary")
                        .font(.headline)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Label {
                                Text("Avg Sleep")
                            } icon: {
                                Image(systemName: "bed.double.fill")
                                    .foregroundColor(.blue)
                            }
                            Text(String(format: "%.1f hours", averageSleep))
                                .bold()
                        }
                        
                        VStack(alignment: .leading) {
                            Label {
                                Text("Avg Caffeine")
                            } icon: {
                                Image(systemName: "cup.and.saucer.fill")
                                    .foregroundColor(.brown)
                            }
                            Text("\(Int(averageCaffeine))mg")
                                .bold()
                        }
                        
                        if let avgBloodLevel = averageBloodLevelAtSleep {
                            VStack(alignment: .leading) {
                                Label {
                                    Text("Avg Bedtime Level")
                                } icon: {
                                    Image(systemName: "moon.fill")
                                        .foregroundColor(.purple)
                                }
                                Text("\(Int(avgBloodLevel))mg")
                                    .bold()
                            }
                        }
                    }
                    .font(.subheadline)
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
    
    private var averageSleep: Double {
        guard !sleepData.isEmpty else { return 0 }
        let total = sleepData.reduce(0.0) { $0 + $1.totalHours }
        return total / Double(sleepData.count)
    }
    
    private var averageCaffeine: Double {
        guard !caffeineData.isEmpty else { return 0 }
        let total = caffeineData.reduce(0.0) { $0 + $1.totalAmount }
        return total / Double(caffeineData.count)
    }
    
    private var averageBloodLevelAtSleep: Double? {
        let levels = caffeineData.compactMap { $0.estimatedBloodLevelAtSleep }
        guard !levels.isEmpty else { return nil }
        return levels.reduce(0.0, +) / Double(levels.count)
    }
}

struct DailyAnalysisCard: View {
    let sleep: DailySleepData
    let caffeine: DailyCaffeineData
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(sleep.date, format: .dateTime.weekday(.wide))
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "bed.double.fill")
                        .foregroundColor(.blue)
                    Text("\(String(format: "%.1f", sleep.totalHours))h sleep")
                }
                
                if let bedTime = sleep.bedTime {
                    Text("Bed: \(bedTime, format: .dateTime.hour().minute())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundColor(.brown)
                    Text("\(Int(caffeine.totalAmount))mg caffeine")
                }
                
                if let lastIntake = caffeine.lastIntakeTime {
                    Text("Last: \(lastIntake, format: .dateTime.hour().minute())")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let bloodLevel = caffeine.estimatedBloodLevelAtSleep {
                    HStack {
                        Image(systemName: "moon.fill")
                            .foregroundColor(.purple)
                        Text("\(Int(bloodLevel))mg at bed")
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .frame(width: 160)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
    }
}

struct AIInsightsButton: View {
    let isGeneratingInsights: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "brain.head.profile")
                Text(isGeneratingInsights ? "Generating Insights..." : "Generate AI Insights")
                
                if isGeneratingInsights {
                    ProgressView()
                        .tint(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isGeneratingInsights)
    }
}

struct EmptyDataView: View {
    let message: String
    
    var body: some View {
        VStack {
            Image(systemName: "chart.bar.xaxis")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(message)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: UserProfile.self, CaffeineEntry.self, configurations: config)
    
    // Add sample data
    let profile = UserProfile(isPremium: true)
    container.mainContext.insert(profile)
    
    return AnalysisView()
        .modelContainer(container)
}
