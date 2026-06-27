// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Features",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Features",
            targets: ["Features"]
        ),
        .library(
            name: "Login",
            targets: ["Login"]
        ),
    ],
    dependencies: [
        .package(path: "../Database"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Features"
        ),
        .target(
            name: "Login",
            dependencies: [
                .product(name: "LocalStoreService", package: "Database"),
            ]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: [
                "Features",
                "Login",
                .product(name: "LocalStoreService", package: "Database"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
