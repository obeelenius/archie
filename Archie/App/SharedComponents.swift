// SharedComponents.swift

import SwiftUI

// MARK: - All Shared UI Components 100084
// Put ALL shared components in this one file to avoid duplicates

// MARK: - Resize Handle Component 100085
struct ResizeHandle: View {
    @Binding var editorWidth: CGFloat
    let windowWidth: CGFloat
    @Binding var isDragging: Bool
    @State private var isHovered = false
    @State private var startWidth: CGFloat = 0
    @State private var startLocation: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 12)
            .contentShape(Rectangle())
            .background(resizeHandleBackground)
            .overlay(resizeHandleBorder)
            .onHover { hovering in
                isHovered = hovering
                // Apply cursor immediately on hover change
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else if !isDragging {
                    NSCursor.pop()
                }
            }
            .gesture(resizeGesture)
            // Add cursor tracking area for more reliable cursor display
            .background(
                CursorTrackingView(cursor: .resizeLeftRight, isActive: isHovered || isDragging)
            )
    }
    
    private var resizeHandleBackground: some View {
        Rectangle()
            .fill(isHovered || isDragging ? Color.accentColor.opacity(0.2) : Color.clear)
            .animation(.easeInOut(duration: 0.2), value: isHovered || isDragging)
    }
    
    private var resizeHandleBorder: some View {
        Rectangle()
            .fill(Color(NSColor.separatorColor))
            .frame(width: isDragging ? 2 : 1)
            .animation(.easeInOut(duration: 0.1), value: isDragging)
    }
    
    private var resizeGesture: some Gesture {
        DragGesture(coordinateSpace: .global)
            .onChanged { value in
                if !isDragging {
                    isDragging = true
                    startWidth = editorWidth
                    startLocation = value.startLocation.x
                    // Ensure cursor stays during drag
                    NSCursor.resizeLeftRight.push()
                }
                
                let deltaX = value.location.x - startLocation
                let deltaWidth = -deltaX / windowWidth
                let newWidth = startWidth + deltaWidth
                
                editorWidth = min(max(newWidth, 0.25), 0.65)
            }
            .onEnded { _ in
                isDragging = false
                handleSnapToTargets()
                // Pop cursor when drag ends if not hovering
                if !isHovered {
                    NSCursor.pop()
                }
            }
    }
    
    private func handleSnapToTargets() {
        let snapTargets: [CGFloat] = [0.25, 0.33, 0.4, 0.5, 0.6, 0.65]
        let snapThreshold: CGFloat = 0.03
        
        for target in snapTargets {
            if abs(editorWidth - target) < snapThreshold {
                withAnimation(.easeOut(duration: 0.3)) {
                    editorWidth = target
                }
                return
            }
        }
    }
}

// MARK: - Cursor Tracking View 100086A
struct CursorTrackingView: NSViewRepresentable {
    let cursor: NSCursor
    let isActive: Bool
    
    func makeNSView(context: Context) -> NSView {
        let view = CursorView()
        view.cursor = cursor
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let cursorView = nsView as? CursorView {
            cursorView.isActive = isActive
        }
    }
    
    class CursorView: NSView {
        var cursor: NSCursor = NSCursor.arrow
        var isActive: Bool = false {
            didSet {
                updateTrackingArea()
            }
        }
        
        private var trackingArea: NSTrackingArea?
        
        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            updateTrackingArea()
        }
        
        private func updateTrackingArea() {
            if let trackingArea = trackingArea {
                removeTrackingArea(trackingArea)
            }
            
            if isActive {
                trackingArea = NSTrackingArea(
                    rect: bounds,
                    options: [.activeInKeyWindow, .mouseEnteredAndExited, .mouseMoved],
                    owner: self,
                    userInfo: nil
                )
                addTrackingArea(trackingArea!)
            }
        }
        
        override func mouseEntered(with event: NSEvent) {
            if isActive {
                cursor.push()
            }
        }
        
        override func mouseExited(with event: NSEvent) {
            if isActive {
                NSCursor.pop()
            }
        }
        
        override func mouseMoved(with event: NSEvent) {
            if isActive {
                cursor.set()
            }
        }
    }
}

// MARK: - Empty State View 100086
struct EmptyStateView: View {
    let isSearching: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            emptyStateIcon
            emptyStateText
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
    
