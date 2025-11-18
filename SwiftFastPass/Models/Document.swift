//
//  Document.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import KeePassKit
import UIKit

enum DocumentError: Error {
    case load
    case noKey
    case noTree
}

class Document: UIDocument {
    var tree: KPKTree?
    var key: KPKCompositeKey?

    override func contents(forType _: String) throws -> Any {
        guard key != nil else {
            throw DocumentError.noKey
        }

        guard tree != nil else {
            throw DocumentError.noTree
        }

        let data: Data
        do {
            try data = tree!.encrypt(with: key, format: .kdbx)
        } catch {
            throw error
        }
        return data
    }

    override func load(fromContents contents: Any, ofType _: String?) throws {
        guard key != nil else {
            throw DocumentError.noKey
        }

        guard let contents = contents as? Data else {
            throw DocumentError.load
        }
        do {
            try tree = KPKTree(data: contents, key: key)
        } catch {
            throw error
        }
    }
}
