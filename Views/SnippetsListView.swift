// SnippetListsView.swift

import SwiftUI

// MARK: - Snippets List View 100144
struct SnippetsListView: View {
    let groupedSnippets: [String: [Snippet]]
    @Binding var editingSnippet: Snippet?
    @State private var expandedCollections: Set<String> = ["Email & Contacts", "Addresses", "Date & Time"]
    
    var sortedGroups: [(String, [Snippet])] {
        groupedSnippets.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(sortedGroups, id: \.0) { collectionData in
                    CollectionSectionView(
                        collectionName: collectionData.0,
                        snippets: collectionData.1,
                        isExpanded: expandedCollections.contains(collectionData.0),
                        editingSnippet: $editingSnippet,
                        onToggle: {
                            toggleCollection(collectionData.0)
                        }
                    )
                }
            }
            .padding(.vertical, 12)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
    
    private func toggleCollection(_ name: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            if expandedCollections.contains(name) {
                expandedCollections.remove(name)
            } else {
                expandedCollections.insert(name)
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
    
    var body: some View {
        VStack(spacing: 0) {
            CollectionHeaderView(
                title: collectionName,
                snippetCount: snippets.count,
                enabledCount: snippets.filter(\.isEnabled).count,
                isExpanded: isExpanded,
                snippetPreviews: Array(snippets.prefix(3)),
                onToggle: onToggle
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
    
    var collectionIcon: String {
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
    
    var collectionColor: Color {
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
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 12) {
                CollectionIconView(icon: collectionIcon, color: collectionColor)
                CollectionInfoView(
                    title: title,
                    snippetCount: snippetCount,
                    enabledCount: enabledCount
                )
                Spacer()
                
                if !isExpanded && !snippetPreviews.isEmpty {
                    PreviewSnippetsView(snippets: snippetPreviews, color: collectionColor)
                }
                
                ExpandIndicatorView(isExpanded: isExpanded)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(headerBackground)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.bottom, isExpanded && !snippetPreviews.isEmpty ? 8 : 12)
    }
    
    private var headerBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(NSColor.controlBackgroundColor))
            .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
    }
}

// MARK: - Collection Icon View 100147
struct CollectionIconView: View {
    let icon: String
    let color: Color
    @StateObject private var snippetManager = SnippetManager.shared
    
    var body: some View {
        let actualIcon = icon.isEmpty ? getDefaultIcon() : icon
        
        Image(systemName: actualIcon)
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(color)
            .frame(width: 24, height: 24)
            .background(
                Circle()
                    .fill(color.opacity(0.15))
            )
    }
    
    private func getDefaultIcon() -> String {
        switch icon {
        case "at": return "at"
        case "location": return "location"
        case "phone": return "phone"
        case "signature": return "signature"
        case "clock": return "clock"
        case "number": return "number"
        default: return "folder"
        }
    }
}

// MARK: - Collection Info View 100148
struct CollectionInfoView: View {
    let title: String
    let snippetCount: Int
    let enabledCount: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("\(snippetCount) snippet\(snippetCount == 1 ? "" : "s") • \(enabledCount) enabled")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview Snippets View 100149
struct PreviewSnippetsView: View {
    let snippets: [Snippet]
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(snippets, id: \.id) { snippet in
                Text(snippet.shortcut)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(color)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(color.opacity(0.1))
                    )
            }
            
            if snippets.count > 3 {
                Text("+\(snippets.count - 3)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Expand Indicator View 100150
struct ExpandIndicatorView: View {
    let isExpanded: Bool
    
    var body: some View {
        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
            .font(.system(size: 11, weight: .medium))
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
        .padding(.bottom, 12)
    }
}
