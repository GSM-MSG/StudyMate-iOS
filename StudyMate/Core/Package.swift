// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Core",
  platforms: [.iOS(.v17)],
  products: [
    .library(
      name: "CoreDataStack",
      targets: ["CoreDataStack"]
    ),
    .library(
      name: "AIService",
      targets: ["AIService"]
    ),
    .library(
      name: "AnalyticsClient",
      targets: ["AnalyticsClient"]
    )
  ],
  dependencies: [
    .package(path: "../Shared"),
    .package(url: "https://github.com/amplitude/Amplitude-Swift.git", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "CoreDataStack",
      resources: [.process("Resources")]
    ),
    .target(
      name: "AIService",
      dependencies: [
        .product(name: "FirebaseWrapper", package: "Shared")
      ]
    ),
    .target(
      name: "AnalyticsClient",
      dependencies: [
        .product(name: "AmplitudeSwift", package: "Amplitude-Swift"),
        .product(name: "FirebaseWrapper", package: "Shared")
      ]
    )
  ]
)
