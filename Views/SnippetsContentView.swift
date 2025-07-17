//
//  SnippetsContentView.swift
//  Archie
//
//  Created by Amy Elenius on 17/7/2025.
//


import SwiftUI

// MARK: - Snippets Content View
struct SnippetsContentView: View {
    let filteredSnippets: [Snippet]
    @Binding var searchText: String
    @Binding var editingSnippet: Snippet?
    @StateObject private var snippetManager = SnippetManager.shared
    
    var groupedSnippets: [String: [Snippet]] {
        Dictionary(grouping: filteredSnippets, by: classifySnippet)
    }
    
    private func classifySnippet(_ snippet: Snippet) -> String {
        let shortcut = snippet.shortcut.lowercased()
        
        if shortcut.hasPrefix("@") { return "Email & Contacts" }
        if shortcut.hasPrefix("#") { return "Social & Tags" }
        if shortcut.contains("addr") || shortcut.contains("address") { return "Addresses" }
        if shortcut.contains("phone") || shortcut.contains("tel") { return "Phone Numbers" }
        if shortcut.contains("sig") || shortcut.contains("signature") { return "Signatures" }
        if shortcut.contains("date") || shortcut.contains("time") || shortcut.contains("today") || shortcut.contains("now") {
            return "Date & Time"
        }
        return "General"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and stats section
            SnippetsSearchSection(searchText: $searchText)
            
            Divider()
            
            // Content area
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
    
    private func getCollectionIcon(for collectionName: String) -> String {
        switch collectionName {
        case "Email & Contacts": return "at"
        case "Social & Tags": return "number"
        case "Addresses": return "location"
        case "Phone Numbers": return "phone"
        case "Signatures": return "signature"
        case "Date & Time": return "clock"
        default: return "folder"
        }
    }
}