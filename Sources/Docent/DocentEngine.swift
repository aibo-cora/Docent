import Foundation
import NaturalLanguage
import Accelerate
import SQLite3
import DocentCore

/// Configuration options for the Docent search engine.
public struct DocentSearchConfiguration: Sendable {
    /// How much weight to give the title/breadcrumb match (0.0 to 1.0).
    /// Higher values prioritize exact topic matches.
    public var titleWeight: Float
    
    /// How much weight to give the body content match (0.0 to 1.0).
    /// Higher values prioritize conceptual similarity in the text.
    public var bodyWeight: Float
    
    /// Maximum number of results to return for a single query.
    public var topK: Int
    
    /// The minimum score (0.0 to 1.0) required to label a result as "High" confidence.
    public var highThreshold: Double
    
    /// The minimum score (0.0 to 1.0) required to label a result as "Medium" confidence.
    public var mediumThreshold: Double
    
    /// The minimum score required to show a result at all. 
    /// Matches scoring below this are filtered out entirely.
    public var silenceThreshold: Double
    
    /// Whether to enable in-memory keyword fallback for prefix matching.
    public var enableKeywordFallback: Bool
    
    /// The score boost applied if the query is found in the title or breadcrumb.
    public var keywordTitleBoost: Float
    
    /// The score boost applied if the query is found in the document body.
    public var keywordBodyBoost: Float
    
    /// Optional tags to restrict the search scope. 
    /// Only chunks matching at least one of these tags will be returned.
    public var filterTags: [String]?
    
    public init(
        titleWeight: Float = 0.7,
        bodyWeight: Float = 0.3,
        topK: Int = 5,
        highThreshold: Double = 0.82,
        mediumThreshold: Double = 0.60,
        silenceThreshold: Double = 0.35,
        enableKeywordFallback: Bool = true,
        keywordTitleBoost: Float = 0.4,
        keywordBodyBoost: Float = 0.15,
        filterTags: [String]? = nil
    ) {
        self.titleWeight = titleWeight
        self.bodyWeight = bodyWeight
        self.topK = topK
        self.highThreshold = highThreshold
        self.mediumThreshold = mediumThreshold
        self.silenceThreshold = silenceThreshold
        self.enableKeywordFallback = enableKeywordFallback
        self.keywordTitleBoost = keywordTitleBoost
        self.keywordBodyBoost = keywordBodyBoost
        self.filterTags = filterTags
    }
    
    /// The default configuration used by the Docent engine.
    public static let `default` = DocentSearchConfiguration()
}

/// A single unit of documentation (a "chunk") retrieved from the knowledge base.
public struct DocentChunk: Identifiable, Sendable {
    /// Unique identifier for the chunk.
    public let id: Int64
    /// The specific heading or title for this chunk.
    public let title: String
    /// The full hierarchical path (e.g., "Setup > Installation > Step 1").
    public let breadcrumb: String
    /// The raw text content of the chunk.
    public let text: String
    /// The relative path of the source Markdown file.
    public let sourceFile: String
    /// The priority multiplier applied to this chunk's search score.
    public let priority: Double
    /// Metadata tags associated with this chunk via Frontmatter.
    public let tags: [String]
    
    public init(id: Int64, title: String, breadcrumb: String, text: String, sourceFile: String, priority: Double, tags: [String]) {
        self.id = id
        self.title = title
        self.breadcrumb = breadcrumb
        self.text = text
        self.sourceFile = sourceFile
        self.priority = priority
        self.tags = tags
    }
}

/// A ranked search result containing a chunk and its relevance score.
public struct DocentResult: Identifiable, Sendable {
    public var id: Int64 { chunk.id }
    /// The documentation chunk found.
    public let chunk: DocentChunk
    /// The similarity score (0.0 to 1.0) adjusted by priority and weights.
    public let score: Double
    /// A human-readable confidence level based on the score.
    public let confidence: Confidence
    
    /// Qualitative levels of search confidence.
    public enum Confidence: String, Sendable {
        case high, medium, low
    }
    
    public init(chunk: DocentChunk, score: Double, config: DocentSearchConfiguration = .default) {
        self.chunk = chunk
        self.score = score
        
        if score >= config.highThreshold { self.confidence = .high }
        else if score >= config.mediumThreshold { self.confidence = .medium }
        else { self.confidence = .low }
    }
}

