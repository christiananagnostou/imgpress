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
            targets: ["ImgPressCore"]
        )
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ImgPressCore",
            dependencies: [],
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .debug)),
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
        ),
    ]
)
