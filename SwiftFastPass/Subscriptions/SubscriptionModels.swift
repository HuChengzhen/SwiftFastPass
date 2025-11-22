import Foundation
import StoreKit

enum SubscriptionTier: CaseIterable {
    case monthly
    case annual

    var marketingName: String {
        switch self {
        case .monthly:
            return NSLocalizedString("Monthly Plan", comment: "")
        case .annual:
            return NSLocalizedString("Annual Plan", comment: "")
        }
    }

    var sortPriority: Int {
        switch self {
        case .monthly:
            return 0
        case .annual:
            return 1
        }
    }
}

enum SubscriptionProductID: String, CaseIterable {
    case premiumMonthly = "com.huchengzhen.swiftfastpass.plus.monthly"
    case premiumAnnual = "com.huchengzhen.swiftfastpass.plus.annual"

    var tier: SubscriptionTier {
        switch self {
        case .premiumMonthly:
            return .monthly
        case .premiumAnnual:
            return .annual
        }
    }
}

struct SubscriptionProduct {
    let identifier: SubscriptionProductID
    let product: SKProduct

    var id: String {
        product.productIdentifier
    }

    var marketingTitle: String {
        product.localizedTitle.isEmpty ? identifier.tier.marketingName : product.localizedTitle
    }

    var marketingDescription: String {
        product.localizedDescription
    }

    var localizedPrice: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? product.price.stringValue
    }

    var callToAction: String {
        switch identifier.tier {
        case .monthly:
            return NSLocalizedString("Start Monthly", comment: "")
        case .annual:
            return NSLocalizedString("Start Annual", comment: "")
        }
    }
}

struct SubscriptionFeature: Equatable {
    let title: String
    let detail: String

    static let `default`: [SubscriptionFeature] = [
        SubscriptionFeature(title: NSLocalizedString("Unlimited AutoFill", comment: ""),
                            detail: NSLocalizedString("Unlock the SwiftFastPass AutoFill extension on all of your devices.", comment: "")),
        SubscriptionFeature(title: NSLocalizedString("Secure Sync", comment: ""),
                            detail: NSLocalizedString("Keep entries in sync and backed up with your preferred storage provider.", comment: "")),
        SubscriptionFeature(title: NSLocalizedString("Priority Support", comment: ""),
                            detail: NSLocalizedString("Dedicated email support from the SwiftFastPass team.", comment: "")),
        SubscriptionFeature(title: NSLocalizedString("Future Pro Features", comment: ""),
                            detail: NSLocalizedString("New password insights, auditors, and automation as they ship.", comment: ""))
    ]
}

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
