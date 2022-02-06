// swift-tools-version:5.6
import PackageDescription

let package = Package(
    name: "Euclid",
    products: [
        .library(name: "Euclid", targets: ["Euclid"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        // Swift-DocC Plugin - swift 5.6 ONLY (GitHhub Actions on 1/29/2022 only supports to 5.5)
        .package(url: "https://github.com/apple/swift-docc-plugin", branch: "main"),
    ],
    targets: [
        .target(name: "Euclid", path: "Sources"),
        .testTarget(name: "EuclidTests", dependencies: ["Euclid"], path: "Tests"),
    ]
)
