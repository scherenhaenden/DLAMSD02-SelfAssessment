// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AssessYourself",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AssessYourselfCore",
            targets: ["AssessYourselfCore"]
        )
    ],
    targets: [
        .target(
            name: "AssessYourselfCore",
            path: "src",
            exclude: ["Tests", "App/AssessYourselfApp.swift"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "AssessYourselfCoreTests",
            dependencies: ["AssessYourselfCore"],
            path: "src/Tests"
        )
    ]
)
