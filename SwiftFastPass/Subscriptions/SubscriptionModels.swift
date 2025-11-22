import Foundation
import StoreKit

enum SubscriptionTier: CaseIterable {
    case monthly

    var marketingName: String {
        switch self {
        case .monthly:
            return NSLocalizedString("FastPass Pro Monthly Plan", comment: "")
        }
    }

    var sortPriority: Int {
        switch self {
        case .monthly:
            return 0
        }
    }
}

enum SubscriptionProductID: String, CaseIterable {
    case premiumMonthly = "com.huchengzhen.swiftfastpass.pro.monthly"

    var tier: SubscriptionTier {
        switch self {
        case .premiumMonthly:
            return .monthly
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
            return NSLocalizedString("Unlock FastPass Pro", comment: "")
        }
    }
}

struct SubscriptionFeature: Equatable {
    let title: String
    let detail: String

    static let `default`: [SubscriptionFeature] = [
        SubscriptionFeature(title: NSLocalizedString("AutoFill everywhere", comment: ""),
                            detail: NSLocalizedString("One-tap fill-ins in Safari, apps, and the FastPass AutoFill extension.", comment: "")),
        SubscriptionFeature(title: NSLocalizedString("Private cloud sync", comment: ""),
                            detail: NSLocalizedString("Encrypted vaults stored in iCloud Drive so every change is backed up.", comment: "")),
        SubscriptionFeature(title: NSLocalizedString("Unlimited vaults & devices", comment: ""),
                            detail: NSLocalizedString("Create as many databases as you need across iPhone and iPad.", comment: "")),
        SubscriptionFeature(title: NSLocalizedString("Priority support & roadmap", comment: ""),
                            detail: NSLocalizedString("Get direct email help and early access to upcoming Pro tools.", comment: ""))
    ]
}
