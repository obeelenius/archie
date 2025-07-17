//  EditCollectionSlideOut.swift

import SwiftUI

// MARK: - Edit Collection Slide Out
struct EditCollectionSlideOut: View {
    let collection: SnippetCollection
    @Binding var isShowing: Bool
    @StateObject private var snippetManager = SnippetManager.shared
    
    @State private var name = ""
    @State private var suffix = ""
    @State private var keepDelimiter = false
    @State private var isEnabled = true
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Edit Collection")
                            .font(.system(size: 16, weight: .bold))
                        
                        Text("Modify collection settings")
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
            
            // Form content
            ScrollView {
                VStack(spacing: 16) {
                    // Collection Status
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "folder")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            
                            Text("Collection Status")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        HStack {
                            Toggle("", isOn: $isEnabled)
                                .toggleStyle(CompactToggleStyle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Enable collection")
                                    .font(.system(size: 12, weight: .medium))
                                
                                Text(isEnabled ? "Collection is active" : "Collection is disabled")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                    }
                    
                    // Collection name section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "textformat")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            
                            Text("Collection Name")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        TextField("Enter collection name", text: $name)
                            .textFieldStyle(.plain)
                            .font(.system(.body))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.textBackgroundColor))
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                        
                        Text("Name for organizing related snippets")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    // Suffix section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "textformat.subscript")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            
                            Text("Collection Suffix")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        TextField("e.g., ';' or '..' or ':'", text: $suffix)
                            .textFieldStyle(.plain)
                            .font(.system(.body, design: .monospaced))
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(NSColor.textBackgroundColor))
                                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                            )
                        
                        Text("Special character(s) to trigger snippets in this collection")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    
                    // Delimiter behavior section
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "keyboard.badge.ellipsis")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            
                            Text("Delimiter Behavior")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        HStack {
                            Toggle("", isOn: $keepDelimiter)
                                .toggleStyle(CompactToggleStyle())
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Keep delimiter after expansion")
                                    .font(.system(size: 12, weight: .medium))
                                
                                let exampleSuffix = suffix.isEmpty ? ";" : suffix
                                let exampleText = keepDelimiter ? 
                                    "addr\(exampleSuffix) → your address\(exampleSuffix)" : 
                                    "addr\(exampleSuffix) → your address"
                                Text(exampleText)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )
                    }
                    
                    // Collection info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                                .font(.system(size: 12))
                            
                            Text("Collection Info")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        let snippetsInCollection = snippetManager.snippets.filter { $0.collectionId == collection.id }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Snippets in collection:")
                                    .font(.system(size: 11, weight: .medium))
                                Spacer()
                                Text("\(snippetsInCollection.count)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.accentColor)
                            }
                            
                            HStack {
                                Text("Enabled snippets:")
                                    .font(.system(size: 11, weight: .medium))
                                Spacer()
                                Text("\(snippetsInCollection.filter(\.isEnabled).count)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue.opacity(0.05))
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                    }
                }
                .padding(16)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
            
            // Footer with buttons
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
                    .disabled(name.isEmpty)
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(name.isEmpty ? Color.gray : Color.accentColor)
                    )
                    .buttonStyle(.plain)
                }
                .padding(12)
                .background(Color(NSColor.windowBackgroundColor))
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            name = collection.name
            suffix = collection.suffix
            keepDelimiter = collection.keepDelimiter
            isEnabled = collection.isEnabled
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func saveChanges() {
        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if snippetManager.collections.contains(where: { $0.name == finalName && $0.id != collection.id }) {
            errorMessage = "A collection with this name already exists."
            showingError = true
            return
        }
        
        if let index = snippetManager.collections.firstIndex(where: { $0.id == collection.id }) {
            snippetManager.collections[index].name = finalName
            snippetManager.collections[index].suffix = suffix
            snippetManager.collections[index].keepDelimiter = keepDelimiter
            snippetManager.collections[index].isEnabled = isEnabled
        }
        
        isShowing = false
    }
}
