# Plan: v1.2.0 — Keyword Fallback (Hybrid Search)

## Objective
Implement a "Keyword Fallback" mechanism to solve the prefix-matching problem in semantic search (e.g., ensuring "accou" matches "account"). This will use an in-memory string matching approach to maintain full compatibility with CryptoKit column-level encryption without leaking plaintext tokens to the SQLite file.

## Key Files & Context
- **Branch**: `v1.2.0/keyword-fallback`
- `Sources/Docent/DocentEngine.swift`: Update scoring logic for hybrid search.
- `Sources/DocentExample/DocentDocs/KeywordSearch.md`: New documentation file explaining this feature.

## Implementation Steps

### 1. Configuration Update
- Update `DocentSearchConfiguration` to include `enableKeywordFallback: Bool = true`.
- Add tuning parameters for keyword boosting (e.g., `keywordTitleBoost: Float = 0.4`, `keywordBodyBoost: Float = 0.15`).

### 2. In-Memory Hybrid Search
- Since `DocentEngine` already loads and decrypts all chunks into memory during `query()`, we will implement the keyword matching directly in Swift.
- **Why in-memory?** Using SQLite FTS5 would require storing plaintext tokens in the database, breaking the security guarantees of our CryptoKit encryption tier. In-memory matching is secure, requires zero schema changes, and is extremely fast for documentation-sized datasets.
- During the scoring loop, check if `queryLower` is a substring of the chunk's title, breadcrumb, or text.

### 3. Weighted Scoring Logic
- If `chunk.title` or `chunk.breadcrumb` contains the query as a substring, apply the `keywordTitleBoost` to the final score.
- If `chunk.text` contains the query, apply the `keywordBodyBoost`.
- This ensures that typing prefixes like "deleting accou" will instantly snap to High/Medium confidence for the "Deleting Account" document, overriding the low semantic vector score of the incomplete word.

### 4. Self-Documenting the Feature
- Create `Sources/DocentExample/DocentDocs/KeywordSearch.md` to explain how hybrid search works and why we chose in-memory over FTS5 for privacy.

## Verification & Testing
- **Prefix Matching**: Verify that searching for a partial word (e.g., "Quick Sta") returns the "Quick Start Guide" with high confidence.
- **CryptoKit Safety**: Verify that this approach requires no database schema changes, ensuring encrypted blobs remain secure.
