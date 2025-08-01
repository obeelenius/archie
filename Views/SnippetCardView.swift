// SnippetCardView.swift

import SwiftUI

// MARK: - Snippet Card View - Close Editor on Card Click 100137
struct SnippetCardView: View {
    let snippet: Snippet
    @Binding var editingSnippet: Snippet?
    let isCompact: Bool
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false
    @State private var isDragging: Bool = false
    
    init(snippet: Snippet, editingSnippet: Binding<Snippet?>, isCompact: Bool = false) {
        self.snippet = snippet
        self._editingSnippet = editingSnippet
        self.isCompact = isCompact
    }
    
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
            let dragData = SnippetDragData(snippet: currentSnippet)
            return NSItemProvider(object: dragData)
        }
    }
}

// MARK: - Main Card Content 100138
extension SnippetCardView {
    private var mainCardContent: some View {
        HStack(spacing: isCompact ? 6 : 8) {
            shortcutPill
            arrowIndicator
            expansionPreview
            Spacer()
            actionButtons
        }
        .padding(.horizontal, isCompact ? 8 : 10)
        .padding(.vertical, isCompact ? 10 : 12)
        .background(cardBackground)
    }
    
    private var shortcutPill: some View {
        HStack(spacing: 3) {
            Text(currentSnippet.shortcut)
                .font(.system(size: isCompact ? 10 : 11, weight: .semibold))
                .foregroundColor(pillForegroundColor)
                .lineLimit(1)
            
            if !currentSnippet.requiresSpace {
                Image(systemName: "bolt.fill")
                    .font(.system(size: isCompact ? 5 : 6))
                    .foregroundColor(pillForegroundColor.opacity(0.7))
            }
        }
        .padding(.horizontal, isCompact ? 5 : 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(pillBackgroundColor)
                .stroke(pillBorderColor, lineWidth: 0.5)
        )
    }
    
    private var arrowIndicator: some View {
        Image(systemName: "arrow.right")
            .font(.system(size: isCompact ? 8 : 9, weight: .medium))
            .foregroundColor(.secondary)
            .scaleEffect(isHovered ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
    
    private var expansionPreview: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(currentSnippet.expansion.replacingOccurrences(of: "\n", with: " "))
                .lineLimit(1)
                .font(.system(size: isCompact ? 10 : 11))
                .foregroundColor(currentSnippet.isEnabled ? .primary : .secondary)
            
            if !isCompact {
                statusIndicators
            }
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
        HStack(spacing: isCompact ? 3 : 4) {
            if !isCompact {
                expandCollapseButton
            }
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
        .scaleEffect(isCompact ? 0.7 : 0.8)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: isCompact ? 5 : 6)
            .fill(cardBackgroundColor)
            .stroke(cardBorderColor, lineWidth: isBeingEdited ? 1.5 : 0.5)
            .shadow(
                color: cardShadowColor,
                radius: isHovered || isBeingEdited ? 2 : 1,
                x: 0,
                y: isHovered || isBeingEdited ? 1.5 : 0.5
            )
    }
}

// MARK: - Card Tap Handling 100140
extension SnippetCardView {
    private func handleCardTap() {
        // Always set this snippet as the editing snippet (discarding any unsaved changes)
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
                    .font(.system(size: 11))
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
    private var collectionColor: Color {
        // First try to get collection by ID
        if let collectionId = currentSnippet.collectionId,
           let collection = snippetManager.collections.first(where: { $0.id == collectionId }) {
            return getColor(from: collection.color)
        }
        
        // Fallback: try to find collection by checking which snippets belong to it
        for collection in snippetManager.collections {
            let snippetsInCollection = snippetManager.snippets(for: collection)
            if snippetsInCollection.contains(where: { $0.id == currentSnippet.id }) {
                return getColor(from: collection.color)
            }
        }
        
        return .blue // Default fallback
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
    
    private var pillBackgroundColor: Color {
        if isBeingEdited {
            return collectionColor
        } else if currentSnippet.isEnabled {
            return collectionColor.opacity(0.15)
        } else {
            return Color.gray.opacity(0.15)
        }
    }
    
    private var pillForegroundColor: Color {
        if isBeingEdited {
            return .white
        } else if currentSnippet.isEnabled {
            return collectionColor
        } else {
            return .secondary
        }
    }
    
    private var pillBorderColor: Color {
        if isBeingEdited {
            return collectionColor.opacity(0.5)
        } else if currentSnippet.isEnabled {
            return collectionColor.opacity(0.3)
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private var cardBackgroundColor: Color {
        if isBeingEdited {
            return collectionColor.opacity(0.05)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
    
    private var cardBorderColor: Color {
        if isBeingEdited {
            return collectionColor.opacity(0.5)
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
