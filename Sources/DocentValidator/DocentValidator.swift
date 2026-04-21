import Foundation
import NaturalLanguage

struct Chunk {
    let title: String
    let text: String
}

struct DocentResult {
    let chunk: Chunk
    let score: Double
}

class DocentValidator {
    private let embedding: NLEmbedding?

    init() {
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
        if self.embedding == nil {
            print("Warning: Could not load NLEmbedding for English.")
        }
    }

    func parse(markdown: String) -> [Chunk] {
        var chunks: [Chunk] = []
        let lines = markdown.components(separatedBy: .newlines)
        
        var currentTitle = "Introduction"
        var currentBody: [String] = []
        
        for line in lines {
            if line.hasPrefix("## ") {
                // Save previous chunk
                if !currentBody.isEmpty {
                    chunks.append(Chunk(title: currentTitle, text: currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                currentTitle = line.trimmingCharacters(in: .whitespacesAndNewlines)
                currentBody = []
            } else if !line.hasPrefix("# ") {
                currentBody.append(line)
            }
        }
        
        // Save last chunk
        if !currentBody.isEmpty {
            chunks.append(Chunk(title: currentTitle, text: currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        
        return chunks
    }

    func embed(_ text: String) -> [Double]? {
        guard let embedding = embedding else { return nil }
        return embedding.vector(for: text)
    }

    func cosineSimilarity(_ v1: [Double], _ v2: [Double]) -> Double {
        guard v1.count == v2.count else { return 0 }
        let dotProduct = zip(v1, v2).map(*).reduce(0, +)
        let magnitude1 = sqrt(v1.map { $0 * $0 }.reduce(0, +))
        let magnitude2 = sqrt(v2.map { $0 * $0 }.reduce(0, +))
        guard magnitude1 > 0 && magnitude2 > 0 else { return 0 }
        return dotProduct / (magnitude1 * magnitude2)
    }

    func query(_ queryText: String, in chunks: [Chunk], topK: Int = 3) -> [DocentResult] {
        guard let queryVector = embed(queryText) else { return [] }
        
        var results: [DocentResult] = []
        
        for chunk in chunks {
            if let chunkVector = embed(chunk.text) {
                let score = cosineSimilarity(queryVector, chunkVector)
                results.append(DocentResult(chunk: chunk, score: score))
            }
        }
        
        return results.sorted(by: { $0.score > $1.score }).prefix(topK).map { $0 }
    }
}

@main
struct Main {
    static func main() async {
        let validator = DocentValidator()
        let testDataPath = "TestData"
        let benchmarksPath = "\(testDataPath)/Benchmarks.json"
        
        guard let benchmarksData = try? Data(contentsOf: URL(fileURLWithPath: benchmarksPath)),
              let json = try? JSONSerialization.jsonObject(with: benchmarksData) as? [String: Any],
              let benchmarks = json["benchmarks"] as? [[String: Any]] else {
            print("Error: Could not load Benchmarks.json")
            return
        }
        
        var totalQueries = 0
        var totalCorrectAt3 = 0
        
        print("Starting NLEmbedding Validation...\n")
        
        for benchmark in benchmarks {
            guard let filename = benchmark["file"] as? String,
                  let queries = benchmark["queries"] as? [[String: String]] else { continue }
            
            let filePath = "\(testDataPath)/\(filename)"
            guard let markdown = try? String(contentsOfFile: filePath) else {
                print("Error: Could not read \(filename)")
                continue
            }
            
            let chunks = validator.parse(markdown: markdown)
            var correctCount = 0
            
            print("Evaluating \(filename) (\(chunks.count) chunks)...")
            
            for q in queries {
                guard let queryText = q["q"], let expected = q["expected"] else { continue }
                totalQueries += 1
                
                let results = validator.query(queryText, in: chunks, topK: 3)
                let found = results.contains(where: { $0.chunk.title == expected })
                
                if found {
                    correctCount += 1
                    totalCorrectAt3 += 1
                } else {
                    // print("  [FAIL] Query: '\(queryText)' - Expected: '\(expected)' - Got: '\(results.first?.chunk.title ?? "None")'")
                }
            }
            
            let p3 = Double(correctCount) / Double(queries.count)
            print("  P@3: \(String(format: "%.2f", p3))")
        }
        
        let overallP3 = Double(totalCorrectAt3) / Double(totalQueries)
        print("\n--- Final Report ---")
        print("Total Queries: \(totalQueries)")
        print("Overall P@3:  \(String(format: "%.2f", overallP3))")
        
        if overallP3 >= 0.75 {
            print("RESULT: SUCCESS - NLEmbedding is viable.")
        } else if overallP3 >= 0.6 {
            print("RESULT: WARNING - Quality is borderline. Review chunking/content.")
        } else {
            print("RESULT: FAILURE - NLEmbedding is insufficient.")
        }
    }
}
