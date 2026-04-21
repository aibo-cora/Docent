# Docent

**Ship your documentation as intelligence.**

Docent is a Swift Package and build-time toolchain that allows iOS developers to embed a fully offline, semantic search engine directly into their app bundle. 

## The Vision

Instead of forcing users to scroll through static FAQs or leave your app for a support site, Docent lets them ask questions in plain English and receive answers sourced directly from your documentation—entirely on-device.

- **Privacy First:** No network calls, no third-party APIs, no data leaves the device.
- **Zero Infrastructure:** No servers to maintain. The "intelligence" is compiled into your app at build time.
- **Native Performance:** Built on top of Apple's `NaturalLanguage` and `Accelerate` frameworks.

## How It Works

1. **Write:** You write your documentation in Markdown (`/DocentDocs`).
2. **Compile:** An SPM Build Tool Plugin runs during compilation, chunking your Markdown and generating semantic embeddings.
3. **Embed:** A compact binary index (`.docent`) is packed into your app bundle.
4. **Query:** At runtime, the `DocentEngine` uses on-device vector search to find the most relevant answers.

## Current Status: v0.1 — Proof of Concept (Complete)

We have successfully validated the core technical thesis: **Can Apple's native `NLEmbedding` handle technical documentation?**

- **Benchmark Results:** Achieved **0.91 Precision@3** across 100 queries on technical document sets.
- **Status:** Core retrieval logic is verified. Moving toward v0.5 (Private Alpha).

## Roadmap

- [x] **v0.1 — Proof of Concept:** Validate `NLEmbedding` quality.
- [ ] **v0.5 — Private Alpha:** 
    - SPM Build Tool Plugin implementation.
    - `.docent` binary format specification.
    - Headless `DocentEngine` runtime.
- [ ] **v1.0 — Public Launch:** 
    - `DocentUI` (SwiftUI components).
    - Incremental build support.
    - Full documentation and example apps.

## Technical Architecture

| Component | Role | Technology |
|---|---|---|
| `DocentPlugin` | SPM build tool plugin | Swift, `PackagePlugin` |
| `DocentEngine` | Runtime query API | Swift, `NaturalLanguage` |
| `.docent` format | Compiled binary index | Custom Binary / SQLite |

## License

Docent is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
