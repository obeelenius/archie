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
    
    var showingEditor: Bool {
        showingAddSheet || editingSnippet != nil || editingCollection != nil
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
                mainLayout(geometry: geometry)
                undoToastOverlay
                SaveNotificationContainer()
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .animation(isDragging ? .none : .easeInOut(duration: 0.3), value: showingEditor)
        .animation(isDragging ? .none : .easeInOut(duration: 0.2), value: editorWidth)
        .onChange(of: selectedView) { oldValue, newValue in
            if newValue != .collections && editingCollection != nil {
                editingCollection = nil
            }
            if newValue != .snippets && editingSnippet != nil {
                editingSnippet = nil
            }
        }
        .sheet(isPresented: $showingAddCollectionSheet) {
            AddCollectionSheet(isShowing: $showingAddCollectionSheet)
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
                    editingCollection: $editingCollection
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
                editingSnippet: $editingSnippet
            )
        case .collections:
            CollectionsContentView(editingCollection: $editingCollection)
        case .general:
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

// MARK: - Add Collection Sheet 100134
struct AddCollectionSheet: View {
    @Binding var isShowing: Bool
    @StateObject private var snippetManager = SnippetManager.shared
    
    @State private var collectionName = ""
    @State private var collectionSuffix = ""
    @State private var keepDelimiter = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            sheetHeader
            sheetForm
            Spacer()
            sheetButtons
        }
        .padding(24)
        .frame(width: 400, height: 350)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Add Collection Sheet Components 100135
extension AddCollectionSheet {
    private var sheetHeader: some View {
        VStack(spacing: 8) {
            Text("Add Collection")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a new snippet collection")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var sheetForm: some View {
        VStack(spacing: 16) {
            collectionNameField
            collectionSuffixField
            keepDelimiterToggle
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private var collectionNameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Collection Name")
                .font(.headline)
            
            TextField("e.g., Work Emails, Code Snippets", text: $collectionName)
                .textFieldStyle(.roundedBorder)
        }
    }
    
    private var collectionSuffixField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Suffix (Optional)")
                .font(.headline)
            
            TextField("e.g., ;, .., --", text: $collectionSuffix)
                .textFieldStyle(.roundedBorder)
            
            Text("Suffix characters that trigger expansion (like ; or ..)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var keepDelimiterToggle: some View {
        Toggle("Keep delimiter after expansion", isOn: $keepDelimiter)
            .toggleStyle(SwitchToggleStyle())
    }
    
    private var sheetButtons: some View {
        HStack(spacing: 12) {
            Button("Cancel") {
                isShowing = false
            }
            .buttonStyle(.bordered)
            
            Button("Create Collection") {
                createCollection()
            }
            .buttonStyle(.borderedProminent)
            .disabled(collectionName.isEmpty)
        }
    }
    
    private func createCollection() {
        let trimmedName = collectionName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if snippetManager.collections.contains(where: { $0.name == trimmedName }) {
            errorMessage = "A collection with this name already exists."
            showingError = true
            return
        }
        
        let newCollection = SnippetCollection(
            name: trimmedName,
            suffix: collectionSuffix.trimmingCharacters(in: .whitespacesAndNewlines),
            keepDelimiter: keepDelimiter
        )
        
        snippetManager.addCollection(newCollection)
        
        collectionName = ""
        collectionSuffix = ""
        keepDelimiter = false
        isShowing = false
    }
}

// MARK: - Preview 100136
#Preview {
    SettingsView()
}
