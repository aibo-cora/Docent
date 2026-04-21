# Docent — Product Brief

> **Tagline:** Ship your documentation as intelligence.

---

## What Is Docent?

Docent is a Swift Package + build-time toolchain that lets iOS developers embed a fully offline, semantic search engine over their own documentation directly into their app bundle.

A developer writes Markdown. Docent compiles it into a pre-computed vector index at build time — using Apple's `NaturalLanguage` framework — and ships it inside the app. At runtime, users ask plain-English questions and get answers sourced from the developer's own words, entirely on-device, with zero network calls and zero third-party AI dependency.

**It is not a chatbot. It is not a cloud service. It is a compiled knowledge layer.**

---

## The Core Problem

App developers face an ugly tradeoff:

- Write no in-app help → support inbox fills up with the same 10 questions forever
- Write an FAQ screen → users don't find it, or it goes stale
- Integrate a support chat platform → monthly SaaS cost, data leaves the device, App Review scrutiny, SDK bloat

No current solution respects the user's privacy, fits the iOS mental model, and requires zero infrastructure from the developer. Docent solves all three.

---

## How It Works

### The Pipeline

```
/DocentDocs/               ← Developer writes Markdown here
  getting-started.md
  troubleshooting.md
  account-settings.md
        ↓
[SPM Build Tool Plugin]    ← Runs automatically at xcodebuild time
        ↓
Knowledge.docent           ← Binary index embedded in app bundle
        ↓
DocentEngine (runtime)     ← Answers queries on-device
```

### Build-Time (SPM Build Tool Plugin)

1. **Parse** — reads every `.md` file in the designated folder
2. **Chunk** — splits on `##` headers into semantically coherent units
3. **Embed** — encodes each chunk via `NLEmbedding` into 768-dimensional vectors
4. **Pack** — writes a compact binary index (text + vectors + positional map) to the bundle

### Runtime (on device)

1. User submits a natural-language query
2. `DocentEngine` embeds the query using the same `NLEmbedding` model
3. Cosine similarity search finds the top-k matching chunks
4. Returns ranked results with source file attribution
5. Optionally passed to an on-device LLM (Apple Intelligence / local model) for synthesis

---

## Technical Architecture

### Key Components

| Component | Role | Technology |
|---|---|---|
| `DocentPlugin` | SPM build tool plugin; runs at compile time | Swift, `PackagePlugin` API |
| `DocentEngine` | Runtime query API | Swift, `NaturalLanguage`, `Accelerate` |
| `DocentUI` (optional) | Pre-built SwiftUI chat/search surface | SwiftUI |
| `.docent` format | Compiled binary index | Custom binary format (text + float32 vectors + index) |

### The `.docent` File Format

```
[Header]
  magic:       "DCNT" (4 bytes)
  version:     UInt16
  chunk_count: UInt32
  
[Chunk Table]
  per chunk:
    source_file:  String (null-terminated)
    text_offset:  UInt32
    text_length:  UInt32
    vector_offset: UInt32

[Text Block]
  raw UTF-8 text of all chunks (concatenated)

[Vector Block]
  Float32[768] per chunk (768 × 4 bytes each)
```

Estimated size: ~3KB per chunk. A 50-chunk documentation set ≈ 150KB. A thorough 200-chunk set ≈ 600KB. Well within acceptable bundle delta.

### Runtime API (Headless / Composable)

```swift
// Initialize from bundle
let engine = try DocentEngine(resource: "Knowledge", bundle: .main)

// Simple async query
let results = await engine.query("How do I reset my password?", topK: 3)

for result in results {
    print(result.text)        // The relevant passage
    print(result.sourceFile)  // e.g. "account-settings.md"
    print(result.score)       // Cosine similarity score (0–1)
}
```

### Optional: Synthesis via Apple Intelligence

```swift
// Pass retrieved chunks as context to on-device model
let context = results.map(\.text).joined(separator: "\n\n")
let answer = await engine.synthesize(query: query, context: context)
// Uses WritingTools / on-device model — no API key, no network
```

---

## Critical Technical Risk: Embedding Quality

`NLEmbedding` is optimized for word/phrase similarity, not technical prose retrieval. The core thesis depends on it performing adequately for queries like:

- "auth token keeps expiring" → matching "Session Management" chunks
- "can't log in after update" → matching "Troubleshooting" chunks

**This must be prototyped and measured before building anything else.**

### Validation Protocol (Before Writing Any Other Code)

