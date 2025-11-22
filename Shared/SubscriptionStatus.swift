import Foundation

enum SubscriptionStatus {
    static func currentEntitlement() -> SubscriptionEntitlement {
        SubscriptionEntitlementStore().entitlement
    }

    static var isPremiumUnlocked: Bool {
        currentEntitlement().isActive
    }
}
