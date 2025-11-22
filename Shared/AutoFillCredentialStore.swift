import AuthenticationServices
import Foundation
import Security

struct AutoFillConstants {
    static let appGroupIdentifier = "group.com.huchengzhen.swiftfastpass"
    static let keychainService = "com.huchengzhen.swiftfastpass.autofill"
    static let keychainAccount = "autofill_credentials"
    static let keychainAccessGroupSuffix = "group.com.huchengzhen.swiftfastpass"
    static let legacyStorageFileName = "autofill_credentials.json"

    static let keychainAccessGroup: String? = {
        guard let prefix = AutoFillConstants.appIdentifierPrefix else {
            return nil
        }
        return prefix + keychainAccessGroupSuffix
    }()

    private static var appIdentifierPrefix: String? {
        if let prefixes = Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? [String] {
            return prefixes.first
        }
        return Bundle.main.object(forInfoDictionaryKey: "AppIdentifierPrefix") as? String
    }
}

struct AutoFillCredentialSnapshot: Codable, Equatable {
    let uuid: String
    let title: String
    let username: String
    let password: String
    let domain: String?
    let url: String?
    let updatedAt: Date

    var displayTitle: String {
        if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return title
        }
        if let domain = domain {
            return domain
        }
        if let url = url {
            return url
        }
        return NSLocalizedString("Untitled Entry", comment: "")
    }

    var detailSummary: String {
        switch (username.isEmpty, domain?.isEmpty ?? true) {
        case (false, false):
            return "\(username) • \(domain ?? "")"
        case (false, true):
            return username
        case (true, false):
            return domain ?? ""
        default:
            return ""
        }
    }

    var credentialIdentity: ASPasswordCredentialIdentity? {
        guard let identifier = serviceIdentifier else { return nil }
        return ASPasswordCredentialIdentity(serviceIdentifier: identifier, user: username, recordIdentifier: uuid)
    }

    private var serviceIdentifier: ASCredentialServiceIdentifier? {
        if let domain = domain, !domain.isEmpty {
            return ASCredentialServiceIdentifier(identifier: domain, type: .domain)
        }
        if let url = url, !url.isEmpty {
            return ASCredentialServiceIdentifier(identifier: url, type: .URL)
        }
        return nil
    }
}

final class AutoFillCredentialStore {
    static let shared = AutoFillCredentialStore()

    private let queue = DispatchQueue(label: "com.huchengzhen.swiftfastpass.autofill", qos: .utility)
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let isRunningInExtension: Bool

    private init() {
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        isRunningInExtension = Bundle.main.bundlePath.hasSuffix(".appex")
    }

    func credentials() -> [AutoFillCredentialSnapshot] {
        guard SubscriptionStatus.isPremiumUnlocked else {
            return []
        }
        return queue.sync {
            loadSnapshots().sorted { sortPredicate(lhs: $0, rhs: $1) }
        }
    }

    func upsert(snapshot: AutoFillCredentialSnapshot) {
        queue.sync {
            var snapshots = loadSnapshots()
            snapshots.removeAll { $0.uuid == snapshot.uuid }
            snapshots.append(snapshot)
            persist(snapshots)
        }
        synchronizeCredentialIdentitiesIfPossible()
    }

    func removeCredential(withUUID uuid: String) {
        queue.sync {
            var snapshots = loadSnapshots()
            snapshots.removeAll { $0.uuid == uuid }
            persist(snapshots)
        }
        synchronizeCredentialIdentitiesIfPossible()
    }

    private func loadSnapshots() -> [AutoFillCredentialSnapshot] {
        if let data = AutoFillKeychainStorage.load() {
            do {
                return try decoder.decode([AutoFillCredentialSnapshot].self, from: data)
            } catch {
                NSLog("AutoFill store decode error: \(error)")
            }
        }
        if let legacySnapshots = loadLegacySnapshots() {
            persist(legacySnapshots)
            removeLegacyBackup()
            return legacySnapshots
        }
        return []
    }

    private func persist(_ snapshots: [AutoFillCredentialSnapshot]) {
        do {
            let data = try encoder.encode(snapshots)
            AutoFillKeychainStorage.save(data)
        } catch {
            NSLog("AutoFill store encode error: \(error)")
        }
    }

    private func loadLegacySnapshots() -> [AutoFillCredentialSnapshot]? {
        guard let url = legacyStorageURL,
              FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode([AutoFillCredentialSnapshot].self, from: data)
        } catch {
            NSLog("AutoFill legacy decode error: \(error)")
            return nil
        }
    }

    private func removeLegacyBackup() {
        guard let url = legacyStorageURL else { return }
        try? FileManager.default.removeItem(at: url)
    }

    private var legacyStorageURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AutoFillConstants.appGroupIdentifier)?
            .appendingPathComponent(AutoFillConstants.legacyStorageFileName)
    }

    private func synchronizeCredentialIdentitiesIfPossible() {
        guard !isRunningInExtension else { return }
        guard #available(iOS 12.0, *) else { return }
        guard SubscriptionStatus.isPremiumUnlocked else {
            ASCredentialIdentityStore.shared.getState { state in
                guard state.isEnabled else { return }
                ASCredentialIdentityStore.shared.replaceCredentialIdentities(with: []) { _, error in
                    if let error = error {
                        NSLog("AutoFill identity sync error: \(error)")
                    }
                }
            }
            return
        }
        let identities = credentials().compactMap(\.credentialIdentity)
        ASCredentialIdentityStore.shared.getState { state in
            guard state.isEnabled else { return }
            ASCredentialIdentityStore.shared.replaceCredentialIdentities(with: identities) { _, error in
                if let error = error {
                    NSLog("AutoFill identity sync error: \(error)")
                }
            }
        }
    }

    private func sortPredicate(lhs: AutoFillCredentialSnapshot, rhs: AutoFillCredentialSnapshot) -> Bool {
        if lhs.displayTitle.caseInsensitiveCompare(rhs.displayTitle) == .orderedSame {
            return lhs.updatedAt > rhs.updatedAt
        }
        return lhs.displayTitle.caseInsensitiveCompare(rhs.displayTitle) == .orderedAscending
    }
}

private enum AutoFillKeychainStorage {
    private static func queryBase() -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: AutoFillConstants.keychainService,
            kSecAttrAccount as String: AutoFillConstants.keychainAccount,
        ]
        if let group = AutoFillConstants.keychainAccessGroup {
            query[kSecAttrAccessGroup as String] = group
        }
        return query
    }

    static func load() -> Data? {
        var query = queryBase()
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            return nil
        }
        return item as? Data
    }

    static func save(_ data: Data) {
        var query = queryBase()
        SecItemDelete(query as CFDictionary)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            NSLog("AutoFill keychain save error: \(status)")
        }
    }
}
