import Foundation

enum OnboardingExperience {
    private static let seenKey = "com.fastpass.onboarding.seen.v1"

    static func shouldShow(using userDefaults: UserDefaults = .standard) -> Bool {
        return !userDefaults.bool(forKey: seenKey)
    }

    static func markSeen(using userDefaults: UserDefaults = .standard) {
        userDefaults.set(true, forKey: seenKey)
    }
}
