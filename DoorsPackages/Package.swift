// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DoorsPackages",
    defaultLocalization: "en",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CoreNetwork", targets: ["CoreNetwork"]),
        .library(name: "BLEKit", targets: ["BLEKit"]),
        .library(name: "DomainKit", targets: ["DomainKit"]),
        .library(name: "AuthFeature", targets: ["AuthFeature"]),
        .library(name: "DoorsFeature", targets: ["DoorsFeature"]),
        .library(name: "EventsFeature", targets: ["EventsFeature"])
    ],
    targets: [
        .target(name: "CoreNetwork", path: "Sources/CoreNetwork"),
        .target(name: "BLEKit", path: "Sources/BLEKit"),
        .target(name: "DomainKit", dependencies: ["CoreNetwork"], path: "Sources/DomainKit"),
        .target(
            name: "AuthFeature",
            dependencies: ["DomainKit"],
            path: "Sources/AuthFeature",
            resources: [.process("Resources")]
        ),
        .target(
            name: "DoorsFeature",
            dependencies: ["DomainKit"],
            path: "Sources/DoorsFeature",
            resources: [.process("Resources")]
        ),
        .target(
            name: "EventsFeature",
            dependencies: ["DomainKit", "BLEKit"],
            path: "Sources/EventsFeature",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "DoorsPackagesTests",
            dependencies: ["CoreNetwork", "DomainKit", "BLEKit"],
            path: "Tests/DoorsPackagesTests"
        )
    ]
)
