// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "swift-immutable",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
    products: [
        .library(
            name: "SwiftImmutable",
            targets: ["SwiftImmutable"]
        ),
        .executable(
            name: "SwiftImmutableClient",
            targets: ["SwiftImmutableClient"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .macro(
            name: "SwiftImmutableMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(name: "SwiftImmutable", dependencies: ["SwiftImmutableMacros"]),
        .executableTarget(name: "SwiftImmutableClient", dependencies: ["SwiftImmutable"]),
        .testTarget(
            name: "SwiftImmutableTests",
            dependencies: [
                "SwiftImmutableMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ]
        ),
    ]
)
