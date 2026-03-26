// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "DoorsPackages",
    defaultLocalization: "en",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "CoreNetwork", targets: ["CoreNetwork"]),
        .library(name: "BLEKit", targets: ["BLEKit"]),
        .library(name: "DomainKit", targets: ["DomainKit"]),
        .library(name: "DesignSystemKit", targets: ["DesignSystemKit"]),
        .library(name: "AuthFeature", targets: ["AuthFeature"]),
        .library(name: "DoorsFeature", targets: ["DoorsFeature"]),
        .library(name: "EventsFeature", targets: ["EventsFeature"])
    ],
    targets: [
        .target(name: "CoreNetwork", path: "Sources/CoreNetwork"),
        .target(name: "BLEKit", path: "Sources/BLEKit"),
        .target(name: "DomainKit", dependencies: ["CoreNetwork"], path: "Sources/DomainKit"),
        .target(name: "DesignSystemKit", path: "Sources/DesignSystemKit"),
        .target(
            name: "AuthFeature",
            dependencies: ["DomainKit", "DesignSystemKit"],
            path: "Sources/AuthFeature",
            resources: [.process("Resources")]
        ),
        .target(
            name: "DoorsFeature",
            dependencies: ["DomainKit", "DesignSystemKit"],
            path: "Sources/DoorsFeature",
            resources: [.process("Resources")]
        ),
        .target(
            name: "EventsFeature",
            dependencies: ["DomainKit", "BLEKit", "DesignSystemKit"],
            path: "Sources/EventsFeature",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "DoorsPackagesTests",
            dependencies: ["CoreNetwork", "DomainKit", "BLEKit", "AuthFeature", "DoorsFeature", "EventsFeature"],
            path: "Tests/DoorsPackagesTests"
        )
    ]
)
