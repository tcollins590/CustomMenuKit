// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CustomMenuKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "CustomMenuKit",
            targets: ["CustomMenuKit"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CustomMenuKit",
            dependencies: []),
        .testTarget(
            name: "CustomMenuKitTests",
            dependencies: ["CustomMenuKit"]),
    ]
)