import SwiftUI

// Extension to add cursor support
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

// MARK: - Main Settings View [ID: 100001]
struct SettingsView: View {
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var selectedView: MainView = .snippets
    @State private var editorWidth: CGFloat = 0.4
    @State private var isDragging = false
    @State private var editingSnippet: Snippet? = nil
    
    var showingEditor: Bool {
        showingAddSheet || editingSnippet != nil
    }
    
    enum MainView: String, CaseIterable, Identifiable {
        case snippets = "Snippets"
        case collections = "Collections"
        case general = "General"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .snippets: return "doc.text"
            case .collections: return "folder"
            case .general: return "gearshape"
            }
        }
    }
    
    var filteredSnippets: [Snippet] {
        if searchText.isEmpty {
            return snippetManager.snippets
        } else {
            return snippetManager.snippets.filter { snippet in
                snippet.shortcut.localizedCaseInsensitiveContains(searchText) ||
                snippet.expansion.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Main content area
                VStack(spacing: 0) {
                    // Top navigation bar
                    VStack(spacing: 0) {
                        // Compact header with app branding
                        HStack {
                            HStack(spacing: 8) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(LinearGradient(
                                            colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 28, height: 28)
                                        .shadow(color: Color.accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
                                    
                                    Image(systemName: "text.cursor")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Archie")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.primary)
                                    
                                    Text("Text Expansion")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Compact add snippet button
                            Button(action: { showingAddSheet = true }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "plus")
                                        .font(.system(size: 12, weight: .semibold))
                                    Text("Add")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.accentColor)
                                        .shadow(color: Color.accentColor.opacity(0.2), radius: 3, x: 0, y: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        
                        // Compact navigation tabs
                        HStack(spacing: 0) {
                            ForEach(MainView.allCases) { view in
                                Button(action: { selectedView = view }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: view.icon)
                                            .font(.system(size: 11, weight: .medium))
                                        Text(view.rawValue)
                                            .font(.system(size: 11, weight: .medium))
                                    }
                                    .foregroundColor(selectedView == view ? .accentColor : .secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(selectedView == view ? Color.accentColor.opacity(0.1) : Color.clear)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        
                        Divider()
                    }
                    .background(Color(NSColor.windowBackgroundColor))
                    
                    // Content area based on selected view
                    Group {
                        switch selectedView {
                        case .snippets:
                            SnippetsContentView(
                                filteredSnippets: filteredSnippets,
                                searchText: $searchText,
                                editingSnippet: $editingSnippet
                            )
                        case .collections:
                            CollectionsContentView()
                        case .general:
                            GeneralSettingsContentView()
                        }
                    }
                }
                .frame(width: showingEditor ? geometry.size.width * (1 - editorWidth) : geometry.size.width)
                
                // Slide-out editor panel
                if showingEditor {
                    HStack(spacing: 0) {
                        // Resize handle
                        ResizeHandle(
                            editorWidth: $editorWidth,
                            windowWidth: geometry.size.width,
                            isDragging: $isDragging
                        )
                        
                        if let editingSnippet = editingSnippet {
                            EditSnippetSlideOut(
                                snippet: editingSnippet,
                                isShowing: Binding(
                                    get: { self.editingSnippet != nil },
                                    set: { if !$0 { self.editingSnippet = nil } }
                                )
                            )
                        } else {
                            AddSnippetSlideOut(isShowing: $showingAddSheet)
                        }
                    }
                    .frame(width: geometry.size.width * editorWidth)
                    .transition(.move(edge: .trailing))
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .animation(isDragging ? .none : .easeInOut(duration: 0.3), value: showingEditor)
        .animation(isDragging ? .none : .easeInOut(duration: 0.2), value: editorWidth)
    }
}

// MARK: - Resize Handle Component [ID: 100002]
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
            .background(
                Rectangle()
                    .fill(isHovered || isDragging ? Color.accentColor.opacity(0.2) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: isHovered || isDragging)
            )
            .overlay(
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(width: isDragging ? 2 : 1)
                    .animation(.easeInOut(duration: 0.1), value: isDragging)
            )
            .cursor(NSCursor.resizeLeftRight)
            .onHover { hovering in
                isHovered = hovering
            }
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            startWidth = editorWidth
                            startLocation = value.startLocation.x
                        }
                        
                        let deltaX = value.location.x - startLocation
                        let deltaWidth = -deltaX / windowWidth
                        let newWidth = startWidth + deltaWidth
                        
                        editorWidth = min(max(newWidth, 0.25), 0.65)
                    }
                    .onEnded { _ in
                        isDragging = false
                        
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
            )
    }
}

// MARK: - Snippets Content View [ID: 100003]
struct SnippetsContentView: View {
    let filteredSnippets: [Snippet]
    @Binding var searchText: String
    @Binding var editingSnippet: Snippet?
    @StateObject private var snippetManager = SnippetManager.shared
    
    var groupedSnippets: [String: [Snippet]] {
        Dictionary(grouping: filteredSnippets, by: classifySnippet)
    }
    
    private func classifySnippet(_ snippet: Snippet) -> String {
        let shortcut = snippet.shortcut.lowercased()
        
        if shortcut.hasPrefix("@") { return "Email & Contacts" }
        if shortcut.hasPrefix("#") { return "Social & Tags" }
        if shortcut.contains("addr") || shortcut.contains("address") { return "Addresses" }
        if shortcut.contains("phone") || shortcut.contains("tel") { return "Phone Numbers" }
        if shortcut.contains("sig") || shortcut.contains("signature") { return "Signatures" }
        if shortcut.contains("date") || shortcut.contains("time") || shortcut.contains("today") || shortcut.contains("now") {
            return "Date & Time"
        }
        return "General"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Compact search and stats bar
            VStack(spacing: 8) {
                // Enhanced search bar
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                    
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .padding(.vertical, 6)
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .stroke(Color(NSColor.separatorColor).opacity(0.5), lineWidth: 1)
                )
                
                // Compact stats row
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text")
                            .foregroundColor(.accentColor)
                            .font(.system(size: 10))
                        Text("\(snippetManager.snippets.count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                        Text("snippets")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text("\(snippetManager.snippets.filter(\.isEnabled).count)")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                        Text("enabled")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content area
            if filteredSnippets.isEmpty {
                EmptyStateView(isSearching: !searchText.isEmpty)
            } else {
                ScrollView {
                    LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                        ForEach(Array(groupedSnippets.keys.sorted()), id: \.self) { collectionName in
                            Section {
                                LazyVStack(spacing: 6) {
                                    ForEach(groupedSnippets[collectionName] ?? []) { snippet in
                                        SnippetCardView(
                                            snippet: snippet,
                                            editingSnippet: $editingSnippet
                                        )
                                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                    }
                                }
                            } header: {
                                let collectionIcon = getCollectionIcon(for: collectionName)
                                let snippetCount = groupedSnippets[collectionName]?.count ?? 0
                                
                                HStack {
                                    Image(systemName: collectionIcon)
                                        .foregroundColor(.accentColor)
                                        .font(.system(size: 12, weight: .medium))
                                    
                                    Text(collectionName)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.primary)
                                    
                                    Text("(\(snippetCount))")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color(NSColor.controlBackgroundColor).opacity(0.8))
                                        .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
                                )
                                .padding(.horizontal, 12)
                            }
                        }
                    }
                    .padding(.vertical, 12)
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            }
        }
    }
    
    private func getCollectionIcon(for collectionName: String) -> String {
        switch collectionName {
        case "Email & Contacts": return "at"
        case "Social & Tags": return "number"
        case "Addresses": return "location"
        case "Phone Numbers": return "phone"
        case "Signatures": return "signature"
        case "Date & Time": return "clock"
        default: return "folder"
        }
    }
}

// MARK: - Collections Content View [ID: 100004]
struct CollectionsContentView: View {
    @StateObject private var snippetManager = SnippetManager.shared
    
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
        VStack(spacing: 0) {
            // Compact header
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "folder")
                            .foregroundColor(.purple)
                            .font(.system(size: 10))
                        Text("\(snippetCollections.count)")
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
            
            // Collections grid
            if snippetCollections.isEmpty {
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
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 280), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Array(snippetCollections.keys.sorted()), id: \.self) { collectionName in
                            CollectionCard(
                                name: collectionName,
                                snippets: snippetCollections[collectionName] ?? []
                            )
                        }
                    }
                    .padding(12)
                }
                .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            }
        }
    }
}

