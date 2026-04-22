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
            toolPath: try context.tool(named: "DocentCompiler").path
        )
    }
}

#if canImport(XcodeProjectPlugin)
extension DocentPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        return try buildCommands(
            inputDirectory: context.xcodeProject.directory,
            outputDirectory: context.pluginWorkDirectory,
            toolPath: try context.tool(named: "DocentCompiler").path
        )
    }
}
#endif

extension DocentPlugin {
    func buildCommands(inputDirectory: Path, outputDirectory: Path, toolPath: Path) throws -> [Command] {
        // We look for a "DocentDocs" folder in the provided directory
        let docsPath = inputDirectory.appending("DocentDocs")
        let fileManager = FileManager.default
        
        // If the folder doesn't exist, we skip
        guard fileManager.fileExists(atPath: docsPath.string) else {
            return []
        }
        
        let outputFile = outputDirectory.appending("Knowledge.docent")
        
        // Find all .md files in the DocentDocs folder
        var markdownFiles: [Path] = []
        let docsURL = URL(fileURLWithPath: docsPath.string)
        
        if let enumerator = fileManager.enumerator(at: docsURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
            while let fileURL = enumerator.nextObject() as? URL {
                if fileURL.pathExtension.lowercased() == "md" {
                    markdownFiles.append(Path(fileURL.path))
                }
            }
        }
        
        // If no markdown files found, no need to run compiler
        guard !markdownFiles.isEmpty else {
            return []
        }
        
        return [
            .buildCommand(
                displayName: "Compiling Docent Knowledge Base",
                executable: toolPath,
                arguments: [
                    docsPath.string,
                    outputFile.string
                ],
                inputFiles: markdownFiles,
                outputFiles: [outputFile]
            )
        ]
    }
}
