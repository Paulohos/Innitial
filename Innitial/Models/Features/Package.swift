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
            name: "Home",
            targets: ["Home"]
        ),
    ],
    dependencies: [
        .package(path: "../AppConfiguration"),
        .package(path: "../Connectivity"),
        .package(path: "../Database"),
        .package(path: "../DesignSystem"),
        .package(path: "../Services"),
        .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Home",
            dependencies: [
                .product(name: "AppConfiguration", package: "AppConfiguration"),
                .product(name: "Connectivity", package: "Connectivity"),
                .product(name: "LocalStorageService", package: "Database"),
                .product(name: "DesignSystem", package: "DesignSystem"),
                .product(name: "MovieListService", package: "Services"),
                .product(name: "MoviesService", package: "Services"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
        .testTarget(
            name: "FeaturesTests",
            dependencies: [
                "Home",
                .product(name: "AppConfiguration", package: "AppConfiguration"),
                .product(name: "Connectivity", package: "Connectivity"),
                .product(name: "MovieListService", package: "Services"),
                .product(name: "MoviesService", package: "Services"),
                .product(name: "Dependencies", package: "swift-dependencies"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
