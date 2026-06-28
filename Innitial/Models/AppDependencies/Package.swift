// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AppDependencies",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AppDependencies",
            targets: ["AppDependencies"]
        ),
    ],
    dependencies: [
        .package(path: "../AppConfiguration"),
        .package(path: "../Database"),
        .package(path: "../Services"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AppDependencies",
            dependencies: [
                .product(name: "AppConfiguration", package: "AppConfiguration"),
                .product(name: "LocalStoreService", package: "Database"),
                .product(name: "NetworkLayer", package: "Services"),
            ]
        ),
        .testTarget(
            name: "AppDependenciesTests",
            dependencies: ["AppDependencies"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
