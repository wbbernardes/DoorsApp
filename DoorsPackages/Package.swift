// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DoorsPackages",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "CoreNetwork", targets: ["CoreNetwork"]),
        .library(name: "DomainKit", targets: ["DomainKit"]),
        .library(name: "AuthFeature", targets: ["AuthFeature"]),
        .library(name: "DoorsFeature", targets: ["DoorsFeature"]),
    ],
    targets: [
        .target(name: "CoreNetwork", path: "Sources/CoreNetwork"),
        .target(name: "DomainKit", dependencies: ["CoreNetwork"], path: "Sources/DomainKit"),
        .target(name: "AuthFeature", dependencies: ["DomainKit"], path: "Sources/AuthFeature"),
        .target(name: "DoorsFeature", dependencies: ["DomainKit"], path: "Sources/DoorsFeature"),
        .testTarget(
            name: "DoorsPackagesTests",
            dependencies: ["CoreNetwork", "DomainKit"],
            path: "Tests/DoorsPackagesTests"
        ),
    ]
)
