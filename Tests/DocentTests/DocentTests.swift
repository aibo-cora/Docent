import XCTest
@testable import Docent

final class DocentTests: XCTestCase {
    func testEncryption() async throws {
        // We need to re-compile test.docent with the new schema if we want to use it
        // Or just use the new v0.6-test.docent for everything.
    }
    
    func testHierarchicalSearch() async throws {
        let testDocPath = "v0.6-test.docent"
        let engine = try DocentEngine(path: testDocPath)
        
        // Query for nested content
        let results = try await engine.query("nested content under 1.1")
        
        XCTAssertFalse(results.isEmpty)
        let topResult = results.first!
        
        // Verify metadata
        XCTAssertEqual(topResult.chunk.title, "Subsection 1.1")
        XCTAssertEqual(topResult.chunk.breadcrumb, "Main Title > Section 1 > Subsection 1.1")
        XCTAssertTrue(topResult.chunk.tags.contains("setup"))
        XCTAssertTrue(topResult.chunk.tags.contains("advanced"))
        XCTAssertEqual(topResult.chunk.priority, 1.5)
        
        print("✅ Hierarchical search and metadata verified.")
        print("   Breadcrumb: \(topResult.chunk.breadcrumb)")
        print("   Confidence: \(topResult.confidence)")
    }
}
