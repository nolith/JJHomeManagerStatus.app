// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "HomeManagerStatus",
  platforms: [
    .macOS(.v13)
  ],
  products: [
    .library(name: "HMStatus", targets: ["HMStatus"])
  ],
  targets: [
    // Cross-platform library — pure Foundation, no Apple frameworks
    .target(
      name: "HMStatus",
      path: "Sources/HMStatus"
    ),
    // macOS menu bar app
    .executableTarget(
      name: "HomeManagerStatus",
      dependencies: ["HMStatus"],
      path: "Sources/HomeManagerStatus"
    ),
    // Cross-platform tests for the library
    .testTarget(
      name: "HMStatusTests",
      dependencies: ["HMStatus"],
      path: "Tests/HMStatusTests"
    ),
  ]
)
