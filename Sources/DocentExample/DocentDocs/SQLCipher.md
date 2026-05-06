# SQLCipher Integration

**Full Database Encryption for Enterprise-Grade Security.**

Docent v1.1.0 introduces optional support for **SQLCipher**, allowing you to encrypt the entire `.docent` knowledge base at the page level.

## Why use SQLCipher?
While the default **CryptoKit** encryption protects your content and vectors, SQLCipher goes a step further by encrypting the **entire database file**. This includes table structures, indexes, and all metadata, making the file completely unreadable without the passphrase.

## Setup

### 1. Add the Dependency
To use SQLCipher, you must link the `DocentSQLCipher` target in your `Package.swift`:

```swift
.target(
    name: "MyApp",
    dependencies: [
        .product(name: "DocentSQLCipher", package: "Docent")
    ]
)
```

### 2. Build-Time Encryption
Pass a password to the `docent-compiler` during your build process:

```bash
docent-compiler ./MyDocs Knowledge.docent --encryption sqlcipher --password "my-secret-passphrase"
```

### 3. Runtime Initialization
Pass the passphrase to the `DocentSearch` view or `DocentEngine`:

```swift
import DocentUI

struct ContentView: View {
    var body: some View {
        DocentSearch(
            resource: "Knowledge",
            encryption: .sqlCipher(passphrase: "my-secret-passphrase")
        )
    }
}
```

## Performance & Size
Using SQLCipher adds approximately **2.5MB** to your app's bundle size. If you do not require full-file encryption, we recommend using the default **CryptoKit** option, which has zero impact on bundle size.
