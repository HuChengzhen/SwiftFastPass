import XCTest
@testable import SwiftFastPass

final class UpgradeExperienceTests: XCTestCase {
    func testDoesNotShowWhenNoVaults() {
        let defaults = UserDefaults(suiteName: "UpgradeExperienceTests_NoVaults")!
        defaults.removePersistentDomain(forName: "UpgradeExperienceTests_NoVaults")
        defer { defaults.removePersistentDomain(forName: "UpgradeExperienceTests_NoVaults") }

        XCTAssertFalse(UpgradeExperience.shouldShow(using: defaults, hasExistingVaults: false))
    }

    func testShowsOnceForExistingVaults() {
        let suite = "UpgradeExperienceTests_WithVaults"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertTrue(UpgradeExperience.shouldShow(using: defaults, hasExistingVaults: true))
        UpgradeExperience.markSeen(using: defaults)
        XCTAssertFalse(UpgradeExperience.shouldShow(using: defaults, hasExistingVaults: true))
    }
}
