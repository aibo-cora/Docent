# Plan: v1.1.0 — SQLCipher Integration

## Objective
Provide an optional, high-security storage tier using **SQLCipher** for full database encryption. This must be implemented as a modular add-on to preserve Docent's "Zero-Bloat" promise for standard users.

## Key Files & Context
- **Branch**: `v1.1.0/sqlcipher-integration`
- `Package.swift`: Add SQLCipher dependency and `DocentSQLCipher` product/target.
- `Sources/Docent/SQLiteStore.swift`: Add support for database passphrases.
- `Sources/DocentCompiler/main.swift`: Add `--password` flag to support SQLCipher encryption during build.
- `Sources/DocentExample/DocentDocs/SQLCipher.md`: New documentation file explaining this feature.

## Implementation Steps

### 1. Package Configuration
- Add a Swift Package dependency for SQLCipher (e.g., `SQLCipher` C library or a known SPM wrapper).
- Create a new library product `DocentSQLCipher`.
- Create a new target `DocentSQLCipher` that depends on `Docent` and the SQLCipher library, using conditional compilation flags (`-DDOCENT_SQLCIPHER`) to enable the required C APIs (`sqlite3_key`).

### 2. SQLiteStore Refactoring
- Modify `SQLiteStore` initialization to accept an optional `passphrase`.
- If a passphrase is provided, execute `PRAGMA key = 'passphrase';` immediately after opening the database, which applies to SQLCipher builds.
- *Note*: If SQLCipher is not linked, `PRAGMA key` is a no-op or returns an error. We will use conditional compilation `#if canImport(SQLCipher)` or a custom flag to safely call `sqlite3_key` or execute the PRAGMA.

### 3. Compiler & Engine Updates
- **DocentCompiler**: Update the CLI to accept an `--encryption sqlcipher` and `--password <pass>` option.
- **DocentEngine**: Add `.sqlCipher(passphrase: String)` to the `DocentEncryption` enum. Update the engine initialization to pass the passphrase down to `SQLiteStore`.

### 4. Self-Documenting the Feature
- Create `Sources/DocentExample/DocentDocs/SQLCipher.md` to explain how to use SQLCipher with Docent.
- This fulfills the requirement that Docent is self-documenting for every new feature.

## Verification & Testing
- **Standard Build**: Verify that the core `Docent` package still compiles without the SQLCipher dependency (zero bloat).
- **Encrypted Build**: Verify that `docent-compiler` can successfully generate a fully encrypted `.docent` file using SQLCipher.
- **Runtime**: Verify that the `DocentEngine` can decrypt and query the SQLCipher-encrypted index using the correct passphrase, and fails gracefully with an incorrect passphrase.
