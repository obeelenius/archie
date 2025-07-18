//  CollectionsContentView.swift

import SwiftUI

// MARK: - Collections Content View 100109
struct CollectionsContentView: View {
    @Binding var editingCollection: SnippetCollection?
    @StateObject private var snippetManager = SnippetManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            compactHeader
            Divider()
            collectionsContent
        }
    }
}

// MARK: - Header Section 100110
extension CollectionsContentView {
    private var compactHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                collectionsStats
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private var collectionsStats: some View {
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
    }
}

// MARK: - Collections Content 100111
extension CollectionsContentView {
    @ViewBuilder
    private var collectionsContent: some View {
        if snippetManager.collections.isEmpty {
            emptyCollectionsView
        } else {
            collectionsGrid
        }
    }
    
    private var emptyCollectionsView: some View {
        VStack(spacing: 24) {
            emptyStateIcon
            emptyStateText
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
    
    private var emptyStateIcon: some View {
        ZStack {
            Circle()
                .fill(Color.purple.opacity(0.1))
                .frame(width: 80, height: 80)
            
            Image(systemName: "folder")
                .font(.system(size: 32))
                .foregroundColor(.purple)
        }
    }
    
    private var emptyStateText: some View {
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
    
    private var collectionsGrid: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 280), spacing: 16)
            ], spacing: 16) {
                ForEach(snippetManager.collections) { collection in
                    CollectionCard(
                        collection: collection,
                        snippets: snippetManager.snippets(for: collection),
                        editingCollection: $editingCollection
                    )
                }
            }
            .padding(12)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
}
