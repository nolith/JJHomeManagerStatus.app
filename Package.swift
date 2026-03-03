// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "HomeManagerStatus",
  platforms: [
    .macOS(.v13)
  ],
  targets: [
    .executableTarget(
      name: "HomeManagerStatus",
      path: "Sources/HomeManagerStatus"
    ),
    .testTarget(
      name: "HomeManagerStatusTests",
      dependencies: ["HomeManagerStatus"],
      path: "Tests/HomeManagerStatusTests"
    ),
  ]
)
