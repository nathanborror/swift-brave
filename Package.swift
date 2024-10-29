// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-brave",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
    ],
    products: [
        .library(name: "Brave", targets: ["Brave"]),
        .executable(name: "BraveCmd", targets: ["BraveCmd"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", branch: "main"),
    ],
    targets: [
        .target(name: "Brave"),
        .executableTarget(name: "BraveCmd", dependencies: [
            "Brave",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]),
    ]
)
