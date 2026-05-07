# Incremental Build Caching

**Performance at Scale.**

Docent v1.3.0 introduces a state-aware compiler that intelligently caches your documentation embeddings. This ensures that only modified content is re-indexed, making builds for large documentation sets lightning fast.

## The "Build-Once" Philosophy
Previously, modifying a single character would force the entire knowledge base to be re-embedded. With v1.3.0, Docent treats your `.docent` file as a persistent cache.

### How it Works: Composite Hashing
For every chunk of documentation, Docent calculates a unique **Composite Hash** based on:
1.  **The Breadcrumb**: The location of the chunk in your document hierarchy.
2.  **The Content**: The actual text of the chunk (normalized for whitespace).

If both remain unchanged, Docent **reuses the existing vector** from the previous build. If either changes, the chunk is automatically re-embedded and updated in the database.

## Features

### 1. "Touch and Sweep" Cleanup
Docent automatically detects when you delete a Markdown file or a heading. At the end of every build, it "sweeps" the database and removes any orphaned chunks that were not seen during the current build.

### 2. Version Lock
If the underlying `NLEmbedding` model or the Docent version changes, the compiler automatically invalidates the entire cache and performs a full rebuild to prevent "vector drift" and ensure maximum search precision.

### 3. Force Rebuild
If you ever need to clear the cache manually, you can pass the `--force` flag to the compiler:
```bash
docent-compiler ./Docs Knowledge.docent --force
```

## Performance
For a typical documentation set of 1,000 chunks, a full rebuild might take **10-15 seconds**. An incremental build with one modified chunk takes **less than 1 second**.
