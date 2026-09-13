// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "SibilClean",
    platforms: [.macOS(.v26)],
    targets: [
        .executableTarget(
            name: "SibilClean",
            path: "Sources/SibilClean"
        )
    ]
)
