# Keyword Fallback (Hybrid Search)

**Precision Meets Intelligence.**

Docent v1.2.0 introduces a **Hybrid Search Engine** that combines the power of semantic vector search with the precision of keyword matching.

## The "Prefix" Problem
Semantic search (`NLEmbedding`) is excellent at understanding concepts, but it can sometimes struggle with incomplete words or specific jargon. For example, searching for `"accou"` might not strongly align with the concept of `"account"` until the word is nearly finished.

## How it Works
Docent solves this by performing a simultaneous **in-memory string match** alongside the vector search:

1.  **Semantic Pass**: The engine calculates the conceptual similarity between your query and the documentation.
2.  **Keyword Pass**: The engine checks if your query exists as a substring in any Title, Breadcrumb, or Body text.
3.  **Hybrid Boost**: If a keyword match is found, a score boost is applied:
    *   **Title Match**: `+0.40` (Ensures quick-start items snap to the top).
    *   **Body Match**: `+0.15` (Surfaces relevant deep-content matches).

## Why In-Memory?
We chose a Swift-native, in-memory matching strategy instead of SQLite FTS5 (Full-Text Search) to preserve our **Privacy Guarantee**. FTS5 requires storing plaintext tokens in the SQLite file, which would leak information if you are using **CryptoKit** encryption. Our in-memory approach performs matching on the *decrypted* text in real-time, keeping your data secure on disk.

## Customization
You can tune the keyword fallback behavior in your `DocentSearchConfiguration`:

```swift
let config = DocentSearchConfiguration(
    enableKeywordFallback: true,
    keywordTitleBoost: 0.5, // Extra aggressive title matching
    keywordBodyBoost: 0.1
)
```

## Performance
Even with hundreds of documentation chunks, the in-memory string search adds negligible latency (typically <1ms) compared to the vector embedding process.
