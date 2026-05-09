import Foundation
import CryptoKit

public class EncryptionService {
    private let key: SymmetricKey
    
    public init(keyData: Data) throws {
        let hashedKey = SHA256.hash(data: keyData)
        self.key = SymmetricKey(data: hashedKey)
    }
    
    public func encrypt(_ data: Data) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        return sealedBox.combined!
    }
    
    public func decrypt(combinedData: Data) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
        return try AES.GCM.open(sealedBox, using: key)
    }
}
