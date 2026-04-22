// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Docent",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "Docent", targets: ["Docent"]),
        .library(name: "DocentUI", targets: ["DocentUI"]),
        .executable(name: "DocentCompiler", targets: ["DocentCompiler"]),
        .plugin(name: "DocentPlugin", targets: ["DocentPlugin"])
    ],
    dependencies: [
        // No external dependencies for core, keeping it lightweight.
    ],
    targets: [
        .target(
            name: "Docent",
            dependencies: [],
            path: "Sources/Docent"
        ),
        .target(
            name: "DocentUI",
            dependencies: ["Docent"],
            path: "Sources/DocentUI"
        ),
        .executableTarget(
            name: "DocentCompiler",
            dependencies: ["Docent"],
            path: "Sources/DocentCompiler"
        ),
        .executableTarget(
            name: "DocentExample",
            dependencies: ["Docent", "DocentUI"],
            path: "Sources/DocentExample",
            plugins: [.plugin(name: "DocentPlugin")]
        ),
        .plugin(
            name: "DocentPlugin",
            capability: .buildTool(),
            dependencies: ["DocentCompiler"]
        ),
        .testTarget(
            name: "DocentTests",
            dependencies: ["Docent"]
        ),
    ]
)
