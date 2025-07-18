//  SnippetsSearchSection.swift

import SwiftUI

// MARK: - Snippets Search Section 100094
struct SnippetsSearchSection: View {
    @Binding var searchText: String
    @StateObject private var snippetManager = SnippetManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            enhancedSearchBar
            compactStatsRow
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

// MARK: - Compact Stats Row 100096
extension SnippetsSearchSection {
    private var compactStatsRow: some View {
        HStack(spacing: 12) {
            totalSnippetsStats
            enabledSnippetsStats
            Spacer()
        }
        .padding(.horizontal, 2)
    }
    
    private var totalSnippetsStats: some View {
        HStack(spacing: 4) {
            Image(systemName: "doc.text")
                .foregroundColor(.accentColor)
                .font(.system(size: 10))
            Text("\(snippetManager.snippets.count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
            Text("snippets")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
    
    private var enabledSnippetsStats: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.green)
                .font(.system(size: 10))
            Text("\(snippetManager.snippets.filter(\.isEnabled).count)")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.primary)
            Text("enabled")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}
