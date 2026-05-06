# Plan: v1.0.0 — Public Launch

## Objective
Finalize Docent for public release by implementing native SwiftUI components, optimizing build performance with incremental indexing, and providing a comprehensive example app.

## Key Files & Context
- **Branch**: `v1.0.0/core-ui`
- `Package.swift`: Add `DocentUI` target and Example target.
- `Sources/DocentUI/`: New target for SwiftUI components.
- `Sources/DocentPlugin/`: Update for incremental build support.
- `Examples/DocentExample/`: A new example project folder.

## Implementation Steps

### 1. DocentUI (SwiftUI Components)
- **DocentSearchView**: A primary search interface with a search bar and live result updates.
- **DocentResultView**: A row component showing breadcrumbs, confidence levels, and text snippets.
- **DocentDetailView**: A view to display the full content of a selected chunk (rendered as simple text/markdown).
- **Style Customization**: Ensure components support basic theming (colors, fonts).

### 2. Incremental Build Support
- **Hashing Logic**: Update `DocentCompiler` to generate a manifest of file hashes during compilation.
- **Plugin Optimization**: Update `DocentPlugin` to compare current file hashes against the manifest and only invoke the compiler if changes are detected.
- **Resource Management**: Ensure the `.docent` file is correctly re-bundled when updated.

### 3. Example App (Sandbox)
- Create a simple iOS app within the repository.
- Integrate the `DocentPlugin` and `DocentUI`.
- Bundle a set of sample documentation to demonstrate semantic search and breadcrumbs.

### 4. API Refinement & Final Docs
- **Public API Review**: Ensure all public structs and classes have clear documentation comments.
- **README Update**: Add a section on `DocentUI` usage and standard patterns.
- **Version Tagging**: Prepare the repository for the `1.0.0` tag.

## Verification & Testing
- **UI Testing**: Verify that search components behave correctly across different screen sizes and orientations.
- **Performance Testing**: Measure build times with and without incremental changes to documentation.
- **Integration Test**: Confirm that the Example app runs out-of-the-box after cloning the repo.
