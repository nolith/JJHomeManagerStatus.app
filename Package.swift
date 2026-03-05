// swift-tools-version: 5.9

import PackageDescription

var products: [Product] = [
  .library(name: "HMStatus", targets: ["HMStatus"]),
  .executable(name: "hm-status", targets: ["hm-status"]),
]

var targets: [Target] = [
  // Cross-platform library — pure Foundation, no Apple frameworks
  .target(
    name: "HMStatus",
    path: "Sources/HMStatus"
  ),
  // Cross-platform CLI tool
  .executableTarget(
    name: "hm-status",
    dependencies: ["HMStatus"],
    path: "Sources/hm-status"
  ),
]

#if os(macOS)
  targets.append(
    // macOS menu bar app — requires SwiftUI
    .executableTarget(
      name: "HomeManagerStatus",
      dependencies: ["HMStatus"],
      path: "Sources/HomeManagerStatus"
    )
  )
#endif

let package = Package(
  name: "HomeManagerStatus",
  platforms: [
    .macOS(.v13)
  ],
  products: products,
  targets: targets
)
