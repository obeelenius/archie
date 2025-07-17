//
//  SnippetsSearchSection.swift
//  Archie
//
//  Created by Amy Elenius on 17/7/2025.
//


import SwiftUI

// MARK: - Snippets Search Section
struct SnippetsSearchSection: View {
    @Binding var searchText: String
    @StateObject private var snippetManager = SnippetManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            // Enhanced search bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 14))
                
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(.vertical, 6)
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.controlBackgroundColor))
                    .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
            )
            
            // Compact stats row
            HStack(spacing: 12) {
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
                
                Spacer()
            }
            .padding(.horizontal, 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
}