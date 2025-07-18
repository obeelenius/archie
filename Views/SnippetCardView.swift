// SnippetCardView.swift

import SwiftUI

// MARK: - Snippet Card View - Close Editor on Card Click 100137
struct SnippetCardView: View {
    let snippet: Snippet
    @Binding var editingSnippet: Snippet?
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false
    @State private var isDragging: Bool = false
    
    private var currentSnippet: Snippet {
        snippetManager.snippets.first { $0.id == snippet.id } ?? snippet
    }
    
    private var isBeingEdited: Bool {
        editingSnippet?.id == snippet.id
    }
    
    var body: some View {
        VStack(spacing: 0) {
            mainCardContent
            expandedContent
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleCardTap()
        }
        .scaleEffect(isHovered ? 1.005 : 1.0)
        .opacity(isDragging ? 0.6 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isBeingEdited)
        .animation(.easeInOut(duration: 0.15), value: isDragging)
        .onHover { hovering in
            isHovered = hovering
        }
        .onDrag {
                    isDragging = true
                    print("DEBUG DRAG: Starting drag for snippet '\(currentSnippet.shortcut)' (ID: \(currentSnippet.id.uuidString))")
                    
                    let dragData = SnippetDragData(snippet: currentSnippet)
                    print("DEBUG DRAG: Created drag data for snippet")
                    
                    return NSItemProvider(object: dragData)
                }
    }
}

// MARK: - Drag Preview 100137A
extension SnippetCardView {
    private var dragPreview: some View {
        HStack(spacing: 8) {
            Text(currentSnippet.shortcut)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor)
                )
            
            Image(systemName: "arrow.right")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
            
            Text(currentSnippet.expansion)
                .font(.system(size: 10))
                .lineLimit(1)
                .truncationMode(.tail)
                .foregroundColor(.primary)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .stroke(Color.accentColor, lineWidth: 1)
        )
        .frame(maxWidth: 200)
    }
}

// MARK: - Main Card Content 100138
extension SnippetCardView {
    private var mainCardContent: some View {
        HStack(spacing: 8) {
            shortcutPill
            arrowIndicator
            expansionPreview
            Spacer()
            actionButtons
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
        .background(cardBackground)
    }
    
    private var shortcutPill: some View {
        HStack(spacing: 3) {
            Text(currentSnippet.shortcut)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(pillForegroundColor)
            
            if !currentSnippet.requiresSpace {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 6))
                    .foregroundColor(pillForegroundColor.opacity(0.7))
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(pillBackgroundColor)
                .stroke(pillBorderColor, lineWidth: 0.5)
        )
    }
    
    private var arrowIndicator: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: 9, weight: .medium))
            .foregroundColor(.secondary)
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    private var expansionPreview: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(currentSnippet.expansion.replacingOccurrences(of: "\n", with: " "))
                .lineLimit(1)
                .font(.system(size: 11))
                .foregroundColor(currentSnippet.isEnabled ? .primary : .secondary)
            
            statusIndicators
        }
    }
    
    private var statusIndicators: some View {
            HStack(spacing: 6) {
                if currentSnippet.expansion.contains("\n") {
                    HStack(spacing: 1) {
                        Image(systemName: "text.alignleft")
                            .font(.system(size: 6))
                        Text("Multi-line")
                            .font(.system(size: 8))
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
}

// MARK: - Action Buttons 100139
extension SnippetCardView {
    private var actionButtons: some View {
        HStack(spacing: 4) {
            expandCollapseButton
            enableToggle
        }
    }
    
    private var expandCollapseButton: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }) {
            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.secondary)
                .frame(width: 14, height: 14)
                .background(
                    Circle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .stroke(Color(NSColor.separatorColor), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
    
    private var enableToggle: some View {
        Toggle("", isOn: Binding(
            get: { currentSnippet.isEnabled },
            set: { newValue in
                if let index = snippetManager.snippets.firstIndex(where: { $0.id == snippet.id }) {
                    snippetManager.snippets[index].isEnabled = newValue
                }
            }
        ))
        .toggleStyle(CompactToggleStyle())
        .scaleEffect(0.8)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(cardBackgroundColor)
            .stroke(cardBorderColor, lineWidth: isBeingEdited ? 1.5 : 0.5)
            .shadow(
                color: cardShadowColor,
                radius: isHovered || isBeingEdited ? 2 : 1,
                x: 0,
                y: isHovered || isBeingEdited ? 1 : 0.5
            )
    }
}

// MARK: - Card Tap Handling 100140
extension SnippetCardView {
    private func handleCardTap() {
        // Always set this card as the editing snippet (discarding any unsaved changes)
        editingSnippet = snippet
    }
}

// MARK: - Expanded Content 100141
extension SnippetCardView {
    @ViewBuilder
    private var expandedContent: some View {
        if isExpanded {
            VStack(alignment: .leading, spacing: 12) {
                Divider()
                    .padding(.horizontal, 14)
                
                fullExpansionSection
                expandedActionButtons
            }
            .background(expandedContentBackground)
            .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
        }
    }
    
    private var fullExpansionSection: some View {
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
    }
    
    private var expandedActionButtons: some View {
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
    
    private var expandedContentBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(NSColor.textBackgroundColor))
            .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
    }
}

// MARK: - Styling Properties 100142
extension SnippetCardView {
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
}

// MARK: - Actions 100143
extension SnippetCardView {
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
