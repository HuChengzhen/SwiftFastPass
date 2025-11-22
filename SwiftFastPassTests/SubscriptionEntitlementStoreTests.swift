@testable import SwiftFastPass
import XCTest

final class SubscriptionEntitlementStoreTests: XCTestCase {
    private var defaults: UserDefaults!
    private var store: SubscriptionEntitlementStore!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "SubscriptionEntitlementStoreTests")
        defaults.removePersistentDomain(forName: "SubscriptionEntitlementStoreTests")
        store = SubscriptionEntitlementStore(userDefaults: defaults)
    }

    override func tearDown() {
        store.reset()
        defaults.removePersistentDomain(forName: "SubscriptionEntitlementStoreTests")
        defaults = nil
        store = nil
        super.tearDown()
    }

    func testSaveAndLoadRoundTrip() {
        let expectationDate = Date(timeIntervalSince1970: 1735689600)
        let entitlement = SubscriptionEntitlement(status: .active,
                                                  expiresAt: expectationDate,
                                                  originalTransactionId: "original-transaction-id",
                                                  lastUpdated: Date())
        store.save(entitlement)
        let stored = store.entitlement
        XCTAssertEqual(stored.status, .active)
        XCTAssertEqual(stored.expiresAt, expectationDate)
        XCTAssertEqual(stored.originalTransactionId, "original-transaction-id")
    }

    func testResetClearsEntitlement() {
        let entitlement = SubscriptionEntitlement(status: .expired,
                                                  expiresAt: nil,
                                                  originalTransactionId: nil,
                                                  lastUpdated: Date())
        store.save(entitlement)
        store.reset()
        XCTAssertEqual(store.entitlement.status, .unknown)
    }
}
