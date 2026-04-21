import PackagePlugin
import Foundation

@main
struct DocentPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        guard let sourceTarget = target as? SourceModuleTarget else { return [] }
        
        let outputDirectory = context.pluginWorkDirectory
        let outputFile = outputDirectory.appending("Knowledge.docent")
        
        // We look for a "DocentDocs" folder in the target's directory
        let docsPath = target.directory.appending("DocentDocs")
        
        // If the folder doesn't exist, we skip but emit a diagnostic
        guard FileManager.default.fileExists(atPath: docsPath.string) else {
            print("warning: DocentDocs folder not found at \(docsPath.string). Documentation will not be indexed for target \(target.name).")
            return []
        }
        
        return [
            .buildCommand(
                displayName: "Compiling Docent Knowledge Base",
                executable: try context.tool(named: "docent-compiler").path,
                arguments: [
                    docsPath.string,
                    outputFile.string
                ],
                inputFiles: [docsPath], // Ideally we'd list all .md files here for incremental support
                outputFiles: [outputFile]
            )
        ]
    }
}
