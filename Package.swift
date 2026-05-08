// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BestBrowser",
    platforms: [
        .macOS(.v26)
    ],
    products: [
        .executable(
            name: "BestBrowser",
            targets: ["BestBrowser"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.28.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.4.0"),
        .package(url: "https://github.com/Quick/Nimble.git", from: "13.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "BestBrowser",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ],
            path: "BestBrowser",
            resources: [
                .process("Assets.xcassets"),
                .process("BrandingAssets"),
                .process("Features/Extensions/BundledExtensions")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "BestBrowserTests",
            dependencies: ["BestBrowser"],
            path: "Tests/BestBrowserTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
    ]
)
