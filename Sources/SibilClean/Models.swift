import AppKit
import Foundation

struct LeftoverItem: Identifiable, Hashable, Sendable {
    let id: String
    let url: URL
    var size: Int64

    init(url: URL, size: Int64) {
        self.id = url.path
        self.url = url
        self.size = size
    }
}

/// Plain, Sendable snapshot of an installed app, produced by the background
/// scan before any AppKit (non-Sendable) objects like NSImage are attached.
struct ScannedApp: Sendable {
    let name: String
    let bundleID: String?
    let path: URL
}

@Observable
final class AppItem: Identifiable, Hashable {
    let id: String
    let name: String
    let bundleID: String?
    let path: URL
    let icon: NSImage

    var appSize: Int64 = 0
    var isSizeLoading: Bool = true
    var leftovers: [LeftoverItem] = []
    var leftoversTotalSize: Int64 = 0
    var isScanned: Bool = false
    var isScanning: Bool = false
    var isSelected: Bool = false

    var totalSize: Int64 { appSize + leftoversTotalSize }

    init(name: String, bundleID: String?, path: URL, icon: NSImage) {
        self.id = path.path
        self.name = name
        self.bundleID = bundleID
        self.path = path
        self.icon = icon
    }

    static func == (lhs: AppItem, rhs: AppItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum ByteFormat {
    nonisolated(unsafe) static let formatter: ByteCountFormatter = {
        let f = ByteCountFormatter()
        f.countStyle = .file
        return f
    }()

    static func string(_ bytes: Int64) -> String {
        formatter.string(fromByteCount: bytes)
    }
}