/// Supported encryption methods for the on-device knowledge base.
public enum DocentEncryption: Sendable {
    /// No encryption. The SQLite file is readable by standard tools.
    case none
    /// Content-level encryption using AES-GCM. Protects text and vectors without bundle bloat.
    case cryptoKit(key: String)
    /// Full-file encryption using SQLCipher. Protects the entire database structure.
    case sqlCipher(passphrase: String)
}

/// @docent(topic: "Knowledge Search Engine")
/// This feature allows users to find documentation using natural language.
/// It uses the Accelerate framework for high-speed math.
/// The runtime engine responsible for performing semantic search over the compiled knowledge base.
public actor DocentEngine {
    /// The bundle containing the Docent library resources.
    public static var bundle: Bundle { .module }
    
    /// Finds all bundles that might contain a .docent resource.
    public static func allAvailableBundles() -> [Bundle] {
        var bundles = [Bundle.main, Bundle.module]
        
        // Scan frameworks and plugins
        bundles.append(contentsOf: Bundle.allFrameworks)
        bundles.append(contentsOf: Bundle.allBundles)
        
        // Remove duplicates and return
        return Array(Set(bundles))
    }
    
    private let embedding: NLEmbedding?
    private let store: SQLiteStore
    private var encryptionService: EncryptionService?
    
    /// Initializes a new engine from a bundled resource.
    /// - Parameters:
    ///   - resource: The name of the `.docent` file (e.g., "Knowledge").
    ///   - bundle: The bundle containing the resource. Defaults to `.main`.
    ///   - encryption: The encryption method used during compilation.
    public init(resource: String, bundle: Bundle = .main, encryption: DocentEncryption = .none) throws {
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
        
        guard let path = bundle.path(forResource: resource, ofType: "docent") else {
            throw DocentError.missingKnowledgeBase
        }
        
        var passphrase: String? = nil
        if case .sqlCipher(let pass) = encryption {
            passphrase = pass
        }
        
        self.store = try SQLiteStore(path: path, passphrase: passphrase)
        
        if case .cryptoKit(let key) = encryption {
            self.encryptionService = try? EncryptionService(keyData: key.data(using: .utf8)!)
        }
    }

    /// Initializes a new engine from a direct file path.
    public init(path: String, encryption: DocentEncryption = .none) throws {
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
        
        var passphrase: String? = nil
        if case .sqlCipher(let pass) = encryption {
            passphrase = pass
        }
        
        self.store = try SQLiteStore(path: path, passphrase: passphrase)
        
        if case .cryptoKit(let key) = encryption {
            self.encryptionService = try? EncryptionService(keyData: key.data(using: .utf8)!)
        }
    }
    
    /// Performs a semantic search over the knowledge base.
    /// - Parameters:
    ///   - text: The natural language query from the user.
    ///   - configuration: Optional search parameters.
    /// - Returns: A ranked list of matching results.
    public func query(_ text: String, configuration: DocentSearchConfiguration = .default) async throws -> [DocentResult] {
        guard let embedding = embedding, let queryVector = embedding.vector(for: text) else {
            return []
        }
        
        let queryFloatVector = queryVector.map { Float($0) }
        let chunks = try loadAllChunks()
        let vectors = try loadAllVectors()
        
        var results: [DocentResult] = []
        
        for (chunkId, (titleVector, bodyVector)) in vectors {
            guard let chunk = chunks[chunkId] else { continue }
            
            // 1. Apply Tag Filtering
            if let filterTags = configuration.filterTags, !filterTags.isEmpty {
                let hasMatch = filterTags.contains { tag in chunk.tags.contains(tag) }
                if !hasMatch { continue }
            }
            
            // 2. Multi-Vector Scoring
            let titleScore = cosineSimilarity(queryFloatVector, titleVector)
            let bodyScore = cosineSimilarity(queryFloatVector, bodyVector)
            
            var weightedScore = (titleScore * configuration.titleWeight) + (bodyScore * configuration.bodyWeight)
            
            // 3. Keyword Fallback (Hybrid Search)
            if configuration.enableKeywordFallback {
                let queryLower = text.lowercased()
                if chunk.title.lowercased().contains(queryLower) || 
                   chunk.breadcrumb.lowercased().contains(queryLower) {
                    weightedScore += configuration.keywordTitleBoost
                } else if chunk.text.lowercased().contains(queryLower) {
                    weightedScore += configuration.keywordBodyBoost
                }
            }
            
            let finalScore = weightedScore * Float(chunk.priority)
            
            // 4. Silence Threshold
            if Double(finalScore) < configuration.silenceThreshold { continue }
            
            results.append(DocentResult(chunk: chunk, score: Double(min(finalScore, 1.0)), config: configuration))
        }
        
        return results.sorted(by: { $0.score > $1.score }).prefix(configuration.topK).map { $0 }
    }
    
    private func loadAllChunks() throws -> [Int64: DocentChunk] {
        var chunks: [Int64: DocentChunk] = [:]
        let sql = "SELECT id, title, breadcrumb, content, file_path, encryption_type, priority, tags FROM docent_chunks;"
        let stmt = try store.prepare(sql: sql)
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let title = String(cString: sqlite3_column_text(stmt, 1))
            let breadcrumb = String(cString: sqlite3_column_text(stmt, 2))
            
            let contentPtr = sqlite3_column_blob(stmt, 3)
            let contentLen = sqlite3_column_bytes(stmt, 3)
            var contentData = Data(bytes: contentPtr!, count: Int(contentLen))
            
            let filePath = String(cString: sqlite3_column_text(stmt, 4))
            let encryptionType = sqlite3_column_int(stmt, 5)
            let priority = sqlite3_column_double(stmt, 6)
            
            let tagsPtr = sqlite3_column_text(stmt, 7)
            let tagsString = tagsPtr != nil ? String(cString: tagsPtr!) : ""
            let tags = tagsString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            
            if encryptionType == 2, let service = encryptionService {
                contentData = try service.decrypt(combinedData: contentData)
            }
            
            let content = String(data: contentData, encoding: .utf8) ?? ""
            chunks[id] = DocentChunk(id: id, title: title, breadcrumb: breadcrumb, text: content, sourceFile: filePath, priority: priority, tags: tags)
        }
        store.finalize(stmt)
        return chunks
    }
    
    private func loadAllVectors() throws -> [Int64: (title: [Float], body: [Float])] {
        var vectors: [Int64: (title: [Float], body: [Float])] = [:]
        let sql = """
            SELECT v.chunk_id, v.title_vector, v.body_vector, v.dimensions, c.encryption_type 
            FROM docent_vectors v
            JOIN docent_chunks c ON v.chunk_id = c.id;
        """
        let stmt = try store.prepare(sql: sql)
        
        while sqlite3_step(stmt) == SQLITE_ROW {
            let chunkId = sqlite3_column_int64(stmt, 0)
            let dimensions = sqlite3_column_int(stmt, 3)
            let encryptionType = sqlite3_column_int(stmt, 4)
            
            func getVector(at index: Int32) throws -> [Float] {
                let ptr = sqlite3_column_blob(stmt, index)
                let len = sqlite3_column_bytes(stmt, index)
                var data = Data(bytes: ptr!, count: Int(len))
                
                if encryptionType == 2, let service = encryptionService {
                    data = try service.decrypt(combinedData: data)
                }
                
                return data.withUnsafeBytes { buffer -> [Float] in
                    let floatPtr = buffer.baseAddress!.assumingMemoryBound(to: Float.self)
                    return Array(UnsafeBufferPointer(start: floatPtr, count: Int(dimensions)))
                }
            }
            
            let titleVector = try getVector(at: 1)
            let bodyVector = try getVector(at: 2)
            
            vectors[chunkId] = (title: titleVector, body: bodyVector)
        }
        store.finalize(stmt)
        return vectors
    }
    
    private func cosineSimilarity(_ v1: [Float], _ v2: [Float]) -> Float {
        var dotProduct: Float = 0
        vDSP_dotpr(v1, 1, v2, 1, &dotProduct, vDSP_Length(v1.count))
        
        var v1SumSq: Float = 0
        vDSP_svesq(v1, 1, &v1SumSq, vDSP_Length(v1.count))
        
        var v2SumSq: Float = 0
        vDSP_svesq(v2, 1, &v2SumSq, vDSP_Length(v2.count))
        
        return dotProduct / (sqrt(v1SumSq) * sqrt(v2SumSq))
    }
}
 
/// @docent(topic: "Accelerate Math")
/// This implementation uses high-performance vector math via the Accelerate framework.
extension DocentEngine {
    // Math logic
}
