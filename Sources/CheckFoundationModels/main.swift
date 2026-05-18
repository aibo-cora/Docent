import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

@available(macOS 26.0, *)
@main
struct CheckFoundationModels {
    static func main() async {
        #if canImport(FoundationModels)
        let model = SystemLanguageModel.default

        guard model.availability == .available else {
            print("❌ SystemLanguageModel not available: \(model.availability)")
            return
        }
        print("✅ SystemLanguageModel available")

        do {
            let session = LanguageModelSession()
            let response = try await session.respond(to: "Reply with the word READY and nothing else.")
            print("✅ LanguageModelSession responded: \(response.content)")
        } catch {
            print("❌ LanguageModelSession error: \(error)")
        }
        #else
        print("❌ FoundationModels not available on this platform")
        #endif
    }
}
