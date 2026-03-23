// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "HDRemove",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "HDRemove", targets: ["HDRemoveApp"])
    ],
    targets: [
        .executableTarget(
            name: "HDRemoveApp",
            path: "Sources"
        )
    ]
)