# Docent

**Ship your documentation as intelligence.**

Docent is a Swift Package and build-time toolchain that allows iOS developers to embed a fully offline, semantic search engine directly into their app bundle. 

## The Vision

Instead of forcing users to scroll through static FAQs or leave your app for a support site, Docent lets them ask questions in plain English and receive answers sourced directly from your documentation—entirely on-device.

- **Privacy First:** No network calls, no third-party APIs, no data leaves the device.
- **Zero Infrastructure:** No servers to maintain. The "intelligence" is compiled into your app at build time.
- **Native Performance:** Built on top of Apple's `NaturalLanguage` and `Accelerate` frameworks.

## How It Works

1. **Write:** You write your documentation in Markdown folders.
2. **Compile:** The **DocentPlugin** runs during the Xcode build, invoking the compiler to chunk your Markdown and generate embeddings.
3. **Embed:** An optimized, read-only **SQLite** index (`.docent`) is packed into your app bundle.
4. **Query:** At runtime, the **DocentEngine** uses the **Accelerate** framework to find relevant matches with near-zero latency.

## Getting Started

### 1. Add Dependency
Add Docent to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/aibo-cora/Docent", from: "0.5.0")
]
```

### 2. Configure Your Target
Add the **DocentPlugin** and the **Docent** library to your app target:

```swift
.target(
    name: "MyCoolApp",
    dependencies: ["Docent"],
    plugins: [
        .plugin(name: "DocentPlugin", package: "Docent")
    ]
)
```

### 3. Add Documentation
Create a folder named `DocentDocs` in your target's directory and drop your `.md` files there.

```text
MyCoolApp/
├── Sources/
└── DocentDocs/
    ├── GettingStarted.md
    └── Troubleshooting.md
```

## Usage

### Simple Query
Initialize the engine and perform a semantic search:

```swift
import Docent

let engine = try DocentEngine(resource: "Knowledge")

let results = await engine.query("How do I reset my password?")

for result in results {
    print("Breadcrumb: \(result.chunk.breadcrumb)")
    print("Content: \(result.chunk.text)")
    print("Confidence: \(result.confidence)")
}
```

## DocentUI (SwiftUI)

Docent provides native SwiftUI components to build a search interface in seconds.

### DocentSearchView
The quickest way to add search to your app:

```swift
import Docent
import DocentUI

struct HelpView: View {
    let engine: DocentEngine
    
    var body: some View {
        DocentSearchView(engine: engine)
    }
}
```

## Example App

A complete example app is included in the repository under `Sources/DocentExample`. To run it:

1. Clone the repo.
2. Run `swift run DocentExample` (on macOS).
3. Or open in Xcode and run the `DocentExample` scheme.

## Markdown & Metadata Guide

To get the best search results, Docent supports [YAML Frontmatter](https://assemble.io/docs/YAML-front-matter.html) and hierarchical [Markdown](https://www.markdownguide.org/basic-syntax/) structures.

### Frontmatter Support
You can define metadata at the top of your `.md` files:

```markdown
---
title: Custom Page Title
tags: account, security
priority: 1.5
---

# Hierarchical Headers
Docent respects your document structure.
```

- **title**: Overrides the auto-detected title.
- **tags**: comma-separated strings for future filtering.
- **priority**: A score multiplier (default 1.0) to boost important documents.

### Hierarchical Chunking
Docent automatically generates **Breadcrumbs** (e.g., `Setup > Step 1`) based on your header hierarchy (#, ##, ###). It also performs **Context Injection**, prepending parent titles to nested content to ensure the semantic search understands the full context of a sub-section.

## Current Status: v0.6 — Parser Refinement (Functional)

The core toolchain is now functionally complete.

- **Automated Pipeline:** Full SPM Build Tool Plugin integration.
- **Optimized Storage:** SQLite-backed index with `VACUUM` and `ANALYZE` for high-speed read performance.
- **Security:** Optional **CryptoKit (AES-GCM)** content encryption at rest.
- **Validation:** 0.91 Precision@3 on technical documentation benchmarks.

## Roadmap

- [x] **v0.1 — Proof of Concept:** Validate `NLEmbedding` quality.
- [x] **v0.5 — Private Alpha:** 
    - [x] SPM Build Tool Plugin implementation.
    - [x] SQLite binary format (`.docent`).
    - [x] Headless `DocentEngine` runtime with Accelerate.
    - [x] AES-GCM Content Encryption.
- [ ] **v1.0 — Public Launch:** 
    - `DocentUI`: Pre-built SwiftUI search and chat components.
    - YAML Frontmatter support for priorities and tags.
    - Incremental build support (caching unchanged chunks).

## Technical Architecture

| Component | Role | Technology |
|---|---|---|
| `DocentPlugin` | SPM build tool plugin | Swift, `PackagePlugin` |
| `docent-compiler` | CLI build tool | Swift, `NaturalLanguage`, `SQLite3` |
| `DocentEngine` | Runtime query API | Swift, `Accelerate`, `SQLite3` |
| `.docent` format | Optimized index | SQLite (Encrypted via CryptoKit) |

## Security

Docent supports optional **AES-GCM encryption** via Apple's `CryptoKit`. 
- **Build-time:** `docent-compiler --key <your-key>`
- **Runtime:** `DocentEngine(resource: "Knowledge", encryption: .cryptoKit(key: "your-key"))`

This protects your documentation text and vectors from being easily scraped from the app bundle while maintaining a tiny binary footprint.

## License

Docent is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
