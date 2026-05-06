import PackagePlugin
import Foundation
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
#endif

@main
struct DocentPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        return try buildCommands(
            inputDirectory: target.directoryURL,
            outputDirectory: context.pluginWorkDirectoryURL,
            toolURL: try context.tool(named: "DocentCompiler").url,
            inputFiles: (target as? SourceModuleTarget)?.sourceFiles.map { $0.url } ?? []
        )
    }
}

#if canImport(XcodeProjectPlugin)
extension DocentPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        return try buildCommands(
            inputDirectory: context.xcodeProject.directoryURL,
            outputDirectory: context.pluginWorkDirectoryURL,
            toolURL: try context.tool(named: "DocentCompiler").url,
            inputFiles: target.inputFiles.map { $0.url }
        )
    }
}
#endif

extension DocentPlugin {
    func buildCommands(inputDirectory: URL, outputDirectory: URL, toolURL: URL, inputFiles: [URL]) throws -> [Command] {
        let fileManager = FileManager.default
        
        // 1. Discovery/Auto-Creation logic
        var docsURL: URL? = nil
        
        // Strategy A: Scan known input files (best for nested structures)
        for fileURL in inputFiles {
            if fileURL.lastPathComponent.lowercased() == "docentdocs" {
                docsURL = fileURL
                break
            }
        }
        
        // Strategy B: Check Target Root and subdirectories
        if docsURL == nil {
            let candidate = inputDirectory.appendingPathComponent("DocentDocs")
            if fileManager.fileExists(atPath: candidate.path) {
                docsURL = candidate
            } else {
                // Try one level deeper for standard Xcode project structures
                let subCandidate = inputDirectory.appendingPathComponent(inputDirectory.lastPathComponent).appendingPathComponent("DocentDocs")
                if fileManager.fileExists(atPath: subCandidate.path) {
                    docsURL = subCandidate
                }
            }
        }
        
        // Strategy C: AUTO-CREATION
        if docsURL == nil {
            // We default to creating it in the inputDirectory (Project Root)
            let newDocsURL = inputDirectory.appendingPathComponent("DocentDocs")
            
            print("info: [Docent] Creating missing DocentDocs folder at \(newDocsURL.path)")
            
            do {
                try fileManager.createDirectory(at: newDocsURL, withIntermediateDirectories: true)
                let welcomeURL = newDocsURL.appendingPathComponent("Welcome.md")
                let welcomeContent = "# Welcome to Docent\n\nAdd your own Markdown files to this folder to build your knowledge base."
                try welcomeContent.write(to: welcomeURL, atomically: true, encoding: .utf8)
                docsURL = newDocsURL
            } catch {
                print("warning: [Docent] Failed to create DocentDocs folder: \(error.localizedDescription)")
            }
        }
        
        guard let finalDocsURL = docsURL else { return [] }
        
        let outputFileURL = outputDirectory.appendingPathComponent("Knowledge.docent")
        
        // 2. Find all .md files
        var markdownFiles: [URL] = []
        if let enumerator = fileManager.enumerator(at: finalDocsURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
            while let fileURL = enumerator.nextObject() as? URL {
                if fileURL.pathExtension.lowercased() == "md" {
                    markdownFiles.append(fileURL)
                }
            }
        }
        
        guard !markdownFiles.isEmpty else { return [] }
        
        return [
            .buildCommand(
                displayName: "Compiling Docent Knowledge Base from \(finalDocsURL.lastPathComponent)",
                executable: toolURL,
                arguments: [
                    finalDocsURL.path,
                    outputFileURL.path
                ],
                inputFiles: markdownFiles,
                outputFiles: [outputFileURL]
            )
        ]
    }
}
