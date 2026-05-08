// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Docent",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "Docent", targets: ["Docent"]),
        .library(name: "DocentUI", targets: ["DocentUI"]),
        .library(name: "DocentSQLCipher", targets: ["DocentSQLCipher"]),
        .executable(name: "DocentCompiler", targets: ["DocentCompiler"]),
        .plugin(name: "DocentPlugin", targets: ["DocentPlugin"]),
        .plugin(name: "DocentInit", targets: ["DocentInit"])
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3"),
        .package(url: "https://github.com/apple/swift-syntax.git", from: "600.0.1"),
    ],
    targets: [
        .target(
            name: "Docent",
            dependencies: [],
            path: "Sources/Docent"
        ),
        .target(
            name: "DocentScraper",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax")
            ],
            path: "Sources/DocentScraper"
        ),
        .target(
            name: "DocentSQLCipher",
            dependencies: [
                "Docent",
                .product(name: "SQLite", package: "SQLite.swift")
            ],
            path: "Sources/DocentSQLCipher",
            swiftSettings: [.define("DOCENT_SQLCIPHER")]
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
        .plugin(
            name: "DocentInit",
            capability: .command(
                intent: .custom(verb: "docent-init", description: "Initializes the DocentDocs folder with sample documentation."),
                permissions: [.writeToPackageDirectory(reason: "Docent needs to create the DocentDocs folder and a sample Welcome.md file.")]
            )
        ),
        .testTarget(
            name: "DocentTests",
            dependencies: ["Docent"]
        ),
    ]
)
