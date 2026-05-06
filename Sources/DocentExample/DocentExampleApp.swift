import SwiftUI
import Docent
import DocentUI

@main
struct DocentExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        // One line of code to add full semantic search.
        DocentSearch(resource: "Knowledge", bundle: .module)
    }
}
