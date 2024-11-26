import SwiftUI
import SwiftData

@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    let modelContainer: ModelContainer
    var modelContext: ModelContext
    
    @AppStorage("onboardingCompleted") private var onboardingCompleted = false
    
    @Published var currentProfile: UserProfile? {
        didSet {
            try? modelContext.save()
            if let profile = currentProfile {
                onboardingCompleted = profile.onboardingCompleted
            }
        }
    }
    
    private init() {
        do {
            let schema = Schema([
                UserProfile.self,
                CaffeineEntry.self
            ])
            let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
            modelContext = modelContainer.mainContext
            currentProfile = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first
        } catch {
            fatalError("Could not initialize UserProfileManager: \(error)")
        }
    }
    
    func setModelContainer(_ container: ModelContainer) {
        // This method allows us to switch to the app's shared container
        modelContext = container.mainContext
        currentProfile = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first
    }
    
    func createInitialProfile() {
        guard currentProfile == nil else { return }
        
        let profile = UserProfile(
            name: "",
            onboardingCompleted: false,
            trialStartDate: Date(),
            isPremium: false,
            healthKitEnabled: false,
            notificationsEnabled: false
        )
        
        modelContext.insert(profile)
        try? modelContext.save()
        currentProfile = profile
    }
    
    func completeOnboarding(name: String) {
        print("DEBUG: UserProfileManager - Completing onboarding for name: \(name)")
        updateProfile { profile in
            profile.name = name
            profile.onboardingCompleted = true
        }
        onboardingCompleted = true
        print("DEBUG: UserProfileManager - Profile updated, onboardingCompleted: \(String(describing: currentProfile?.onboardingCompleted))")
        print("DEBUG: UserProfileManager - AppStorage onboardingCompleted: \(onboardingCompleted)")
        objectWillChange.send()
    }
    
    func updateProfile(_ updates: (UserProfile) -> Void) {
        guard let profile = currentProfile else { return }
        updates(profile)
        try? modelContext.save()
    }
    
    func togglePremium() {
        updateProfile { profile in
            profile.isPremium.toggle()
        }
    }
    
    func resetProfile() {
        if let profile = currentProfile {
            modelContext.delete(profile)
            try? modelContext.save()
            currentProfile = nil
            onboardingCompleted = false
        }
    }
    
    static func preview(isPremium: Bool = false) -> UserProfileManager {
        let manager = UserProfileManager()
        let profile = UserProfile(
            name: "Preview User",
            onboardingCompleted: true,
            trialStartDate: Date(),
            isPremium: isPremium,
            healthKitEnabled: true,
            notificationsEnabled: true
        )
        manager.modelContext.insert(profile)
        manager.currentProfile = profile
        return manager
    }
}
