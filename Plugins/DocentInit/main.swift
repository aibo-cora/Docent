import PackagePlugin
import Foundation

@main
struct DocentInit: CommandPlugin {
    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let projectDir = context.package.directoryURL
        try initializeDocent(at: projectDir)
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension DocentInit: XcodeCommandPlugin {
    func performCommand(context: XcodePluginContext, arguments: [String]) async throws {
        let projectDir = context.xcodeProject.directoryURL
        try initializeDocent(at: projectDir)
    }
}
#endif

extension DocentInit {
    func initializeDocent(at projectDir: URL) throws {
        let fileManager = FileManager.default
        let docsURL = projectDir.appendingPathComponent("DocentDocs")
        
        if !fileManager.fileExists(atPath: docsURL.path) {
            print("Creating DocentDocs folder at \(docsURL.path)...")
            try fileManager.createDirectory(at: docsURL, withIntermediateDirectories: true)
        } else {
            print("DocentDocs folder already exists.")
        }
        
        let welcomeURL = docsURL.appendingPathComponent("Welcome.md")
        if !fileManager.fileExists(atPath: welcomeURL.path) {
            let content = """
            # Welcome to Docent
            
            This folder was automatically created by the `docent-init` command.
            
            ## Getting Started
            1. Add your `.md` files to this folder.
            2. Build your project to generate the search index.
            3. Use `DocentSearch` in your SwiftUI views to enable semantic search.
            
            Happy documenting!
            """
            try content.write(to: welcomeURL, atomically: true, encoding: .utf8)
            print("Created sample Welcome.md.")
        } else {
            print("Welcome.md already exists.")
        }
        
        print("\n✅ Docent initialized successfully!")
    }
}
