import SwiftUI

struct SettingsView: View {
    @StateObject private var snippetManager = SnippetManager.shared
    @State private var showingAddSheet = false
    @State private var searchText = ""
    
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
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "text.cursor")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Archie")
                                .font(.title2)
                                .fontWeight(.semibold)
                            Text("Text Expansion Made Simple")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Add Snippet") {
                            showingAddSheet = true
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
                                showingAddSheet = true
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    List {
                        ForEach(filteredSnippets) { snippet in
                            SnippetRowView(snippet: snippet)
                        }
                        .onDelete(perform: deleteSnippets)
                    }
                    .listStyle(.inset)
                }
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .sheet(isPresented: $showingAddSheet) {
            AddSnippetView()
        }
    }
    
    private func deleteSnippets(offsets: IndexSet) {
        for index in offsets {
            let snippet = filteredSnippets[index]
            snippetManager.deleteSnippet(snippet)
        }
    }
}

struct SnippetRowView: View {
    @State private var snippet: Snippet
    @State private var isExpanded = false
    @StateObject private var snippetManager = SnippetManager.shared
    
    init(snippet: Snippet) {
        _snippet = State(initialValue: snippet)
    }
    
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
                
                // Toggle button
                Toggle("", isOn: Binding(
                    get: { snippet.isEnabled },
                    set: { newValue in
                        snippet.isEnabled = newValue
                        updateSnippet()
                    }
                ))
                .toggleStyle(SwitchToggleStyle())
                
                // Expand button
                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Expanded view
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Full Expansion:")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                        
                        Text(snippet.expansion)
                            .font(.system(.body, design: .monospaced))
                            .padding(10)
                            .background(Color(NSColor.textBackgroundColor))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                    }
                    
                    HStack {
                        Button("Edit") {
                            // TODO: Implement edit functionality
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Copy Expansion") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(snippet.expansion, forType: .string)
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Button("Delete") {
                            snippetManager.deleteSnippet(snippet)
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func updateSnippet() {
        if let index = snippetManager.snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippetManager.snippets[index] = snippet
        }
    }
}

struct AddSnippetView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var snippetManager = SnippetManager.shared
    
    @State private var shortcut = ""
    @State private var expansion = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Shortcut")
                            .font(.headline)
                        
                        TextField("Enter shortcut (e.g., 'addr', '@@')", text: $shortcut)
                            .textFieldStyle(.roundedBorder)
                            .font(.system(.body, design: .monospaced))
                        
                        Text("Type this sequence followed by a space to trigger expansion")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Shortcut Configuration")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Expansion")
                            .font(.headline)
                        
                        TextEditor(text: $expansion)
                            .font(.system(.body, design: .monospaced))
                            .frame(minHeight: 100)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                        
                        Text("This text will replace your shortcut. Use \\n for line breaks.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Expansion Text")
                }
                
                Section {
                    HStack {
                        Image(systemName: "lightbulb")
                            .foregroundColor(.orange)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Pro Tips")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("• Use memorable abbreviations")
                            Text("• Start with special characters (@, #) to avoid conflicts")
                            Text("• Keep shortcuts short but unique")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Add New Snippet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSnippet()
                    }
                    .disabled(shortcut.isEmpty || expansion.isEmpty)
                }
            }
        }
        .frame(width: 500, height: 450)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveSnippet() {
        // Validate shortcut uniqueness
        if snippetManager.snippets.contains(where: { $0.shortcut == shortcut }) {
            errorMessage = "A snippet with this shortcut already exists."
            showingError = true
            return
        }
        
        // Create and save snippet
        let newSnippet = Snippet(
            shortcut: shortcut.trimmingCharacters(in: .whitespacesAndNewlines),
            expansion: expansion.replacingOccurrences(of: "\\n", with: "\n")
        )
        
        snippetManager.addSnippet(newSnippet)
        dismiss()
    }
}

#Preview {
    SettingsView()
}
