// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "Euclid",
    platforms: [
        .macOS(.v12),
        .iOS(.v15),
        .tvOS(.v15),
        .watchOS(.v9),
        .visionOS("1.3"),
    ],
    products: [
        .library(name: "Euclid", targets: ["Euclid"]),
    ],
    targets: [
        .target(
            name: "Euclid",
            path: "Sources"
        ),
        .testTarget(
            name: "EuclidTests",
            dependencies: ["Euclid"],
            path: "Tests"
        ),
    ]
)
