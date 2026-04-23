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
        
        for fileURL in inputFiles {
            if fileURL.lastPathComponent.lowercased() == "docentdocs" {
                docsURL = fileURL
                break
            }
        }
        
        if docsURL == nil {
            let candidate = inputDirectory.appendingPathComponent("DocentDocs")
            if fileManager.fileExists(atPath: candidate.path) {
                docsURL = candidate
            } else {
                // AUTO-CREATION: Create the folder if it doesn't exist
                print("info: Creating missing DocentDocs folder at \(candidate.path)")
                try? fileManager.createDirectory(at: candidate, withIntermediateDirectories: true)
                
                // Create a sample file so the compiler has something to work with
                let welcomeURL = candidate.appendingPathComponent("Welcome.md")
                let welcomeContent = "# Welcome to Docent\n\nAdd your own Markdown files to this folder to build your knowledge base."
                try? welcomeContent.write(to: welcomeURL, atomically: true, encoding: .utf8)
                
                docsURL = candidate
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
        
        // If still empty (e.g. creation failed or user deleted the sample), skip
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