// MARK: - General Settings Content View [ID: 100005]
struct GeneralSettingsContentView: View {
    @State private var startAtLogin = false
    @State private var showNotifications = true
    @State private var soundEnabled = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    SettingsSection(title: "Startup", icon: "power") {
                        SettingsRow(
                            title: "Start Archie at login",
                            subtitle: "Automatically start when you log in to your Mac"
                        ) {
                            Toggle("", isOn: $startAtLogin)
                                .toggleStyle(ModernToggleStyle())
                        }
                    }
                    
                    SettingsSection(title: "Notifications", icon: "bell") {
                        SettingsRow(
                            title: "Show notifications",
                            subtitle: "Display alerts when snippets are expanded"
                        ) {
                            Toggle("", isOn: $showNotifications)
                                .toggleStyle(ModernToggleStyle())
                        }
                        
                        SettingsRow(
                            title: "Play sound",
                            subtitle: "Audio feedback when text is expanded"
                        ) {
                            Toggle("", isOn: $soundEnabled)
                                .toggleStyle(ModernToggleStyle())
                        }
                    }
                    
                    SettingsSection(title: "About", icon: "info.circle") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Archie")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("Version 1.0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Text Expansion Made Simple")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Divider()
                                .padding(.vertical, 8)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Button("Check for Updates") {
                                    // TODO: Implement update checking
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Send Feedback") {
                                    // TODO: Implement feedback
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        )
                    }
                }
                .padding(16)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        }
    }
}

