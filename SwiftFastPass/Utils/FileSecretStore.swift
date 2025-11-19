//
//  FileSecretStore.swift
//  SwiftFastPass
//
//  Created by huchengzhen on 2024/05/16.
//

import Foundation
import Security

struct FileSecrets: Codable {
    let password: String?
    let keyFileContent: Data?
}

enum FileSecretStore {
    private static let service = (Bundle.main.bundleIdentifier ?? "SwiftFastPass") + ".fileSecrets"
    private static let encoder = PropertyListEncoder()
    private static let decoder = PropertyListDecoder()

    private static func baseQuery(for file: File) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: file.id.uuidString,
        ]
    }

    static func save(_ secrets: FileSecrets, for file: File) {
        guard secrets.password != nil || secrets.keyFileContent != nil else {
            deleteSecrets(for: file)
            return
        }

        do {
            let data = try encoder.encode(secrets)
            let deletionQuery = baseQuery(for: file)
            SecItemDelete(deletionQuery as CFDictionary)

            var attributes = deletionQuery
            attributes[kSecValueData as String] = data

            if let accessControl = accessControl(for: file.securityLevel) {
                attributes[kSecAttrAccessControl as String] = accessControl
            } else {
                attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            }
            let status = SecItemAdd(attributes as CFDictionary, nil)
            if status != errSecSuccess {
                print("FileSecretStore.save error: \(status)")
            }
        } catch {
            print("FileSecretStore.save encode error: \(error)")
        }
    }

    static func credentials(for file: File) -> FileSecrets? {
        var query = baseQuery(for: file)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess,
              let data = item as? Data
        else {
            return nil
        }

        do {
            return try decoder.decode(FileSecrets.self, from: data)
        } catch {
            print("FileSecretStore.credentials decode error: \(error)")
            return nil
        }
    }

    static func hasSecrets(for file: File) -> Bool {
        var query = baseQuery(for: file)
        query[kSecReturnData as String] = kCFBooleanFalse
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    static func deleteSecrets(for file: File) {
        let status = SecItemDelete(baseQuery(for: file) as CFDictionary)
        if status != errSecSuccess && status != errSecItemNotFound {
            print("FileSecretStore.deleteSecrets error: \(status)")
        }
    }

    private static func accessControl(for level: File.SecurityLevel) -> SecAccessControl? {
        switch level {
        case .paranoid:
            // paranoid 模式我们本来就不缓存，所以一般不会走到这里
            return nil

        case .balanced:
            // 设备解锁 + 用户存在（Face ID / Touch ID / 密码）
            // 每次取 Keychain 条目时会弹一次验证
            return SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                [.userPresence],  // or [.biometryCurrentSet] 只允许当前录入的生物信息
                nil
            )

        case .convenience:
            // 方便模式：允许在解锁状态下直接用（你可以选择是否仍然要求 userPresence）
            return SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                [],               // 不强制每次弹生物识别（真正的“偏方便”）
                nil
            )
        }
    }

}
