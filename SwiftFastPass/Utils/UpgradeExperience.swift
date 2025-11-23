import Foundation

enum UpgradeExperience {
    private static let seenKey = "com.fastpass.upgradePromo.seen.v1"

    static func shouldShow(using userDefaults: UserDefaults = .standard, hasExistingVaults: Bool) -> Bool {
        guard hasExistingVaults else { return false }
        return !userDefaults.bool(forKey: seenKey)
    }

    static func markSeen(using userDefaults: UserDefaults = .standard) {
        userDefaults.set(true, forKey: seenKey)
    }
}
