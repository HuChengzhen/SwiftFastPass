import Foundation

struct SubscriptionEntitlement: Codable, Equatable {
    enum Status: String, Codable {
        case unknown
        case active
        case gracePeriod
        case expired
    }

    var status: Status
    var expiresAt: Date?
    var originalTransactionId: String?
    var lastUpdated: Date

    var isActive: Bool {
        switch status {
        case .active, .gracePeriod:
            if let expiresAt = expiresAt {
                return expiresAt > Date()
            }
            return true
        case .unknown, .expired:
            return false
        }
    }

    static func empty() -> SubscriptionEntitlement {
        SubscriptionEntitlement(status: .unknown, expiresAt: nil, originalTransactionId: nil, lastUpdated: Date.distantPast)
    }
}
