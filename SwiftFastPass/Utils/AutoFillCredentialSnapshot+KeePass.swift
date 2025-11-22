import Foundation
import KeePassKit

extension AutoFillCredentialSnapshot {
    init?(entry: KPKEntry) {
        let password = entry.password?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let username = entry.username?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !password.isEmpty, !username.isEmpty else {
            return nil
        }

        let normalizedURL = AutoFillCredentialSnapshot.normalize(urlString: entry.url)
        let domain = AutoFillCredentialSnapshot.extractDomain(from: normalizedURL)
        let title = entry.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        self.init(uuid: entry.uuid.uuidString,
                  title: title,
                  username: username,
                  password: password,
                  domain: domain,
                  url: normalizedURL,
                  updatedAt: Date())
    }

    private static func normalize(urlString: String?) -> String? {
        guard var value = urlString?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else {
            return nil
        }
        if !value.contains("://") {
            value = "https://\(value)"
        }
        return value
    }

    private static func extractDomain(from normalizedURL: String?) -> String? {
        guard let normalizedURL = normalizedURL,
              let url = URL(string: normalizedURL),
              let host = url.host,
              !host.isEmpty else {
            return nil
        }
        return host.lowercased()
    }
}

extension AutoFillCredentialStore {
    func upsertEntryIfPossible(_ entry: KPKEntry) {
        guard let snapshot = AutoFillCredentialSnapshot(entry: entry) else {
            removeCredential(withUUID: entry.uuid.uuidString)
            return
        }
        upsert(snapshot: snapshot)
    }

    func removeCredentials(in group: KPKGroup) {
        group.entries.forEach { removeCredential(withUUID: $0.uuid.uuidString) }
        group.groups.forEach { removeCredentials(in: $0) }
    }
}
