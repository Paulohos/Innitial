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
        .library(
            name: "Home",
            targets: ["Home"]
        ),
    ],
    dependencies: [
        .package(path: "../Database"),
        .package(path: "../DesignSystem"),
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
        .target(
            name: "Home",
            dependencies: [
                .product(name: "LocalStoreService", package: "Database"),
                .product(name: "DesignSystem", package: "DesignSystem"),
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
