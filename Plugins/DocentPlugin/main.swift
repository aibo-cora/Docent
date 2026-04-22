import PackagePlugin
import Foundation
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
#endif

@main
struct DocentPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        return try buildCommands(
            inputDirectory: target.directory,
            outputDirectory: context.pluginWorkDirectory,
            toolPath: try context.tool(named: "DocentCompiler").path,
            inputFiles: (target as? SourceModuleTarget)?.sourceFiles.map { $0.path } ?? []
        )
    }
}

#if canImport(XcodeProjectPlugin)
extension DocentPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        return try buildCommands(
            inputDirectory: context.xcodeProject.directory,
            outputDirectory: context.pluginWorkDirectory,
            toolPath: try context.tool(named: "DocentCompiler").path,
            inputFiles: target.inputFiles.map { $0.path }
        )
    }
}
#endif

extension DocentPlugin {
    func buildCommands(inputDirectory: Path, outputDirectory: Path, toolPath: Path, inputFiles: [Path]) throws -> [Command] {
        let fileManager = FileManager.default
        
        // 1. Try to find the DocentDocs directory by scanning input files
        // This handles cases where DocentDocs is nested deep in the project
        var docsPath: Path? = nil
        
        for file in inputFiles {
            if file.lastComponent.lowercased() == "docentdocs" {
                docsPath = file
                break
            }
            // Also check if any .md file is inside a DocentDocs folder
            if file.extension?.lowercased() == "md" {
                var current = file
                while current.string.count > inputDirectory.string.count {
                    current = current.removingLastComponent()
                    if current.lastComponent.lowercased() == "docentdocs" {
                        docsPath = current
                        break
                    }
                }
            }
            if docsPath != nil { break }
        }
        
        // Fallback to the old method if discovery failed
        if docsPath == nil {
            let candidate = inputDirectory.appending("DocentDocs")
            if fileManager.fileExists(atPath: candidate.string) {
                docsPath = candidate
            }
        }
        
        guard let finalDocsPath = docsPath else {
            // We return empty here because we don't want to break the build, 
            // but the user will see that Knowledge.docent is missing at runtime.
            return []
        }
        
        let outputFile = outputDirectory.appending("Knowledge.docent")
        
        // 2. Find all .md files for incremental tracking
        var markdownFiles: [Path] = []
        let docsURL = URL(fileURLWithPath: finalDocsPath.string)
        
        if let enumerator = fileManager.enumerator(at: docsURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
            while let fileURL = enumerator.nextObject() as? URL {
                if fileURL.pathExtension.lowercased() == "md" {
                    markdownFiles.append(Path(fileURL.path))
                }
            }
        }
        
        guard !markdownFiles.isEmpty else { return [] }
        
        return [
            .buildCommand(
                displayName: "Compiling Docent Knowledge Base from \(finalDocsPath.lastComponent)",
                executable: toolPath,
                arguments: [
                    finalDocsPath.string,
                    outputFile.string
                ],
                inputFiles: markdownFiles,
                outputFiles: [outputFile]
            )
        ]
    }
}
