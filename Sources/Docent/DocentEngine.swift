import Foundation
import NaturalLanguage
import Accelerate
import SQLite3

public struct DocentChunk: Identifiable, Sendable {
    public let id: Int64
    public let title: String
    public let breadcrumb: String
    public let text: String
    public let sourceFile: String
    public let priority: Double
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

public struct DocentResult: Identifiable, Sendable {
    public var id: Int64 { chunk.id }
    public let chunk: DocentChunk
    public let score: Double
    public let confidence: Confidence
    
    public enum Confidence: String, Sendable {
        case high, medium, low
    }
    
    public init(chunk: DocentChunk, score: Double) {
        self.chunk = chunk
        self.score = score
        
        // Restore stricter confidence for v1.0 (with Title Boosting)
        if score > 0.82 { self.confidence = .high }
        else if score > 0.65 { self.confidence = .medium }
        else { self.confidence = .low }
    }
}

public enum DocentEncryption: Sendable {
    case none
    case cryptoKit(key: String)
}

public actor DocentEngine {
    private let embedding: NLEmbedding?
    private let store: SQLiteStore
    private var encryptionService: EncryptionService?
    
    public init(resource: String, bundle: Bundle = .main, encryption: DocentEncryption = .none) throws {
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
        
        guard let path = bundle.path(forResource: resource, ofType: "docent") else {
            throw DocentError.fileError("Could not find \(resource).docent in bundle")
        }
        
        self.store = try SQLiteStore(path: path)
        
        if case .cryptoKit(let key) = encryption {
            self.encryptionService = try? EncryptionService(keyData: key.data(using: .utf8)!)
        }
    }

    public init(path: String, encryption: DocentEncryption = .none) throws {
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
        self.store = try SQLiteStore(path: path)
        
        if case .cryptoKit(let key) = encryption {
            self.encryptionService = try? EncryptionService(keyData: key.data(using: .utf8)!)
        }
    }
    
    public func query(_ text: String, topK: Int = 3) async throws -> [DocentResult] {
        guard let embedding = embedding, let queryVector = embedding.vector(for: text) else {
            return []
        }
        
        let queryFloatVector = queryVector.map { Float($0) }
        let chunks = try loadAllChunks()
        let vectors = try loadAllVectors()
        
        var results: [DocentResult] = []
        
        for (chunkId, (titleVector, bodyVector)) in vectors {
            guard let chunk = chunks[chunkId] else { continue }
            
            // Compare query against both Title and Body
            let titleScore = cosineSimilarity(queryFloatVector, titleVector)
            let bodyScore = cosineSimilarity(queryFloatVector, bodyVector)
            
            // Weighted average: Title match is usually what user wants
            // 70% Title match, 30% Body match
            let weightedScore = (titleScore * 0.7) + (bodyScore * 0.3)
            
            // Apply priority multiplier
            let finalScore = weightedScore * Float(chunk.priority)
            
            results.append(DocentResult(chunk: chunk, score: Double(min(finalScore, 1.0))))
        }
        
        return results.sorted(by: { $0.score > $1.score }).prefix(topK).map { $0 }
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
                
                return data.withUnsafeBytes { buffer in
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
