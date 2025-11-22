import UIKit

enum PremiumFeature {
    case multipleDatabases
    case advancedSecurity
    case keyFile
    case iCloudSync
    case autoFill

    var message: String {
        switch self {
        case .multipleDatabases:
            return NSLocalizedString("FastPass Pro unlocks unlimited databases, secure sync, and premium protection.", comment: "")
        case .advancedSecurity:
            return NSLocalizedString("Face ID / Touch ID unlock and balanced protection levels are part of FastPass Pro.", comment: "")
        case .keyFile:
            return NSLocalizedString("Storing additional key files requires FastPass Pro.", comment: "")
        case .iCloudSync:
            return NSLocalizedString("iCloud syncing is a FastPass Pro benefit.", comment: "")
        case .autoFill:
            return NSLocalizedString("AutoFill integration is only available to FastPass Pro subscribers.", comment: "")
        }
    }
}

final class PremiumAccessController {
    static let shared = PremiumAccessController(subscriptionManager: .shared)

    private let subscriptionManager: SubscriptionManager

    init(subscriptionManager: SubscriptionManager) {
        self.subscriptionManager = subscriptionManager
    }

    var isPremiumUnlocked: Bool {
        subscriptionManager.entitlement.isActive
    }

    func enforceDatabaseLimit(currentCount: Int, presenter: UIViewController) -> Bool {
        guard isPremiumUnlocked || currentCount == 0 else {
            presentPaywall(from: presenter, feature: .multipleDatabases)
            return false
        }
        return true
    }

    func enforce(feature: PremiumFeature, presenter: UIViewController) -> Bool {
        guard isPremiumUnlocked else {
            presentPaywall(from: presenter, feature: feature)
            return false
        }
        return true
    }

    func presentPaywall(from presenter: UIViewController, feature: PremiumFeature) {
        let alert = UIAlertController(title: NSLocalizedString("FastPass Pro", comment: ""),
                                      message: feature.message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Not Now", comment: ""), style: .cancel))
        alert.addAction(UIAlertAction(title: NSLocalizedString("See Plans", comment: ""), style: .default) { _ in
            let paywall = SubscriptionPaywallViewController()
            let navigation = paywall
            presenter.present(navigation, animated: true)
        })
        presenter.present(alert, animated: true)
    }

    func documentsDirectoryURL() -> URL {
        if isPremiumUnlocked,
           let iCloudURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?
           .appendingPathComponent("Documents", isDirectory: true)
        {
            return iCloudURL
        }
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
