import Foundation

/// A standardized prompt for Retrieval-Augmented Generation (RAG).
/// It combines the system persona, the retrieved documentation context, and the user's query.
public struct SynthesisPrompt: Sendable {
    public let query: String
    public let context: String
    public let systemPersona: String
    
    public init(query: String, context: String, systemPersona: String = "You are a helpful technical assistant. Answer the user's question using ONLY the provided documentation context. If the answer is not in the context, say 'I don't know'.") {
        self.query = query
        self.context = context
        self.systemPersona = systemPersona
    }
    
    /// Formats the prompt into a single string for LLM consumption.
    public var formattedPrompt: String {
        return """
        \(systemPersona)
        
        [CONTEXT]
        \(context)
        
        [QUERY]
        \(query)
        
        [ANSWER]
        """
    }
}

/// A protocol defining the behavior of an on-device LLM provider.
/// Supports both full-response and token-by-token streaming.
public protocol LLMProvider: Sendable {
    /// The name of the provider (e.g., "Apple Intelligence" or "CoreML Fallback").
    var name: String { get }
    
    /// Generates a streaming response for the given prompt.
    /// - Parameter prompt: The RAG prompt containing context and query.
    /// - Returns: A stream of tokens as they are generated.
    func generateResponse(for prompt: SynthesisPrompt) -> AsyncThrowingStream<String, Error>
    
    /// Checks if the provider is currently available on the device.
    func isAvailable() async -> Bool
}
