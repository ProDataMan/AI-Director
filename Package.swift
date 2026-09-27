// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AI-Director",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "StudioCore", targets: ["StudioCore"]),
        .library(name: "OBSKit", targets: ["OBSKit"]),
        .library(name: "StudioDirector", targets: ["StudioDirector"]),
        .library(name: "AIKit", targets: ["AIKit"]),
        .library(name: "RecordingKit", targets: ["RecordingKit"])
    ],
    targets: [
        .target(name: "StudioCore"),
        .target(name: "OBSKit", dependencies: ["StudioCore"]),
        .target(name: "StudioDirector", dependencies: ["StudioCore", "OBSKit", "AIKit", "RecordingKit"]),
        .target(name: "AIKit", dependencies: ["StudioCore"]),
        .target(name: "RecordingKit", dependencies: ["StudioCore"]),
        .testTarget(name: "StudioCoreTests", dependencies: ["StudioCore"]),
        .testTarget(name: "OBSKitTests", dependencies: ["OBSKit", "StudioCore"])
    ]
)
