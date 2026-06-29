// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Services",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Services",
            targets: ["Services"]
        ),
        .library(
            name: "NetworkLayer",
            targets: ["NetworkLayer"]
        ),
        .library(
            name: "MovieListService",
            targets: ["MovieListService"]
        ),
        .library(
            name: "Movies",
            targets: ["Movies"]
        ),
    ],
    dependencies: [
        .package(path: "../AppConfiguration"),
        .package(path: "../Database"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "NetworkLayer",
            dependencies: [
                .product(name: "AppConfiguration", package: "AppConfiguration"),
                .product(name: "LocalStoreService", package: "Database"),
            ],
        ),
        .target(
            name: "MovieListService",
            dependencies: [
                "NetworkLayer"
            ],
        ),
        .target(
            name: "Movies",
            dependencies: [
                "NetworkLayer"
            ],
        ),
        .target(
            name: "Services"
        ),
        .testTarget(
            name: "ServicesTests",
            dependencies: ["Services"]
        ),
        .testTarget(
            name: "MoviesTests",
            dependencies: ["Movies"]
        ),
        .testTarget(
            name: "NetworkLayerTests",
            dependencies: [
                "NetworkLayer",
                .product(name: "AppConfiguration", package: "AppConfiguration"),
                .product(name: "LocalStoreService", package: "Database"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
