// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StreamingDashboard",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "../../messaging-engine")
    ],
    targets: [
        .executableTarget(
            name: "StreamingDashboard",
            dependencies: [
                .product(name: "MessagingEngine", package: "messaging-engine")
            ]
        )
    ]
)

