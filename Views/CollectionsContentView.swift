//  CollectionsContentView.swift

import SwiftUI

// MARK: - Collections Content View
struct CollectionsContentView: View {
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var editingCollection: SnippetCollection? = nil
    
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
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main collections view
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
                    
                    // Collections list
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
                            LazyVStack(spacing: 12) {
                                ForEach(snippetManager.collections) { collection in
                                    EditableCollectionCard(
                                        collection: collection,
                                        snippets: snippetManager.snippets(for: collection),
                                        onEdit: { editingCollection = collection }
                                    )
                                }
                            }
                            .padding(12)
                        }
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
                    }
                }
                .frame(width: editingCollection != nil ? geometry.size.width * 0.6 : geometry.size.width)
                
                // Collection editor panel
                if let editingCollection = editingCollection {
                    HStack(spacing: 0) {
                        // Resize handle (simplified)
                        Rectangle()
                            .fill(Color(NSColor.separatorColor))
                            .frame(width: 1)
                        
                        EditCollectionSlideOut(
                            collection: editingCollection,
                            isShowing: Binding(
                                get: { self.editingCollection != nil },
                                set: { if !$0 { self.editingCollection = nil } }
                            )
                        )
                    }
                    .frame(width: geometry.size.width * 0.4)
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: editingCollection != nil)
    }
}

// MARK: - Editable Collection Card
struct EditableCollectionCard: View {
    let collection: SnippetCollection
    let snippets: [Snippet]
    let onEdit: () -> Void
    @State private var isExpanded = false
    
    var enabledCount: Int {
        snippets.filter(\.isEnabled).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(collection.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if !collection.isEnabled {
                            Text("DISABLED")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.red)
                                .cornerRadius(4)
                        }
                        
                        if !collection.suffix.isEmpty {
                            Text("suffix: \(collection.suffix)")
                                .font(.system(size: 9, weight: .medium, design: .monospaced))
                                .foregroundColor(.purple)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(4)
                        }
                    }
                    
                    Text("\(snippets.count) snippets • \(enabledCount) enabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button("Edit") {
                        onEdit()
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.accentColor, lineWidth: 1)
                    )
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12, weight: .medium))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            if !isExpanded {
                HStack {
                    ForEach(Array(snippets.prefix(3)), id: \.id) { snippet in
                        Text(snippet.shortcut)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accentColor.opacity(0.1))
                            )
                            .foregroundColor(.accentColor)
                    }
                    
                    if snippets.count > 3 {
                        Text("+\(snippets.count - 3)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(snippets) { snippet in
                        HStack {
                            Text(snippet.shortcut)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.accentColor.opacity(0.1))
                                )
                                .foregroundColor(.accentColor)
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            Text(snippet.expansion.replacingOccurrences(of: "\n", with: " "))
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Circle()
                                .fill(snippet.isEnabled ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
        )
    }
}
