// AllCollectionsListView.swift

import SwiftUI
import UniformTypeIdentifiers

// MARK: - All Collections List View 100160
struct AllCollectionsListView: View {
    let collectionsWithSnippets: [(SnippetCollection, [Snippet])]
    @Binding var editingSnippet: Snippet?
    let onCollectionHeaderTapped: (() -> Void)?
    let availableWidth: CGFloat
    @StateObject private var snippetManager = SnippetManager.shared
    
    init(collectionsWithSnippets: [(SnippetCollection, [Snippet])],
         editingSnippet: Binding<Snippet?>,
         onCollectionHeaderTapped: (() -> Void)? = nil,
         availableWidth: CGFloat = 0) {
        self.collectionsWithSnippets = collectionsWithSnippets
        self._editingSnippet = editingSnippet
        self.onCollectionHeaderTapped = onCollectionHeaderTapped
        self.availableWidth = availableWidth
    }
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(collectionsWithSnippets, id: \.0.id) { collection, snippets in
                AllCollectionsSectionView(
                    collection: collection,
                    snippets: snippets,
                    isExpanded: snippetManager.expandedCollections.contains(collection.id),
                    editingSnippet: $editingSnippet,
                    availableWidth: availableWidth,
                    onToggle: {
                        toggleCollection(collection.id)
                    },
                    onHeaderTapped: onCollectionHeaderTapped
                )
            }
        }
        .onAppear {
            // Ensure newly created collections are expanded by default
            for (collection, _) in collectionsWithSnippets {
                if !snippetManager.expandedCollections.contains(collection.id) {
                    snippetManager.expandedCollections.insert(collection.id)
                }
            }
        }
    }
    
    private func toggleCollection(_ collectionId: UUID) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if snippetManager.expandedCollections.contains(collectionId) {
                snippetManager.expandedCollections.remove(collectionId)
            } else {
                snippetManager.expandedCollections.insert(collectionId)
            }
        }
    }
}

// MARK: - All Collections Section View 100161
struct AllCollectionsSectionView: View {
    let collection: SnippetCollection
    let snippets: [Snippet]
    let isExpanded: Bool
    @Binding var editingSnippet: Snippet?
    let availableWidth: CGFloat
    let onToggle: () -> Void
    let onHeaderTapped: (() -> Void)?
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var isDropTarget = false
    
