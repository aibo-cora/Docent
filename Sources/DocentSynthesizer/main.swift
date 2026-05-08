import Foundation
import Docent
import DocentScraper

@main
struct DocentSynthesizer {
    static func main() async {
        let args = ProcessInfo.processInfo.arguments
        guard args.count >= 3 else {
            print("Usage: docent-synthesizer <source_folder> <output_folder>")
            return
        }
        
        let sourceFolder = args[1]
        let outputFolder = args[2]
        // The plugin now passes the sandbox output directory
        let generatedFolder = URL(fileURLWithPath: outputFolder).appendingPathComponent("Generated")
        
        print("🤖 Docent Synthesizer starting...")
        print("📁 Output: \(generatedFolder.path)")
        
        do {
            try FileManager.default.createDirectory(at: generatedFolder, withIntermediateDirectories: true)
            
            let sourceFiles = try findSwiftFiles(at: sourceFolder)
            var totalSynthesized = 0
            
            for fileURL in sourceFiles {
                let code = try String(contentsOf: fileURL)
                let contexts = KnowledgeScraper.scrape(source: code)
                
                for context in contexts {
                    print("  Synthesizing guide for: \(context.topic)...")
                    let markdown = try await synthesize(context: context)
                    
                    let safeFilename = context.topic.replacingOccurrences(of: " ", with: "_") + ".md"
                    let outputURL = generatedFolder.appendingPathComponent(safeFilename)
                    
                    try markdown.write(to: outputURL, atomically: true, encoding: .utf8)
                    totalSynthesized += 1
                }
            }
            
            // Stable anchor for build system
            let timestampURL = outputFolder.hasSuffix("/") ? 
                URL(fileURLWithPath: outputFolder + "generated.timestamp") :
                URL(fileURLWithPath: outputFolder).appendingPathComponent("generated.timestamp")
            
            try "\(Date().timeIntervalSince1970)".write(to: timestampURL, atomically: true, encoding: .utf8)
            
            print("✅ Synthesis complete! Generated \(totalSynthesized) guides.")
        } catch {
            print("error: \(error.localizedDescription)")
            exit(1)
        }
    }
    
    static func synthesize(context: KnowledgeContext) async throws -> String {
        let prompt = "Synthesizing \(context.topic)"
        return simulateAppleIntelligence(context: context, prompt: prompt)
    }
    
    static func simulateAppleIntelligence(context: KnowledgeContext, prompt: String) -> String {
        let threshold = context.constants["threshold"] ?? "3"
        let total = context.constants["totalShares"] ?? "5"
        
        return """
        # \(context.topic)
        
        ## What is it?
        \(context.topic) is a secure feature automatically documented by Docent Autopilot.
        
        ## How it works
        This implementation uses a threshold of **\(threshold)** out of **\(total)** total pieces.
        
        ## Technical Details
        - Methods: \(context.methods.joined(separator: ", "))
        - Note: \(context.comments.first ?? "Conceptual guide generated from source.")
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
