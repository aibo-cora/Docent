# Idea: SQLCipher Integration (Full Database Encryption)

## Concept
Provide an optional, high-security storage tier using **SQLCipher** for full, transparent database encryption at the page level. This complements our existing CryptoKit (column-level) encryption.

## Why SQLCipher?
While CryptoKit is excellent for protecting specific text and vectors without binary bloat, some enterprise and high-compliance apps require the **entire database file** (including SQLite metadata, table structures, and indexes) to be encrypted at rest.

## Modular Architecture (Avoiding Core Bloat)
To maintain Docent's 'Zero-Bloat' promise, SQLCipher will not be part of the core library. Instead, we will use a **Modular Package Structure**:
- **Docent (Core)**: Dependency-free. Uses system SQLite. Supports 'None' and 'CryptoKit' encryption.
- **DocentSQLCipher (Add-on)**: A separate target that brings in the SQLCipher C-library dependency. 

## Technical implementation
1. **Unified Storage Protocol**: Refactor `SQLiteStore` into a protocol so it can be backed by either standard `sqlite3` or `SQLCipher`.
2. **Conditional Compilation**: Use Swift build flags (`-D DOCENT_USE_SQLCIPHER`) to swap the storage engine at compile-time.
3. **Key Management**: Use the same API as CryptoKit but pass the key as a database passphrase during the `sqlite3_open` or `PRAGMA key` phase.

## Developer Experience
Developers who need maximum security simply change one line in their `Package.swift`:
```swift
.product(name: 'DocentSQLCipher', package: 'Docent')
```
And initialize the engine with a passphrase:
```swift
let engine = try DocentEngine(resource: 'Knowledge', encryption: .sqlCipher(passphrase: 'secure-pass'))
```

## Roadmap Position
Targeted for **v1.2**. This feature provides the 'Enterprise' security tier needed for professional adoption.