    private var emptyStateIcon: some View {
        ZStack {
            Circle()
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 80, height: 80)
            
            Image(systemName: isSearching ? "magnifyingglass" : "doc.text.below.ecg")
                .font(.system(size: 32))
                .foregroundColor(.accentColor)
        }
    }
    
    private var emptyStateText: some View {
        VStack(spacing: 12) {
            Text(isSearching ? "No matching snippets" : "No snippets yet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(emptyStateMessage)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(3)
        }
    }
    
    private var emptyStateMessage: String {
        isSearching ?
        "Try adjusting your search terms or click 'Add' to create a new one" :
        "Click 'Add' to create your first text expansion"
    }
}

// MARK: - Compact Toggle Style 100087
struct CompactToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 8)
                .fill(configuration.isOn ? Color.green : Color.gray.opacity(0.4))
                .frame(width: 32, height: 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(configuration.isOn ? Color.clear : Color.gray.opacity(0.6), lineWidth: 1)
                )
                .overlay(toggleThumb(configuration))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
    
    private func toggleThumb(_ configuration: Configuration) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 14, height: 14)
            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1)
            .offset(x: configuration.isOn ? 7 : -7)
            .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
    }
}

// MARK: - Modern Toggle Style 100088
struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 12)
                .fill(configuration.isOn ? Color.green : Color(NSColor.controlColor))
                .frame(width: 44, height: 24)
                .overlay(modernToggleThumb(configuration))
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
    
    private func modernToggleThumb(_ configuration: Configuration) -> some View {
        Circle()
            .fill(Color.white)
            .frame(width: 20, height: 20)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .offset(x: configuration.isOn ? 10 : -10)
            .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
    }
}

// MARK: - Compact Action Button 100089
struct CompactActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(buttonBackground)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color.opacity(isPressed ? 0.2 : 0.1))
            .stroke(color.opacity(0.3), lineWidth: 1)
    }
}

