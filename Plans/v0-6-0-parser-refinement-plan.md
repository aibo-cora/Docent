# Plan: v0.6.0 — Parser Refinement

## Objective
Enhance the Markdown parser and data schema to support metadata (Frontmatter) and hierarchical chunking. This improves retrieval accuracy by providing more context to the embedding model.

## Key Files & Context
- **Branch**: `v0.6/parser-refinement`
- `Sources/Docent/DocentEngine.swift`: Update runtime models to include metadata.
- `Sources/DocentCompiler/main.swift`: Refactor parser and SQLite insertion logic.

## Implementation Steps

### 1. YAML Frontmatter Support
- Implement a regex-based extractor for `---` blocks at the top of `.md` files.
- Parse key metadata: `title`, `tags` (comma-separated), and `priority` (float).
- Update `docent_chunks` schema to include `priority` and `tags` columns.

### 2. Hierarchical Chunking
- **Header Tracking**: Update parser to maintain a stack of current headers (`#`, `##`, `###`).
- **Context Injection**: For any chunk under a sub-header, prepend the parent titles to the body before embedding (e.g., "Installation > Manual Install: [body]"). This significantly improves vector similarity for specific sub-topics.
- **Breadcrumb Generation**: Store the full header path as a string in the database.

### 3. Metadata Schema Update
- Add `tags` (TEXT) and `priority` (REAL) columns to `docent_chunks`.
- Update `DocentChunk` model in the `Docent` library to expose these new fields.

### 4. Compiler Refinement
- Update `insertChunk` to handle the new metadata fields.
- Implement soft-length limits: Warn if a chunk is > 2000 characters after context injection.

## Verification & Testing
- **New Test Data**: Create a nested Markdown file (`NestedDocs.md`) with Frontmatter.
- **Verification**: 
    - Compile the nested docs and use `sqlite3` to verify `tags`, `priority`, and breadcrumbs are stored correctly.
    - Use `DocentEngine` to query a specific sub-topic and ensure the breadcrumb (e.g., "Setup > Step 1") is returned correctly.
