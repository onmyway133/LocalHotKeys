// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalHotKeys",
    platforms: [.macOS(.v12)],
    products: [
        .library(name: "LocalHotKeys", targets: ["LocalHotKeys"]),
    ],
    targets: [
        .target(name: "LocalHotKeys"),
    ]
)
