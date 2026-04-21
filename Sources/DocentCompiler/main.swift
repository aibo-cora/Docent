import Foundation
import NaturalLanguage
import Docent
import SQLite3

@main
struct DocentCompiler {
    static func main() async {
        let args = ProcessInfo.processInfo.arguments
        guard args.count >= 3 else {
            print("Usage: docent-compiler <input_folder> <output_file> [--key <encryption_key>]")
            return
        }
        
        let inputFolder = args[1]
        let outputFile = args[2]
        
        var encryptionKey: String?
        if let keyIndex = args.firstIndex(of: "--key"), keyIndex + 1 < args.count {
            encryptionKey = args[keyIndex + 1]
        }

        print("🚀 Docent Compiler starting...")
        print("📁 Input: \(inputFolder)")
        print("📄 Output: \(outputFile)")
        
        do {
            let compiler = Compiler(inputPath: inputFolder, outputPath: outputFile, key: encryptionKey)
            try await compiler.run()
            print("✅ Compilation complete!")
        } catch {
            print("error: \(error.localizedDescription)")
            exit(1)
        }
    }
}

class Compiler {
    let inputPath: String
    let outputPath: String
    let encryptionKey: String?
    let embedding: NLEmbedding?
    private var encryptionService: EncryptionService?

    init(inputPath: String, outputPath: String, key: String?) {
        self.inputPath = inputPath
        self.outputPath = outputPath
        self.encryptionKey = key
        self.embedding = NLEmbedding.sentenceEmbedding(for: .english)
        
        if let key = key {
            self.encryptionService = try? EncryptionService(keyData: key.data(using: .utf8)!)
        }
    }

    func run() async throws {
        // 1. Initialize SQLite
        if FileManager.default.fileExists(atPath: outputPath) {
            try FileManager.default.removeItem(atPath: outputPath)
        }
        
        let db = try SQLiteStore(path: outputPath)
        try createSchema(db)

        // 2. Crawl and Process
        let mdFiles = try findMarkdownFiles(at: inputPath)
        print("Found \(mdFiles.count) Markdown files.")

        for fileURL in mdFiles {
            try processFile(fileURL, db: db)
        }

        // 3. Optimize
        print("Optimizing database...")
        try db.execute("PRAGMA journal_mode = DELETE;")
        try db.execute("VACUUM;")
        try db.execute("ANALYZE;")
    }

    private func createSchema(_ db: SQLiteStore) throws {
        try db.execute("""
            CREATE TABLE docent_info (key TEXT PRIMARY KEY, value TEXT);
            INSERT INTO docent_info (key, value) VALUES ('version', '0.5.0');
            INSERT INTO docent_info (key, value) VALUES ('model', 'apple-nl-v1');
            
            CREATE TABLE docent_chunks (
                id INTEGER PRIMARY KEY,
                file_path TEXT,
                title TEXT,
                content BLOB,
                encryption_type INTEGER DEFAULT 0,
                nonce BLOB
            );
            
            CREATE TABLE docent_vectors (
                chunk_id INTEGER PRIMARY KEY,
                vector BLOB,
                dimensions INTEGER,
                FOREIGN KEY(chunk_id) REFERENCES docent_chunks(id)
            );
        """)
    }

    private func findMarkdownFiles(at path: String) throws -> [URL] {
        let url = URL(fileURLWithPath: path)
        var files: [URL] = []
        let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        
        while let fileURL = enumerator?.nextObject() as? URL {
            if fileURL.pathExtension.lowercased() == "md" {
                files.append(fileURL)
            }
        }
        return files
    }

    private func processFile(_ url: URL, db: SQLiteStore) throws {
        let relativePath = url.path.replacingOccurrences(of: URL(fileURLWithPath: inputPath).path + "/", with: "")
        print("  Processing: \(relativePath)")
        
        let content = try String(contentsOf: url)
        let chunks = parseMarkdown(content)
        
        for chunk in chunks {
            try insertChunk(chunk, relativePath: relativePath, db: db)
        }
    }

