//
//  AnalysisView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/12/24.
//

import SwiftUI
import Foundation

import SwiftUI
import SwiftData

struct AnalysisView: View {
    @Query private var userProfile: [UserProfile]
    @State private var showingPremiumUpgrade = false
    
    var body: some View {
        NavigationView {
            VStack {
                if let profile = userProfile.first, profile.isPremium {
                    ScrollView {
                        VStack(spacing: 20) {
                            WeeklyConsumptionChart()
                            SleepCorrelationView()
                            AIInsightsButton()
                        }
                        .padding()
                    }
                } else {
                    PremiumUpgradeView(showingUpgrade: $showingPremiumUpgrade)
                }
            }
            .navigationTitle("Analysis")
        }
    }
}

struct WeeklyConsumptionChart: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Weekly Consumption")
                .font(.headline)
            
            // Placeholder for actual chart implementation
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    Text("Weekly consumption chart will be implemented here")
                        .foregroundColor(.secondary)
                )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct SleepCorrelationView: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Sleep Correlation")
                .font(.headline)
            
            // Placeholder for sleep correlation data
            Rectangle()
                .fill(Color.secondary.opacity(0.2))
                .frame(height: 200)
                .overlay(
                    Text("Sleep correlation data will be shown here")
                        .foregroundColor(.secondary)
                )
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct AIInsightsButton: View {
    @State private var isGeneratingInsights = false
    
    var body: some View {
        Button(action: generateInsights) {
            HStack {
                Image(systemName: "brain.head.profile")
                Text("Generate AI Insights")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .disabled(isGeneratingInsights)
    }
    
    private func generateInsights() {
        isGeneratingInsights = true
        // Implementation for AI insights generation
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isGeneratingInsights = false
        }
    }
}

#Preview {
    AnalysisView()
        .modelContainer(for: [UserProfile.self])
}
