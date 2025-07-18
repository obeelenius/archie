//
//  CollectionsContentView.swift
//  Archie
//
//  Created by Amy Elenius on 17/7/2025.
//


import SwiftUI

// MARK: - Collections Content View
struct CollectionsContentView: View {
    @Binding var editingCollection: SnippetCollection?
    @StateObject private var snippetManager = SnippetManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .foregroundColor(.purple)
                            .font(.system(size: 10))
                        Text("\(snippetManager.collections.count)")
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
            
            // Collections list (full width)
            if snippetManager.collections.isEmpty {
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
                        
                        Text("Collections will automatically appear as you create them")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(32)
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(snippetManager.collections) { collection in
                            CollectionCard(
                                collection: collection,
                                snippets: snippetManager.snippets(for: collection),
                                editingCollection: $editingCollection
                            )
                        }
                    }
                    .padding(16)
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            }
        }
    }
}
