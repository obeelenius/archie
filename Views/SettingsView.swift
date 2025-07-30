//  SettingsView.swift

import SwiftUI

// MARK: - Cursor Extension 100130
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

// MARK: - Updated Settings View with Collection Edit Panel 100131
struct SettingsView: View {
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var showingAddSheet = false
    @State private var showingAddCollectionSheet = false
    @State private var searchText = ""
    @State private var selectedView: MainView = .snippets
    @State private var editorWidth: CGFloat = 0.4
    @State private var isDragging = false
    @State private var editingSnippet: Snippet? = nil
    @State private var editingCollection: SnippetCollection? = nil
    
    // Add initializer to accept initial selected view
    init(initialSelectedView: MainView = .snippets) {
        self._selectedView = State(initialValue: initialSelectedView)
    }
    
    var showingEditor: Bool {
        showingAddSheet || showingAddCollectionSheet || editingSnippet != nil || editingCollection != nil
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
            ZStack {
                VStack(spacing: 0) {
                    PermissionBanner()
                    mainLayout(geometry: geometry)
                }
                undoToastOverlay
                SaveNotificationContainer()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .animation(isDragging ? .none : .easeInOut(duration: 0.3), value: showingEditor)
        .animation(isDragging ? .none : .easeInOut(duration: 0.2), value: editorWidth)
        .onChange(of: selectedView) { oldValue, newValue in
            // Close all editors when navigating between main views
            editingCollection = nil
            editingSnippet = nil
            showingAddSheet = false
            showingAddCollectionSheet = false
            
            // Notify AppDelegate of tab change for state tracking
            NotificationCenter.default.post(
                name: NSNotification.Name("TabChanged"),
                object: newValue
            )
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToTab"))) { notification in
            if let newTab = notification.object as? MainView {
                selectedView = newTab
            }
        }
    }
}

// MARK: - Main View Enum 100132
extension SettingsView {
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
}

// MARK: - Layout Components 100133
extension SettingsView {
    private func mainLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 0) {
            mainContentArea(geometry: geometry)
            editorPanel(geometry: geometry)
        }
    }
    
    private func mainContentArea(geometry: GeometryProxy) -> some View {
            VStack(spacing: 0) {
                SettingsHeaderView(
                    selectedView: $selectedView,
                    showingAddSheet: $showingAddSheet,
                    showingAddCollectionSheet: $showingAddCollectionSheet,
                    editingSnippet: $editingSnippet,
                    editingCollection: $editingCollection,
                    onAddSnippetTapped: {
                        // Close any existing editor and open add snippet
                        editingSnippet = nil
                        editingCollection = nil
                        showingAddSheet = true
                    }
                )
                
                contentBasedOnSelectedView
            }
            .frame(width: showingEditor ? geometry.size.width * (1 - editorWidth) : geometry.size.width)
        }
    
    @ViewBuilder
    private var contentBasedOnSelectedView: some View {
        switch selectedView {
        case .snippets:
            SnippetsContentView(
                filteredSnippets: filteredSnippets,
                searchText: $searchText,
                editingSnippet: $editingSnippet,
                onCollectionHeaderTapped: {
                    // Close editor when collection header is tapped
                    editingSnippet = nil
                }
            )
        case .collections:
            CollectionsContentView(editingCollection: $editingCollection)
        case .general:  // Changed from .settings to .general
            GeneralSettingsContentView()
        }
    }
    
    @ViewBuilder
    private func editorPanel(geometry: GeometryProxy) -> some View {
        if showingEditor {
            HStack(spacing: 0) {
                ResizeHandle(
                    editorWidth: $editorWidth,
                    windowWidth: geometry.size.width,
                    isDragging: $isDragging
                )
                
                currentEditorContent
            }
            .frame(width: geometry.size.width * editorWidth)
            .transition(.move(edge: .trailing))
        }
    }
    
    @ViewBuilder
        private var currentEditorContent: some View {
            if let editingCollection = editingCollection {
                EditCollectionSlideOut(
                    collection: editingCollection,
                    isShowing: Binding(
                        get: { self.editingCollection != nil },
                        set: { if !$0 { self.editingCollection = nil } }
                    )
                )
            } else if let editingSnippet = editingSnippet {
                EditSnippetSlideOut(
                    snippet: editingSnippet,
                    isShowing: Binding(
                        get: { self.editingSnippet != nil },
                        set: { if !$0 { self.editingSnippet = nil } }
                    )
                )
            } else if showingAddCollectionSheet {
                AddCollectionSlideOut(isShowing: $showingAddCollectionSheet)
            } else {
                AddSnippetSlideOut(isShowing: $showingAddSheet)
            }
        }
    
    private var undoToastOverlay: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                UndoToastContainer()
            }
        }
    }
}

// MARK: - Preview 100136
#Preview {
    SettingsView()
}
