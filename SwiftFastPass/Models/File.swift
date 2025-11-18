//
//  File.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit

class File: NSObject, NSCoding {
    let name: String
    private(set) var bookmark: Data
    var image: UIImage?
    private(set) var password: String?
    private(set) var keyFileContent: Data?
    /// Track whether this database needs a companion key file, even if we are not storing the content.
    var requiresKeyFileContent: Bool = false
    var allowBiometricUnlock: Bool = false

    static var files = loadFiles()

    init(name: String, bookmark: Data, requiresKeyFileContent: Bool = false) {
        self.name = name
        self.bookmark = bookmark
        self.requiresKeyFileContent = requiresKeyFileContent
    }

    func updateBookmark(_ bookmark: Data) {
        self.bookmark = bookmark
    }

    func attach(password: String?, keyFileContent: Data?, requiresKeyFileContent: Bool? = nil) {
        self.password = password
        self.keyFileContent = keyFileContent

        if let requiresKeyFileContent = requiresKeyFileContent {
            self.requiresKeyFileContent = requiresKeyFileContent
        } else if keyFileContent != nil {
            self.requiresKeyFileContent = true
        }
    }

    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(bookmark, forKey: "bookmark")
        coder.encode(image, forKey: "image")
        coder.encode(password, forKey: "password")
        coder.encode(keyFileContent, forKey: "keyFileContent")
        coder.encode(requiresKeyFileContent, forKey: "requiresKeyFileContent")
        coder.encode(allowBiometricUnlock, forKey: "allowBiometricUnlock")
    }

    required convenience init?(coder: NSCoder) {
        let name = coder.decodeObject(forKey: "name") as! String
        let bookmark = coder.decodeObject(forKey: "bookmark") as! Data
        let image = coder.decodeObject(forKey: "image") as? UIImage
        let password = coder.decodeObject(forKey: "password") as? String
        let keyFileContent = coder.decodeObject(forKey: "keyFileContent") as? Data
        let requiresKeyFileContent: Bool
        if coder.containsValue(forKey: "requiresKeyFileContent") {
            requiresKeyFileContent = coder.decodeBool(forKey: "requiresKeyFileContent")
        } else {
            requiresKeyFileContent = keyFileContent != nil
        }
        self.init(name: name, bookmark: bookmark, requiresKeyFileContent: requiresKeyFileContent)
        self.image = image
        attach(password: password, keyFileContent: keyFileContent, requiresKeyFileContent: requiresKeyFileContent)

        // 新增：兼容性非常重要！
        if coder.containsValue(forKey: "allowBiometricUnlock") {
            allowBiometricUnlock = coder.decodeBool(forKey: "allowBiometricUnlock")
        } else {
            allowBiometricUnlock = false // 老版本存档里没有，默认 false
        }
    }

    private static let archiveURL: URL = {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let archiveURL = documentsDirectory.appendingPathComponent("files")
        return archiveURL
    }()

    static func save() {
        let success = NSKeyedArchiver.archiveRootObject(files, toFile: archiveURL.path)
        if !success {
            print("File.save failed")
        }
    }

    static func loadFiles() -> [File] {
        return (NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL.path) as? [File]) ?? []
    }
}
