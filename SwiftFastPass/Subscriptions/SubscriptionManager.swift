import Foundation
import StoreKit

protocol SubscriptionManagerObserver: AnyObject {
    func subscriptionManager(_ manager: SubscriptionManager, didUpdateProducts products: [SubscriptionProduct])
    func subscriptionManager(_ manager: SubscriptionManager, didUpdate entitlement: SubscriptionEntitlement)
    func subscriptionManager(_ manager: SubscriptionManager, didFailWith error: Error)
}

extension SubscriptionManagerObserver {
    func subscriptionManager(_: SubscriptionManager, didUpdateProducts _: [SubscriptionProduct]) {}
    func subscriptionManager(_: SubscriptionManager, didUpdate _: SubscriptionEntitlement) {}
    func subscriptionManager(_: SubscriptionManager, didFailWith _: Error) {}
}

enum SubscriptionError: LocalizedError {
    case paymentsNotAllowed
    case productUnavailable

    var errorDescription: String? {
        switch self {
        case .paymentsNotAllowed:
            return NSLocalizedString("Purchases are disabled on this device. Please enable payments under Screen Time settings.", comment: "")
        case .productUnavailable:
            return NSLocalizedString("Unable to load subscription options right now. Please try again later.", comment: "")
        }
    }
}

final class SubscriptionManager: NSObject {
    static let shared = SubscriptionManager()

    private let entitlementStore: SubscriptionEntitlementStore
    private var observers = NSHashTable<AnyObject>.weakObjects()
    private var productsRequest: SKProductsRequest?
    private var isObservingTransactions = false
    private let notificationQueue = DispatchQueue.main

    private(set) var products: [SubscriptionProduct] = [] {
        didSet {
            notifyObservers { $0.subscriptionManager(self, didUpdateProducts: self.products) }
        }
    }

    private(set) var entitlement: SubscriptionEntitlement {
        didSet {
            entitlementStore.save(entitlement)
            notifyObservers { $0.subscriptionManager(self, didUpdate: self.entitlement) }
        }
    }

    init(entitlementStore: SubscriptionEntitlementStore = SubscriptionEntitlementStore()) {
        self.entitlementStore = entitlementStore
        entitlement = entitlementStore.entitlement
        super.init()
    }

    func start() {
        guard !isObservingTransactions else { return }
        SKPaymentQueue.default().add(self)
        isObservingTransactions = true
        fetchProductsIfNeeded(force: false)
    }

    func addObserver(_ observer: SubscriptionManagerObserver) {
        observers.add(observer)
        observer.subscriptionManager(self, didUpdate: entitlement)
        if !products.isEmpty {
            observer.subscriptionManager(self, didUpdateProducts: products)
        }
    }

    func removeObserver(_ observer: SubscriptionManagerObserver) {
        observers.remove(observer)
    }

    func fetchProductsIfNeeded(force: Bool) {
        guard products.isEmpty || force else {
            notifyObservers { $0.subscriptionManager(self, didUpdateProducts: self.products) }
            return
        }
        productsRequest?.cancel()
        let identifiers = Set(SubscriptionProductID.allCases.map(\.rawValue))
        let request = SKProductsRequest(productIdentifiers: identifiers)
        request.delegate = self
        productsRequest = request
        request.start()
    }

    func purchase(productID: SubscriptionProductID) {
        guard SKPaymentQueue.canMakePayments() else {
            notifyObservers { $0.subscriptionManager(self, didFailWith: SubscriptionError.paymentsNotAllowed) }
            return
        }
        guard let product = products.first(where: { $0.identifier == productID }) else {
            notifyObservers { $0.subscriptionManager(self, didFailWith: SubscriptionError.productUnavailable) }
            fetchProductsIfNeeded(force: true)
            return
        }
        let payment = SKMutablePayment(product: product.product)
        SKPaymentQueue.default().add(payment)
    }

    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    private func applyEntitlement(for transaction: SKPaymentTransaction) {
        var newEntitlement = subscriptionEntitlement(from: transaction)
        // Use the longest expiration between local data and new data.
        if let existingExpiration = entitlement.expiresAt,
           let candidateExpiration = newEntitlement.expiresAt,
           existingExpiration > candidateExpiration {
            newEntitlement.expiresAt = existingExpiration
        }
        entitlement = newEntitlement
    }

    private func subscriptionEntitlement(from transaction: SKPaymentTransaction) -> SubscriptionEntitlement {
        let originalIdentifier = transaction.original?.transactionIdentifier ?? transaction.transactionIdentifier
        let expirationDate = transaction.transactionDate?.addingTimeInterval(30 * 24 * 60 * 60)
        return SubscriptionEntitlement(status: .active,
                                       expiresAt: expirationDate,
                                       originalTransactionId: originalIdentifier,
                                       lastUpdated: Date())
    }

    private func complete(_ transaction: SKPaymentTransaction) {
        applyEntitlement(for: transaction)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func handleFailure(_ transaction: SKPaymentTransaction) {
        let error = transaction.error ?? SubscriptionError.productUnavailable
        notifyObservers { $0.subscriptionManager(self, didFailWith: error) }
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func notifyObservers(_ block: @escaping (SubscriptionManagerObserver) -> Void) {
        let observers = observers.allObjects.compactMap { $0 as? SubscriptionManagerObserver }
        guard !observers.isEmpty else { return }
        notificationQueue.async {
            observers.forEach { block($0) }
        }
    }
}

extension SubscriptionManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        productsRequest = nil
        let mapped = response.products.compactMap { product -> SubscriptionProduct? in
            guard let identifier = SubscriptionProductID(rawValue: product.productIdentifier) else {
                return nil
            }
            return SubscriptionProduct(identifier: identifier, product: product)
        }
        products = mapped.sorted { lhs, rhs in
            lhs.identifier.tier.sortPriority < rhs.identifier.tier.sortPriority
        }
        if !response.invalidProductIdentifiers.isEmpty {
            NSLog("SubscriptionManager invalid products: \(response.invalidProductIdentifiers)")
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        if request === productsRequest {
            productsRequest = nil
        }
        notifyObservers { $0.subscriptionManager(self, didFailWith: error) }
    }
}

extension SubscriptionManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                complete(transaction)
            case .failed:
                handleFailure(transaction)
            case .purchasing, .deferred:
                break
            @unknown default:
                break
            }
        }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_: SKPaymentQueue) {
        notifyObservers { $0.subscriptionManager(self, didUpdate: self.entitlement) }
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        notifyObservers { $0.subscriptionManager(self, didFailWith: error) }
    }
}
