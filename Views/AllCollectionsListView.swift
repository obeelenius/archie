// AllCollectionsListView.swift

import SwiftUI
import UniformTypeIdentifiers

// MARK: - All Collections List View 100163
struct AllCollectionsListView: View {
    let collectionsWithSnippets: [(SnippetCollection, [Snippet])]
    @Binding var editingSnippet: Snippet?
    let onCollectionHeaderTapped: (() -> Void)?
    @StateObject private var snippetManager = SnippetManager.shared
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(collectionsWithSnippets, id: \.0.id) { collectionData in
                    let isExpanded = snippetManager.expandedCollections.contains(collectionData.0.id)
                    
                    AllCollectionsSectionView(
                        collection: collectionData.0,
                        snippets: collectionData.1,
                        isExpanded: isExpanded,
                        editingSnippet: $editingSnippet,
                        onToggle: {
                            toggleCollection(collectionData.0.id)
                        },
                        onHeaderTapped: onCollectionHeaderTapped
                    )
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
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

// MARK: - All Collections Section View 100164
struct AllCollectionsSectionView: View {
    let collection: SnippetCollection
    let snippets: [Snippet]
    let isExpanded: Bool
    @Binding var editingSnippet: Snippet?
    let onToggle: () -> Void
    let onHeaderTapped: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            AllCollectionsHeaderView(
                collection: collection,
                snippetCount: snippets.count,
                enabledCount: snippets.filter(\.isEnabled).count,
                isExpanded: isExpanded,
                snippetPreviews: Array(snippets.prefix(3)),
                onToggle: onToggle,
                onHeaderTapped: onHeaderTapped
            )
            
            if isExpanded {
                if snippets.isEmpty {
                    EmptyCollectionView(collectionName: collection.name)
                } else {
                    AllExpandedSnippetsView(
                        snippets: snippets,
                        editingSnippet: $editingSnippet
                    )
                }
            }
        }
    }
}

// MARK: - All Collections Header View 100165
struct AllCollectionsHeaderView: View {
    let collection: SnippetCollection
    let snippetCount: Int
    let enabledCount: Int
    let isExpanded: Bool
    let snippetPreviews: [Snippet]
    let onToggle: () -> Void
    let onHeaderTapped: (() -> Void)?
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var isDropTarget = false
    
    var collectionColor: Color {
        getColor(from: collection.color)
    }
    
    private func getColor(from colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "teal": return .teal
        case "mint": return .mint
        case "cyan": return .cyan
        case "brown": return .brown
        case "gray": return .gray
        case "black": return .black
        case "white": return Color.white
        case "accentColor": return .accentColor
        default: return .blue
        }
    }
    
    var body: some View {
        Button(action: {
            // Call the header tapped callback if provided, otherwise just toggle
            if let headerTapped = onHeaderTapped {
                headerTapped()
            }
            onToggle()
        }) {
            HStack(spacing: 10) {
                // Left side: Icon and title only
                HStack(spacing: 8) {
                    AllCollectionIconView(collection: collection)
                    
                    Text(collection.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Drop indicator when dragging
                if isDropTarget {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(collectionColor)
                            .font(.system(size: 10))
                        Text("Drop here")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(collectionColor)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(collectionColor.opacity(0.1))
                            .stroke(collectionColor.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Right side: Preview and expand indicator
                HStack(spacing: 6) {
                    if !isExpanded && !snippetPreviews.isEmpty && !isDropTarget {
                        AllCollectionPreviewSnippetsView(snippets: snippetPreviews, collection: collection)
                    }
                    
                    ExpandIndicatorView(isExpanded: isExpanded)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(headerBackground)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, isExpanded ? 4 : 6)
        .onDrop(of: [.json], isTargeted: $isDropTarget) { providers in
            return handleSnippetDrop(providers: providers)
        }
    }
    
    private var headerBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(NSColor.controlBackgroundColor))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .fill(collectionColor.opacity(isDropTarget ? 0.08 : 0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(collectionColor.opacity(isDropTarget ? 0.5 : 0.2), lineWidth: isDropTarget ? 2 : 1)
            )
            .shadow(
                color: Color.black.opacity(0.02),
                radius: 1,
                x: 0,
                y: 0.5
            )
            .animation(.easeInOut(duration: 0.2), value: isDropTarget)
    }
    
    private func handleSnippetDrop(providers: [NSItemProvider]) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.json.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.json.identifier, options: nil) { item, error in
                    if error != nil {
                        return
                    }
                    
                    var data: Data?
                    
                    // Handle different possible data types
                    if let directData = item as? Data {
                        data = directData
                    } else if let nsData = item as? NSData {
                        data = nsData as Data
                    } else if let string = item as? String {
                        data = string.data(using: .utf8)
                    } else if let url = item as? URL {
                        data = try? Data(contentsOf: url)
                    } else {
                        return
                    }
                    
                    guard let finalData = data else {
                        return
                    }
                    
                    do {
                        let snippet = try JSONDecoder().decode(Snippet.self, from: finalData)
                        
                        DispatchQueue.main.async {
                            moveSnippetToCollection(snippet: snippet, targetCollection: collection)
                        }
                    } catch {
                        return
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func moveSnippetToCollection(snippet: Snippet, targetCollection: SnippetCollection) {
        if let index = snippetManager.snippets.firstIndex(where: { $0.id == snippet.id }) {
            // Only move if it's a different collection
            if snippetManager.snippets[index].collectionId != targetCollection.id {
                snippetManager.snippets[index].collectionId = targetCollection.id
                SaveNotificationManager.shared.show("Moved to \(targetCollection.name)")
            }
        }
    }
}

// MARK: - All Collection Icon View 100166
struct AllCollectionIconView: View {
    let collection: SnippetCollection
    
    var icon: String {
        collection.icon.isEmpty ? "folder" : collection.icon
    }
    
    var color: Color {
        getColor(from: collection.color)
    }
    
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(color)
            .frame(width: 20, height: 20)
            .background(
                Circle()
                    .fill(color.opacity(0.12))
            )
    }
    
    private func getColor(from colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "teal": return .teal
        case "mint": return .mint
        case "cyan": return .cyan
        case "brown": return .brown
        case "gray": return .gray
        case "black": return .black
        case "white": return Color.white
        case "accentColor": return .accentColor
        default: return .blue
        }
    }
}

// MARK: - All Collection Preview Snippets View 100167
struct AllCollectionPreviewSnippetsView: View {
    let snippets: [Snippet]
    let collection: SnippetCollection
    
    var color: Color {
        getColor(from: collection.color)
    }
    
    var body: some View {
        HStack(spacing: 3) {
            ForEach(snippets, id: \.id) { snippet in
                Text(snippet.shortcut)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(color)
                    .padding(.horizontal, 3)
                    .padding(.vertical, 1)
                    .background(
                        RoundedRectangle(cornerRadius: 2)
                            .fill(color.opacity(0.1))
                    )
            }
            
            if snippets.count > 3 {
                Text("+\(snippets.count - 3)")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func getColor(from colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "teal": return .teal
        case "mint": return .mint
        case "cyan": return .cyan
        case "brown": return .brown
        case "gray": return .gray
        case "black": return .black
        case "white": return Color.white
        case "accentColor": return .accentColor
        default: return .blue
        }
    }
}

// MARK: - Empty Collection View 100168
struct EmptyCollectionView: View {
    let collectionName: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 24))
                .foregroundColor(.secondary.opacity(0.6))
            
            Text("No snippets in \(collectionName)")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            
            Text("Drag snippets here to organize them")
                .font(.system(size: 11))
                .foregroundColor(.secondary.opacity(0.8))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 32)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor).opacity(0.5))
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 44)
        .padding(.bottom, 12)
    }
}

