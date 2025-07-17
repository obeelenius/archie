//  SettingsView.swift

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

// MARK: - Main Settings View
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
                    SettingsHeaderView(
                        selectedView: $selectedView,
                        showingAddSheet: $showingAddSheet
                    )
                    
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

#Preview {
    SettingsView()
}