1. Pick 5 real iOS app documentation sets (open-source apps with READMEs, or write synthetic ones)
2. Generate 20 natural-language user queries per set
3. Embed with `NLEmbedding` and measure Precision@3 (did the right chunk appear in top 3 results?)
4. Target: P@3 > 0.75. Below 0.6, the product is broken regardless of UX.

**If `NLEmbedding` fails this bar**, the fallback is a small CoreML retrieval model (~15–40MB). This changes the bundle size story significantly and must be decided before any public commitment.

---

## Roadmap

### v0.1 — Proof of Concept (2–3 weeks)
*Goal: validate embedding quality before writing any other code*

- [ ] Swift CLI script that reads `.md` files and generates vectors via `NLEmbedding`
- [ ] In-memory cosine similarity search over a test documentation set
- [ ] Benchmark: Precision@3 across 5 test corpora, 20 queries each
- [ ] Go/no-go decision on `NLEmbedding` vs. CoreML model

### v0.5 — Private Alpha (4–6 weeks)
*Goal: end-to-end pipeline works, used by 2–3 developer friends*

- [ ] SPM build tool plugin (`PackagePlugin`) that runs at compile time
- [ ] `.docent` binary format defined and implemented
- [ ] `DocentEngine` runtime: load index, embed query, cosine search, return results
- [ ] Headless API only (no SwiftUI) — raw `DocentResult` structs
- [ ] Works in a real Xcode project via SPM `binaryTarget` or source dependency
- [ ] Basic README with integration instructions

### v1.0 — Public Launch
*Goal: zero-friction integration, good enough to ship in a real app*

- [ ] `DocentUI`: opt-in SwiftUI components (search bar, result list, chat bubble layout)
- [ ] `docentcheck` script (runs as pre-build phase): warns on chunks that are too long, too short, or contain no headers
- [ ] Source attribution in results (`result.sourceFile`, `result.sectionTitle`)
- [ ] Graceful degradation: if no chunk scores above threshold, returns "I couldn't find that in the docs" rather than a bad result
- [ ] iOS 16+ support
- [ ] Documentation site
- [ ] Example app (open source, in the repo)
- [ ] Package published to GitHub with SPM support

### v1.5 — Developer Experience Polish
- [ ] `docent init` CLI: scaffolds `/DocentDocs` folder with template files and a style guide
- [ ] Incremental builds: only re-embeds chunks whose source `.md` changed (cache by file hash)
- [ ] Multi-language support: per-locale `.docent` files, language auto-detected at runtime
- [ ] Xcode build warning integration: surfaces chunk quality issues as Xcode warnings/errors
- [ ] TestFlight-friendly: query logging (local only, never transmitted) for developer review

### v2.0 — Synthesis + Intelligence Layer
- [ ] Optional synthesis pass: retrieved chunks → on-device model → full-sentence answer
- [ ] Apple Intelligence integration (where available, iOS 18.1+)
- [ ] Local model fallback (bundled CoreML BERT-style model) for pre-iOS 18 devices
- [ ] `result.confidence` score with automatic "I don't know" threshold
- [ ] Streaming response support for synthesis pass

### v2.5 — Analytics + Feedback Loop (Requires Privacy Architecture)
- [ ] Local query log: stores anonymized query hashes + match scores in app sandbox
- [ ] `docent analyze` CLI command: reads an exported log and shows which queries had low match scores, which docs were never retrieved
- [ ] Zero-network: all analysis happens on the developer's machine against an exported file — nothing is sent to Docent servers
- [ ] Query clustering (local, on-device): surfaces the 10 most common question themes without seeing raw query text

### v3.0 — Platform Expansion
- [ ] macOS support (same SPM package, AppKit-compatible UI layer)
- [ ] visionOS support
- [ ] watchOS stripped-down runtime (read-only, no SwiftUI layer)
- [ ] CI/CD integration: `docent build` as a standalone CLI for use in GitHub Actions

---

## Monetization

### Principles
- **Runtime must always be free.** Any cost or restriction on the on-device `DocentEngine` is a non-starter. Privacy-focused developers will not accept a phone-home check or a license validation at query time.
- **The SPM package is the adoption driver, not the revenue driver.** Keep it fully open-source under MIT. Adoption compounds through developer word-of-mouth.
- **Charge for build-time tooling and developer insight.** That's where the professional value is.

### Revenue Model

