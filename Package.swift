// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "mf64-key-light",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "mf64", targets: ["CLI"]),
        .executable(name: "mf64-settings", targets: ["GUI"]),
    ],
    targets: [
        .target(name: "Core"),
        .target(
            name: "IO",
            dependencies: ["Core"]
        ),
        .executableTarget(
            name: "CLI",
            dependencies: ["Core", "IO"]
        ),
        .executableTarget(
            name: "GUI",
            dependencies: ["Core", "IO"]
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]
        ),
        .testTarget(
            name: "IOTests",
            dependencies: ["Core", "IO"]
        ),
    ]
)
