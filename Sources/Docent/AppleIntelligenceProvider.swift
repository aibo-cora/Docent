import Foundation
import DocentCore
#if canImport(FoundationModels)
import FoundationModels
#endif

/// A `LLMProvider` backed by Apple Intelligence via `LanguageModelSession`.
/// Requires macOS 26+ / iOS 19+. Use `isAvailable()` to gate at runtime.
@available(macOS 26.0, iOS 19.0, *)
public struct AppleIntelligenceProvider: LLMProvider {
    public let name = "Apple Intelligence"

    public init() {}

    public func isAvailable() async -> Bool {
        #if canImport(FoundationModels)
        return SystemLanguageModel.default.availability == .available
        #else
        return false
        #endif
    }

    public func generateResponse(for prompt: SynthesisPrompt) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                #if canImport(FoundationModels)
                do {
                    let session = LanguageModelSession(instructions: prompt.systemPersona)
                    let userMessage = """
                        [CONTEXT]
                        \(prompt.context)

                        [QUERY]
                        \(prompt.query)
                        """
                    var lastContent = ""
                    for try await snapshot in session.streamResponse(to: userMessage) {
                        let newTokens = String(snapshot.content.dropFirst(lastContent.count))
                        if !newTokens.isEmpty {
                            continuation.yield(newTokens)
                        }
                        lastContent = snapshot.content
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
                #else
                continuation.finish(throwing: DocentError.embeddingError("FoundationModels not available on this platform"))
                #endif
            }
        }
    }
}
