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
    let availableWidth: CGFloat
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var isExpanded = true
    @State private var isDropTarget = false
    
    init(snippets: [Snippet], editingSnippet: Binding<Snippet?>, availableWidth: CGFloat = 0) {
        self.snippets = snippets
        self._editingSnippet = editingSnippet
        self.availableWidth = availableWidth
    }
    
    // Determine layout based on width
    private var useCompactLayout: Bool {
        availableWidth > 0 && availableWidth < 500
    }
    
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
            HStack(spacing: useCompactLayout ? 8 : 10) {
                // Left side: Icon and title
                HStack(spacing: useCompactLayout ? 6 : 8) {
                    Image(systemName: "tray")
                        .font(.system(size: useCompactLayout ? 10 : 12, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: useCompactLayout ? 18 : 20, height: useCompactLayout ? 18 : 20)
                        .background(
                            Circle()
                                .fill(Color.gray.opacity(0.12))
                        )
                    
                    Text("Uncollected Snippets")
                        .font(.system(size: useCompactLayout ? 13 : 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Drop indicator when dragging from collections
                if isDropTarget {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: useCompactLayout ? 9 : 10))
                        
                        if !useCompactLayout {
                            Text("Remove from collection")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, useCompactLayout ? 4 : 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.1))
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Right side: Count and expand indicator
                HStack(spacing: useCompactLayout ? 4 : 6) {
                    if !isExpanded && !snippets.isEmpty {
                        Text("(\(snippets.count))")
                            .font(.system(size: useCompactLayout ? 10 : 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.system(size: useCompactLayout ? 8 : 9, weight: .medium))
                        .foregroundColor(.secondary)
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
            }
            .padding(.horizontal, useCompactLayout ? 12 : 16)
            .padding(.vertical, useCompactLayout ? 10 : 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(uncollectedHeaderBackground)
    }
    
    private var uncollectedHeaderBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(
                Color.gray.opacity(isDropTarget ? 0.08 : 0.02)
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
                .fill(Color.clear)
        )
    }
}
