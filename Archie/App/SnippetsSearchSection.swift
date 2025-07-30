//  SnippetsSearchSection.swift

import SwiftUI

// MARK: - Snippets Search Section 100094
struct SnippetsSearchSection: View {
    @Binding var searchText: String
    let availableWidth: CGFloat
    @StateObject private var snippetManager = SnippetManager.shared
    
    init(searchText: Binding<String>, availableWidth: CGFloat = 0) {
        self._searchText = searchText
        self.availableWidth = availableWidth
    }
    
    var body: some View {
        VStack(spacing: 8) {
            enhancedSearchBar
            if availableWidth > 0 && availableWidth < 400 {
                compactStatsView
            } else {
                fullStatsView
            }
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

// MARK: - Stats Views 100096
extension SnippetsSearchSection {
    private var fullStatsView: some View {
        HStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("\(snippetManager.snippets.count) snippets")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 4) {
                Image(systemName: "folder")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                Text("\(snippetManager.collections.count) collections")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
    
    private var compactStatsView: some View {
        HStack(spacing: 8) {
            Text("\(snippetManager.snippets.count)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("•")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Text("\(snippetManager.collections.count) collections")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
}
