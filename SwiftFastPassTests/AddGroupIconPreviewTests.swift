import XCTest
@testable import SwiftFastPass

final class AddGroupIconPreviewTests: XCTestCase {
    func testUsesLegacyIconWhenColorIsZero() {
        XCTAssertTrue(AddGroupViewController.shouldUseLegacyIcon(iconId: 5, iconColorId: 0))
    }

    func testUsesLegacyIconWhenIconIndexOutOfRange() {
        XCTAssertTrue(AddGroupViewController.shouldUseLegacyIcon(iconId: 999, iconColorId: 2))
    }

    func testUsesSFSymbolWhenIndexAndColorValid() {
        XCTAssertFalse(AddGroupViewController.shouldUseLegacyIcon(iconId: 1, iconColorId: 2))
    }
}
