@testable import SwiftFastPass
import XCTest

final class PasswordCreatorTests: XCTestCase {
    func testPasswordGenerationFailsWithoutAllowedCharacters() {
        let emptyFlag = MPPasswordCharacterFlags(rawValue: 0)
        let password = NSString.password(
            withCharactersets: emptyFlag,
            withCustomCharacters: "",
            ensureOccurence: false,
            length: 12
        )
        XCTAssertNil(password)
    }

    func testPasswordGenerationEnforcesMinimumLengthWhenZeroRequested() {
        let lowercaseOnly = MPPasswordCharacterFlags(rawValue: 1 << 1)
        let password = NSString.password(
            withCharactersets: lowercaseOnly,
            withCustomCharacters: "",
            ensureOccurence: false,
            length: 0
        )
        XCTAssertNotNil(password)
        XCTAssertEqual(password?.count, 1)
    }
}
