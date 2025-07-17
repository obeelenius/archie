import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            SnippetsTab()
                .tabItem {
                    Image(systemName: "text.cursor")
                    Text("Snippets")
                }
            
            CollectionsTab()
                .tabItem {
                    Image(systemName: "folder")
                    Text("Collections")
                }
            
            GeneralTab()
                .tabItem {
                    Image(systemName: "gear")
                    Text("General")
                }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}

// MARK: - Snippets Tab
struct SnippetsTab: View {
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var searchText = ""
    @State private var selectedSnippet: Snippet?
    @State private var isEditing = false
    @State private var showingEditor = false
    @State private var editorWidth: CGFloat = 400
    
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
        HStack(spacing: 0) {
            // Left side - Snippet list
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Text Snippets")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Manage your text expansions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Add Snippet") {
                            startAddingSnippet()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search snippets...", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Snippet list
                if filteredSnippets.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        
                        Text(searchText.isEmpty ? "No snippets yet" : "No matching snippets")
                            .font(.title3)
                            .fontWeight(.medium)
                        
                        Text(searchText.isEmpty ?
                             "Click 'Add Snippet' to create your first text expansion" :
                             "Try a different search term")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        if searchText.isEmpty {
                            Button("Add Your First Snippet") {
                                startAddingSnippet()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List(selection: $selectedSnippet) {
                        ForEach(filteredSnippets) { snippet in
                            SnippetRowView(
                                snippet: snippet,
                                isSelected: selectedSnippet?.id == snippet.id,
                                onEdit: { editSnippet(snippet) }
                            )
                            .tag(snippet)
                        }
                        .onDelete(perform: deleteSnippets)
                    }
                    .listStyle(.inset)
                }
            }
            .frame(minWidth: 300)
            
            // Right side - Editor panel (when visible)
            if showingEditor {
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(width: 1)
                    .overlay(
                        // Resize handle
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 10)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        let newWidth = editorWidth - value.translation.width
                                        editorWidth = max(300, min(600, newWidth))
                                    }
                            )
                            .onHover { inside in
                                if inside {
                                    NSCursor.resizeLeftRight.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                    )
                
                SnippetEditorPanel(
                    snippet: $selectedSnippet,
                    isEditing: $isEditing,
                    onSave: { savedSnippet in
                        saveSnippet(savedSnippet)
                    },
                    onCancel: {
                        closeEditor()
                    }
                )
                .frame(width: editorWidth)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingEditor)
    }
    
    private func startAddingSnippet() {
        let defaultCollection = snippetManager.collections.first ?? SnippetCollection(name: "Default")
        selectedSnippet = Snippet(shortcut: "", expansion: "", collectionId: defaultCollection.id)
        isEditing = false
        showingEditor = true
    }
    
    private func editSnippet(_ snippet: Snippet) {
        selectedSnippet = snippet
        isEditing = true
        showingEditor = true
    }
    
    private func saveSnippet(_ snippet: Snippet) {
        if isEditing {
            // Update existing snippet
            if let index = snippetManager.snippets.firstIndex(where: { $0.id == snippet.id }) {
                snippetManager.snippets[index] = snippet
            }
        } else {
            // Add new snippet
            snippetManager.addSnippet(snippet)
        }
        closeEditor()
    }
    
    private func closeEditor() {
        showingEditor = false
        selectedSnippet = nil
        isEditing = false
    }
    
    private func deleteSnippets(offsets: IndexSet) {
        for index in offsets {
            let snippet = filteredSnippets[index]
            snippetManager.deleteSnippet(snippet)
        }
        if let selectedId = selectedSnippet?.id,
           !snippetManager.snippets.contains(where: { $0.id == selectedId }) {
            closeEditor()
        }
    }
}

// MARK: - Collections Tab
struct CollectionsTab: View {
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var selectedCollection: SnippetCollection?
    @State private var showingEditor = false
    @State private var isEditing = false
    
    var body: some View {
        HStack(spacing: 0) {
            // Left side - Collections list
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Collections")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Organize your snippets into groups")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Add Collection") {
                            startAddingCollection()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Collections list
                List(selection: $selectedCollection) {
                    ForEach(snippetManager.collections) { collection in
                        CollectionRowView(
                            collection: collection,
                            snippetCount: snippetManager.snippets(for: collection).count,
                            onEdit: { editCollection(collection) },
                            onDelete: { deleteCollection(collection) }
                        )
                        .tag(collection)
                    }
                }
                .listStyle(.inset)
            }
            .frame(minWidth: 300)
            
