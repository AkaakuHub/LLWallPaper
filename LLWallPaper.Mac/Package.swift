// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "LLWallPaperMac",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "LLWallPaperMac", targets: ["LLWallPaperMac"]),
        .library(name: "LLWallPaperMacCore", targets: ["LLWallPaperMacCore"]),
    ],
    targets: [
        .target(
            name: "LLWallPaperMacCore",
            path: "Sources/LLWallPaperMacCore"
        ),
        .executableTarget(
            name: "LLWallPaperMac",
            dependencies: ["LLWallPaperMacCore"],
            path: "Sources/LLWallPaperMac",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "LLWallPaperMacTests",
            dependencies: ["LLWallPaperMacCore"],
            path: "Tests/LLWallPaperMacTests"
        ),
    ]
)
