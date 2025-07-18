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
        print("DEBUG: Toggling collection \(collectionId)")
        print("DEBUG: Before toggle - expandedCollections: \(snippetManager.expandedCollections)")
        
        withAnimation(.easeInOut(duration: 0.3)) {
            if snippetManager.expandedCollections.contains(collectionId) {
                snippetManager.expandedCollections.remove(collectionId)
                print("DEBUG: Collapsed collection \(collectionId)")
            } else {
                snippetManager.expandedCollections.insert(collectionId)
                print("DEBUG: Expanded collection \(collectionId)")
            }
        }
        
        print("DEBUG: After toggle - expandedCollections: \(snippetManager.expandedCollections)")
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
                    ExpandedSnippetsView(
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
            print("DEBUG DROP: Starting drop handling for collection '\(collection.name)'")
            print("DEBUG DROP: Number of providers: \(providers.count)")
            
            for (index, provider) in providers.enumerated() {
                print("DEBUG DROP: Provider \(index) registeredTypeIdentifiers: \(provider.registeredTypeIdentifiers)")
                print("DEBUG DROP: Provider \(index) hasItemConformingToTypeIdentifier(json): \(provider.hasItemConformingToTypeIdentifier(UTType.json.identifier))")
                
                if provider.hasItemConformingToTypeIdentifier(UTType.json.identifier) {
                    print("DEBUG DROP: Loading item from provider \(index)")
                    
                    provider.loadItem(forTypeIdentifier: UTType.json.identifier, options: nil) { item, error in
                        if let error = error {
                            print("DEBUG DROP: Error loading item: \(error)")
                            return
                        }
                        
                        print("DEBUG DROP: Received item of type: \(type(of: item))")
                        
                        var data: Data?
                        
                        // Handle different possible data types
                        if let directData = item as? Data {
                            print("DEBUG DROP: Item is already Data")
                            data = directData
                        } else if let nsData = item as? NSData {
                            print("DEBUG DROP: Item is NSData, converting to Data")
                            data = nsData as Data
                        } else if let string = item as? String {
                            print("DEBUG DROP: Item is String, converting to Data")
                            data = string.data(using: .utf8)
                        } else if let url = item as? URL {
                            print("DEBUG DROP: Item is URL, reading data")
                            data = try? Data(contentsOf: url)
                        } else {
                            print("DEBUG DROP: Unknown item type, cannot convert to Data")
                            return
                        }
                        
                        guard let finalData = data else {
                            print("DEBUG DROP: Could not extract Data from item")
                            return
                        }
                        
                        print("DEBUG DROP: Successfully extracted data of size: \(finalData.count) bytes")
                        
                        do {
                            let snippet = try JSONDecoder().decode(Snippet.self, from: finalData)
                            print("DEBUG DROP: Successfully decoded snippet '\(snippet.shortcut)'")
                            
                            DispatchQueue.main.async {
                                moveSnippetToCollection(snippet: snippet, targetCollection: collection)
                            }
                        } catch {
                            print("DEBUG DROP: Failed to decode snippet: \(error)")
                            
                            // Try to print the raw data as string for debugging
                            if let dataString = String(data: finalData, encoding: .utf8) {
                                print("DEBUG DROP: Raw data as string: \(dataString)")
                            }
                        }
                    }
                    return true
                }
            }
            print("DEBUG DROP: No valid JSON data found in any provider")
            return false
        }
        
        private func moveSnippetToCollection(snippet: Snippet, targetCollection: SnippetCollection) {
            print("DEBUG MOVE: Attempting to move snippet '\(snippet.shortcut)' to collection '\(targetCollection.name)'")
            
            if let index = snippetManager.snippets.firstIndex(where: { $0.id == snippet.id }) {
                let oldCollectionId = snippetManager.snippets[index].collectionId
                let newCollectionId = targetCollection.id
                
                print("DEBUG MOVE: Found snippet at index \(index)")
                print("DEBUG MOVE: Old collection ID: \(oldCollectionId?.uuidString ?? "nil")")
                print("DEBUG MOVE: New collection ID: \(newCollectionId.uuidString)")
                
                // Only move if it's a different collection
                if snippetManager.snippets[index].collectionId != targetCollection.id {
                    snippetManager.snippets[index].collectionId = targetCollection.id
                    print("DEBUG MOVE: Successfully moved snippet to new collection")
                    SaveNotificationManager.shared.show("Moved to \(targetCollection.name)")
                } else {
                    print("DEBUG MOVE: Snippet is already in target collection")
                }
            } else {
                print("DEBUG MOVE: ERROR - Could not find snippet in snippetManager.snippets")
                print("DEBUG MOVE: Looking for snippet ID: \(snippet.id.uuidString)")
                print("DEBUG MOVE: Current snippets count: \(snippetManager.snippets.count)")
                for (index, existingSnippet) in snippetManager.snippets.enumerated() {
                    print("DEBUG MOVE: Snippet \(index): \(existingSnippet.shortcut) (\(existingSnippet.id.uuidString))")
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
                    .font(.system(size: 8, weight: .medium, design: .monospaced))
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
