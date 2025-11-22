//
//  File.swift
//  SwiftFastPass
//
//  Created by 胡诚真 on 2019/6/6.
//  Copyright © 2019 huchengzhen. All rights reserved.
//

import UIKit

final class File: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }
    enum SecurityLevel: Int, CaseIterable {
        case paranoid
        case balanced
        case convenience

        /// 是否把密码 / keyfile 内容缓存到 Keychain
        var cachesCredentials: Bool {
            switch self {
            case .paranoid:
                return false            // 不缓存 → 每次都要输
            case .balanced, .convenience:
                return true
            }
        }

        /// 是否使用生物识别参与解锁（只是能力，具体怎么用由上层控制）
        var usesBiometrics: Bool {
            switch self {
            case .paranoid:
                return false            // 可以在设置里直接关掉
            case .balanced, .convenience:
                return true
            }
        }

        /// 记住解锁状态的时间窗口（秒）
        /// nil 表示不记住，永远要求重新验证
        var unlockGraceInterval: TimeInterval? {
            switch self {
            case .paranoid:
                return nil              // 每次都输主密码 + keyfile
            case .balanced:
                return 60 * 60          // 例如 1 小时内可用生物识别 / 免输
            case .convenience:
                return 24 * 60 * 60     // 例如 1 天，甚至可以设成很长
            }
        }

        /// 是否记住 keyfile 的选择（路径 / URL），而不是内容
        var rememberKeyFileSelection: Bool {
            switch self {
            case .paranoid:
                return true   // 可以允许：只记“位置”，不记“内容”，省得每次选文件
            case .balanced, .convenience:
                return true
            }
        }

        /// 是否允许缓存 keyfile 的内容（加密后放 Keychain）
        /// 对应你说的「方案 B：记住 keyfile，但不记主密码」可以只在 balanced 下开启
        var rememberKeyFileContent: Bool {
            switch self {
            case .paranoid:
                return false
            case .balanced:
                return true   // 可以记 keyfile 内容，但不一定记主密码
            case .convenience:
                return true   // 主密码 + keyfile 内容都可以缓存
            }
        }

        /// Balanced 模式的 Keychain 读写需要 Face ID / Touch ID
        /// 以避免后续重复弹窗。
        var keychainRequiresUserPresence: Bool {
            switch self {
            case .balanced:
                return true
            case .paranoid, .convenience:
                return false
            }
        }
    }

    let name: String
    private(set) var bookmark: Data
    let id: UUID
    var image: UIImage?
    private(set) var password: String?
    private(set) var keyFileContent: Data?
    /// Track whether this database needs a companion key file, even if we are not storing the content.
    var requiresKeyFileContent: Bool = false
    private(set) var securityLevel: SecurityLevel

    static var files = loadFiles()

    init(id: UUID = UUID(),
         name: String,
         bookmark: Data,
         requiresKeyFileContent: Bool = false,
         securityLevel: SecurityLevel = .paranoid)
    {
        self.id = id
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

        self.password = password
        self.keyFileContent = keyFileContent

        if let requiresKeyFileContent = requiresKeyFileContent {
            self.requiresKeyFileContent = requiresKeyFileContent
        } else if keyFileContent != nil {
            self.requiresKeyFileContent = true
        }

        if self.securityLevel.cachesCredentials,
           password != nil || keyFileContent != nil
        {
            let secrets = FileSecrets(password: password, keyFileContent: keyFileContent)
            FileSecretStore.save(secrets, for: self)
        } else {
            FileSecretStore.deleteSecrets(for: self)
        }
    }

    func updateSecurityLevel(_ level: SecurityLevel) {
        guard securityLevel != level else {
            return
        }
        let shouldCacheSecrets = level.cachesCredentials
        var existingPassword = password
        var existingKeyFile = keyFileContent

        if shouldCacheSecrets,
           (existingPassword == nil && existingKeyFile == nil),
           securityLevel.cachesCredentials,
           let secrets = FileSecretStore.credentials(for: self)
        {
            existingPassword = secrets.password
            existingKeyFile = secrets.keyFileContent
        }

        let passwordToStore = shouldCacheSecrets ? existingPassword : nil
        let keyFileToStore = shouldCacheSecrets ? existingKeyFile : nil
        attach(password: passwordToStore,
               keyFileContent: keyFileToStore,
               requiresKeyFileContent: requiresKeyFileContent,
               securityLevel: level)
    }

    var hasCachedCredentials: Bool {
        if password != nil || keyFileContent != nil {
            return true
        }
        guard securityLevel.cachesCredentials else {
            return false
        }
        return FileSecretStore.hasSecrets(for: self)
    }

    @discardableResult
    func loadCachedCredentials() -> Bool {
        guard securityLevel.cachesCredentials,
              let secrets = FileSecretStore.credentials(for: self)
        else {
            return false
        }
        password = secrets.password
        keyFileContent = secrets.keyFileContent
        return password != nil || keyFileContent != nil
    }

    func encode(with coder: NSCoder) {
        coder.encode(name, forKey: "name")
        coder.encode(bookmark, forKey: "bookmark")
        coder.encode(id.uuidString, forKey: "id")
        coder.encode(image, forKey: "image")
        coder.encode(requiresKeyFileContent, forKey: "requiresKeyFileContent")
        coder.encode(securityLevel.rawValue, forKey: "securityLevel")
    }

    required convenience init?(coder: NSCoder) {
        guard let name = coder.decodeObject(of: NSString.self, forKey: "name") as String?,
              let bookmarkData = coder.decodeObject(of: NSData.self, forKey: "bookmark") as Data?
        else {
            return nil
        }

        let identifier: UUID
        if let idString = coder.decodeObject(of: NSString.self, forKey: "id") as String?,
           let uuid = UUID(uuidString: idString)
        {
            identifier = uuid
        } else {
            identifier = UUID()
        }

        let image = coder.decodeObject(of: UIImage.self, forKey: "image")
        let legacyPassword = coder.decodeObject(of: NSString.self, forKey: "password") as String?
        let legacyKeyFileContent = coder.decodeObject(of: NSData.self, forKey: "keyFileContent") as Data?
        let requiresKeyFileContent: Bool
        if coder.containsValue(forKey: "requiresKeyFileContent") {
            requiresKeyFileContent = coder.decodeBool(forKey: "requiresKeyFileContent")
        } else {
            requiresKeyFileContent = legacyKeyFileContent != nil
        }
        let securityLevel: SecurityLevel
        if coder.containsValue(forKey: "securityLevel") {
            let rawValue = coder.decodeInteger(forKey: "securityLevel")
            securityLevel = SecurityLevel(rawValue: rawValue) ?? .balanced
        } else if coder.containsValue(forKey: "allowBiometricUnlock") {
            let legacyBiometricFlag = coder.decodeBool(forKey: "allowBiometricUnlock")
            if legacyBiometricFlag {
                securityLevel = .convenience
            } else if legacyPassword != nil || legacyKeyFileContent != nil {
                securityLevel = .balanced
            } else {
                securityLevel = .paranoid
            }
        } else if legacyPassword != nil || legacyKeyFileContent != nil {
            securityLevel = .balanced
        } else {
            securityLevel = .paranoid
        }

        self.init(id: identifier,
                  name: name,
                  bookmark: bookmarkData,
                  requiresKeyFileContent: requiresKeyFileContent,
                  securityLevel: securityLevel)
        self.image = image
        if legacyPassword != nil || legacyKeyFileContent != nil {
            attach(password: legacyPassword,
                   keyFileContent: legacyKeyFileContent,
                   requiresKeyFileContent: requiresKeyFileContent)
        }
    }

    private static let archiveURL: URL = {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("files")
    }()

    static func save() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: files, requiringSecureCoding: true)
            try data.write(to: archiveURL, options: .atomic)
        } catch {
            print("File.save failed: \(error)")
        }
    }

    static func loadFiles() -> [File] {
        if let data = try? Data(contentsOf: archiveURL),
           let decodedFiles = try? NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: File.self, from: data)
        {
            return decodedFiles
        }
        return (NSKeyedUnarchiver.unarchiveObject(withFile: archiveURL.path) as? [File]) ?? []
    }
}

extension File.SecurityLevel {
    var localizedTitle: String {
        switch self {
        case .paranoid:
            return NSLocalizedString("Lockdown", comment: "Security level option")
        case .balanced:
            return NSLocalizedString("Balanced", comment: "Security level option")
        case .convenience:
            return NSLocalizedString("Quick Unlock", comment: "Security level option")
        }
    }

    var localizedDescription: String {
        switch self {
        case .paranoid:
            return NSLocalizedString("Every unlock requires the master password plus the key file. Nothing is cached and biometrics stay off.", comment: "Security level description")
        case .balanced:
            return NSLocalizedString("Enter the master password after a reboot or long break, but Face ID / Touch ID can reopen the vault for a short period. The key file selection is stored only on this device and is not uploaded or synced.", comment: "Security level description")
        case .convenience:
            return NSLocalizedString("Store a derived master key inside iOS Keychain so biometrics always unlock this database. If someone can unlock your device, they can open the vault too.", comment: "Security level description")
        }
    }
}
