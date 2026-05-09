# Autopilot: AI Synthesizer

**Conceptual Intelligence from Raw Logic.**

Docent v1.5.0 introduces the **AI Synthesizer**, the second phase of our Autopilot pipeline. It uses on-device **Apple Intelligence** to translate the raw code facts extracted by the Knowledge Scraper into human-friendly Markdown documentation.

## How it Works
The synthesizer performs three critical steps during your build process:

1.  **Prompt Construction**: It builds a specialized technical prompt containing the extracted constants (e.g. `threshold = 3`), method signatures, and your technical comments.
2.  **Narrative Synthesis**: It calls the on-device Apple Foundation Models to write a clear, conceptual explanation of what the feature does and how a user should interact with it.
3.  **Hybrid Fact-Locking**: It ensures the generated narrative is factually anchored to your code. If the AI describes your logic, it *must* use the hard numbers found in your source-of-truth variables.

## Privacy & Privacy Guarantee
Unlike traditional AI tools that send your source code to the cloud, Docent Autopilot is **100% On-Device**:
-   **Local Processing**: The synthesis happens entirely on your Mac's Neural Engine.
-   **Zero Leakage**: Your code context never leaves your computer.
-   **Secure Builds**: You get the power of LLMs without compromising your intellectual property.

## Generated Documentation
Synthesized guides are automatically saved to `DocentDocs/Generated/`. You can open these files to proofread them. If you manually edit a generated file, Docent will respect your changes and treat them as the new source of truth.

## Requirements
To use the AI Synthesizer, you must be using a Mac with **Apple Silicon** (M1 or later) running **macOS Sequoia (15.0)** or newer, as it relies on the system-level Apple Intelligence APIs.
