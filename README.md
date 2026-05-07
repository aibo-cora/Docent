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
2. **Compile:** The **DocentPlugin** runs during the Xcode build, invoking the compiler to chunk your Markdown and generate dual-vector embeddings (Title + Body).
3. **Embed:** An optimized, read-only **SQLite** index (`.docent`) is packed into your app bundle.
4. **Query:** At runtime, the **DocentEngine** uses the **Accelerate** framework to find relevant matches with near-zero latency.

---

## Installation & Setup

### 1. Add Dependency
Add Docent to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/aibo-cora/Docent", from: "1.3.0")
]
```

### 2. Configure Your Target
In your app target settings:

1.  **Frameworks**: Add **Docent** and **DocentUI** to "Frameworks, Libraries, and Embedded Content."
2.  **Build Phases**: Add **DocentPlugin** to the "Run Build Tool Plugins" section.

### 3. Add Documentation Folder
Initialize your project to create the folder: `swift package docent-init` (or via Xcode menu).

---

## Usage

### One-Line Integration (SwiftUI)
The easiest way to add search to your app is using the managed `DocentSearch` view:

```swift
import SwiftUI
import DocentUI

struct HelpView: View {
    var body: some View {
        DocentSearch(resource: "Knowledge")
    }
}
```

### High-Precision Search
Docent uses **Dual-Vector Weighted Search**, which embeds your Titles and Body text separately to ensure that exact topic matches (like "deleting account") receive high confidence scores.

### Incremental Build Caching
Starting in v1.3.0, Docent uses a state-aware compiler that only re-indexes documentation that has actually changed. This makes builds lightning fast even for massive documentation sets.

---

## Security & Encryption

Docent provides two tiers of on-device security:

### Tier 1: CryptoKit (Default)
Encrypts documentation text and vectors using AES-GCM. Zero impact on bundle size.
- **Runtime:** `DocentSearch(resource: "Knowledge", encryption: .cryptoKit(key: "your-key"))`

### Tier 2: SQLCipher (Full Database Encryption)
Encrypts the entire `.docent` file at the page level. Adds ~2.5MB to bundle size.
- **Dependency**: Link the `DocentSQLCipher` target.
- **Runtime:** `DocentSearch(resource: "Knowledge", encryption: .sqlCipher(passphrase: "your-pass"))`

---

## Markdown & Metadata Guide

Define metadata at the top of your `.md` files to control the engine:

```markdown
---
title: Advanced Encryption
tags: security, pro
priority: 1.5
---

# Shamir Secret Sharing
This section explains our security model...
```

- **title**: Overrides the filename in search results.
- **tags**: Used for scoped searching (see `DocentSearchConfiguration`).
- **priority**: A multiplier (default 1.0) to "boost" important docs.

## License
Docent is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
