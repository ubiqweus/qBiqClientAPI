// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "qBiqClientAPI",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "qBiqClientAPI",
            targets: ["qBiqClientAPI"]),
    ],
    dependencies: [
		.package(url: "https://github.com/ubiqweus/qBiqSwiftCodables.git", .branch("master")),
		.package(url: "https://github.com/kjessup/SAuthCodables.git", .branch("master")),
		.package(url: "https://github.com/OAuthSwift/OAuthSwift.git", .branch("master")),
		
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "qBiqClientAPI",
            dependencies: ["SwiftCodables", "SAuthCodables", "OAuthSwift"]),
        .testTarget(
            name: "qBiqClientAPITests",
            dependencies: ["qBiqClientAPI"]),
    ]
)
