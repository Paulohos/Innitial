import Foundation
import Security

/// Errors thrown by the Keychain-backed ``KeyValueStore``.
public enum KeychainError: Error, Sendable, Equatable {
    /// The Keychain returned an unexpected `OSStatus`.
    case unexpectedStatus(OSStatus)
}

extension KeyValueStore {
    /// A store backed by the Keychain (generic password items).
    ///
    /// - Parameters:
    ///   - service: The `kSecAttrService` namespace for these items (e.g. the app's bundle id).
    ///   - accessGroup: Optional Keychain access group for sharing between apps/extensions.
    public static func keychain(
        service: String,
        accessGroup: String? = nil
    ) -> Self {
        // Base query shared by every operation. Captures only `Sendable` strings.
        let baseQuery: @Sendable (_ key: String) -> [String: Any] = { key in
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: service,
                kSecAttrAccount as String: key,
            ]
            if let accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }
            return query
        }

        return .init(
            loadData: { key in
                var query = baseQuery(key)
                query[kSecReturnData as String] = true
                query[kSecMatchLimit as String] = kSecMatchLimitOne

                var item: CFTypeRef?
                let status = SecItemCopyMatching(query as CFDictionary, &item)
                switch status {
                case errSecSuccess:
                    return item as? Data
                case errSecItemNotFound:
                    return nil
                default:
                    throw KeychainError.unexpectedStatus(status)
                }
            },
            saveData: { data, key in
                // Upsert: try to update first, insert if the item doesn't exist yet.
                let query = baseQuery(key)
                let attributes: [String: Any] = [kSecValueData as String: data]
                let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

                switch status {
                case errSecSuccess:
                    return
                case errSecItemNotFound:
                    var insert = query
                    insert[kSecValueData as String] = data
                    // Tokens/secrets: readable after first unlock (so background refresh works)
                    // but never synced to iCloud Keychain and bound to this device only.
                    insert[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                    let addStatus = SecItemAdd(insert as CFDictionary, nil)
                    guard addStatus == errSecSuccess else {
                        throw KeychainError.unexpectedStatus(addStatus)
                    }
                default:
                    throw KeychainError.unexpectedStatus(status)
                }
            },
            removeValue: { key in
                let status = SecItemDelete(baseQuery(key) as CFDictionary)
                guard status == errSecSuccess || status == errSecItemNotFound else {
                    throw KeychainError.unexpectedStatus(status)
                }
            },
            removeAll: {
                var query: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: service,
                ]
                if let accessGroup {
                    query[kSecAttrAccessGroup as String] = accessGroup
                }
                let status = SecItemDelete(query as CFDictionary)
                guard status == errSecSuccess || status == errSecItemNotFound else {
                    throw KeychainError.unexpectedStatus(status)
                }
            }
        )
    }
}
