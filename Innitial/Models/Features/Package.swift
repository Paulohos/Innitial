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
            name: "Home",
            targets: ["Home"]
        ),
    ],
    dependencies: [
        .package(path: "../Database"),
        .package(path: "../DesignSystem"),
        .package(path: "../Services"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Features"
        ),
        .target(
            name: "Home",
            dependencies: [
                .product(name: "LocalStoreService", package: "Database"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "MovieListService", package: "Services"),
            ]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: [
                "Features",
                "Home",
                .product(name: "MovieListService", package: "Services"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
