# Idea: Source-to-Knowledge Synthesis (Docent Autopilot)

## Concept
Automatically generate conceptual, user-friendly Markdown documentation by analyzing the project's source code and technical comments using a Local LLM (Apple Intelligence). This transforms Docent from a search engine into a self-documenting ecosystem.

## The Technical "Magic"

### 1. Signal-to-Noise Extraction (SwiftSyntax & Macros)
- **The `@Docent` Macro**: A Swift Macro that marks classes or structs for indexing. It can perform compile-time validation to ensure the code is "explainable."
- **Variable Extraction**: The tool identifies factual constants (e.g., `let threshold = 3`, `let shardCount = 5`) and "locks" them into the LLM prompt, ensuring the generated text is factually accurate to the code's configuration.
- **Property Analysis**: Using property wrappers (like `@Published` or `@Secret`), the tool identifies sensitive data and automatically prioritizes security warnings in the output.

### 2. Hybrid Documentation Strategy
To eliminate AI "hallucinations," the tool uses a two-layer approach:
- **Hard Facts (The Skeleton)**: Values like algorithm names, thresholds, and limits are extracted directly from the AST (Abstract Syntax Tree).
- **AI Narrative (The Muscle)**: The local LLM writes the "Human" explanation of why those numbers matter (e.g., *"This means you can lose two shards and still recover your vault"*).

### 3. Leveraging the "Writing Tools" API
- **Apple Intelligence**: Uses on-device Foundation Models for synthesis.
- **Security**: Since the LLM runs locally on the developer's Mac, the source code never leaves the device—a critical requirement for security-focused apps (like those using SSS).

### 4. Handling Dynamic App State (Runtime Variables)
Since users often choose their own configurations (e.g., custom shard counts or thresholds in SSS), the tool doesn't just generate static text.
- **Placeholder Generation**: The Synthesis Tool identifies variables in the code and generates Markdown with placeholders: *"You chose to split your secret into **{{shardCount}}** shards."*
- **Runtime Injection**: At query time, the developer passes the "Live State" to the `DocentEngine`. The engine then merges these values into the retrieved documentation chunks before showing them to the user.
- **Logic Explanation**: The LLM writes different "Narrative Branches" based on the variables (e.g., explaining the trade-offs of a high vs. low threshold).

### 5. Solving the "Black Box" Problem
Developers need to trust what the AI writes.
- **Proofreading Folder**: Generated `.md` files are saved to a visible `DocentDocs/Generated/` folder.
- **Human Override**: If a developer manually edits a generated file, the tool respects the manual changes (using file hashing to track "Human-vetted" status).

## The Autopilot Lifecycle

| Step | Action | Outcome |
|---|---|---|
| **Code** | Dev writes a struct with a `@Docent` tag and dynamic variables. | No manual docs required. |
| **Build** | Plugin triggers `docent-synthesizer`. | Code is parsed; placeholders like `{{threshold}}` are created. |
| **Synthesis** | AI generates a dynamic `SSS.md` template. | Conceptual logic is written with variable slots. |
| **Indexing** | `docent-compiler` (SQLite/Accelerate) runs. | Templates are vectorized into the app bundle. |
| **Runtime** | User asks "What is my threshold?" | Engine merges live app state into the template and answers. |

## Roadmap Position
Targeted for **v1.5** or **v2.0**. This feature serves as the primary differentiator between Docent and every other help-desk SDK on the market.
