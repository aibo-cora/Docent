import PackagePlugin
import Foundation

@main
struct DocentPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        // We look for a "DocentDocs" folder in the target's directory
        let docsPath = target.directory.appending("DocentDocs")
        let fileManager = FileManager.default
        
        // If the folder doesn't exist, we skip but emit a diagnostic
        guard fileManager.fileExists(atPath: docsPath.string) else {
            // Note: Diagnostics should be emitted via context.diagnostics if available, 
            // but print() usually works for build tools.
            return []
        }
        
        let outputDirectory = context.pluginWorkDirectory
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
                executable: try context.tool(named: "DocentCompiler").path,
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
