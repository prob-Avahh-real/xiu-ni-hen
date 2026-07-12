// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "OdorWatch",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "OdorWatch", targets: ["OdorWatch"]),
        .executable(name: "OdorWatchApp", targets: ["OdorWatchApp"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "OdorWatch",
            path: "Sources/OdorWatch",
            exclude: ["App"]
        ),
        .executableTarget(
            name: "OdorWatchApp",
            dependencies: ["OdorWatch"],
            path: "Sources/OdorWatch/App"
        ),
        .testTarget(
            name: "OdorWatchTests",
            dependencies: ["OdorWatch"],
            path: "Tests/OdorWatchTests"
        ),
    ]
)
