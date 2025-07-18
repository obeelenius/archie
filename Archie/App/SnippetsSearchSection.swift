//  SnippetsSearchSection.swift

import SwiftUI

// MARK: - Snippets Search Section 100094
struct SnippetsSearchSection: View {
    @Binding var searchText: String
    @StateObject private var snippetManager = SnippetManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            enhancedSearchBar
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Enhanced Search Bar 100095
extension SnippetsSearchSection {
    private var enhancedSearchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 14))
            
            TextField("Search...", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .padding(.vertical, 6)
            
            if !searchText.isEmpty {
                clearSearchButton
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(searchBarBackground)
    }
    
    private var clearSearchButton: some View {
        Button(action: { searchText = "" }) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary)
                .font(.system(size: 12))
        }
        .buttonStyle(.plain)
    }
    
    private var searchBarBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(NSColor.controlBackgroundColor))
            .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
    }
}
