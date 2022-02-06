// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "Euclid",
    products: [
        .library(name: "Euclid", targets: ["Euclid"]),
    ],
    targets: [
        .target(name: "Euclid", path: "Sources"),
        .testTarget(name: "EuclidTests", dependencies: ["Euclid"], path: "Tests"),
    ]
)
