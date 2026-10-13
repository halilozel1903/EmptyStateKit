// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "EmptyStateKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(name: "EmptyStateKit", targets: ["EmptyStateKit"]),
    ],
    targets: [
        .target(name: "EmptyStateKit"),
        .testTarget(name: "EmptyStateKitTests", dependencies: ["EmptyStateKit"]),
    ]
)
