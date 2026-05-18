// DocentValidator/main.swift
// Benchmarks NLEmbedding P@3 using triple-vector score fusion:
//   - Title vector, body vector (dual-vector from DocentEngine)
//   - Context vector: concatenated title+body (holistic semantics)
//   - Keyword fallback boost
//   - Final score: blend of dual-vector score + context score
//
// Usage: swift run DocentValidator [path/to/TestData]

import Foundation
import NaturalLanguage
import Accelerate

// MARK: - Models

struct BenchmarkFile: Decodable {
    let file: String
    let queries: [BenchmarkQuery]
}

struct BenchmarkQuery: Decodable {
    let q: String
    let expected: String
}

struct BenchmarkSuite: Decodable {
    let benchmarks: [BenchmarkFile]
}

struct Chunk {
    let header: String
    let body: String
    var titleVector: [Float] = []
    var bodyVector: [Float] = []
    var contextVector: [Float] = []  // concatenated title+body — holistic semantics
}

// MARK: - Scoring

// Dual-vector weights (match DocentEngine defaults)
private let titleWeight: Float = 0.7
private let bodyWeight: Float = 0.3
// Blend: how much weight to give dual-vector vs context vector
// 0.0 = context only, 1.0 = dual-vector only
private let dualWeight: Float = 0.4
private let contextWeight: Float = 0.6

private let keywordTitleBoost: Float = 0.4
private let keywordBodyBoost: Float = 0.15

func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Float {
    guard a.count == b.count, !a.isEmpty else { return 0 }
    var dot: Float = 0
    var normA: Float = 0
    var normB: Float = 0
    vDSP_dotpr(a, 1, b, 1, &dot, vDSP_Length(a.count))
    vDSP_svesq(a, 1, &normA, vDSP_Length(a.count))
    vDSP_svesq(b, 1, &normB, vDSP_Length(b.count))
    let denom = sqrt(normA) * sqrt(normB)
    return denom > 0 ? dot / denom : 0
}

func fusedScore(query: String, queryVec: [Float], chunk: Chunk) -> Float {
    // Dual-vector component (DocentEngine-style)
    let dualScore = (cosineSimilarity(queryVec, chunk.titleVector) * titleWeight)
                  + (cosineSimilarity(queryVec, chunk.bodyVector) * bodyWeight)

    // Context component (holistic title+body embedding)
    let ctxScore = cosineSimilarity(queryVec, chunk.contextVector)

    // Blend the two semantic signals
    var score = (dualScore * dualWeight) + (ctxScore * contextWeight)

    // Keyword boost
    let queryLower = query.lowercased()
    if chunk.header.lowercased().contains(queryLower) {
        score += keywordTitleBoost
    } else if chunk.body.lowercased().contains(queryLower) {
        score += keywordBodyBoost
    }

    return score
}

// MARK: - Parsing

func parseChunks(from markdown: String) -> [Chunk] {
    var chunks: [Chunk] = []
    var currentHeader: String? = nil
    var currentLines: [String] = []

    func flush() {
        guard let header = currentHeader else { return }
        let body = currentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        chunks.append(Chunk(header: header, body: body))
        currentLines = []
    }

    for line in markdown.components(separatedBy: .newlines) {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("## ") {
            flush()
            currentHeader = trimmed
        } else if currentHeader != nil {
            currentLines.append(line)
        }
    }
    flush()
    return chunks
}

// MARK: - Main