            // Right side - Collection editor (when visible)
            if showingEditor {
                Divider()
                
                CollectionEditorPanel(
                    collection: $selectedCollection,
                    isEditing: $isEditing,
                    onSave: { savedCollection in
                        saveCollection(savedCollection)
                    },
                    onCancel: {
                        closeEditor()
                    }
                )
                .frame(width: 350)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingEditor)
    }
    
    private func startAddingCollection() {
        selectedCollection = SnippetCollection(name: "")
        isEditing = false
        showingEditor = true
    }
    
    private func editCollection(_ collection: SnippetCollection) {
        selectedCollection = collection
        isEditing = true
        showingEditor = true
    }
    
    private func saveCollection(_ collection: SnippetCollection) {
        if isEditing {
            // Update existing collection
            if let index = snippetManager.collections.firstIndex(where: { $0.id == collection.id }) {
                snippetManager.collections[index] = collection
            }
        } else {
            // Add new collection
            snippetManager.addCollection(collection)
        }
        closeEditor()
    }
    
    private func deleteCollection(_ collection: SnippetCollection) {
        snippetManager.deleteCollection(collection)
        if selectedCollection?.id == collection.id {
            closeEditor()
        }
    }
    
    private func closeEditor() {
        showingEditor = false
        selectedCollection = nil
        isEditing = false
    }
}

// MARK: - Collection Row View
struct CollectionRowView: View {
    let collection: SnippetCollection
    let snippetCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(collection.name)
                    .font(.headline)
                
