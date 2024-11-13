//
//  OnboardingView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/11/24.
//


import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    private let pages = [
        OnboardingPage(
            title: "Track Your Caffeine",
            subtitle: "Monitor your daily caffeine intake and understand how it affects your body",
            imageName: "cup.and.saucer.fill"
        ),
        OnboardingPage(
            title: "Sleep Better",
            subtitle: "See how caffeine impacts your sleep quality with Apple Health integration",
            imageName: "bed.double.fill"
        ),
        OnboardingPage(
            title: "AI-Powered Insights",
            subtitle: "Get personalized recommendations and analysis of your consumption patterns",
            imageName: "brain.head.profile"
        )
    ]
    
    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                ForEach(0..<pages.count, id: \.self) { index in
                    OnboardingPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            
            VStack {
                Spacer()
                PageControl(numberOfPages: pages.count, currentPage: $currentPage)
                    .padding(.bottom)
                
                Button(action: nextPage) {
                    Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < 0 {
                        nextPage()
                    } else if value.translation.width > 0 {
                        previousPage()
                    }
                }
        )
    }
    
    private func nextPage() {
        withAnimation {
            if currentPage < pages.count - 1 {
                currentPage += 1
            } else {
                // Handle onboarding completion
            }
        }
    }
    
    private func previousPage() {
        withAnimation {
            if currentPage > 0 {
                currentPage -= 1
            }
        }
    }
}

struct OnboardingPage {
    let title: String
    let subtitle: String
    let imageName: String
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: page.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
                .foregroundColor(.accentColor)
                .padding(.top, 50)
            
            Text(page.title)
                .font(.title)
                .bold()
            
            Text(page.subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Spacer()
        }
    }
}

struct PageControl: View {
    let numberOfPages: Int
    @Binding var currentPage: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<numberOfPages, id: \.self) { page in
                Circle()
                    .fill(page == currentPage ? Color.accentColor : Color.gray.opacity(0.5))
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    OnboardingView()
}
