import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

public struct AppleIntelligenceTest {
    public static func checkAvailability() -> Bool {
        #if canImport(FoundationModels)
        return true
        #else
        return false
        #endif
    }
}
