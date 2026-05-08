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
2. **Compile:** The **DocentPlugin** runs during the build, invoking the compiler to chunk your content and generate dual-vector embeddings.
3. **Embed:** An optimized, read-only **SQLite** index (`.docent`) is packed into your app bundle.
4. **Query:** At runtime, the **DocentEngine** uses the **Accelerate** framework to find matches with near-zero latency.

---

## Installation & Setup

### 1. Add Dependency
Add Docent to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/aibo-cora/Docent", from: "1.4.0")
]
```

### 2. Configure Your Target
In your app target settings:
1.  **Frameworks**: Add **Docent** and **DocentUI** to "Frameworks, Libraries, and Embedded Content."
2.  **Build Phases**: Add **DocentPlugin** to the "Run Build Tool Plugins" section.

---

## Docent Autopilot (Beta)

Docent v1.4.0 introduces the first phase of **Autopilot**: The Knowledge Scraper. This allows Docent to "read" your source code and extract conceptual intelligence automatically.

### Marking Your Code
Simply add a `/// @docent` marker above your feature logic. Docent will extract constants, variables, and technical comments to build a conceptual understanding of the feature.

```swift
/// @docent(topic: "Shamir Secret Sharing")
/// This implementation provides secure secret splitting.
struct SSSManager {
    let threshold = 3
    let totalShares = 5
}
```

*Note: Automated Markdown synthesis using Apple Intelligence is coming in v1.5.0.*

---

## Features

### 🎯 High-Precision Search
Uses **Dual-Vector Weighted Search** to separate Titles and Body embeddings, ensuring exact topic matches receive high confidence scores.

### ⚡️ Incremental Build Caching
State-aware compiler that only re-indexes modified documentation, keeping Xcode builds fast.

### 🔐 Tiered Encryption
- **Tier 1 (CryptoKit)**: Encrypts text and vectors with AES-GCM (Zero bundle bloat).
- **Tier 2 (SQLCipher)**: Full page-level database encryption (Modular add-on).

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
