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
            compilerURL: try context.tool(named: "DocentCompiler").url,
            synthesizerURL: try context.tool(named: "DocentSynthesizer").url,
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
            compilerURL: try context.tool(named: "DocentCompiler").url,
            synthesizerURL: try context.tool(named: "DocentSynthesizer").url,
            inputFiles: target.inputFiles.map { $0.url }
        )
    }
}
#endif

extension DocentPlugin {
    func buildCommands(inputDirectory: URL, outputDirectory: URL, compilerURL: URL, synthesizerURL: URL, inputFiles: [URL]) throws -> [Command] {
        let fileManager = FileManager.default
        
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
            }
        }
        
        guard let finalDocsURL = docsURL else { return [] }
        
        let knowledgeOutputURL = outputDirectory.appendingPathComponent("Knowledge.docent")
        let timestampURL = outputDirectory.appendingPathComponent("generated.timestamp")
        let generatedDocsWorkURL = outputDirectory.appendingPathComponent("Generated")
        
        // 1.5.0: AI SYNTHESIS PASS
        let synthesisCommand = Command.buildCommand(
            displayName: "Synthesizing Documentation via Apple Intelligence",
            executable: synthesizerURL,
            arguments: [
                inputDirectory.path, 
                outputDirectory.path
            ],
            inputFiles: inputFiles,
            outputFiles: [timestampURL]
        )
        
        // 2. COMPILATION PASS
        return [
            synthesisCommand,
            .buildCommand(
                displayName: "Compiling Docent Knowledge Base",
                executable: compilerURL,
                arguments: [
                    finalDocsURL.path,
                    knowledgeOutputURL.path,
                    "--additional-docs", generatedDocsWorkURL.path
                ],
                inputFiles: [timestampURL],
                outputFiles: [knowledgeOutputURL]
            )
        ]
    }
}
