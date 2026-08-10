// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "Euclid",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v14),
        .tvOS(.v14),
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
