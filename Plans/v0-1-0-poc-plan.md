# Plan: v0.1.0 — Proof of Concept (NLEmbedding Validation)

## Objective
The primary goal is to validate if Apple's `NLEmbedding` (NaturalLanguage framework) provides sufficient retrieval quality for technical documentation. We will build a CLI tool to benchmark Precision@3 across multiple test datasets.

## Key Files & Context
- **Branch**: `v0.1.0/poc-validation`
- `Package.swift`: Swift Package definition for the `DocentValidator` CLI.
- `Sources/DocentValidator/`: Implementation of the parser, embedder, and evaluator.
- `TestData/`: Directory containing Markdown documentation sets and their corresponding query benchmarks.

## Implementation Steps

### 1. Project Initialization
- Create a Swift Executable package.
- Set up the folder structure for `TestData`.

### 2. Test Data Preparation
- Create 5 Markdown files (`AccountSettings.md`, `Troubleshooting.md`, `SyncIssues.md`, `Authentication.md`, `Payments.md`).
- Create a `Benchmarks.json` file mapping 20 queries per document to their target header/chunk.

### 3. Core Engine Development
- **Parser**: A simple regex-based parser to split Markdown by `##` headers into `Chunk` structs.
- **Embedder**: A wrapper for `NLEmbedding.sentenceEmbedding(for: .english)` to convert chunks and queries into `[Float]` vectors.
- **Search**: Logic to calculate Cosine Similarity between vectors and rank results.

### 4. Benchmarking Logic
- Implement the evaluation loop:
    - Load a doc set -> Chunk it -> Embed it.
    - Run queries -> Retrieve Top 3.
    - Compare Top 3 against `Benchmarks.json`.
    - Calculate and print P@3 per dataset and overall.

## Verification & Testing
- **Execution**: Run `swift run DocentValidator` and inspect the output.
- **Criteria**:
    - **Success**: Overall P@3 >= 0.75.
    - **Warning**: Overall P@3 between 0.6 and 0.75 (requires investigation into chunking logic).
    - **Failure**: Overall P@3 < 0.6 (trigger fallback to CoreML/BERT research).
