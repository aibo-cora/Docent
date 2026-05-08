# Plan: v1.4.0 — The Knowledge Scraper

## Objective
Implement the "Signal Extraction" engine of Docent Autopilot. This tool uses **SwiftSyntax** to analyze source code, find marked sections, and extract factual data (constants, variables, doc comments) to prepare a structured context for the AI synthesis pass in v1.5.0.

## Key Files & Context
- **Branch**: `v1.4.0/knowledge-scraper`
- `Package.swift`: Add `swift-syntax` dependency.
- `Sources/DocentScraper/`: New target for source code analysis logic.
- `Sources/DocentExample/DocentDocs/AutopilotExtraction.md`: New documentation file.

## Implementation Steps

### 1. Dependency Integration
- Add the `apple/swift-syntax` package to `Package.swift`.
- Create a new library target `DocentScraper` that provides the AST walking logic.

### 2. The Knowledge Walker
- Implement a `SyntaxWalker` that scans `.swift` files for a specific trigger comment: `/// @docent`.
- When a trigger is found, extract the following from the associated Class, Struct, or Enum:
    - **Doc Comments**: All `///` comments preceding the declaration.
    - **Constants**: Property names and values of `let` declarations (e.g., `let threshold = 3`).
    - **Variables**: Property names of `var` declarations for dynamic template generation.
    - **Method Signatures**: Public method names to understand available actions.

### 3. Structured Data Export
- Implement logic to serialize the extracted facts into a `KnowledgeContext` (JSON).
- This JSON will serve as the "Prompt Input" for the Apple Intelligence synthesis pass in v1.5.0.

### 4. Self-Documenting the Feature
- Create `Sources/DocentExample/DocentDocs/AutopilotExtraction.md` to explain how developers can "mark" their code for Autopilot and what kind of facts the scraper can see.

## Verification & Testing
- **Extraction Test**: Use the Shamir Secret Sharing implementation as a test case.
- **Verification**: 
    - Ensure the scraper correctly identifies `threshold` and `totalShards` constants.
    - Verify that technical doc comments are correctly captured.
    - Confirm that the output JSON contains all necessary signals for an AI to write a guide.
