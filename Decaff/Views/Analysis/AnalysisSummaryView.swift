import SwiftUI

struct CircularScoreView: View {
    let score: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                
                Text("\(score)")
                    .font(.title2)
                    .bold()
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct AnalysisSummaryView: View {
    let analysis: WeeklyAnalysis
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary Section
                Text("Weekly Summary")
                    .font(.title2)
                    .bold()
                
                Text(analysis.summary)
                    .foregroundColor(.secondary)
                
                // Scores Section
                HStack(spacing: 20) {
                    CircularScoreView(
                        score: analysis.sleepQualityScore,
                        label: "Sleep",
                        color: .blue
                    )
                    
                    CircularScoreView(
                        score: analysis.caffeineBalanceScore,
                        label: "Caffeine",
                        color: .green
                    )
                    
                    CircularScoreView(
                        score: analysis.overallScore,
                        label: "Overall",
                        color: .purple
                    )
                }
                .padding(.vertical)
                
                // Insights Section
                Text("Key Insights")
                    .font(.title2)
                    .bold()
                
                ForEach(analysis.insights, id: \.self) { insight in
                    HStack(alignment: .top) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                        Text(insight)
                    }
                }
                
                // Recommendations Section
                Text("Recommendations")
                    .font(.title2)
                    .bold()
                
                ForEach(analysis.recommendations, id: \.self) { recommendation in
                    HStack(alignment: .top) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text(recommendation)
                    }
                }
            }
            .padding()
        }
    }
}

#Preview {
    AnalysisSummaryView(analysis: WeeklyAnalysis.mockData)
}
