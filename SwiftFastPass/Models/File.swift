//
//  File.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit

final class File: NSObject, NSCoding {
    enum SecurityLevel: Int, CaseIterable {
        case paranoid
        case balanced
        case convenience

        var cachesCredentials: Bool {
            switch self {
            case .paranoid:
                return false
            case .balanced, .convenience:
                return true
            }
        }

        var allowsBiometricUnlock: Bool {
            switch self {
            case .paranoid:
                return false
            case .balanced, .convenience:
                return true
            }
        }

        var requiresBiometricEnrollment: Bool {
            return allowsBiometricUnlock
        }
    }

    let name: String
    private(set) var bookmark: Data
    var image: UIImage?
    private(set) var password: String?
    private(set) var keyFileContent: Data?
    /// Track whether this database needs a companion key file, even if we are not storing the content.
    var requiresKeyFileContent: Bool = false
    private(set) var securityLevel: SecurityLevel

    static var files = loadFiles()

    init(name: String,
         bookmark: Data,
         requiresKeyFileContent: Bool = false,
         securityLevel: SecurityLevel = .paranoid)
    {
        self.name = name
        self.bookmark = bookmark
        self.requiresKeyFileContent = requiresKeyFileContent
        self.securityLevel = securityLevel
    }

    func updateBookmark(_ bookmark: Data) {
        self.bookmark = bookmark
    }

    func attach(password: String?,
                keyFileContent: Data?,
                requiresKeyFileContent: Bool? = nil,
                securityLevel: SecurityLevel? = nil)
    {
        if let securityLevel = securityLevel {
            self.securityLevel = securityLevel
        }

        if self.securityLevel.cachesCredentials {
            self.password = password
            self.keyFileContent = keyFileContent
        } else {
            self.password = nil
            self.keyFileContent = nil
        }

        if let requiresKeyFileContent = requiresKeyFileContent {
            self.requiresKeyFileContent = requiresKeyFileContent
        } else if keyFileContent != nil {
            self.requiresKeyFileContent = true
        }
    }

    var hasCachedCredentials: Bool {
        return password != nil || keyFileContent != nil
    }

    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(bookmark, forKey: "bookmark")
        coder.encode(image, forKey: "image")
        coder.encode(password, forKey: "password")
        coder.encode(keyFileContent, forKey: "keyFileContent")
        coder.encode(requiresKeyFileContent, forKey: "requiresKeyFileContent")
        coder.encode(securityLevel.rawValue, forKey: "securityLevel")
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
        let securityLevel: SecurityLevel
        if coder.containsValue(forKey: "securityLevel") {
            let rawValue = coder.decodeInteger(forKey: "securityLevel")
            securityLevel = SecurityLevel(rawValue: rawValue) ?? .balanced
        } else if coder.containsValue(forKey: "allowBiometricUnlock") {
            let legacyBiometricFlag = coder.decodeBool(forKey: "allowBiometricUnlock")
            if legacyBiometricFlag {
                securityLevel = .convenience
            } else if password != nil || keyFileContent != nil {
                securityLevel = .balanced
            } else {
                securityLevel = .paranoid
            }
        } else if password != nil || keyFileContent != nil {
            securityLevel = .balanced
        } else {
            securityLevel = .paranoid
        }

        self.init(name: name,
                  bookmark: bookmark,
                  requiresKeyFileContent: requiresKeyFileContent,
                  securityLevel: securityLevel)
        self.image = image
        attach(password: password,
               keyFileContent: keyFileContent,
               requiresKeyFileContent: requiresKeyFileContent)
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
