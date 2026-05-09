# Plan: v1.5.0 — The AI Synthesizer

## Objective
Implement the "Narrative Synthesis" layer of Docent Autopilot. This feature uses on-device **Apple Foundation Models** to translate the structured technical context from the v1.4.0 Knowledge Scraper into human-friendly Markdown documentation.

## Key Files & Context
- **Branch**: `v1.5.0/ai-synthesizer`
- `Sources/DocentSynthesizer/`: New target for AI communication logic.
- `Plugins/DocentPlugin/main.swift`: Update to trigger the synthesizer before the compiler.
- `Sources/DocentExample/DocentDocs/AutopilotSynthesis.md`: New documentation file.

## Implementation Steps

### 1. Synthesizer Implementation
- Create a new tool `DocentSynthesizer` that interfaces with Apple's Foundation Models (via private system API or the 2026 equivalent of WritingTools).
- **Prompt Engineering**: Develop a template-based system that:
    - Sets the persona (Technical Writer).
    - Injects the `KnowledgeContext` (Topic, Constants, Methods).
    - Enforces Markdown formatting rules.

### 2. Hybrid Fact-Locking
- Implement a post-processing pass that ensures all `constants` from the source code (e.g. `threshold = 3`) are explicitly mentioned in the generated text.
- If the AI hallucinates a value that contradicts the code, the tool will automatically override it with the source-of-truth.

### 3. Pipeline Integration
- Update the `DocentPlugin` (Build Tool Plugin):
    - **Step A**: Run `DocentScraper` to extract facts.
    - **Step B**: Run `DocentSynthesizer` to generate `.md` files in `DocentDocs/Generated/`.
    - **Step C**: Run `DocentCompiler` to index everything (Manual + Generated) into `.docent`.

### 4. Self-Documenting the Feature
- Create `Sources/DocentExample/DocentDocs/AutopilotSynthesis.md` explaining the synthesis process, privacy guarantees, and how to verify generated content.

## Verification & Testing
- **Synthesis Test**: Run the build on a class marked with `/// @docent`.
- **Verification**: 
    - Confirm that a new `.md` file appears in the `Generated/` folder.
    - Verify that the text correctly explains the feature's logic.
    - Ensure that hard numbers from the code (like SSS thresholds) are factually accurate in the output.
