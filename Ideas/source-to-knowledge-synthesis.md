# Idea: Source-to-Knowledge Synthesis (Docent Autopilot)

## Concept
Automatically generate user-friendly Markdown documentation by analyzing the project's source code and technical comments using a Local LLM (Apple Intelligence or similar).

## Problem Solved
- Documentation going stale as code changes.
- Developers not having the time or interest in writing 'Help' content.
- The gap between technical API docs (DocC) and human-friendly 'How-to' guides.

## How it Works
1. **Marker Detection**: Developers add tags like `/// @docent(topic: 'Shamir Secret Sharing')` to their Swift code.
2. **Context Extraction**: A build tool (using SwiftSyntax) extracts the logic, parameters (e.g., threshold, shard count), and comments from the marked sections.
3. **LLM Synthesis**: The extracted code is passed to a local LLM with a specialized prompt to generate a conceptual, user-friendly guide.
4. **Automated Pipeline**: The generated Markdown is automatically fed into the `docent-compiler` and packed into the app bundle.

## Example Case: Shamir Secret Sharing
- **Code**: A struct with `threshold = 3` and `totalShards = 5`.
- **Output**: A guide explaining that 'You need 3 of 5 friends to unlock your vault,' including security considerations and distribution tips, all derived from the code's configuration.

## Roadmap Position
Targeted for **v1.5** or **v2.0** as a premium 'Autopilot' feature.
