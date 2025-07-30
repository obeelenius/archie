//
//  UncollectedSnippetsSection.swift
//  Archie
//
//  Created by Amy Elenius on 30/7/2025.
//


// UncollectedSnippetsSection.swift

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Uncollected Snippets Section 100300
struct UncollectedSnippetsSection: View {
    let snippets: [Snippet]
    @Binding var editingSnippet: Snippet?
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var isExpanded = true
    @State private var isDropTarget = false
    
    var body: some View {
        VStack(spacing: 0) {
            uncollectedHeader
            
            if isExpanded {
                uncollectedSnippetsList
            }
        }
    }
}

// MARK: - Uncollected Header 100301
extension UncollectedSnippetsSection {
    private var uncollectedHeader: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                isExpanded.toggle()
            }
        }) {
            HStack(spacing: 10) {
                // Left side: Icon and title
                HStack(spacing: 8) {
                    Image(systemName: "tray")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.12))
                        )
                    
                    Text("Uncollected Snippets")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Drop indicator when dragging from collections
                if isDropTarget {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 10))
                        Text("Remove from collection")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.1))
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Right side: Count and expand indicator
                HStack(spacing: 6) {
                    if !isExpanded && !snippets.isEmpty && !isDropTarget {
                        HStack(spacing: 3) {
                            ForEach(Array(snippets.prefix(3)), id: \.id) { snippet in
                                Text(snippet.shortcut)
                                    .font(.system(size: 8, weight: .medium, design: .monospaced))
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(Color.gray.opacity(0.1))
                                    )
                            }
                            
                            if snippets.count > 3 {
                                Text("+\(snippets.count - 3)")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
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
                    .fill(Color.gray.opacity(isDropTarget ? 0.08 : 0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.gray.opacity(isDropTarget ? 0.5 : 0.2), lineWidth: isDropTarget ? 2 : 1)
            )
            .shadow(
                color: Color.black.opacity(0.02),
                radius: 1,
                x: 0,
                y: 0.5
            )
            .animation(.easeInOut(duration: 0.2), value: isDropTarget)
    }
}

// MARK: - Uncollected Snippets List 100302
extension UncollectedSnippetsSection {
    private var uncollectedSnippetsList: some View {
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
                .fill(Color.clear)
        )
    }
}

// MARK: - Drop Handling 100303
extension UncollectedSnippetsSection {
    private func handleSnippetDrop(providers: [NSItemProvider]) -> Bool {
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
                            removeSnippetFromCollection(snippet: snippet)
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
    
    private func removeSnippetFromCollection(snippet: Snippet) {
        if let index = snippetManager.snippets.firstIndex(where: { $0.id == snippet.id }) {
            // Only remove if it's currently in a collection
            if snippetManager.snippets[index].collectionId != nil {
                snippetManager.snippets[index].collectionId = nil
                SaveNotificationManager.shared.show("Removed from collection")
            }
        }
    }
}