// MARK: - Edit Snippet Slide Out [ID: 100006]
struct EditSnippetSlideOut: View {
    let snippet: Snippet
    @Binding var isShowing: Bool
    @StateObject private var snippetManager = SnippetManager.shared
    
    @State private var shortcut = ""
    @State private var expansion = ""
    @State private var requiresSpace = true
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Edit Snippet")
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("Modify text expansion")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { isShowing = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                            .padding(6)
                            .background(Circle().fill(Color(NSColor.controlColor)))
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Compact form content
            ScrollView {
                VStack(spacing: 16) {
                    // Original shortcut display (read-only)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "keyboard")
                                .foregroundColor(.secondary)
                                .font(.system(size: 12))
                            
                            Text("Original Shortcut")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        
                        Text(snippet.shortcut)
                            .font(.system(.body, design: .monospaced, weight: .semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.accentColor.opacity(0.1))
                                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Editable shortcut section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            
                            Text("New Shortcut")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        TextField("Current: \(snippet.shortcut)", text: $shortcut)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.textBackgroundColor))
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                        
                        Text("Edit shortcut or leave unchanged")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    // Expansion section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            
                            Text("Expansion")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.textBackgroundColor))
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                .frame(minHeight: 80)
                            
                            TextEditor(text: $expansion)
                                .font(.system(.body, design: .monospaced))
                                .padding(6)
                                .scrollContentBackground(.hidden)
                        }
                        
                        Text("Supports line breaks")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    // Trigger option section - inline implementation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "keyboard.badge.ellipsis")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            
                            Text("Trigger Behavior")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Toggle("", isOn: $requiresSpace)
                                    .toggleStyle(CompactToggleStyle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Require space after shortcut")
                                        .font(.system(size: 12, weight: .medium))
                                    
                                    let displayText = requiresSpace ? "Expands after '\(shortcut) '" : "Expands immediately after '\(shortcut)'"
                                    Text(displayText)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                    }
                    
                    // Preview section - inline implementation
                    if !shortcut.isEmpty && !expansion.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                
                                Text("Smart Replacement")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Example:")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    let triggerText = "'\(shortcut)\(requiresSpace ? " " : "")'"
                                    let previewText = String(expansion.prefix(20)) + (expansion.count > 20 ? "..." : "")
                                    
                                    Text("Typing")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                    
                                    Text(triggerText)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.accentColor)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color.accentColor.opacity(0.1))
                                        )
                                    
                                    Text("→")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                    
                                    Text(previewText)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color(NSColor.controlBackgroundColor))
                                        )
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.05))
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(16)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            
            // Compact footer with buttons
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 8) {
                    Button("Cancel") {
                        isShowing = false
                    }
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .disabled(expansion.isEmpty)
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(expansion.isEmpty ? Color.gray : Color.accentColor)
                    )
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color.clear)
                .frame(width: 1),
            alignment: .trailing
        )
        .onAppear {
            shortcut = snippet.shortcut
            expansion = snippet.expansion
            requiresSpace = snippet.requiresSpace
        }
        .onChange(of: snippet.id) { oldValue, newValue in
            shortcut = snippet.shortcut
            expansion = snippet.expansion
            requiresSpace = snippet.requiresSpace
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveChanges() {
        let finalShortcut = shortcut.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if snippetManager.snippets.contains(where: { $0.shortcut == finalShortcut && $0.id != snippet.id }) {
            errorMessage = "A snippet with this shortcut already exists."
            showingError = true
            return
        }
        
        if let index = snippetManager.snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippetManager.snippets[index].shortcut = finalShortcut
            snippetManager.snippets[index].expansion = expansion
            snippetManager.snippets[index].requiresSpace = requiresSpace
        }
        
        isShowing = false
    }
}

