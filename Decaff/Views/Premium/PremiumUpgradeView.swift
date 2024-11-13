//
//  PremiumUpgradeView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/13/24.
//

import SwiftUI
import StoreKit

struct PremiumUpgradeView: View {
    @Binding var showingUpgrade: Bool
    @State private var isPurchasing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "star.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.yellow)
            
            Text("Unlock Premium Features")
                .font(.title2)
                .bold()
            
            VStack(alignment: .leading, spacing: 12) {
                FeatureRow(icon: "chart.bar.fill", text: "Detailed Analytics")
                FeatureRow(icon: "brain.head.profile", text: "AI-Powered Insights")
                FeatureRow(icon: "bed.double.fill", text: "Sleep Correlation Analysis")
                FeatureRow(icon: "arrow.up.arrow.down", text: "Export Your Data")
            }
            .padding(.vertical)
            
            Button(action: startPurchase) {
                if isPurchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else {
                    Text("Upgrade Now - $5")
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(10)
            .disabled(isPurchasing)
            
            Button("Maybe Later") {
                showingUpgrade = false
            }
            .foregroundColor(.secondary)
        }
        .padding()
    }
    
    private func startPurchase() {
        isPurchasing = true
        // Implement in-app purchase logic here
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isPurchasing = false
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 30)
            Text(text)
            Spacer()
            Image(systemName: "checkmark")
                .foregroundColor(.green)
        }
    }
}

#Preview {
    PremiumUpgradeView(showingUpgrade: .constant(true))
}
