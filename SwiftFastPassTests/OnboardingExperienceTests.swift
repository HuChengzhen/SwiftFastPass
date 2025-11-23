import XCTest
@testable import SwiftFastPass

final class OnboardingExperienceTests: XCTestCase {
    func testMarksOnboardingAsSeen() {
        let suiteName = "OnboardingExperienceTests"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Unable to create isolated UserDefaults suite")
            return
        }
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertTrue(OnboardingExperience.shouldShow(using: defaults))

        OnboardingExperience.markSeen(using: defaults)

        XCTAssertFalse(OnboardingExperience.shouldShow(using: defaults))
    }
}
