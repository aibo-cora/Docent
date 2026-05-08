# Autopilot: Knowledge Scraper

**Source-Driven Documentation.**

Docent v1.4.0 introduces the **Knowledge Scraper**, the first step in our Autopilot pipeline. It allows Docent to "read" your source code and extract factual intelligence to build a conceptual understanding of your features.

## How to Mark Your Code
To enable Autopilot for a specific part of your app, simply add the `/// @docent` trigger comment above any Class, Struct, or Enum declaration.

```swift
/// @docent(topic: "Shamir Secret Sharing")
/// This implementation provides conceptually secure secret splitting.
struct SSSManager {
    let threshold = 3
    let totalShares = 5
    
    func split(secret: String) -> [String] { ... }
}
```

## What the Scraper Sees
The scraper uses **SwiftSyntax** to analyze the Abstract Syntax Tree (AST) of your code. It extracts:

1.  **Hard Constants**: Values like `threshold = 3` are locked into the knowledge base to ensure factual accuracy.
2.  **Technical Comments**: Any `///` comments are treated as technical hints for the AI pass.
3.  **Dynamic Variables**: Properties marked as `var` are identified as potential runtime placeholders (e.g. `{{threshold}}`).
4.  **Interface Signals**: Method names and signatures help the engine understand the "actions" available for a feature.

## Privacy & Security
The scraper runs entirely **on your Mac** during the build process. No source code is sent to any external server. It produces a structured JSON context that stays local to your project.

## The Next Step: Synthesis
The data extracted by the scraper in v1.4.0 is used by the **Docent Synthesizer** (coming in v1.5.0) to generate human-readable Markdown guides automatically using Apple Intelligence.
