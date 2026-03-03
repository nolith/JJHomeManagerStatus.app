// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "HomeManagerStatus",
    platforms: [
        .macOS(.v14),
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-testing.git", branch: "release/6.2"),
    ],
    targets: [
        .executableTarget(
            name: "HomeManagerStatus",
            path: "Sources/HomeManagerStatus"
        ),
        .testTarget(
            name: "HomeManagerStatusTests",
            dependencies: [
                "HomeManagerStatus",
                .product(name: "Testing", package: "swift-testing"),
            ],
            path: "Tests/HomeManagerStatusTests"
        ),
    ]
)
