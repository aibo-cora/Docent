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
        
        // 1. Try to find the DocentDocs directory by scanning input files
        var docsURL: URL? = nil
        
        for fileURL in inputFiles {
            if fileURL.lastPathComponent.lowercased() == "docentdocs" {
                docsURL = fileURL
                break
            }
            if fileURL.pathExtension.lowercased() == "md" {
                var current = fileURL
                while current.path.count > inputDirectory.path.count {
                    current = current.deletingLastPathComponent()
                    if current.lastPathComponent.lowercased() == "docentdocs" {
                        docsURL = current
                        break
                    }
                }
            }
            if docsURL != nil { break }
        }
        
        // Fallback
        if docsURL == nil {
            let candidate = inputDirectory.appendingPathComponent("DocentDocs")
            if fileManager.fileExists(atPath: candidate.path) {
                docsURL = candidate
            }
        }
        
        guard let finalDocsURL = docsURL else {
            return []
        }
        
        let outputFileURL = outputDirectory.appendingPathComponent("Knowledge.docent")
        
        // 2. Find all .md files for incremental tracking
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
