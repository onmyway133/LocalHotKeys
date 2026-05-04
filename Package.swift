// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "LocalHotKeys",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "LocalHotKeys", targets: ["LocalHotKeys"]),
    ],
    targets: [
        .target(
            name: "LocalHotKeys"
        ),
    ]
)