// MARK: - All Expanded Snippets View 100169
struct AllExpandedSnippetsView: View {
    let snippets: [Snippet]
    @Binding var editingSnippet: Snippet?
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var isDropTarget = false
    
    // Get the collection for these snippets
    private var collection: SnippetCollection? {
        guard let firstSnippet = snippets.first,
              let collectionId = firstSnippet.collectionId else { return nil }
        return snippetManager.collections.first { $0.id == collectionId }
    }
    
    var body: some View {
        LazyVStack(spacing: 6) {
            ForEach(snippets) { snippet in
                SnippetCardView(
                    snippet: snippet,
                    editingSnippet: $editingSnippet
                )
                .padding(.leading, 32)
                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isDropTarget ? (collection.map { getColor(from: $0.color) } ?? .blue).opacity(0.05) : Color.clear)
                .stroke(isDropTarget ? (collection.map { getColor(from: $0.color) } ?? .blue).opacity(0.3) : Color.clear, lineWidth: isDropTarget ? 2 : 0)
                .animation(.easeInOut(duration: 0.2), value: isDropTarget)
        )
        .onDrop(of: [.json], isTargeted: $isDropTarget) { providers in
            guard let collection = collection else { return false }
            return handleSnippetDrop(providers: providers, targetCollection: collection)
        }
    }
    
    private func getColor(from colorName: String) -> Color {
        switch colorName {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "yellow": return .yellow
        case "indigo": return .indigo
        case "teal": return .teal
        case "mint": return .mint
        case "cyan": return .cyan
        case "brown": return .brown
        case "gray": return .gray
        case "black": return .black
        case "white": return Color.white
        case "accentColor": return .accentColor
        default: return .blue
        }
    }
    
    private func handleSnippetDrop(providers: [NSItemProvider], targetCollection: SnippetCollection) -> Bool {
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.json.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.json.identifier, options: nil) { item, error in
                    if error != nil {
                        return
                    }
                    
                    var data: Data?
                    
                    if let directData = item as? Data {
                        data = directData
                    } else if let nsData = item as? NSData {
                        data = nsData as Data
                    } else if let string = item as? String {
                        data = string.data(using: .utf8)
                    } else if let url = item as? URL {
                        data = try? Data(contentsOf: url)
                    }
                    
                    guard let finalData = data else {
                        return
                    }
                    
                    do {
                        let snippet = try JSONDecoder().decode(Snippet.self, from: finalData)
                        
                        DispatchQueue.main.async {
                            moveSnippetToCollection(snippet: snippet, targetCollection: targetCollection)
                        }
                    } catch {
                        return
                    }
                }
                return true
            }
        }
        return false
    }
    
    private func moveSnippetToCollection(snippet: Snippet, targetCollection: SnippetCollection) {
        if let index = snippetManager.snippets.firstIndex(where: { $0.id == snippet.id }) {
            if snippetManager.snippets[index].collectionId != targetCollection.id {
                snippetManager.snippets[index].collectionId = targetCollection.id
                SaveNotificationManager.shared.show("Moved to \(targetCollection.name)")
            }
        }
    }
}
