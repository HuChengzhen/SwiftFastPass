import Foundation

final class SubscriptionEntitlementStore {
    private static let storageKey = "com.huchengzhen.swiftfastpass.subscription.entitlement"

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let lock = NSLock()

    init(userDefaults: UserDefaults = UserDefaults(suiteName: AutoFillConstants.appGroupIdentifier) ?? .standard) {
        self.userDefaults = userDefaults
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    var entitlement: SubscriptionEntitlement {
        lock.lock()
        defer { lock.unlock() }
        guard let data = userDefaults.data(forKey: SubscriptionEntitlementStore.storageKey) else {
            return .empty()
        }
        do {
            return try decoder.decode(SubscriptionEntitlement.self, from: data)
        } catch {
            NSLog("SubscriptionEntitlementStore decode error: \(error)")
            userDefaults.removeObject(forKey: SubscriptionEntitlementStore.storageKey)
            return .empty()
        }
    }

    func save(_ entitlement: SubscriptionEntitlement) {
        lock.lock()
        defer { lock.unlock() }
        do {
            let data = try encoder.encode(entitlement)
            userDefaults.set(data, forKey: SubscriptionEntitlementStore.storageKey)
        } catch {
            NSLog("SubscriptionEntitlementStore encode error: \(error)")
        }
    }

    func reset() {
        lock.lock()
        userDefaults.removeObject(forKey: SubscriptionEntitlementStore.storageKey)
        lock.unlock()
    }
}