    private func parseMarkdown(_ text: String) -> [RawChunk] {
        var chunks: [RawChunk] = []
        let lines = text.components(separatedBy: .newlines)
        
        var currentTitle = "Introduction"
        var currentBody: [String] = []
        
        for line in lines {
            if line.hasPrefix("## ") {
                if !currentBody.isEmpty {
                    chunks.append(RawChunk(title: currentTitle, body: currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)))
                }
                currentTitle = line.replacingOccurrences(of: "## ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                currentBody = []
            } else if !line.hasPrefix("# ") {
                currentBody.append(line)
            }
        }
        
        if !currentBody.isEmpty {
            chunks.append(RawChunk(title: currentTitle, body: currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)))
        }
        
        return chunks
    }

    private func insertChunk(_ chunk: RawChunk, relativePath: String, db: SQLiteStore) throws {
        // Validate chunk
        if chunk.body.isEmpty {
            print("warning: Skipping empty chunk in '\(relativePath)' with title '\(chunk.title)'")
            return
        }
        
        // NLEmbedding has limits on sentence/paragraph length. 
        // A rough limit for reliable embedding is ~2000 characters.
        if chunk.body.count > 5000 {
            print("warning: Chunk '\(chunk.title)' in '\(relativePath)' is very large (\(chunk.body.count) chars). Semantic search quality may decrease. Consider splitting with '##' headers.")
        }

        guard let embedding = embedding else {
            print("error: NLEmbedding for English is not available on this system.")
            throw DocentError.embeddingError("NLEmbedding unavailable")
        }
        
        guard let vector = embedding.vector(for: chunk.body) else {
            print("error: Failed to generate embedding vector for chunk '\(chunk.title)' in '\(relativePath)'.")
            return 
        }
        
        let floatVector = vector.map { Float32($0) }
        var vectorData = Data(bytes: floatVector, count: floatVector.count * MemoryLayout<Float32>.size)
        var contentData = chunk.body.data(using: .utf8)!
        var encryptionType = 0

        if let service = encryptionService {
            contentData = try service.encrypt(contentData)
            vectorData = try service.encrypt(vectorData)
            encryptionType = 2
        }
        
        let chunkSql = "INSERT INTO docent_chunks (file_path, title, content, encryption_type) VALUES (?, ?, ?, ?);"
        let chunkStmt = try db.prepare(sql: chunkSql)
        
        sqlite3_bind_text(chunkStmt, 1, (relativePath as NSString).utf8String, -1, nil)
        sqlite3_bind_text(chunkStmt, 2, (chunk.title as NSString).utf8String, -1, nil)
        
        contentData.withUnsafeBytes { buf in
            sqlite3_bind_blob(chunkStmt, 3, buf.baseAddress, Int32(contentData.count), nil)
        }
        sqlite3_bind_int(chunkStmt, 4, Int32(encryptionType))
        
        if sqlite3_step(chunkStmt) != SQLITE_DONE {
            throw DocentError.databaseError("Failed to insert chunk")
        }
        
        let chunkId = db.lastInsertRowId()
        db.finalize(chunkStmt)
        
        // Insert into docent_vectors
        let vectorSql = "INSERT INTO docent_vectors (chunk_id, vector, dimensions) VALUES (?, ?, ?);"
        let vectorStmt = try db.prepare(sql: vectorSql)
        
        sqlite3_bind_int64(vectorStmt, 1, chunkId)
        vectorData.withUnsafeBytes { buf in
            sqlite3_bind_blob(vectorStmt, 2, buf.baseAddress, Int32(vectorData.count), nil)
        }
        sqlite3_bind_int(vectorStmt, 3, Int32(floatVector.count))
        
        if sqlite3_step(vectorStmt) != SQLITE_DONE {
            throw DocentError.databaseError("Failed to insert vector")
        }
        db.finalize(vectorStmt)
    }
}

struct RawChunk {
    let title: String
    let body: String
}
