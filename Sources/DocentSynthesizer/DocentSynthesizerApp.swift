import Foundation
import DocentCore
import DocentScraper

@main
struct DocentSynthesizerApp {
    static func main() async {
        let args = ProcessInfo.processInfo.arguments
        guard args.count >= 3 else {
            print("Usage: docent-synthesizer <source_folder> <output_folder>")
            return
        }
        
        let sourceFolder = args[1]
        let outputFolder = args[2]
        let generatedFolder = URL(fileURLWithPath: outputFolder).appendingPathComponent("Generated")
        
        print("🤖 Docent Synthesizer starting...")
        
        do {
            try FileManager.default.createDirectory(at: generatedFolder, withIntermediateDirectories: true)
            let sourceFiles = try findSwiftFiles(at: sourceFolder)
            var totalSynthesized = 0
            
            for fileURL in sourceFiles {
                let code = try String(contentsOf: fileURL)
                let contexts = KnowledgeScraper.scrape(source: code)
                
                for context in contexts {
                    print("  Synthesizing guide for: \(context.topic)...")
                    let markdown = await synthesize(context: context)
                    
                    let safeFilename = context.topic.replacingOccurrences(of: " ", with: "_") + ".md"
                    let outputURL = generatedFolder.appendingPathComponent(safeFilename)
                    
                    try markdown.write(to: outputURL, atomically: true, encoding: .utf8)
                    totalSynthesized += 1
                }
            }
            
            let timestampURL = outputFolder.hasSuffix("/") ? 
                URL(fileURLWithPath: outputFolder + "synthesis.anchor") :
                URL(fileURLWithPath: outputFolder).appendingPathComponent("synthesis.anchor")
            
            try "READY".write(to: timestampURL, atomically: true, encoding: .utf8)
            print("✅ Synthesis complete! Generated \(totalSynthesized) guides.")
        } catch {
            print("error: \(error.localizedDescription)")
            exit(1)
        }
    }
    
    /// A truly generic synthesis engine that weaves any code context into a human narrative.
    static func synthesize(context: KnowledgeContext) async -> String {
        let topic = context.topic
        
        // Extract facts
        let constantsSection = context.constants.isEmpty ? "" : "\n### Configuration\n" + context.constants.map { "- **\($0.key)**: \($0.value)" }.joined(separator: "\n")
        
        let methodsSection = context.methods.isEmpty ? "" : "\n### Capabilities\nYou can interact with this feature using the following actions: \(context.methods.joined(separator: ", "))."
        
        let description = context.comments.first ?? "This feature provides specialized logic for your application."
        let technicalHints = context.comments.count > 1 ? "\n\n**Note**: " + context.comments.dropFirst().joined(separator: " ") : ""

        return """
        # \(topic)
        
        ## Overview
        \(topic) is a native capability of this application. \(description)
        \(methodsSection)
        
        ## How it works
        The behavior of this feature is factually determined by the following source-code constraints:
        \(constantsSection)
        \(technicalHints)
        
        ---
        *Self-documented by Docent Autopilot.*
        """
    }

    static func findSwiftFiles(at path: String) throws -> [URL] {
        let url = URL(fileURLWithPath: path)
        var files: [URL] = []
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: path) { return [] }
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension.lowercased() == "swift" {
                files.append(fileURL)
            }
        }
        return files
    }
}
