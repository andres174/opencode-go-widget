// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "OpenCodeGoWidget",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "OpenCodeGoWidget", targets: ["OpenCodeGoWidget"]),
    ],
    targets: [
        .executableTarget(
            name: "OpenCodeGoWidget",
            path: "Sources/OpenCodeGoWidget"
        ),
        .testTarget(
            name: "OpenCodeGoWidgetTests",
            dependencies: ["OpenCodeGoWidget"],
            path: "Tests/OpenCodeGoWidgetTests"
        ),
    ]
)
