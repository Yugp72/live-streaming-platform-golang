// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MessagingEngine",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MessagingEngine",
            targets: ["MessagingEngine"]),
        .executable(
            name: "MessagingServer",
            targets: ["MessagingServer"]),
        .executable(
            name: "MessagingClient",
            targets: ["MessagingClient"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "MessagingEngine",
            dependencies: []),
        .executableTarget(
            name: "MessagingServer",
            dependencies: ["MessagingEngine"]),
        .executableTarget(
            name: "MessagingClient",
            dependencies: ["MessagingEngine"]),
        .testTarget(
            name: "MessagingEngineTests",
            dependencies: ["MessagingEngine"]),
    ]
)

