import XCTest
@testable import Docent

final class DocentTests: XCTestCase {
    func testEncryption() async throws {
        let testDocPath = "test.docent"
        
        // 1. Try to load and query WITH the correct key
        let engineWithKey = try DocentEngine(path: testDocPath, encryption: .cryptoKit(key: "supersecret"))
        let results = try await engineWithKey.query("secret")
        
        XCTAssertFalse(results.isEmpty)
        XCTAssertEqual(results.first?.chunk.title, "Test Chunk")
        XCTAssertEqual(results.first?.chunk.text, "This is a secret chunk.")
        print("✅ Decryption successful with correct key.")
        
        // 2. Try to load with WRONG key (should fail decryption)
        let engineWithWrongKey = try DocentEngine(path: testDocPath, encryption: .cryptoKit(key: "wrongkey"))
        do {
            _ = try await engineWithWrongKey.query("secret")
            XCTFail("Should have failed decryption with wrong key")
        } catch {
            print("✅ Correctly failed decryption with wrong key: \(error)")
        }
        
        // 3. Try to load with NO key (should fail since data is encrypted)
        let engineNoKey = try DocentEngine(path: testDocPath, encryption: .none)
        let resultsNoKey = try await engineNoKey.query("secret")
        // Since it's encryptionType 2, the engine will skip decryption and likely 
        // return gibberish or fail depending on how String(data:encoding:) handles it.
        // In our current implementation, it returns empty string if encoding fails.
        XCTAssertTrue(resultsNoKey.first?.chunk.text == "" || resultsNoKey.first?.chunk.text == nil)
        print("✅ Correctly returned no/empty content without key.")
    }
}
