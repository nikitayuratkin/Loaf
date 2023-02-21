// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Loaf",
    platforms: [
        .iOS(.v9)
    ],
    products: [
        .library(
            name: "Loaf",
            targets: ["Loaf"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Loaf",
            dependencies: [],
            resources: [
                .process("Resources/Media.xcassets")
            ]
        ),
        .testTarget(
            name: "LoafTests",
            dependencies: ["Loaf"]),
    ]
)
