# Plan: v0.5.0 — Private Alpha (Core Infrastructure)

## Objective
Build the end-to-end toolchain for Docent, moving from a validation script to a unified Swift Package featuring a Compiler, an SPM Plugin, and a SQLite-backed Runtime Engine.

## Key Files & Context
- **Branch**: `v0.5/core-infrastructure`
- `Package.swift`: Multi-target configuration.
- `Sources/Docent/`: The runtime library (Engine).
- `Sources/DocentCompiler/`: The CLI build tool.
- `Sources/DocentPlugin/`: The SPM Build Tool Plugin.

## Implementation Steps

### 1. Package Re-architecture
- Update `Package.swift` to define `Docent` (library), `DocentCompiler` (executable), and `DocentPlugin` (plugin).
- Set up directory structure for the new targets.

### 2. The Compiler (`DocentCompiler`)
- **Recursive Crawler**: Use `FileManager` to walk directory trees for `.md` files.
- **SQLite Writer**: 
    - Implement schema creation (`Files`, `Chunks`).
    - Store vectors as `BLOB`s.
    - Apply `VACUUM` and `ANALYZE` optimizations.
- **Encryption**: Implement optional `CryptoKit` encryption for `text` and `vector` columns.

### 3. The Engine (`Docent`)
- **SQLite Reader**: Connect to the bundled `.docent` file.
- **Similarity Search**: Use the `Accelerate` framework for high-performance cosine similarity on the retrieved blobs.
- **Decryption**: Handle transparent decryption of content if a key is provided.

### 4. The Plugin (`DocentPlugin`)
- Implement `BuildToolPlugin`.
- Configure it to scan the target's source files for Markdown.
- Invoke `DocentCompiler` and output `Knowledge.docent` as a generated resource.

## Verification & Testing
- **Integration Test**: Create an "Example" target within the package that uses the plugin.
- **Verification**: 
    - Ensure `Knowledge.docent` is generated automatically on build.
    - Verify that `DocentEngine` can successfully query the generated file.
    - Test encryption by attempting to read an encrypted file without the correct key.
