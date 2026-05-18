# Docent

**Ship your documentation as intelligence.**

Docent is a Swift Package and build-time toolchain that allows iOS developers to embed a fully offline, semantic search engine directly into their app bundle. 

## The Vision

Instead of forcing users to scroll through static FAQs or leave your app for a support site, Docent lets them ask questions in plain English and receive answers sourced directly from your documentation—entirely on-device.

- **Privacy First:** No network calls, no third-party APIs, no data leaves the device.
- **Zero Infrastructure:** No servers to maintain. The "intelligence" is compiled into your app at build time.
- **Native Performance:** Built on top of Apple's `NaturalLanguage` and `Accelerate` frameworks.

## How It Works

1. **Write:** You write your documentation in Markdown or let **Autopilot** synthesize it from code.
2. **Compile:** The **DocentPlugin** runs during the build, invoking the compiler to chunk your content and generate triple-vector embeddings.
3. **Embed:** An optimized, read-only **SQLite** index (`.docent`) is packed into your app bundle.
4. **Query:** At runtime, the **DocentEngine** uses the **Accelerate** framework to find matches with near-zero latency.

---

## Installation & Setup

### 1. Add Dependency
Add Docent to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/aibo-cora/Docent", from: "2.0.0")
]
```

### 2. Configure Your Target
In your app target settings:
1.  **Frameworks**: Add **Docent** and **DocentUI** to "Frameworks, Libraries, and Embedded Content."
2.  **Build Phases**: Add **DocentPlugin** to the "Run Build Tool Plugins" section.

---

## Docent Autopilot (New!)

Docent v1.6.0 officially launches **Autopilot**, a visionary AI-powered documentation pipeline. By simply marking your code, Docent will automatically "read" your source logic and synthesize user-friendly guides using on-device **Apple Intelligence**.

### Marking Your Code
Add the `@Docent(topic: "Topic Name")` macro above any class or struct. Docent will extract constants, variables, and technical comments to build a conceptual guide automatically.

```swift
import DocentMacros

@Docent(topic: "Shamir Secret Sharing")
/// This implementation provides secure secret splitting.
struct SSSManager {
    let threshold = 3
    let totalShares = 5
}
```

### How Synthesis Works
-   **Extraction**: Uses **SwiftSyntax** to factually map your code configuration.
-   **Synthesis**: Uses on-device **Foundation Models** to write human narratives.
-   **Privacy**: 100% on-device. Your source code never leaves your Mac.

---

## Apple Intelligence Synthesis (v2.0)

Docent v2.0 adds on-device answer synthesis on top of retrieval. When a user's query matches your documentation with sufficient confidence, Docent passes the relevant chunks to Apple Intelligence and streams a plain-English answer back — entirely on-device, no API key, no network call.

```swift
if #available(macOS 26.0, iOS 19.0, *) {
    let provider = AppleIntelligenceProvider()
    guard await provider.isAvailable() else { /* show retrieval results only */ return }

    let stream = try await engine.synthesize("How do I recover a lost shard?", provider: provider)
    for try await token in stream {
        answer += token  // streams word by word
    }
}
```

- **Silence threshold:** if no chunk scores above the confidence floor, the engine returns an empty stream rather than letting the model guess from weak context.
- **Graceful fallback:** on devices where Apple Intelligence is unavailable, retrieval results are shown as normal.
- **`DocentUI` included:** `DocentSearch` and `DocentSearchView` handle synthesis automatically — the answer card appears above results with no extra code.

---

## Features

### 🎯 Triple-Vector Fusion Search (v2.0)
Scores each chunk against three separate embeddings — title, full context (breadcrumb + body), and pure body — then blends them at validated weights (0.28 / 0.60 / 0.12). Benchmarked at **95% Precision@3** across 100 queries, up from 91% with dual-vector scoring.

### ⚡️ Incremental Build Caching
State-aware compiler that only re-indexes modified documentation, keeping Xcode builds fast.

### 🔐 Tiered Encryption
- **Tier 1 (CryptoKit)**: Encrypts text and vectors with AES-GCM (Zero bundle bloat).
- **Tier 2 (SQLCipher)**: Full page-level database encryption (Modular add-on).

---

## Try the Example App

Clone the repo and run the `DocentExample` target in Xcode. It ships with documentation for two features — **Shamir Secret Sharing** and **SQLite Storage** — so you can test the full pipeline immediately.

**Things to try:**

| Query | What to expect |
|---|---|
| `Secret Sharing` | Answer card streams a summary of what the feature does and how to use it |
| `How do I recover my secret?` | Synthesis explains the combine flow and threshold requirement |
| `What happens if I lose a shard?` | Answer references the 3-of-5 threshold table |
| `How do I split a secret?` | Returns the split API with usage guidance |
| `sqlite` | Retrieval results only — keyword query, no synthesis |
| `Something completely unrelated` | No answer card — silence threshold blocks weak context |

The left pane always shows ranked retrieval results with confidence badges. The answer card only appears when Apple Intelligence is available on the device and retrieval confidence is medium or above.

---

## Markdown & Metadata Guide

Define metadata at the top of your `.md` files:

```markdown
---
title: Advanced Encryption
tags: security, pro
priority: 1.5
---
```

- **title**: Overrides the filename in results.
- **tags**: Used for scoped searching.
- **priority**: Multiplier to boost important docs.

## License
Docent is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
