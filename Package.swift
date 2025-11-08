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
        )
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "ImgPress",
            dependencies: [],
            path: "Sources/ImgPress",
            swiftSettings: [
                .enableUpcomingFeature("StrictConcurrency"),
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .debug))
            ]
        )
    ]
)
