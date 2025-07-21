// SnippetListsView.swift

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Snippets List View 100144
struct SnippetsListView: View {
    let groupedSnippets: [String: [Snippet]]
    @Binding var editingSnippet: Snippet?
    let onCollectionHeaderTapped: (() -> Void)?
    @StateObject private var snippetManager = SnippetManager.shared
    
    init(groupedSnippets: [String: [Snippet]],
         editingSnippet: Binding<Snippet?>,
         onCollectionHeaderTapped: (() -> Void)? = nil) {
        self.groupedSnippets = groupedSnippets
        self._editingSnippet = editingSnippet
        self.onCollectionHeaderTapped = onCollectionHeaderTapped
    }
    
    var sortedGroups: [(String, [Snippet])] {
        groupedSnippets.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sortedGroups, id: \.0) { collectionData in
                    let collection = snippetManager.collections.first { $0.name == collectionData.0 }
                    let collectionId = collection?.id ?? UUID() // fallback for unknown collections
                    
                    CollectionSectionView(
                        collectionName: collectionData.0,
                        snippets: collectionData.1,
                        isExpanded: snippetManager.expandedCollections.contains(collectionId),
                        editingSnippet: $editingSnippet,
                        onToggle: {
                            toggleCollection(collectionId)
                        },
                        onHeaderTapped: onCollectionHeaderTapped
                    )
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .onAppear {
            // Ensure newly created collections are expanded by default
            for (collectionName, _) in sortedGroups {
                if let collection = snippetManager.collections.first(where: { $0.name == collectionName }) {
                    if !snippetManager.expandedCollections.contains(collection.id) {
                        snippetManager.expandedCollections.insert(collection.id)
                    }
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

// MARK: - Collection Section View 100145
struct CollectionSectionView: View {
    let collectionName: String
    let snippets: [Snippet]
    let isExpanded: Bool
    @Binding var editingSnippet: Snippet?
    let onToggle: () -> Void
    let onHeaderTapped: (() -> Void)?
    
    init(collectionName: String,
         snippets: [Snippet],
         isExpanded: Bool,
         editingSnippet: Binding<Snippet?>,
         onToggle: @escaping () -> Void,
         onHeaderTapped: (() -> Void)? = nil) {
        self.collectionName = collectionName
        self.snippets = snippets
        self.isExpanded = isExpanded
        self._editingSnippet = editingSnippet
        self.onToggle = onToggle
        self.onHeaderTapped = onHeaderTapped
    }
    
    var body: some View {
        VStack(spacing: 0) {
            CollectionHeaderView(
                title: collectionName,
                snippetCount: snippets.count,
                enabledCount: snippets.filter(\.isEnabled).count,
                isExpanded: isExpanded,
                snippetPreviews: Array(snippets.prefix(3)),
                onToggle: onToggle,
                onHeaderTapped: onHeaderTapped
            )
            
            if isExpanded {
                ExpandedSnippetsView(
                    snippets: snippets,
                    editingSnippet: $editingSnippet
                )
            }
        }
    }
}

// MARK: - Collection Header View 100146
struct CollectionHeaderView: View {
    let title: String
    let snippetCount: Int
    let enabledCount: Int
    let isExpanded: Bool
    let snippetPreviews: [Snippet]
    let onToggle: () -> Void
    let onHeaderTapped: (() -> Void)?
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var isDropTarget = false
    
    init(title: String,
         snippetCount: Int,
         enabledCount: Int,
         isExpanded: Bool,
         snippetPreviews: [Snippet],
         onToggle: @escaping () -> Void,
         onHeaderTapped: (() -> Void)? = nil) {
        self.title = title
        self.snippetCount = snippetCount
        self.enabledCount = enabledCount
        self.isExpanded = isExpanded
        self.snippetPreviews = snippetPreviews
        self.onToggle = onToggle
        self.onHeaderTapped = onHeaderTapped
    }
    
    var collection: SnippetCollection? {
        snippetManager.collections.first { $0.name == title }
    }
    
    var collectionIcon: String {
        if let collection = collection {
            return collection.icon.isEmpty ? getDefaultIcon() : collection.icon
        }
        return getDefaultIcon()
    }
    
    var collectionColor: Color {
        if let collection = collection {
            return getColor(from: collection.color)
        }
        return getDefaultColor()
    }
    
    private func getDefaultIcon() -> String {
        switch title {
        case "Email & Contacts": return "at"
        case "Addresses": return "location"
        case "Phone Numbers": return "phone"
        case "Signatures": return "signature"
        case "Date & Time": return "clock"
        case "Social & Tags": return "number"
        default: return "folder"
        }
    }
    
    private func getDefaultColor() -> Color {
        switch title {
        case "Email & Contacts": return .blue
        case "Addresses": return .green
        case "Phone Numbers": return .indigo
        case "Signatures": return .purple
        case "Date & Time": return .orange
        case "Social & Tags": return .pink
        default: return .gray
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
                    CollectionIconView(collectionName: title)
                    
                    Text(title)
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
                        PreviewSnippetsView(snippets: snippetPreviews, collectionName: title)
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
        guard let collection = collection else { return false }
        
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.json.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.json.identifier, options: nil) { data, error in
                    guard let data = data as? Data,
                          let snippet = try? JSONDecoder().decode(Snippet.self, from: data) else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        moveSnippetToCollection(snippet: snippet, targetCollection: collection)
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
                
                // Show success feedback
                withAnimation(.easeInOut(duration: 0.3)) {
                    // Could add a success toast here
                }
            }
        }
    }
}

// MARK: - Collection Icon View 100147
struct CollectionIconView: View {
    let collectionName: String
    @StateObject private var snippetManager = SnippetManager.shared
    
    var collection: SnippetCollection? {
        snippetManager.collections.first { $0.name == collectionName }
    }
    
    var icon: String {
        if let collection = collection {
            return collection.icon.isEmpty ? getDefaultIcon() : collection.icon
        }
        return getDefaultIcon()
    }
    
    var color: Color {
        if let collection = collection {
            return getColor(from: collection.color)
        }
        return getDefaultColor()
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
    
    private func getDefaultIcon() -> String {
        switch collectionName {
        case "Email & Contacts": return "at"
        case "Addresses": return "location"
        case "Phone Numbers": return "phone"
        case "Signatures": return "signature"
        case "Date & Time": return "clock"
        case "Social & Tags": return "number"
        default: return "folder"
        }
    }
    
    private func getDefaultColor() -> Color {
        switch collectionName {
        case "Email & Contacts": return .blue
        case "Addresses": return .green
        case "Phone Numbers": return .indigo
        case "Signatures": return .purple
        case "Date & Time": return .orange
        case "Social & Tags": return .pink
        default: return .gray
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

// MARK: - Preview Snippets View 100149
struct PreviewSnippetsView: View {
    let snippets: [Snippet]
    let collectionName: String
    @StateObject private var snippetManager = SnippetManager.shared
    
    var collection: SnippetCollection? {
        snippetManager.collections.first { $0.name == collectionName }
    }
    
    var color: Color {
        if let collection = collection {
            return getColor(from: collection.color)
        }
        return getDefaultColor()
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
    
    private func getDefaultColor() -> Color {
        switch collectionName {
        case "Email & Contacts": return .blue
        case "Addresses": return .green
        case "Phone Numbers": return .indigo
        case "Signatures": return .purple
        case "Date & Time": return .orange
        case "Social & Tags": return .pink
        default: return .gray
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

// MARK: - Expand Indicator View 100150
struct ExpandIndicatorView: View {
    let isExpanded: Bool
    
    var body: some View {
        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.secondary)
            .animation(.easeInOut(duration: 0.2), value: isExpanded)
    }
}

// MARK: - Expanded Snippets View 100151
struct ExpandedSnippetsView: View {
    let snippets: [Snippet]
    @Binding var editingSnippet: Snippet?
    
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
    }
}
