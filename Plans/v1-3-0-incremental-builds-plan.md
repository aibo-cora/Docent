# Plan: v1.3.0 — Incremental Build Caching

## Objective
Implement a robust, state-aware incremental build system for the Docent compiler. This reduces build times by only re-embedding chunks that have changed, using composite hashing and a "Touch and Sweep" cleanup strategy.

## Key Files & Context
- **Branch**: `v1.3.0/incremental-builds`
- `Sources/DocentCompiler/main.swift`: Refactor the `run` loop to implement state-awareness and hashing.
- `Sources/DocentExample/DocentDocs/IncrementalBuilds.md`: New documentation file.

## Implementation Steps

### 1. Schema Update
- Update `docent_chunks` table to include:
    - `content_hash` (TEXT): SHA-256 of (breadcrumb + normalized body).
    - `last_seen` (INTEGER): The build timestamp/ID to track active chunks.
- Update `docent_info` to include `embedding_model_version`.

### 2. State-Aware Compiler Loop
- **Load Existing State**: At the start of the build, if the `.docent` file exists, the compiler loads the existing chunks and hashes into an in-memory lookup table.
- **Model Version Check**: If the system's `NLEmbedding` version differs from the one stored in `docent_info`, force a full rebuild.
- **Incremental Processing**: 
    - For each chunk found in Markdown:
        - Generate composite hash: `SHA256(breadcrumb + normalized_body)`.
        - Compare against the existing hash in the lookup table.
        - **Match**: Update the `last_seen` timestamp in the DB (reuse existing vector).
        - **Mismatch/New**: Generate new embeddings and insert/update the row.
- **Sweep (Cleanup)**: After processing all files, delete all rows where `last_seen` is older than the current build timestamp.

### 3. CLI Enhancements
- Add `--force` flag to bypass the cache and re-embed everything.
- Implement a **Build Summary** output: `"Docent: 12 chunks updated, 450 reused. Build time: 1.2s."`

### 4. Self-Documenting the Feature
- Create `Sources/DocentExample/DocentDocs/IncrementalBuilds.md` explaining the "Build-Once" philosophy and how hashing works.

## Verification & Testing
- **Speed Test**: Measure the time for a first build vs. a second build with no changes.
- **Invalidation Test**: Modify one character in a Markdown file and verify that only that specific chunk is re-embedded.
- **Cleanup Test**: Delete a Markdown file and verify that its chunks are removed from the SQLite database.
