# Plan: v1.6.0 — Docent Macro

## Objective
Transition the Docent Autopilot extraction system from the fragile comment-based marker (`/// @docent`) to a robust, native Swift Macro (`@Docent`). This enables compile-time validation, ensures correct usage, and provides a cleaner API for developers marking their code for AI synthesis.

## Key Files & Context
- **Branch**: `v1.6.0/docent-macro`
- `Package.swift`: Define new macro targets (`DocentMacros` and its compiler plugin).
- `Sources/DocentMacros/`: New directory for the macro definition and implementation.
- `Sources/DocentScraper/KnowledgeScraper.swift`: Update AST parsing to look for attributes instead of comments.
- `Sources/DocentExample/ShamirSecretSharing.swift`: Update to use the new macro format.

## Implementation Steps

### 1. Macro Target Setup
- Update `Package.swift` to include `SwiftCompilerPlugin` from the `swift-syntax` package.
- Define two new targets:
  - `DocentMacrosCompilerPlugin` (type: `macro`): Contains the actual macro expansion/validation logic.
  - `DocentMacros` (type: `target`): Exposes the public `@Docent` macro interface.
- Add `DocentMacros` as a dependency to the main `Docent` target so clients can use it.

### 2. Macro Definition & Implementation
- Create `Sources/DocentMacros/DocentMacro.swift`:
  - Define the public macro: `@attached(peer) public macro Docent(topic: String) = #externalMacro(module: "DocentMacrosCompilerPlugin", type: "DocentMacro")`
- Create `Sources/DocentMacrosCompilerPlugin/DocentMacro.swift`:
  - Implement `PeerMacro` protocol.
  - **Compile-Time Validation**: Ensure the macro is only attached to `StructDeclSyntax`, `ClassDeclSyntax`, or `EnumDeclSyntax`. If attached to a variable or function, emit a diagnostic error (e.g., `"@Docent can only be applied to structs, classes, or enums."`).
  - Return an empty array of declarations (we are using the macro purely as an AST marker and validation tool, not to generate code).

### 3. Refactoring the Knowledge Scraper
- Update `Sources/DocentScraper/KnowledgeScraper.swift`.
- Instead of scanning `leadingTrivia` for `/// @docent(topic: "...")`, inspect the `attributes` list of the declaration.
- If an attribute named `Docent` is found, extract the `topic` argument from its argument list.
- Retain the existing logic that extracts properties, constants, and standard `///` doc comments.

### 4. Updating Examples and Tests
- Update `Sources/DocentExample/ShamirSecretSharing.swift` to replace `/// @docent(topic: "...")` with the actual `@Docent(topic: "...")` macro.
- Add `import DocentMacros` where necessary.

## Verification & Testing
- **Validation Test**: Temporarily apply `@Docent` to a variable in the example app and verify that Xcode/compiler throws the expected error.
- **End-to-End Build**: Run the full Xcode build on the example app to verify the Macro expands correctly, the build tool plugin runs, the Scraper successfully extracts the facts using the new attribute logic, and the Synthesizer generates the final Markdown documentation.
- **Binary Check**: Verify `Knowledge.docent` is generated without errors.