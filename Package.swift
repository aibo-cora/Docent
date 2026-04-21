// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Docent",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "Docent", targets: ["Docent"]),
        .executable(name: "docent-compiler", targets: ["DocentCompiler"]),
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
        .executableTarget(
            name: "DocentCompiler",
            dependencies: ["Docent"],
            path: "Sources/DocentCompiler"
        ),
        .plugin(
            name: "DocentPlugin",
            capability: .buildTool(),
            dependencies: ["DocentCompiler"],
            path: "Sources/DocentPlugin"
        ),
        .testTarget(
            name: "DocentTests",
            dependencies: ["Docent"]
        ),
    ]
)
