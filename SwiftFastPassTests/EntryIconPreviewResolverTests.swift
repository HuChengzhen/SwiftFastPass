import XCTest
@testable import SwiftFastPass
import KeePassKit

final class EntryIconPreviewResolverTests: XCTestCase {
    func testDetectsOverrideWhenLegacyEntryPickedNewIcon() {
        let entry = KPKEntry()
        entry.iconId = 2
        entry.iconColorId = 0

        let hasOverride = EntryViewController.hasIconOverride(
            entry: entry,
            selectedIconId: 10,
            selectedColorId: 3
        )

        XCTAssertTrue(hasOverride)
    }

    func testKeepsEntryIconWhenSelectionMatches() {
        let entry = KPKEntry()
        entry.iconId = 4
        entry.iconColorId = 6

        let hasOverride = EntryViewController.hasIconOverride(
            entry: entry,
            selectedIconId: 4,
            selectedColorId: 6
        )

        XCTAssertFalse(hasOverride)
    }
}
