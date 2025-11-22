//
//  SwiftFastPassTests.swift
//  SwiftFastPassTests
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

@testable import SwiftFastPass
import XCTest

class SwiftFastPassTests: XCTestCase {
    func testUpdatingSecurityLevelClearsSecretsWhenDowngrading() {
        let file = File(name: "Test.kdbx", bookmark: Data(), securityLevel: .convenience)
        file.attach(password: "secret",
                    keyFileContent: Data([0x0A]),
                    requiresKeyFileContent: true,
                    securityLevel: .convenience)
        XCTAssertNotNil(file.password)
        XCTAssertNotNil(file.keyFileContent)

        file.updateSecurityLevel(.paranoid)

        XCTAssertEqual(file.securityLevel, .paranoid)
        XCTAssertNil(file.password)
        XCTAssertNil(file.keyFileContent)
        XCTAssertFalse(file.hasCachedCredentials)
        FileSecretStore.deleteSecrets(for: file)
    }

    func testUpdatingSecurityLevelKeepsSecretsWhenStillAllowed() {
        let file = File(name: "Test2.kdbx", bookmark: Data(), securityLevel: .balanced)
        file.attach(password: "hunter2",
                    keyFileContent: nil,
                    requiresKeyFileContent: false,
                    securityLevel: .balanced)

        file.updateSecurityLevel(.convenience)

        XCTAssertEqual(file.securityLevel, .convenience)
        XCTAssertEqual(file.password, "hunter2")
        FileSecretStore.deleteSecrets(for: file)
    }
}
