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
                breadcrumb TEXT,
                content BLOB,
                encryption_type INTEGER DEFAULT 0,
                nonce BLOB,
                priority REAL DEFAULT 1.0,
                tags TEXT
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
        let (metadata, markdown) = extractFrontmatter(content)
        let chunks = parseMarkdown(markdown, fileMetadata: metadata)
        
        for chunk in chunks {
            try insertChunk(chunk, relativePath: relativePath, db: db)
        }
    }

    private func extractFrontmatter(_ text: String) -> (FileMetadata, String) {
        let lines = text.components(separatedBy: .newlines)
        guard lines.first?.trimmingCharacters(in: .whitespaces) == "---" else {
            return (FileMetadata(), text)
        }
        
        var frontmatter: [String] = []
        var content: [String] = []
        var inFrontmatter = true
        
        for (index, line) in lines.enumerated() {
            if index == 0 { continue }
            if inFrontmatter {
                if line.trimmingCharacters(in: .whitespaces) == "---" {
                    inFrontmatter = false
                } else {
                    frontmatter.append(line)
                }
            } else {
                content.append(line)
            }
        }
        
        var metadata = FileMetadata()
        for line in frontmatter {
            let parts = line.components(separatedBy: ":")
            if parts.count >= 2 {
                let key = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
                let value = parts.dropFirst().joined(separator: ":").trimmingCharacters(in: .whitespaces)
                
                switch key {
                case "title": metadata.title = value
                case "tags": metadata.tags = value
                case "priority": metadata.priority = Double(value) ?? 1.0
                default: break
                }
            }
        }
        
        return (metadata, content.joined(separator: "\n"))
    }

    private func parseMarkdown(_ text: String, fileMetadata: FileMetadata) -> [RawChunk] {
        var chunks: [RawChunk] = []
        let lines = text.components(separatedBy: .newlines)
        
        var headerStack: [(level: Int, title: String)] = []
        var currentBody: [String] = []
        
        func createChunk() {
            guard !currentBody.isEmpty, !headerStack.isEmpty else { return }
            let breadcrumb = headerStack.map { $0.title }.joined(separator: " > ")
            let title = headerStack.last!.title
            // Context injection: Prepend breadcrumb to body for better embedding
            let contextBody = "\(breadcrumb): " + currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            
            chunks.append(RawChunk(
                title: title,
                breadcrumb: breadcrumb,
                body: contextBody,
                priority: fileMetadata.priority,
                tags: fileMetadata.tags
            ))
            currentBody = []
        }

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("#") {
                let level = trimmed.prefix(while: { $0 == "#" }).count
                let title = trimmed.replacingOccurrences(of: String(repeating: "#", count: level), with: "").trimmingCharacters(in: .whitespaces)
                
                if level <= 3 { // We support up to ###
                    createChunk()
                    
                    // Pop stack if new level is higher or equal
                    while let last = headerStack.last, last.level >= level {
                        headerStack.removeLast()
                    }
                    headerStack.append((level, title))
                }
            } else {
                currentBody.append(line)
            }
        }
        
        createChunk()
        
        // If no headers were found, treat the whole file as one chunk
        if chunks.isEmpty && !currentBody.isEmpty {
            chunks.append(RawChunk(
                title: fileMetadata.title ?? "General",
                breadcrumb: fileMetadata.title ?? "General",
                body: currentBody.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines),
                priority: fileMetadata.priority,
                tags: fileMetadata.tags
            ))
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
        
        let chunkSql = "INSERT INTO docent_chunks (file_path, title, breadcrumb, content, encryption_type, priority, tags) VALUES (?, ?, ?, ?, ?, ?, ?);"
        let chunkStmt = try db.prepare(sql: chunkSql)
        
        sqlite3_bind_text(chunkStmt, 1, (relativePath as NSString).utf8String, -1, nil)
        sqlite3_bind_text(chunkStmt, 2, (chunk.title as NSString).utf8String, -1, nil)
        sqlite3_bind_text(chunkStmt, 3, (chunk.breadcrumb as NSString).utf8String, -1, nil)
        
        contentData.withUnsafeBytes { buf in
            sqlite3_bind_blob(chunkStmt, 4, buf.baseAddress, Int32(contentData.count), nil)
        }
        sqlite3_bind_int(chunkStmt, 5, Int32(encryptionType))
        sqlite3_bind_double(chunkStmt, 6, chunk.priority)
        
        if let tags = chunk.tags {
            sqlite3_bind_text(chunkStmt, 7, (tags as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(chunkStmt, 7)
        }
        
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
    let breadcrumb: String
    let body: String
    let priority: Double
    let tags: String?
}

struct FileMetadata {
    var title: String?
    var tags: String?
    var priority: Double = 1.0
}