    // Determine layout based on width
    private var useCompactLayout: Bool {
        availableWidth > 0 && availableWidth < 500
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            collectionHeader
            
            if isExpanded {
                if snippets.isEmpty {
                    EmptyCollectionView(
                        collectionName: collection.name,
                        isCompact: useCompactLayout
                    )
                } else {
                    AllExpandedSnippetsView(
                        snippets: snippets,
                        editingSnippet: $editingSnippet,
                        availableWidth: availableWidth
                    )
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isDropTarget ? getColor(from: collection.color).opacity(0.05) : Color.clear)
                .stroke(isDropTarget ? getColor(from: collection.color).opacity(0.3) : Color.clear, lineWidth: isDropTarget ? 2 : 0)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .onDrop(of: [.text], isTargeted: $isDropTarget) { providers in
            handleDrop(providers: providers)
        }
    }
    
    private var collectionHeader: some View {
        Button(action: {
            onToggle()
            onHeaderTapped?()
        }) {
            HStack(spacing: useCompactLayout ? 8 : 12) {
                // Collection icon and color indicator
                ZStack {
                    Circle()
                        .fill(getColor(from: collection.color))
                        .frame(width: useCompactLayout ? 20 : 24, height: useCompactLayout ? 20 : 24)
                    
                    Image(systemName: collection.icon.isEmpty ? "folder" : collection.icon)
                        .font(.system(size: useCompactLayout ? 10 : 12, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Collection name and snippet count
                VStack(alignment: .leading, spacing: 1) {
                    Text(collection.name)
                        .font(.system(size: useCompactLayout ? 14 : 15, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if !useCompactLayout {
                        Text("\(snippets.count) snippet\(snippets.count == 1 ? "" : "s")")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                if useCompactLayout {
                    Text("(\(snippets.count))")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Drop indicator when dragging
                if isDropTarget {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(getColor(from: collection.color))
                            .font(.system(size: useCompactLayout ? 9 : 10))
                        
                        if !useCompactLayout {
                            Text("Drop here")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(getColor(from: collection.color))
                        }
                    }
                    .padding(.horizontal, useCompactLayout ? 4 : 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(getColor(from: collection.color).opacity(0.1))
                            .stroke(getColor(from: collection.color).opacity(0.3), lineWidth: 1)
                    )
                } else {
                    // Preview snippets when collapsed
                    if !isExpanded && !snippets.isEmpty && !useCompactLayout {
                        CollectionPreviewSnippetsView(
                            snippets: Array(snippets.prefix(3)),
                            collection: collection
                        )
                    }
                }
                
                // Chevron
                Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    .font(.system(size: useCompactLayout ? 8 : 9, weight: .medium))
                    .foregroundColor(.secondary)
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)
            }
            .padding(.horizontal, useCompactLayout ? 12 : 16)
            .padding(.vertical, useCompactLayout ? 10 : 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))
        )
    }
    
    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.text.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.text.identifier, options: nil) { item, error in
                    if let data = item as? Data,
                       let snippetIdString = String(data: data, encoding: .utf8),
                       let snippetId = UUID(uuidString: snippetIdString) {
                        DispatchQueue.main.async {
                            if let index = self.snippetManager.snippets.firstIndex(where: { $0.id == snippetId }) {
                                if self.snippetManager.snippets[index].collectionId != collection.id {
                                    self.snippetManager.snippets[index].collectionId = collection.id
                                    SaveNotificationManager.shared.show("Moved to \(collection.name)")
                                }
                            }
                        }
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func getColor(from colorString: String) -> Color {
        switch colorString.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "gray", "grey": return .gray
        case "brown": return .brown
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        case "black": return .black
        case "white": return Color.white
        case "accentColor": return .accentColor
        default: return .blue
        }
    }
}

// MARK: - Collection Preview Snippets View 100162
struct CollectionPreviewSnippetsView: View {
    let snippets: [Snippet]
    let collection: SnippetCollection
    
    private func getColor(from colorString: String) -> Color {
        switch colorString.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "gray", "grey": return .gray
        case "brown": return .brown
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        case "black": return .black
        case "white": return Color.white
        case "accentColor": return .accentColor
        default: return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(snippets, id: \.id) { snippet in
                Text(snippet.shortcut)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(getColor(from: collection.color))
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(getColor(from: collection.color).opacity(0.1))
                    )
                    .lineLimit(1)
            }
            
            if snippets.count > 3 {
                Text("+\(snippets.count - 3)")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Empty Collection View 100168
struct EmptyCollectionView: View {
    let collectionName: String
    let isCompact: Bool
    
    init(collectionName: String, isCompact: Bool = false) {
        self.collectionName = collectionName
        self.isCompact = isCompact
    }
    
    var body: some View {
        VStack(spacing: isCompact ? 8 : 12) {
            Image(systemName: "tray")
                .font(.system(size: isCompact ? 20 : 24))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 4) {
                Text("No snippets in \(collectionName)")
                    .font(.system(size: isCompact ? 12 : 13, weight: .medium))
                    .foregroundColor(.secondary)
                
                if !isCompact {
                    Text("Drag snippets here to organize them")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, isCompact ? 16 : 24)
        .padding(.horizontal, isCompact ? 16 : 32)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor).opacity(0.5))
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, isCompact ? 24 : 44)
        .padding(.bottom, 12)
    }
}

// MARK: - All Expanded Snippets View 100169
struct AllExpandedSnippetsView: View {
    let snippets: [Snippet]
    @Binding var editingSnippet: Snippet?
    let availableWidth: CGFloat
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var isDropTarget = false
    
    // Get the collection for these snippets
    private var collection: SnippetCollection? {
        guard let firstSnippet = snippets.first,
              let collectionId = firstSnippet.collectionId else { return nil }
        return snippetManager.collections.first { $0.id == collectionId }
    }
    
    // Determine compact layout
    private var useCompactLayout: Bool {
        availableWidth > 0 && availableWidth < 500
    }
    
    var body: some View {
        LazyVStack(spacing: useCompactLayout ? 4 : 6) {
            ForEach(snippets) { snippet in
                SnippetCardView(
                    snippet: snippet,
                    editingSnippet: $editingSnippet,
                    isCompact: useCompactLayout
                )
                .padding(.leading, useCompactLayout ? 24 : 32)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .padding(.horizontal, useCompactLayout ? 8 : 12)
        .padding(.top, useCompactLayout ? 6 : 8)
        .padding(.bottom, useCompactLayout ? 8 : 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDropTarget ? (collection.map { getColor(from: $0.color) } ?? .blue).opacity(0.05) : Color.clear)
                .stroke(isDropTarget ? (collection.map { getColor(from: $0.color) } ?? .blue).opacity(0.3) : Color.clear, lineWidth: isDropTarget ? 2 : 0)
        )
        .onDrop(of: [.text], isTargeted: $isDropTarget) { providers in
            // Handle snippet reordering within collection
            return false // For now, don't handle reordering
        }
    }
    
    private func getColor(from colorString: String) -> Color {
        switch colorString.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "gray", "grey": return .gray
        case "brown": return .brown
        case "cyan": return .cyan
        case "mint": return .mint
        case "teal": return .teal
        case "indigo": return .indigo
        case "black": return .black
        case "white": return Color.white
        case "accentColor": return .accentColor
        default: return .blue
        }
    }
}
