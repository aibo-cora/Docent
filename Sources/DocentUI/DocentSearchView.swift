import SwiftUI
import Docent

/// A managed search view that handles the lifecycle of the DocentEngine internally.
public struct DocentSearch: View {
    let resource: String
    let bundle: Bundle
    let encryption: DocentEncryption
    let configuration: DocentSearchConfiguration
    
    @State private var engine: DocentEngine?
    @State private var loadError: Error?
    
    public init(
        resource: String = "Knowledge",
        bundle: Bundle = .main,
        encryption: DocentEncryption = .none,
        configuration: DocentSearchConfiguration = .default
    ) {
        self.resource = resource
        self.bundle = bundle
        self.encryption = encryption
        self.configuration = configuration
    }
    
    public var body: some View {
        Group {
            if let engine = engine {
                DocentSearchView(engine: engine, configuration: configuration)
            } else if let error = loadError {
                if let docentError = error as? DocentError, case .missingKnowledgeBase = docentError {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .foregroundColor(.accentColor)
                        Text("No Knowledge Found")
                            .font(.title2).bold()
                        Text("To enable search, add your Markdown files to the **DocentDocs** folder in your project and rebuild your app.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        Text("Docent will automatically index your content during the build.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("Knowledge Base Error")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }
            } else {
                ProgressView("Loading intelligence...")
                    .task {
                        await loadEngine()
                    }
            }
        }
    }
    
    private func loadEngine() async {
        do {
            let docentEngine = try DocentEngine(resource: resource, bundle: bundle, encryption: encryption)
            self.engine = docentEngine
        } catch {
            self.loadError = error
        }
    }
}

/// The underlying search interface. Can be used directly for custom implementations.
public struct DocentSearchView: View {
    @State private var searchText = ""
    @State private var results: [DocentResult] = []
    @State private var isSearching = false
    
    private let engine: DocentEngine
    private let configuration: DocentSearchConfiguration
    
    public init(engine: DocentEngine, configuration: DocentSearchConfiguration = .default) {
        self.engine = engine
        self.configuration = configuration
    }
    
    public var body: some View {
        NavigationView {
            List {
                if results.isEmpty && !searchText.isEmpty && !isSearching {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No results for '\(searchText)'")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(results) { result in
                        NavigationLink(destination: DocentDetailView(result: result)) {
                            DocentResultRow(result: result)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Ask a question...")
            .onChange(of: searchText) { newValue in
                performSearch(query: newValue)
            }
            .navigationTitle("Help & Docs")
            .overlay {
                if isSearching {
                    ProgressView()
                }
            }
        }
    }
    
    private func performSearch(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            results = []
            return
        }
        
        isSearching = true
        Task {
            do {
                let searchResults = try await engine.query(query, configuration: configuration)
                await MainActor.run {
                    self.results = searchResults
                    self.isSearching = false
                }
            } catch {
                print("Search error: \(error)")
                await MainActor.run {
                    self.isSearching = false
                }
            }
        }
    }
}

struct DocentResultRow: View {
    let result: DocentResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(result.chunk.breadcrumb)
                .font(.caption)
                .foregroundColor(.accentColor)
            
            Text(result.chunk.title)
                .font(.headline)
            
            Text(result.chunk.text)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(result.confidence.rawValue.capitalized)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(confidenceColor.opacity(0.2))
                    .foregroundColor(confidenceColor)
                    .cornerRadius(4)
                
                Spacer()
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }
    
    private var confidenceColor: Color {
        switch result.confidence {
        case .high: return .green
        case .medium: return .orange
        case .low: return .red
        }
    }
}

public struct DocentDetailView: View {
    let result: DocentResult
    
    public init(result: DocentResult) {
        self.result = result
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(result.chunk.breadcrumb)
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                    
                    Text(result.chunk.title)
                        .font(.largeTitle)
                        .bold()
                }
                
                Divider()
                
                Text(result.chunk.text)
                    .font(.body)
                    .lineSpacing(4)
                
                Spacer()
            }
            .padding()
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
