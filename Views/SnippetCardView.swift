//
//  SnippetCardView.swift
//  Archie
//
//  Created by Amy Elenius on 17/7/2025.
//


import SwiftUI

// MARK: - Snippet Card View
struct SnippetCardView: View {
    let snippet: Snippet
    @Binding var editingSnippet: Snippet?
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false
    
    private var currentSnippet: Snippet {
        snippetManager.snippets.first { $0.id == snippet.id } ?? snippet
    }
    
    private var isBeingEdited: Bool {
        editingSnippet?.id == snippet.id
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main card content
            HStack(spacing: 12) {
                // Enhanced shortcut pill with status indication
                HStack(spacing: 4) {
                    Text(currentSnippet.shortcut)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(pillForegroundColor)
                    
                    if !currentSnippet.requiresSpace {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8))
                            .foregroundColor(pillForegroundColor.opacity(0.7))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(pillBackgroundColor)
                        .stroke(pillBorderColor, lineWidth: 1)
                )
                
                // Enhanced arrow with animation
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
                
                // Improved expansion preview
                VStack(alignment: .leading, spacing: 2) {
                    Text(currentSnippet.expansion.replacingOccurrences(of: "\n", with: " "))
                        .lineLimit(1)
                        .font(.system(size: 12))
                        .foregroundColor(currentSnippet.isEnabled ? .primary : .secondary)
                    
                    // Status indicators
                    HStack(spacing: 8) {
                        if currentSnippet.expansion.contains("\n") {
                            HStack(spacing: 2) {
                                Image(systemName: "text.alignleft")
                                    .font(.system(size: 8))
                                Text("Multi-line")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(.secondary)
                        }
                        
                        if !currentSnippet.requiresSpace {
                            HStack(spacing: 2) {
                                Image(systemName: "bolt")
                                    .font(.system(size: 8))
                                Text("Instant")
                                    .font(.system(size: 9))
                            }
                            .foregroundColor(.orange)
                        }
                    }
                }
                
                Spacer()
                
                // Enhanced action buttons
                HStack(spacing: 6) {
                    // Expand/collapse button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 18, height: 18)
                            .background(
                                Circle()
                                    .fill(Color(NSColor.controlBackgroundColor))
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    
                    // Status toggle with better visual feedback
                    Toggle("", isOn: Binding(
                        get: { currentSnippet.isEnabled },
                        set: { newValue in
                            if let index = snippetManager.snippets.firstIndex(where: { $0.id == snippet.id }) {
                                snippetManager.snippets[index].isEnabled = newValue
                            }
                        }
                    ))
                    .toggleStyle(CompactToggleStyle())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(cardBackgroundColor)
                    .stroke(cardBorderColor, lineWidth: isBeingEdited ? 2 : 1)
                    .shadow(
                        color: cardShadowColor,
                        radius: isHovered || isBeingEdited ? 4 : 2,
                        x: 0,
                        y: isHovered || isBeingEdited ? 2 : 1
                    )
            )
            
            // Expanded details section
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editingSnippet = snippet
        }
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isBeingEdited)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    // MARK: - Expanded Content
    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()
                .padding(.horizontal, 14)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Expansion:")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                
                ScrollView {
                    Text(currentSnippet.expansion)
                        .font(.system(size: 11, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 80)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
            }
            .padding(.horizontal, 14)
            
            // Action buttons
            HStack(spacing: 8) {
                CompactActionButton(
                    title: "Copy",
                    icon: "doc.on.doc",
                    color: .blue
                ) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(currentSnippet.expansion, forType: .string)
                }
                
                CompactActionButton(
                    title: "Duplicate",
                    icon: "plus.square.on.square",
                    color: .green
                ) {
                    duplicateSnippet()
                }
                
                Spacer()
                
                CompactActionButton(
                    title: "Delete",
                    icon: "trash",
                    color: .red
                ) {
                    deleteSnippet()
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor))
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Computed Properties for Styling
    private var pillBackgroundColor: Color {
        if isBeingEdited {
            return Color.accentColor
        } else if currentSnippet.isEnabled {
            return Color.accentColor.opacity(0.15)
        } else {
            return Color.gray.opacity(0.15)
        }
    }
    
    private var pillForegroundColor: Color {
        if isBeingEdited {
            return .white
        } else if currentSnippet.isEnabled {
            return .accentColor
        } else {
            return .secondary
        }
    }
    
    private var pillBorderColor: Color {
        if isBeingEdited {
            return Color.accentColor.opacity(0.5)
        } else if currentSnippet.isEnabled {
            return Color.accentColor.opacity(0.3)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private var cardBackgroundColor: Color {
        if isBeingEdited {
            return Color.accentColor.opacity(0.05)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
    
    private var cardBorderColor: Color {
        if isBeingEdited {
            return Color.accentColor.opacity(0.5)
        } else {
            return Color(NSColor.separatorColor).opacity(isHovered ? 0.8 : 0.3)
        }
    }
    
    private var cardShadowColor: Color {
        return Color.black.opacity(isHovered || isBeingEdited ? 0.08 : 0.03)
    }
    
    // MARK: - Actions
    private func duplicateSnippet() {
        let duplicatedSnippet = Snippet(
            shortcut: "\(currentSnippet.shortcut)_copy",
            expansion: currentSnippet.expansion,
            requiresSpace: currentSnippet.requiresSpace
        )
        snippetManager.addSnippet(duplicatedSnippet)
    }
    
    private func deleteSnippet() {
        withAnimation(.easeInOut(duration: 0.3)) {
            snippetManager.deleteSnippet(currentSnippet)
        }
    }
}