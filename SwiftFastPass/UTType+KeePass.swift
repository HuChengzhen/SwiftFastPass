//
//  UTType+KeePass.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2025/11/19.
//  Copyright © 2025 huchengzhen. All rights reserved.
//

import UniformTypeIdentifiers

extension UTType {
    /// KeePass Keyfile (.key)
    static let keepassKey = UTType(exportedAs: "com.jflan.MiniKeePass.key")

    /// KeePass Database v1 (.kdb)
    static let keepassDatabaseV1 = UTType(exportedAs: "com.jflan.MiniKeePass.kdb")

    /// KeePass Database v2 (.kdbx)
    static let keepassDatabaseV2 = UTType(exportedAs: "com.jflan.MiniKeePass.kdbx")
}