// MARK: - Add Snippet Slide Out [ID: 100007]
struct AddSnippetSlideOut: View {
    @Binding var isShowing: Bool
    @StateObject private var snippetManager = SnippetManager.shared
    
    @State private var shortcut = ""
    @State private var expansion = ""
    @State private var requiresSpace = true
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Add Snippet")
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("Create text expansion")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: { isShowing = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .font(.system(size: 12))
                            .padding(6)
                            .background(Circle().fill(Color(NSColor.controlColor)))
                    }
                    .buttonStyle(.plain)
                }
                
                Divider()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            // Compact form content
            ScrollView {
                VStack(spacing: 16) {
                    // Shortcut section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "keyboard")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            
                            Text("Shortcut")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        TextField("e.g., 'addr', '@@'", text: $shortcut)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.textBackgroundColor))
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                        
                        Text("Type + space to expand")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    // Expansion section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "text.alignleft")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            
                            Text("Expansion")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.textBackgroundColor))
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                .frame(minHeight: 80)
                            
                            TextEditor(text: $expansion)
                                .font(.system(.body, design: .monospaced))
                                .padding(6)
                                .scrollContentBackground(.hidden)
                            
                            if expansion.isEmpty {
                                Text("Replacement text...")
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                                    .padding(10)
                                    .allowsHitTesting(false)
                            }
                        }
                        
                        Text("Supports line breaks")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    // Trigger option section - inline implementation
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "keyboard.badge.ellipsis")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            
                            Text("Trigger Behavior")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        VStack(spacing: 8) {
                            HStack {
                                Toggle("", isOn: $requiresSpace)
                                    .toggleStyle(CompactToggleStyle())
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Require space after shortcut")
                                        .font(.system(size: 12, weight: .medium))
                                    
                                    let displayText = requiresSpace ? "Expands after '\(shortcut.isEmpty ? "shortcut" : shortcut) '" : "Expands immediately after '\(shortcut.isEmpty ? "shortcut" : shortcut)'"
                                    Text(displayText)
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                    }
                    
                    // Compact tips
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            
                            Text("Tips")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            CompactTip(text: "Use @ or # prefixes")
                            CompactTip(text: "Keep shortcuts short")
                            CompactTip(text: "Test in different apps")
                        }
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(0.05))
                            .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Preview section - inline implementation
                    if !shortcut.isEmpty && !expansion.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                    .font(.system(size: 12))
                                
                                Text("Preview")
                                    .font(.system(size: 13, weight: .semibold))
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Example:")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 4) {
                                    let triggerText = "'\(shortcut)\(requiresSpace ? " " : "")'"
                                    let previewText = String(expansion.prefix(20)) + (expansion.count > 20 ? "..." : "")
                                    
                                    Text("Typing")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                    
                                    Text(triggerText)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.accentColor)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color.accentColor.opacity(0.1))
                                        )
                                    
                                    Text("→")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                    
                                    Text(previewText)
                                        .font(.system(size: 9, design: .monospaced))
                                        .foregroundColor(.primary)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(
                                            RoundedRectangle(cornerRadius: 3)
                                                .fill(Color(NSColor.controlBackgroundColor))
                                        )
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.05))
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                }
                .padding(16)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            
            // Compact footer with buttons
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 8) {
                    Button("Cancel") {
                        isShowing = false
                    }
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button("Create") {
                        saveSnippet()
                    }
                    .disabled(shortcut.isEmpty || expansion.isEmpty)
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(shortcut.isEmpty || expansion.isEmpty ? Color.gray : Color.accentColor)
                    )
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .overlay(
            Rectangle()
                .fill(Color.clear)
                .frame(width: 1),
            alignment: .trailing
        )
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveSnippet() {
        if snippetManager.snippets.contains(where: { $0.shortcut == shortcut }) {
            errorMessage = "A snippet with this shortcut already exists."
            showingError = true
            return
        }
        
        let newSnippet = Snippet(
            shortcut: shortcut.trimmingCharacters(in: .whitespacesAndNewlines),
            expansion: expansion,
            requiresSpace: requiresSpace
        )
        
        snippetManager.addSnippet(newSnippet)
        
        shortcut = ""
        expansion = ""
        requiresSpace = true
        isShowing = false
    }
}

