// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ImgPress",
    platforms: [
        .macOS(.v14) 
    ],
    products: [
        .executable(
            name: "ImgPress",
            targets: ["ImgPress"]
        ),
        .library(
            name: "ImgPressCore",
            targets: ["ImgPressCore"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "ImgPressCore",
            dependencies: [],
            path: "ImgPress",
            exclude: ["RebarApp.swift"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .debug))
            ]
        ),
        .executableTarget(
            name: "ImgPress",
            dependencies: ["ImgPressCore"],
            path: "Sources/ImgPressApp",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        ),
        .testTarget(
            name: "ImgPressTests",
            dependencies: ["ImgPressCore"],
            path: "Tests",
            exclude: ["README.md"],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency")
            ]
        )
    ]
)
