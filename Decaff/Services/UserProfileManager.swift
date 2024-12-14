import SwiftUI
import SwiftData

@MainActor
class UserProfileManager: ObservableObject {
    static let shared = UserProfileManager()
    
    let modelContainer: ModelContainer
    var modelContext: ModelContext
    
    @Published var currentProfile: UserProfile? {
        didSet {
            try? modelContext.save()
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
        modelContext = container.mainContext
        currentProfile = try? modelContext.fetch(FetchDescriptor<UserProfile>()).first
    }
    
    func createInitialProfile() {
        guard currentProfile == nil else { return }
        
        let profile = UserProfile(
            notificationsEnabled: false, onboardingCompleted: false
        )
        
        modelContext.insert(profile)
        try? modelContext.save()
        currentProfile = profile
    }
    
    func completeOnboarding(name: String) {
        updateProfile { profile in
            profile.name = name
            profile.onboardingCompleted = true
        }
        objectWillChange.send()
    }
    
    func updateProfile(_ updates: (UserProfile) -> Void) {
        guard let profile = currentProfile else { return }
        updates(profile)
        try? modelContext.save()
    }
    
    func resetProfile() {
        if let profile = currentProfile {
            modelContext.delete(profile)
            try? modelContext.save()
            currentProfile = nil
        }
    }
}
