// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "BoboMind",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "BoboMind",
            dependencies: [],
            path: "BoboMind",
            resources: [
                .process("Resources")
            ]
        ),
    ]
)
