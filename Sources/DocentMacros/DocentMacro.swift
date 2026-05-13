import Foundation

/// Marks a type for indexing by Docent Autopilot.
/// - Parameter topic: The human-readable name of the topic for this code section.
@attached(peer)
public macro Docent(topic: String) = #externalMacro(module: "DocentMacrosCompilerPlugin", type: "DocentMacro")
