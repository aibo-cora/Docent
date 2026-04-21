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

## Current Status: v0.5 — Private Alpha (Core Functional)

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