                HStack {
                    if !collection.suffix.isEmpty {
                        Text("Suffix: \"\(collection.suffix)\"")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("\(snippetCount) snippet\(snippetCount == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                if collection.name != "Default" {
                    Button("Delete") {
                        onDelete()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .foregroundColor(.red)
                }
                
                Toggle("", isOn: .constant(collection.isEnabled))
                    .toggleStyle(SwitchToggleStyle())
                    .disabled(true)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Collection Editor Panel
struct CollectionEditorPanel: View {
    @Binding var collection: SnippetCollection?
    @Binding var isEditing: Bool
    let onSave: (SnippetCollection) -> Void
    let onCancel: () -> Void
    
    @State private var name = ""
    @State private var suffix = ""
    @State private var keepDelimiter = false
    @State private var color = "blue"
    @State private var isEnabled = true
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Collection" : "Add New Collection")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Name Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Collection Name")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter collection name", text: $name)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    // Suffix Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Suffix")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Optional suffix (e.g., ';', '..')", text: $suffix)
                            .textFieldStyle(.roundedBorder)
                        
                        Text("All shortcuts in this collection will have this suffix appended")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Options Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Options")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Toggle("Keep delimiter after expansion", isOn: $keepDelimiter)
                        Toggle("Enable collection", isOn: $isEnabled)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Bottom buttons
            HStack {
                Spacer()
                
                Button("Save") {
                    saveCollection()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onAppear {
            loadCollectionData()
        }
        .onChange(of: collection) {
            loadCollectionData()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadCollectionData() {
        guard let collection = collection else { return }
        name = collection.name
        suffix = collection.suffix
        keepDelimiter = collection.keepDelimiter
        color = collection.color
        isEnabled = collection.isEnabled
    }
    
    private func saveCollection() {
        guard var currentCollection = collection else { return }
        
        // Update collection
        currentCollection.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        currentCollection.suffix = suffix.trimmingCharacters(in: .whitespacesAndNewlines)
        currentCollection.keepDelimiter = keepDelimiter
        currentCollection.color = color
        currentCollection.isEnabled = isEnabled
        
        onSave(currentCollection)
    }
}

// MARK: - Snippet Editor Panel
struct SnippetEditorPanel: View {
    @Binding var snippet: Snippet?
    @Binding var isEditing: Bool
    let onSave: (Snippet) -> Void
    let onCancel: () -> Void
    
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var shortcut = ""
    @State private var expansion = ""
    @State private var selectedCollectionId: UUID?
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var showingVariables = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(isEditing ? "Edit Snippet" : "Add New Snippet")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Collection Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Collection")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Picker("Collection", selection: $selectedCollectionId) {
                            ForEach(snippetManager.collections) { collection in
                                Text(collection.name).tag(collection.id as UUID?)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    // Shortcut Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Shortcut")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        TextField("Enter shortcut (e.g., 'addr', '@@')", text: $shortcut)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                        
                        if let collectionId = selectedCollectionId,
                           let collection = snippetManager.collections.first(where: { $0.id == collectionId }),
                           !collection.suffix.isEmpty {
                            Text("Full shortcut: \(shortcut)\(collection.suffix)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Expansion Section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Expansion")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Button("Variables") {
                                showingVariables.toggle()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        TextEditor(text: $expansion)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 120)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                        
                        Text("This text will replace your shortcut. Use \\n for line breaks.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Variables Panel
                    if showingVariables {
                        VariablesPanel(onInsert: { variable in
                            expansion += variable
                        })
                    }
                    
                    // Preview Section
                    if !expansion.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preview")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text(previewExpansion())
                                .font(.system(.body, design: .monospaced))
                                .padding(10)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                                )
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Bottom buttons
            HStack {
                Spacer()
                
                Button("Save") {
                    saveSnippet()
                }
                .buttonStyle(.borderedProminent)
                .disabled(shortcut.isEmpty || expansion.isEmpty)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .onAppear {
            loadSnippetData()
        }
        .onChange(of: snippet) {
            loadSnippetData()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func loadSnippetData() {
        guard let snippet = snippet else { return }
        shortcut = snippet.shortcut
        expansion = snippet.expansion
        selectedCollectionId = snippet.collectionId ?? snippetManager.collections.first?.id
    }
    
    private func previewExpansion() -> String {
        let tempSnippet = Snippet(shortcut: shortcut, expansion: expansion)
        return tempSnippet.processedExpansion()
    }
    
    private func saveSnippet() {
        guard var currentSnippet = snippet else { return }
        
        // Validate shortcut uniqueness (except for current snippet when editing)
        let existingSnippet = snippetManager.snippets.first { $0.shortcut == shortcut }
        if let existingSnippet = existingSnippet, existingSnippet.id != currentSnippet.id {
            errorMessage = "A snippet with this shortcut already exists."
            showingError = true
            return
        }
        
        // Update snippet
        currentSnippet.shortcut = shortcut.trimmingCharacters(in: .whitespacesAndNewlines)
        currentSnippet.expansion = expansion.replacingOccurrences(of: "\\n", with: "\n")
        currentSnippet.collectionId = selectedCollectionId
        
        onSave(currentSnippet)
    }
}

// MARK: - Variables Panel
struct VariablesPanel: View {
    let onInsert: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Insert Variables")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(SnippetVariable.VariableType.allCases, id: \.self) { type in
                    Button(type.displayName) {
                        onInsert(type.placeholder)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
}

// MARK: - Updated Snippet Row View
struct SnippetRowView: View {
    let snippet: Snippet
    let isSelected: Bool
    let onEdit: () -> Void
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Shortcut
                Text(snippet.shortcut)
                    .font(.system(.body, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundColor(.accentColor)
                    .cornerRadius(6)
                
                // Arrow
                Image(systemName: "arrow.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                // Expansion preview
                Text(snippet.expansion.replacingOccurrences(of: "\n", with: " "))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Edit button
                Button("Edit") {
                    onEdit()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                // Toggle button
                Toggle("", isOn: .constant(snippet.isEnabled))
                    .toggleStyle(SwitchToggleStyle())
                    .disabled(true) // We'll handle this in the editor
            }
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }
}

// MARK: - General Settings Tab
struct GeneralTab: View {
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var launchAtLogin = false
    @State private var showNotifications = true
    @State private var expansionDelay = 0.1
    @State private var enableSounds = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("General Settings")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Configure Archie's behavior")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Settings content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // App Behavior Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("App Behavior")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Launch Archie at login", isOn: $launchAtLogin)
                            
                            Toggle("Show expansion notifications", isOn: $showNotifications)
                            
                            Toggle("Play sound effects", isOn: $enableSounds)
                        }
                    }
                    
                    Divider()
                    
                    // Performance Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Performance")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Expansion Delay")
                                    .font(.subheadline)
                                
                                HStack {
                                    Slider(value: $expansionDelay, in: 0.0...1.0, step: 0.1)
                                    Text("\(expansionDelay, specifier: "%.1f")s")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .frame(width: 40)
                                }
                                
                                Text("Delay before text expansion occurs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Statistics Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Statistics")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Total Snippets:")
                                Spacer()
                                Text("\(snippetManager.snippets.count)")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Active Snippets:")
                                Spacer()
                                Text("\(snippetManager.snippets.filter { $0.isEnabled }.count)")
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(8)
                    }
                    
                    Divider()
                    
                    // Data Management Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Data Management")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Button("Export Snippets...") {
                                // TODO: Implement export
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Import Snippets...") {
                                // TODO: Implement import
                            }
                            .buttonStyle(.bordered)
                            
                            Button("Reset to Defaults") {
                                // TODO: Implement reset
                            }
                            .buttonStyle(.bordered)
                            .foregroundColor(.red)
                        }
                    }
                    
                    Divider()
                    
                    // About Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Version:")
                                Spacer()
                                Text("1.0.0")
                                    .fontWeight(.medium)
                            }
                            
                            HStack {
                                Text("Build:")
                                Spacer()
                                Text("1")
                                    .fontWeight(.medium)
                            }
                        }
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    SettingsView()
}
