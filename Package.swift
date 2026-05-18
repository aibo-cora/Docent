// swift-tools-version: 6.0
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "Docent",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "Docent", targets: ["Docent"]),
        .library(name: "DocentUI", targets: ["DocentUI"]),
        .library(name: "DocentSQLCipher", targets: ["DocentSQLCipher"]),
        .library(name: "DocentMacros", targets: ["DocentMacros"]),
        .executable(name: "DocentCompiler", targets: ["DocentCompiler"]),
        .executable(name: "DocentValidator", targets: ["DocentValidator"]),
        .plugin(name: "DocentPlugin", targets: ["DocentPlugin"]),
        .plugin(name: "DocentInit", targets: ["DocentInit"])
    ],
    dependencies: [
        .package(url: "https://github.com/stephencelis/SQLite.swift.git", from: "0.15.3"),
        .package(url: "https://github.com/apple/swift-syntax.git", "509.0.0"..<"601.0.0"),
    ],
    targets: [
        .macro(
            name: "DocentMacrosCompilerPlugin",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Sources/DocentMacrosCompilerPlugin"
        ),
        .target(
            name: "DocentMacros",
            dependencies: ["DocentMacrosCompilerPlugin"],
            path: "Sources/DocentMacros"
        ),
        .target(
            name: "DocentCore",
            dependencies: [],
            path: "Sources/DocentCore"
        ),
        .target(
            name: "Docent",
            dependencies: ["DocentCore", "DocentMacros"],
            path: "Sources/Docent",
            plugins: [.plugin(name: "DocentPlugin")]
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
                "DocentCore",
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
            dependencies: ["DocentCore"],
            path: "Sources/DocentCompiler"
        ),
        .executableTarget(
            name: "DocentSynthesizer",
            dependencies: ["DocentCore", "DocentScraper"],
            path: "Sources/DocentSynthesizer"
        ),
        .executableTarget(
            name: "CheckFoundationModels",
            dependencies: [],
            path: "Sources/CheckFoundationModels"
        ),
        .executableTarget(
            name: "DocentValidator",
            dependencies: [],
            path: "Sources/DocentValidator"
        ),
        .executableTarget(
            name: "DocentExample",
            dependencies: ["Docent", "DocentUI"],
            path: "Sources/DocentExample",
            resources: [.process("DocentDocs")]
        ),
        .plugin(
            name: "DocentPlugin",
            capability: .buildTool(),
            dependencies: ["DocentCompiler", "DocentSynthesizer"]
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
