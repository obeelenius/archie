import Foundation

class SnippetManager: ObservableObject {
    static let shared = SnippetManager()
    
    @Published var snippets: [Snippet] = [] {
        didSet {
            saveSnippets()
        }
    }
    
    @Published var collections: [SnippetCollection] = [] {
        didSet {
            saveCollections()
        }
    }
    
    private init() {
        loadCollections()
        loadSnippets()
        
        // Add default collection if none exist
        if collections.isEmpty {
            let defaultCollection = SnippetCollection(name: "Default", suffix: "", keepDelimiter: false)
            collections = [defaultCollection]
        }
        
        // Add some default snippets if none exist
        if snippets.isEmpty {
            let defaultCollection = collections.first!
            snippets = [
                Snippet(shortcut: "@@", expansion: "your@email.com", collectionId: defaultCollection.id),
                Snippet(shortcut: "addr", expansion: "123 Main St\nYour City, State 12345", collectionId: defaultCollection.id),
                Snippet(shortcut: "phone", expansion: "+1 (555) 123-4567", collectionId: defaultCollection.id),
                Snippet(shortcut: "sig", expansion: "Best regards,\nYour Name", collectionId: defaultCollection.id),
                Snippet(shortcut: "today", expansion: "{{date}}", collectionId: defaultCollection.id),
                Snippet(shortcut: "now", expansion: "{{time}}", collectionId: defaultCollection.id)
            ]
        }
    }
    
    func addSnippet(_ snippet: Snippet) {
        snippets.append(snippet)
    }
    
    func deleteSnippet(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
    }
    
    func addCollection(_ collection: SnippetCollection) {
        collections.append(collection)
    }
    
    func deleteCollection(_ collection: SnippetCollection) {
        // Move snippets to default collection
        let defaultCollection = collections.first { $0.name == "Default" } ?? collections.first!
        for i in snippets.indices {
            if snippets[i].collectionId == collection.id {
                snippets[i].collectionId = defaultCollection.id
            }
        }
        collections.removeAll { $0.id == collection.id }
    }
    
    func collection(for snippet: Snippet) -> SnippetCollection? {
        guard let collectionId = snippet.collectionId else { return nil }
        return collections.first { $0.id == collectionId }
    }
    
    func snippets(for collection: SnippetCollection) -> [Snippet] {
        return snippets.filter { $0.collectionId == collection.id }
    }
    
    func getExpansion(for shortcut: String) -> String? {
        // Check all enabled collections and their snippets
        for collection in collections.filter({ $0.isEnabled }) {
            let collectionSnippets = snippets(for: collection).filter { $0.isEnabled }
            
            for snippet in collectionSnippets {
                let fullShortcut = snippet.fullShortcut(with: collection)
                if fullShortcut == shortcut {
                    return snippet.processedExpansion()
                }
            }
        }
        return nil
    }
    
    private func saveSnippets() {
        if let data = try? JSONEncoder().encode(snippets) {
            UserDefaults.standard.set(data, forKey: "snippets")
        }
    }
    
    private func loadSnippets() {
        if let data = UserDefaults.standard.data(forKey: "snippets"),
           let decoded = try? JSONDecoder().decode([Snippet].self, from: data) {
            snippets = decoded
        }
    }
    
    private func saveCollections() {
        if let data = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(data, forKey: "collections")
        }
    }
    
    private func loadCollections() {
        if let data = UserDefaults.standard.data(forKey: "collections"),
           let decoded = try? JSONDecoder().decode([SnippetCollection].self, from: data) {
            collections = decoded
        }
    }
}
