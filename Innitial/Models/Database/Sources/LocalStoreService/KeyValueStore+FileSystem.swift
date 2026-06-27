import Foundation
import CryptoKit

extension KeyValueStore {
    /// A store backed by files on disk — one file per key, under `directory`.
    ///
    /// Each key (e.g. a request URL) is hashed (SHA-256) into a fixed-length,
    /// filesystem-safe filename, so arbitrary strings are valid keys.
    ///
    /// - Parameter directory: The folder that holds the files. Created on first write.
    public static func fileSystem(directory: URL) -> Self {
        // Only the `URL` is captured (it's Sendable); `FileManager.default`
        // is accessed inside each closure rather than captured.
        let directory = directory

        @Sendable func fileURL(for key: String) -> URL {
            let digest = SHA256.hash(data: Data(key.utf8))
            let name = digest.map { String(format: "%02x", $0) }.joined()
            return directory.appendingPathComponent(name, isDirectory: false)
        }

        return .init(
            loadData: { key in
                let url = fileURL(for: key)
                guard FileManager.default.fileExists(atPath: url.path) else { return nil }
                return try Data(contentsOf: url)
            },
            saveData: { data, key in
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true
                )
                try data.write(to: fileURL(for: key), options: .atomic)
            },
            removeValue: { key in
                let url = fileURL(for: key)
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
            },
            removeAll: {
                if FileManager.default.fileExists(atPath: directory.path) {
                    try FileManager.default.removeItem(at: directory)
                }
            }
        )
    }
}
