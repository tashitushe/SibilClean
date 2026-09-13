import AppKit
import Foundation

enum AppScanner {
    private nonisolated(unsafe) static let fm = FileManager.default

    private static var homeLibrary: URL {
        fm.homeDirectoryForCurrentUser.appendingPathComponent("Library")
    }

    /// System apps that should never show up as removable.
    private static let excludedBundleIDs: Set<String> = [
        "com.apple.dt.Xcode",
    ]

    static func scanInstalledApps() -> [ScannedApp] {
        var results: [ScannedApp] = []
        var seenPaths = Set<String>()

        let searchDirs = [
            URL(fileURLWithPath: "/Applications"),
            fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
        ]

        for dir in searchDirs {
            guard let entries = try? fm.contentsOfDirectory(
                at: dir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
            ) else { continue }

            for entry in entries where entry.pathExtension == "app" {
                guard !seenPaths.contains(entry.path) else { continue }
                seenPaths.insert(entry.path)

                let infoPlistURL = entry.appendingPathComponent("Contents/Info.plist")
                let info = NSDictionary(contentsOf: infoPlistURL) as? [String: Any]
                let bundleID = info?["CFBundleIdentifier"] as? String

                if let bundleID, excludedBundleIDs.contains(bundleID) { continue }
                // Apple's own system-owned apps live directly under /Applications
                // but many are also not user-removable; only /System/Applications
                // is truly protected, so /Applications entries are fair game.

                let displayName = (info?["CFBundleDisplayName"] as? String)
                    ?? (info?["CFBundleName"] as? String)
                    ?? entry.deletingPathExtension().lastPathComponent

                results.append(ScannedApp(
                    name: displayName,
                    bundleID: bundleID,
                    path: entry
                ))
            }
        }

        return results.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    /// Finds files/folders left behind in the user's Library for a given app.
    static func findLeftovers(bundleID: String?, name: String) -> [LeftoverItem] {
        guard let bundleID else { return [] }

        var candidates: [URL] = []
        let lib = homeLibrary

        func add(_ relative: String) {
            candidates.append(lib.appendingPathComponent(relative))
        }

        add("Application Support/\(bundleID)")
        add("Application Support/\(name)")
        add("Caches/\(bundleID)")
        add("Preferences/\(bundleID).plist")
        add("Logs/\(name)")
        add("Saved Application State/\(bundleID).savedState")
        add("HTTPStorages/\(bundleID)")
        add("WebKit/\(bundleID)")
        add("Containers/\(bundleID)")
        add("Cookies/\(bundleID).binarycookies")

        var found: [LeftoverItem] = []
        var seen = Set<String>()

        for url in candidates {
            guard fm.fileExists(atPath: url.path), !seen.contains(url.path) else { continue }
            seen.insert(url.path)
            let size = fm.isDirectoryPath(url) ? directorySize(at: url) : fileSize(at: url)
            found.append(LeftoverItem(url: url, size: size))
        }

        // LaunchAgents whose plist references this bundle ID.
        if let agentsEntries = try? fm.contentsOfDirectory(
            at: lib.appendingPathComponent("LaunchAgents"),
            includingPropertiesForKeys: nil
        ) {
            for plistURL in agentsEntries where plistURL.pathExtension == "plist" {
                guard !seen.contains(plistURL.path) else { continue }
                if let dict = NSDictionary(contentsOf: plistURL) as? [String: Any] {
                    let label = dict["Label"] as? String ?? ""
                    let program = (dict["Program"] as? String) ?? ((dict["ProgramArguments"] as? [String])?.first ?? "")
                    if label.contains(bundleID) || program.contains(bundleID) {
                        seen.insert(plistURL.path)
                        found.append(LeftoverItem(url: plistURL, size: fileSize(at: plistURL)))
                    }
                }
            }
        }

        return found
    }

    // MARK: - Size helpers

    static func fileSize(at url: URL) -> Int64 {
        (try? fm.attributesOfItem(atPath: url.path)[.size] as? Int64) ?? 0
    }

    static func directorySize(at url: URL) -> Int64 {
        guard let enumerator = fm.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileAllocatedSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles],
            errorHandler: nil
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            guard let values = try? fileURL.resourceValues(forKeys: [.fileAllocatedSizeKey, .isDirectoryKey]),
                  values.isDirectory != true else { continue }
            total += Int64(values.fileAllocatedSize ?? 0)
        }
        return total
    }
}

private extension FileManager {
    func isDirectoryPath(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        _ = fileExists(atPath: url.path, isDirectory: &isDir)
        return isDir.boolValue
    }
}