// MARK: - Compact Tip Component 100090
struct CompactTip: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.orange)
                .frame(width: 4, height: 4)
            
            Text(text)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Settings Section Component 100091
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader
            content
        }
    }
    
    private var sectionHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.system(size: 16))
            
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Settings Row Component 100092
struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String
    let control: Content
    
    init(title: String, subtitle: String, @ViewBuilder control: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.control = control()
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            control
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Collection Card Component 100093
struct CollectionCard: View {
    let collection: SnippetCollection
    let snippets: [Snippet]
    @Binding var editingCollection: SnippetCollection?
    @State private var isExpanded = false
    @StateObject private var snippetManager = SnippetManager.shared
    
    var enabledCount: Int {
        snippets.filter(\.isEnabled).count
    }
    
    // Get the current collection data from the manager to reflect any changes
    var currentCollection: SnippetCollection {
        snippetManager.collections.first { $0.id == collection.id } ?? collection
    }
    
    // Calculate the effective enabled state based on snippets
    var effectiveEnabledState: Bool {
        // Get the current snippets from the manager to ensure we have the latest state
        let currentSnippets = snippetManager.snippets.filter { $0.collectionId == collection.id }
        
        // If collection has no snippets, use collection's isEnabled state
        if currentSnippets.isEmpty {
            return currentCollection.isEnabled
        }
        // If collection has snippets, it's enabled only if ALL snippets are enabled
        return currentSnippets.allSatisfy(\.isEnabled)
    }
    
    var isBeingEdited: Bool {
        editingCollection?.id == collection.id
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            collectionHeader
            collectionPreview
            expandedContent
        }
        .padding(12)
        .background(cardBackground)
        .contentShape(Rectangle())
        .onTapGesture {
            handleCardTap()
        }
        // Force refresh when snippets change
        .id("\(collection.id)-\(snippetManager.snippets.filter { $0.collectionId == collection.id }.map(\.isEnabled).description)")
    }
    
    private var collectionHeader: some View {
        HStack {
            HStack(spacing: 8) {
                collectionIcon
                collectionInfo
            }
            
            Spacer()
            
            collectionActions
        }
    }
    
    private var collectionIcon: some View {
        Image(systemName: currentCollection.icon.isEmpty ? "folder" : currentCollection.icon)
            .foregroundColor(getColor(from: currentCollection.color))
            .font(.system(size: 16))
    }
    
    private var collectionInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(currentCollection.name)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("\(snippets.count) snippets • \(enabledCount) enabled")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var collectionActions: some View {
        HStack(spacing: 8) {
            Toggle("", isOn: Binding(
                get: {
                    let state = effectiveEnabledState
                    print("DEBUG TOGGLE: Collection '\(currentCollection.name)' effective state: \(state)")
                    return state
                },
                set: { newValue in
                    print("DEBUG TOGGLE: User toggled collection '\(currentCollection.name)' to: \(newValue)")
                    toggleCollectionAndSnippets(enabled: newValue)
                }
            ))
            .toggleStyle(CompactToggleStyle())
            
            Button("Edit") {
                editingCollection = currentCollection
            }
            .font(.system(size: 12))
            .foregroundColor(.accentColor)
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
    
    private func toggleCollectionAndSnippets(enabled: Bool) {
        print("DEBUG COLLECTION TOGGLE: Setting collection '\(currentCollection.name)' to enabled: \(enabled)")
        
        // Use withAnimation to ensure smooth UI updates
        withAnimation(.easeInOut(duration: 0.2)) {
            // Always update the collection state
            if let index = snippetManager.collections.firstIndex(where: { $0.id == collection.id }) {
                snippetManager.collections[index].isEnabled = enabled
                print("DEBUG COLLECTION TOGGLE: Updated collection isEnabled to \(enabled)")
            }
            
            // Always override ALL snippets in this collection to match the collection state
            var updatedSnippetsCount = 0
            for i in snippetManager.snippets.indices {
                if snippetManager.snippets[i].collectionId == collection.id {
                    let oldState = snippetManager.snippets[i].isEnabled
                    snippetManager.snippets[i].isEnabled = enabled
                    if oldState != enabled {
                        updatedSnippetsCount += 1
                    }
                }
            }
            
            print("DEBUG COLLECTION TOGGLE: Updated \(updatedSnippetsCount) snippets to match collection state")
        }
        
        // Show notification
        let currentSnippets = snippetManager.snippets.filter { $0.collectionId == collection.id }
        let message: String
        if enabled {
            message = "Enabled \(currentCollection.name) and all \(currentSnippets.count) snippets"
        } else {
            message = "Disabled \(currentCollection.name) and all \(currentSnippets.count) snippets"
        }
        SaveNotificationManager.shared.show(message)
    }
    
    private func handleCardTap() {
        // Always set this collection as the editing collection (discarding any unsaved changes)
        editingCollection = currentCollection
    }
    
    @ViewBuilder
    private var collectionPreview: some View {
        if !isExpanded && !snippets.isEmpty {
            HStack {
                ForEach(Array(snippets.prefix(3)), id: \.id) { snippet in
                    snippetPreview(snippet)
                }
                
                if snippets.count > 3 {
                    Text("+\(snippets.count - 3)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
        }
    }
    
    private func snippetPreview(_ snippet: Snippet) -> some View {
        // Get current snippet state from manager
        let currentSnippet = snippetManager.snippets.first { $0.id == snippet.id } ?? snippet
        
        return Text(currentSnippet.shortcut)
            .font(.system(.caption))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(getColor(from: currentCollection.color).opacity(currentSnippet.isEnabled ? 0.1 : 0.05))
            )
            .foregroundColor(getColor(from: currentCollection.color).opacity(currentSnippet.isEnabled ? 1.0 : 0.5))
    }
    
    @ViewBuilder
    private var expandedContent: some View {
        if isExpanded {
            VStack(spacing: 8) {
                ForEach(snippets) { snippet in
                    expandedSnippetRow(snippet)
                }
            }
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }
    
    private func expandedSnippetRow(_ snippet: Snippet) -> some View {
        // Get current snippet state from manager
        let currentSnippet = snippetManager.snippets.first { $0.id == snippet.id } ?? snippet
        
        return HStack {
            Text(currentSnippet.shortcut)
                .font(.system(.caption))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(getColor(from: currentCollection.color).opacity(0.1))
                )
                .foregroundColor(getColor(from: currentCollection.color))
            
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .font(.caption)
            
            Text(currentSnippet.expansion.replacingOccurrences(of: "\n", with: " "))
                .font(.caption)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            Spacer()
            
            Circle()
                .fill(currentSnippet.isEnabled ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.white)
        .cornerRadius(6)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(NSColor.controlBackgroundColor))
            .stroke(isBeingEdited ? getColor(from: currentCollection.color).opacity(0.5) : Color(NSColor.separatorColor).opacity(0.3), lineWidth: isBeingEdited ? 2 : 1)
            .shadow(
                color: isBeingEdited ? getColor(from: currentCollection.color).opacity(0.2) : Color.black.opacity(0.05),
                radius: isBeingEdited ? 6 : 2,
                x: 0,
                y: isBeingEdited ? 3 : 1
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
