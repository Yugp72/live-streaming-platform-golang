// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "EventSubscriber",
    platforms: [
        .macOS(.v13)
    ],
    dependencies: [
        .package(path: "../../messaging-engine")
    ],
    targets: [
        .executableTarget(
            name: "EventSubscriber",
            dependencies: [
                .product(name: "MessagingEngine", package: "messaging-engine")
            ]
        )
    ]
)

