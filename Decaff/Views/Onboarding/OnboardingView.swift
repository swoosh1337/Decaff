//
//  OnboardingView.swift
//  Decaff
//
//  Created by Tazi Grigolia on 11/11/24.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @StateObject private var profileManager = UserProfileManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var showNameInput = false
    @Binding var isOnboarding: Bool
    @Environment(\.dismiss) private var dismiss
    
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
            if showNameInput {
                NameInputView(userName: $userName, onComplete: completeOnboarding)
                    .transition(.move(edge: .trailing))
            } else {
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
                        Text(currentPage == pages.count - 1 ? "Continue" : "Next")
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
        }
        .gesture(
            DragGesture()
                .onEnded { value in
                    if !showNameInput {
                        if value.translation.width < 0 {
                            nextPage()
                        } else if value.translation.width > 0 {
                            previousPage()
                        }
                    }
                }
        )
        .onAppear {
            profileManager.createInitialProfile()
        }
    }
    
    private func nextPage() {
        withAnimation {
            if currentPage < pages.count - 1 {
                currentPage += 1
            } else {
                withAnimation {
                    showNameInput = true
                }
            }
        }
    }
    
    private func completeOnboarding() {
        print("DEBUG: Completing onboarding with name: \(userName)")
        profileManager.completeOnboarding(name: userName)
        print("DEBUG: Onboarding completed, profile state: \(String(describing: profileManager.currentProfile?.onboardingCompleted))")
        withAnimation {
            isOnboarding = false
            presentationMode.wrappedValue.dismiss()
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

struct NameInputView: View {
    @Binding var userName: String
    let onComplete: () -> Void
    @FocusState private var isNameFocused: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            Text("What should we call you?")
                .font(.title2)
                .bold()
            
            TextField("Your name", text: $userName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
                .focused($isNameFocused)
            
            Button(action: {
                if !userName.isEmpty {
                    withAnimation {
                        onComplete()
                    }
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(!userName.isEmpty ? Color.accentColor : Color.gray)
                    .cornerRadius(10)
            }
            .disabled(userName.isEmpty)
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            isNameFocused = true
        }
    }
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
                .foregroundColor(.primary)
            
            Text(page.subtitle)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
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
                    .frame(width: 10, height: 10)
                    .padding(.top, 8)
            }
        }
    }
}

#Preview {
    let previewManager = UserProfileManager.preview(isPremium: false)
    return OnboardingView(isOnboarding: .constant(true))
        .modelContainer(previewManager.modelContainer)
}
