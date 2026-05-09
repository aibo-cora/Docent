import PackagePlugin
import Foundation
#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin
#endif

@main
struct DocentPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
        print("info: [DocentPlugin] Triggered for target: \(target.name)")
        return try buildCommands(
            inputDirectory: context.package.directoryURL,
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
        print("info: [DocentPlugin] Triggered for Xcode target: \(target.displayName)")
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
        
        if docsURL == nil {
             // Hardcoded fallback for the current repo structure to force a working state
             let srcCandidate = inputDirectory.appendingPathComponent("Sources").appendingPathComponent("Docent").appendingPathComponent("DocentDocs")
             if fileManager.fileExists(atPath: srcCandidate.path) {
                 docsURL = srcCandidate
             }
        }
        
        guard let finalDocsURL = docsURL else {
            print("info: [DocentPlugin] No DocentDocs folder found. Skipping.")
            return []
        }
        
        print("info: [DocentPlugin] Using docs folder: \(finalDocsURL.path)")
        
        let knowledgeOutputURL = outputDirectory.appendingPathComponent("Knowledge.docent")
        let generatedDocsWorkURL = outputDirectory.appendingPathComponent("Generated")
        let synthesisAnchorURL = outputDirectory.appendingPathComponent("synthesis.anchor")
        
        // 1.5.0: AI SYNTHESIS PASS
        let synthesisCommand = Command.buildCommand(
            displayName: "Docent Autopilot: Synthesizing Knowledge",
            executable: synthesizerURL,
            arguments: [
                inputDirectory.path, 
                outputDirectory.path
            ],
            inputFiles: inputFiles,
            outputFiles: [synthesisAnchorURL]
        )
        
        // Manual files for incremental tracking
        var manualMarkdownFiles: [URL] = []
        if let enumerator = fileManager.enumerator(at: finalDocsURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles]) {
            while let fileURL = enumerator.nextObject() as? URL {
                if fileURL.pathExtension.lowercased() == "md" {
                    manualMarkdownFiles.append(fileURL)
                }
            }
        }
        
        return [
            synthesisCommand,
            .buildCommand(
                displayName: "[Docent v1.5.0] Compiling Knowledge Base from \(finalDocsURL.lastPathComponent)",
                executable: compilerURL,
                arguments: [
                    finalDocsURL.path,
                    knowledgeOutputURL.path,
                    "--additional-docs", generatedDocsWorkURL.path
                ],
                inputFiles: manualMarkdownFiles + [synthesisAnchorURL],
                outputFiles: [knowledgeOutputURL]
            )
        ]
    }
}
