//  SnippetsContentView.swift

import SwiftUI

// MARK: - Snippets Content View 100152
struct SnippetsContentView: View {
    let filteredSnippets: [Snippet]
    @Binding var searchText: String
    @Binding var editingSnippet: Snippet?
    let onCollectionHeaderTapped: (() -> Void)?
    @StateObject private var snippetManager = SnippetManager.shared
    
    init(filteredSnippets: [Snippet],
         searchText: Binding<String>,
         editingSnippet: Binding<Snippet?>,
         onCollectionHeaderTapped: (() -> Void)? = nil) {
        self.filteredSnippets = filteredSnippets
        self._searchText = searchText
        self._editingSnippet = editingSnippet
        self.onCollectionHeaderTapped = onCollectionHeaderTapped
    }
    
    // Group snippets by collection, but ensure all collections are represented
    // This computed property will update automatically when snippetManager.snippets changes
    var allCollectionsWithSnippets: [(SnippetCollection, [Snippet])] {
        var result: [(SnippetCollection, [Snippet])] = []
        
        for collection in snippetManager.collections.sorted(by: { $0.name < $1.name }) {
            // Use snippetManager.snippets directly to ensure reactivity
            let snippetsInCollection = snippetManager.snippets.filter { snippet in
                snippet.collectionId == collection.id &&
                (searchText.isEmpty ||
                 snippet.shortcut.localizedCaseInsensitiveContains(searchText) ||
                 snippet.expansion.localizedCaseInsensitiveContains(searchText))
            }
            result.append((collection, snippetsInCollection))
        }
        
        return result
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchAndStatsSection
            Divider()
            contentArea
        }
    }
}

// MARK: - Helper Methods 100153
extension SnippetsContentView {
    private func getCollectionName(_ snippet: Snippet) -> String {
        guard let collectionId = snippet.collectionId,
              let collection = snippetManager.collections.first(where: { $0.id == collectionId }) else {
            return "General"
        }
        return collection.name
    }
    
    private func getCollectionIcon(for collectionName: String) -> String {
        if let collection = snippetManager.collections.first(where: { $0.name == collectionName }) {
            return collection.icon.isEmpty ? "folder" : collection.icon
        }
        return "folder"
    }
}

// MARK: - View Components 100154
extension SnippetsContentView {
    private var searchAndStatsSection: some View {
        SnippetsSearchSection(searchText: $searchText)
    }
    
    @ViewBuilder
    private var contentArea: some View {
        if snippetManager.collections.isEmpty {
            EmptyStateView(isSearching: false)
        } else {
            AllCollectionsListView(
                collectionsWithSnippets: allCollectionsWithSnippets,
                editingSnippet: $editingSnippet,
                onCollectionHeaderTapped: onCollectionHeaderTapped
            )
        }
    }
}