// MARK: - Collection Card Component [ID: 100008]
struct CollectionCard: View {
    let name: String
    let snippets: [Snippet]
    @State private var isExpanded = false
    
    var enabledCount: Int {
        snippets.filter(\.isEnabled).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(snippets.count) snippets • \(enabledCount) enabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
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

// MARK: - Settings Section Component [ID: 100009]
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
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
        }
    }
}

// MARK: - Settings Row Component [ID: 100010]
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

// MARK: - Empty State View [ID: 100011]
struct EmptyStateView: View {
    let isSearching: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: isSearching ? "magnifyingglass" : "doc.text.below.ecg")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 12) {
                Text(isSearching ? "No matching snippets" : "No snippets yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(isSearching ?
                     "Try adjusting your search terms or click 'Add' to create a new one" :
                     "Click 'Add' to create your first text expansion")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

// MARK: - Snippet Card View [ID: 100012]
struct SnippetCardView: View {
    let snippet: Snippet
    @Binding var editingSnippet: Snippet?
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var isHovered: Bool = false
    
    private var currentSnippet: Snippet {
        snippetManager.snippets.first { $0.id == snippet.id } ?? snippet
    }
    
    private var isBeingEdited: Bool {
        editingSnippet?.id == snippet.id
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Compact shortcut pill
            Text(currentSnippet.shortcut)
                .font(.system(.body, design: .monospaced, weight: .semibold))
                .foregroundColor(isBeingEdited ? .white : .accentColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isBeingEdited ? Color.accentColor : Color.accentColor.opacity(0.1))
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            
            // Arrow
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
                .font(.system(size: 12, weight: .medium))
                .scaleEffect(isHovered ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isHovered)
            
            // Compact expansion preview
            VStack(alignment: .leading, spacing: 1) {
                Text(currentSnippet.expansion.replacingOccurrences(of: "\n", with: " "))
                    .lineLimit(1)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                
                if currentSnippet.expansion.contains("\n") {
                    Text("Multi-line")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 4) {
                // Duplicate button
                Button(action: duplicateSnippet) {
                    Image(systemName: "doc.on.doc")
                        .foregroundColor(.blue)
                        .font(.system(size: 11))
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                // Delete button
                Button(action: deleteSnippet) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.system(size: 11))
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.1))
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                
                // Compact toggle
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
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isBeingEdited ? Color.accentColor.opacity(0.05) : Color(NSColor.controlBackgroundColor))
                .stroke(
                    isBeingEdited ? Color.accentColor.opacity(0.5) : Color(NSColor.separatorColor).opacity(isHovered ? 0.8 : 0.3),
                    lineWidth: isBeingEdited ? 2 : 1
                )
                .shadow(
                    color: Color.black.opacity(isHovered || isBeingEdited ? 0.08 : 0.03),
                    radius: isHovered || isBeingEdited ? 4 : 2,
                    x: 0,
                    y: isHovered || isBeingEdited ? 2 : 1
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            editingSnippet = snippet
        }
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .animation(.easeInOut(duration: 0.2), value: isBeingEdited)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func duplicateSnippet() {
        let duplicatedSnippet = Snippet(
            shortcut: "\(currentSnippet.shortcut)_copy",
            expansion: currentSnippet.expansion
        )
        snippetManager.addSnippet(duplicatedSnippet)
    }
    
    private func deleteSnippet() {
        withAnimation(.easeInOut(duration: 0.3)) {
            snippetManager.deleteSnippet(currentSnippet)
        }
    }
}

// MARK: - Compact Toggle Style [ID: 100013]
struct CompactToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 8)
                .fill(configuration.isOn ? Color.green : Color(NSColor.controlColor))
                .frame(width: 32, height: 18)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)
                        .offset(x: configuration.isOn ? 7 : -7)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

// MARK: - Compact Action Button [ID: 100014]
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
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(isPressed ? 0.2 : 0.1))
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Compact Tip Component [ID: 100015]
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

// MARK: - Modern Toggle Style [ID: 100016]
struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 12)
                .fill(configuration.isOn ? Color.green : Color(NSColor.controlColor))
                .frame(width: 44, height: 24)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

// MARK: - Action Button Component [ID: 100017]
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                Text(title)
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(color.opacity(isPressed ? 0.2 : 0.1))
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Tip Row Component [ID: 100018]
struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .font(.system(size: 12))
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}