#### Tier 1 — Free (Forever)
- Full SPM package: `DocentEngine`, `DocentUI`, `.docent` format
- `docentcheck` validation script
- Up to 1 app, unlimited queries
- Community support

#### Tier 2 — Indie ($9/month or $79/year)
- Unlimited apps
- `docent analyze`: local query log analysis tool (surfaces bad matches, coverage gaps)
- Incremental build caching (faster CI)
- Email support
- Priority bug fixes

#### Tier 3 — Studio ($49/month or $399/year)
- Everything in Indie
- Team seats (5 included)
- Multi-locale build pipeline
- Slack/Discord support channel
- Early access to v2.x synthesis features
- Custom chunk quality thresholds

#### Tier 4 — Enterprise (Custom)
- On-premise `docent build` server for CI environments with restricted internet
- SLA
- Custom model support (bring your own CoreML embedding model)
- Dedicated onboarding

### Secondary Revenue Opportunities

**Consulting:** Documentation audits. Many teams have docs but they're badly structured for retrieval. A paid "Docent Audit" service (review their Markdown, restructure for retrieval quality, deliver a report) is a natural service offering in year 2.

**Marketplace:** In v3+, a curated set of pre-built `.docent` indexes for common frameworks (StoreKit, CloudKit, HealthKit). Developers integrating third-party SDKs could ship Docent-powered help for the SDK's own documentation. Licensing revenue from SDK authors.

---

## Distribution & Go-To-Market

### Year 1 Priorities

1. **The demo video.** A 7-minute screen recording: blank Xcode project → add SPM dependency → drop in 3 Markdown files → build → working in-app semantic search. No CLI, no config, no API keys. This video is the entire marketing strategy.

2. **Target audience for launch:** Indie iOS developers with utility apps (password managers, finance, health, productivity). They have documentation problems and no support team. Find them on Twitter/X, the iOS dev Slack communities, and Hacker News.

3. **Open source the core.** MIT license on GitHub. Stars are the social proof that gets the product into developer newsletters and "awesome-ios" lists.

4. **Write the post-mortem you wish existed.** "How I cut support tickets by 40% with on-device semantic search" — written as a case study once you have a real user. This performs well on HN and indie dev communities.

### Positioning
- **Not:** "AI-powered in-app chat"
- **Yes:** "Compile your docs into intelligence. No cloud. No subscription. No API key."

The privacy framing is the differentiator. Every competing solution (Intercom, Crisp, Zendesk mobile SDK) requires a network call. Lead with that.

---

## Risks & Mitigations

| Risk | Severity | Mitigation |
|---|---|---|
| `NLEmbedding` quality insufficient for technical prose | **Critical** | Validate in v0.1 before any other work |
| Apple ships native contextual in-app help in Xcode | High | Move fast; become the standard before they ship; open source moat |
| CLI becomes a second product with its own maintenance | Medium | Delay CLI to v1.5; use SPM build plugin instead (no install step) |
| Bundle size concerns from embedding model | Medium | Benchmark early; provide a "lite" mode with BM25 text search fallback |
| Developers don't write documentation | Low | Not your problem to solve; filter for developers who already have docs |

---

## What Success Looks Like

- **3 months:** 50 GitHub stars, 5 developers using it in production, retrieval quality validated
- **6 months:** 500 stars, covered in one major iOS newsletter (iOS Dev Weekly, Swift Weekly Brief), first paying Indie subscribers
- **12 months:** 2,000+ stars, 200+ active integrations, one recognizable app shipping with it
- **24 months:** Recognized as the standard approach for on-device in-app help; acquisition interest from Apple, Xcode plugin ecosystem, or developer tools companies

---

## Open Questions (Decide Before v1)

1. **CoreML vs. NLEmbedding:** What's the actual Precision@3 on technical docs? Run the benchmark.
2. **`.docent` format vs. SQLite:** A custom binary format is fast but a SQLite db with vector extension might be simpler to debug and extend. Evaluate before committing.
3. **Synthesis in v1 or v2?** Shipping synthesis (i.e., full-sentence answers) in v1 is tempting but adds complexity and a dependency on iOS version. Retrieval-only v1 is a better bet.
4. **License:** MIT for the runtime. What about the build tooling? Could be MIT or a source-available license (BSL 1.1) that converts to MIT after 4 years — protects against large companies building competing products on top of your build infrastructure.
5. **Name:** "Docent" is evocative (a museum guide who answers questions) but may conflict with existing tools. Verify before launch.
