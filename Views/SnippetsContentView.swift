//  SnippetsContentView.swift

import SwiftUI

// MARK: - Snippets Content View 100152
struct SnippetsContentView: View {
    let filteredSnippets: [Snippet]
    @Binding var searchText: String
    @Binding var editingSnippet: Snippet?
    @StateObject private var snippetManager = SnippetManager.shared
    
    var groupedSnippets: [String: [Snippet]] {
        Dictionary(grouping: filteredSnippets, by: getCollectionName)
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
        if filteredSnippets.isEmpty {
            EmptyStateView(isSearching: !searchText.isEmpty)
        } else {
            SnippetsListView(
                groupedSnippets: groupedSnippets,
                editingSnippet: $editingSnippet
            )
        }
    }
}
