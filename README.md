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
    .package(url: "https://github.com/aibo-cora/Docent", from: "1.0.0")
]
```

### 2. Configure Your Target
In your app target settings:

1.  **Frameworks**: Add **Docent** and **DocentUI** to "Frameworks, Libraries, and Embedded Content."
2.  **Build Phases**: Add **DocentPlugin** to the "Run Build Tool Plugins" section.

### 3. Add Documentation Folder
Create a folder named **`DocentDocs`** in your **project's root directory** (where your `.xcodeproj` or `Package.swift` lives).

```text
MyCoolApp/
├── Sources/
├── DocentDocs/             <-- Must be named exactly this
│   ├── GettingStarted.md
│   └── Security.md
└── MyCoolApp.xcodeproj
```

**Note:** Ensure the `DocentDocs` folder is added to your Xcode project and its **Target Membership** is checked for your app target.

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

### Custom Configuration
You can fine-tune how Docent retrieves and presents results:

```swift
let config = DocentSearchConfiguration(
    titleWeight: 0.8,        // 80% weight on title matches
    bodyWeight: 0.2,         // 20% weight on content matches
    topK: 3,                 // Show only top 3 results
    silenceThreshold: 0.4,   // Hide results with score below 0.4
    filterTags: ["pro"]      // Only search documents tagged with 'pro'
)

DocentSearch(resource: "Knowledge", configuration: config)
```

---

## Markdown & Metadata Guide

### Frontmatter Support
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
- **tags**: Used for scoped searching (see `filterTags` in config).
- **priority**: A multiplier (default 1.0) to "boost" important docs.

### Hierarchical Chunking
Docent automatically generates **Breadcrumbs** (e.g., `Setup > Step 1`) based on your `#`, `##`, and `###` headers. It also performs **Context Injection**, ensuring that sub-sections understand the full context of their parent headers.

---

## Advanced Customization

| Parameter | Default | Description |
|---|---|---|
| `titleWeight` | `0.7` | Influence of the title/breadcrumb on the final score. |
| `bodyWeight` | `0.3` | Influence of the document body on the final score. |
| `highThreshold` | `0.82` | Score required for "High" confidence badge. |
| `mediumThreshold` | `0.60` | Score required for "Medium" confidence badge. |
| `silenceThreshold` | `0.35` | Results scoring below this are hidden from the user. |

---

## Security

Docent supports **AES-GCM encryption** via Apple's `CryptoKit`. 
- **Build-time:** Use the `--key` flag if running compiler manually, or configure via build settings.
- **Runtime:** `DocentSearch(resource: "Knowledge", encryption: .cryptoKit(key: "your-key"))`

## License
Docent is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
