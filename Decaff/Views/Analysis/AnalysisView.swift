//
//  AnalysisView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/12/24.
//

import SwiftUI
import SwiftData

struct AnalysisView: View {
    @Query private var userProfile: [UserProfile]
    @Query(sort: \CaffeineEntry.timestamp) private var caffeineEntries: [CaffeineEntry]
    @StateObject private var healthKitService = HealthKitService.shared
    @StateObject private var gptService = GPTService.shared
    @State private var showingPremiumUpgrade = false
    @State private var weeklyAnalysis: WeeklyAnalysis?
    @State private var sleepData: [SleepEntry] = []
    @State private var showingHealthKitPermission = false
    @State private var errorMessage: String?
    @State private var showingError = false
    @State private var showingTestingMenu = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let profile = userProfile.first, profile.isPremium {
                    ScrollView {
                        VStack(spacing: 20) {
                            WeeklyConsumptionChart(entries: caffeineEntries)
                            SleepCorrelationView(sleepData: sleepData, caffeineEntries: caffeineEntries)
                            
                            if let analysis = weeklyAnalysis {
                                AnalysisSummaryView(analysis: analysis)
                            }
                            
                            AIInsightsButton(
                                isGeneratingInsights: gptService.isAnalyzing,
                                action: generateInsights
                            )
                        }
                        .padding()
                    }
                    .onAppear {
                        Task {
                            await requestHealthKitPermission()
                            await fetchSleepData()
                        }
                    }
                } else {
                    PremiumUpgradeView(showingUpgrade: $showingPremiumUpgrade)
                }
            }
            .navigationTitle("Analysis")
            .toolbar {
                #if DEBUG
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingTestingMenu = true }) {
                        Image(systemName: "hammer.fill")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingTestingMenu) {
                TestingMenu(isPresented: $showingTestingMenu)
            }
            .alert("HealthKit Access", isPresented: $showingHealthKitPermission) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable HealthKit access in Settings to view sleep data analysis.")
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "An unknown error occurred")
            }
        }
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
            let sleepEntries = try await healthKitService.fetchSleepData(from: startDate, to: endDate)
            await MainActor.run {
                self.sleepData = sleepEntries
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error fetching sleep data: \(error.localizedDescription)"
                showingError = true
            }
        }
    }
    
    private func generateInsights() {
        Task {
            do {
                let calendar = Calendar.current
                let endDate = Date()
                guard let startDate = calendar.date(byAdding: .day, value: -7, to: endDate) else { return }
                
                let recentEntries = caffeineEntries.filter { entry in
                    calendar.isDate(entry.timestamp, inSameDayAs: startDate) ||
                    (entry.timestamp > startDate && entry.timestamp <= endDate)
                }
                
                let analysis = try await gptService.analyzeWeeklyData(
                    caffeineEntries: recentEntries,
                    sleepEntries: sleepData
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
}

struct WeeklyConsumptionChart: View {
    let entries: [CaffeineEntry]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Consumption")
                .font(.headline)
            
            if entries.isEmpty {
                EmptyDataView(message: "No caffeine data available for the past week")
            } else {
                // TODO: Implement chart using Swift Charts
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        Text("Weekly consumption chart will be implemented here")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SleepCorrelationView: View {
    let sleepData: [SleepEntry]
    let caffeineEntries: [CaffeineEntry]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Sleep Correlation")
                .font(.headline)
            
            if sleepData.isEmpty {
                EmptyDataView(message: "No sleep data available")
            } else {
                // TODO: Implement correlation visualization
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .frame(height: 200)
                    .overlay(
                        Text("Sleep correlation data will be shown here")
                            .foregroundColor(.secondary)
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct AnalysisSummaryView: View {
    let analysis: WeeklyAnalysis
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Analysis")
                .font(.headline)
            
            Text(analysis.summary)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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
