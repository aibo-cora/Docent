import Foundation
import SQLite3

public class SQLiteStore {
    private var db: OpaquePointer?
    private let path: String

    public init(path: String) throws {
        self.path = path
        if sqlite3_open(path, &db) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            throw DocentError.databaseError("Could not open database at \(path): \(error)")
        }
    }

    deinit {
        sqlite3_close(db)
    }

    public func execute(_ sql: String) throws {
        if sqlite3_exec(db, sql, nil, nil, nil) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            throw DocentError.databaseError("Execution failed: \(error)")
        }
    }

    public func lastInsertRowId() -> Int64 {
        return sqlite3_last_insert_rowid(db)
    }

    public func prepare(sql: String) throws -> OpaquePointer? {
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) != SQLITE_OK {
            let error = String(cString: sqlite3_errmsg(db))
            throw DocentError.databaseError("Prepare failed: \(error)")
        }
        return statement
    }

    public func finalize(_ statement: OpaquePointer?) {
        sqlite3_finalize(statement)
    }
}

public enum DocentError: Error, LocalizedError {
    case databaseError(String)
    case embeddingError(String)
    case encryptionError(String)
    case fileError(String)
    case missingKnowledgeBase

    public var errorDescription: String? {
        switch self {
        case .databaseError(let msg): return "Database Error: \(msg)"
        case .embeddingError(let msg): return "Embedding Error: \(msg)"
        case .encryptionError(let msg): return "Encryption Error: \(msg)"
        case .fileError(let msg): return "File Error: \(msg)"
        }
    }
}
