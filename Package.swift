// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Rebar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "Rebar",
            targets: ["Rebar"]
        )
    ],
    dependencies: [
    ],
    targets: [
        .executableTarget(
            name: "Rebar",
            dependencies: [],
            path: "Sources/Rebar",
            swiftSettings: [
                .unsafeFlags(["-warnings-as-errors"], .when(configuration: .debug))
            ]
        )
    ]
)
