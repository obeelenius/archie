//
//  CollectionsContentView.swift
//  Archie
//
//  Created by Amy Elenius on 17/7/2025.
//


import SwiftUI

// MARK: - Collections Content View
struct CollectionsContentView: View {
    @StateObject private var snippetManager = SnippetManager.shared
    
    var snippetCollections: [String: [Snippet]] {
        Dictionary(grouping: snippetManager.snippets) { snippet in
            if snippet.shortcut.hasPrefix("@") {
                return "Email & Contacts"
            } else if snippet.shortcut.hasPrefix("#") {
                return "Social & Tags"
            } else if snippet.shortcut.hasPrefix("addr") || snippet.shortcut.contains("address") {
                return "Addresses"
            } else if snippet.shortcut.contains("phone") || snippet.shortcut.contains("tel") {
                return "Phone Numbers"
            } else if snippet.shortcut.contains("sig") || snippet.shortcut.contains("signature") {
                return "Signatures"
            } else {
                return "General"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .foregroundColor(.purple)
                            .font(.system(size: 10))
                        Text("\(snippetCollections.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                        Text("collections")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Collections grid
            if snippetCollections.isEmpty {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.1))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "folder")
                            .font(.system(size: 32))
                            .foregroundColor(.purple)
                    }
                    
                    VStack(spacing: 12) {
                        Text("No collections yet")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("Collections will automatically appear as you create snippets with similar patterns")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(32)
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 280), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Array(snippetCollections.keys.sorted()), id: \.self) { collectionName in
                            CollectionCard(
                                name: collectionName,
                                snippets: snippetCollections[collectionName] ?? []
                            )
                        }
                    }
                    .padding(12)
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            }
        }
    }
}