func main() {
    let args = CommandLine.arguments
    let testDataPath = args.count >= 2 ? args[1] : "./TestData"

    print("╔══════════════════════════════════════════════════════════════╗")
    print("║         Docent — Triple-Vector Fusion P@3 Benchmark          ║")
    print("║  dual(70/30)×0.4 + context×0.6 + keyword boost              ║")
    print("╚══════════════════════════════════════════════════════════════╝")
    print("📁 TestData: \(testDataPath)")
    print("")

    guard let embedding = NLEmbedding.sentenceEmbedding(for: .english) else {
        print("❌ FATAL: NLEmbedding.sentenceEmbedding(for: .english) returned nil.")
        exit(1)
    }
    print("✅ NLEmbedding model loaded (sentence, english, \(embedding.dimension)d)")
    print("")

    let benchmarkURL = URL(fileURLWithPath: testDataPath).appendingPathComponent("Benchmarks.json")
    guard let benchmarkData = try? Data(contentsOf: benchmarkURL),
          let suite = try? JSONDecoder().decode(BenchmarkSuite.self, from: benchmarkData) else {
        print("❌ FATAL: Could not load Benchmarks.json from \(benchmarkURL.path)")
        exit(1)
    }
    print("📋 Loaded \(suite.benchmarks.count) benchmark files, \(suite.benchmarks.map(\.queries.count).reduce(0, +)) total queries")
    print("")

    var totalQueries = 0
    var totalHits = 0
    var fileResults: [(file: String, p3: Double, hits: Int, total: Int)] = []

    for benchmark in suite.benchmarks {
        let mdURL = URL(fileURLWithPath: testDataPath).appendingPathComponent(benchmark.file)
        guard let markdown = try? String(contentsOf: mdURL, encoding: .utf8) else {
            print("⚠️  Skipping \(benchmark.file) — file not found at \(mdURL.path)")
            continue
        }

        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📄 \(benchmark.file)")

        var chunks = parseChunks(from: markdown)
        guard !chunks.isEmpty else {
            print("   ⚠️  No ## chunks found — skipping")
            continue
        }

        // Embed title, body, and context (title+body) separately
        print("   Embedding \(chunks.count) chunks (title + body + context)...", terminator: "")
        fflush(stdout)
        for i in chunks.indices {
            let titleText = chunks[i].header.replacingOccurrences(of: "## ", with: "")
            if let vec = embedding.vector(for: titleText) {
                chunks[i].titleVector = vec.map { Float($0) }
            }
            if let vec = embedding.vector(for: chunks[i].body) {
                chunks[i].bodyVector = vec.map { Float($0) }
            }
            let contextText = "\(titleText): \(chunks[i].body)"
            if let vec = embedding.vector(for: contextText) {
                chunks[i].contextVector = vec.map { Float($0) }
            }
        }
        print(" done")

        let headers = chunks.map { $0.header }.joined(separator: ", ")
        print("   Chunks: \(headers)")
        print("")

        var fileHits = 0
        var misses: [(q: String, expected: String, got: [String])] = []

        for bq in benchmark.queries {
            guard let queryVec = embedding.vector(for: bq.q) else { continue }
            let queryFloats = queryVec.map { Float($0) }

            let scored = chunks
                .map { chunk -> (header: String, score: Float) in
                    (chunk.header, fusedScore(query: bq.q, queryVec: queryFloats, chunk: chunk))
                }
                .sorted { $0.score > $1.score }

            let top3 = scored.prefix(3).map { $0.header }
            let hit = top3.contains(bq.expected)

            if hit {
                fileHits += 1
            } else {
                misses.append((q: bq.q, expected: bq.expected, got: Array(top3)))
            }
        }

        let fileTotal = benchmark.queries.count
        let p3 = Double(fileHits) / Double(fileTotal)
        fileResults.append((file: benchmark.file, p3: p3, hits: fileHits, total: fileTotal))
        totalHits += fileHits
        totalQueries += fileTotal

        let bar = p3 >= 0.75 ? "✅" : p3 >= 0.60 ? "⚠️ " : "❌"
        print("   \(bar) P@3: \(String(format: "%.1f%%", p3 * 100)) (\(fileHits)/\(fileTotal) hits)")

        if !misses.isEmpty {
            print("   Misses:")
            for miss in misses {
                print("     ✗ \"\(miss.q)\"")
                print("       expected: \(miss.expected)")
                print("       top-3:    \(miss.got.joined(separator: " | "))")
            }
        }
        print("")
    }

    let overall = totalQueries > 0 ? Double(totalHits) / Double(totalQueries) : 0
    print("╔══════════════════════════════════════════════════════════════╗")
    print("║                         RESULTS                             ║")
    print("╠══════════════════════════════════════════════════════════════╣")
    for r in fileResults {
        let bar = r.p3 >= 0.75 ? "✅" : r.p3 >= 0.60 ? "⚠️ " : "❌"
        let name = r.file.padding(toLength: 28, withPad: " ", startingAt: 0)
        print("║  \(bar) \(name) \(String(format: "%5.1f%%", r.p3 * 100)) (\(r.hits)/\(r.total))".padding(toLength: 65, withPad: " ", startingAt: 0) + "║")
    }
    print("╠══════════════════════════════════════════════════════════════╣")

    let overallBar: String
    let verdict: String
    if overall >= 0.75 {
        overallBar = "✅"
        verdict = "PASS — Triple-vector fusion viable. Ship contextWeight to DocentEngine."
    } else if overall >= 0.60 {
        overallBar = "⚠️ "
        verdict = "WARN — Investigate chunking strategy & scoring weights."
    } else {
        overallBar = "❌"
        verdict = "FAIL — Evaluate CoreML fallback or BM25-only retrieval."
    }
    print("║  \(overallBar) OVERALL P@3: \(String(format: "%.1f%%", overall * 100)) (\(totalHits)/\(totalQueries))".padding(toLength: 65, withPad: " ", startingAt: 0) + "║")
    print("╠══════════════════════════════════════════════════════════════╣")
    print("║  \(verdict)".padding(toLength: 65, withPad: " ", startingAt: 0) + "║")
    print("╚══════════════════════════════════════════════════════════════╝")
}

main()
