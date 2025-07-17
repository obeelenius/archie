//
//  EditSnippetSlideOut.swift
//  Archie
//
//  Created by Amy Elenius on 17/7/2025.
//


import SwiftUI

// MARK: - Edit Snippet Slide Out
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
            
            // Form content
            ScrollView {
                VStack(spacing: 16) {
                    // Original shortcut display
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
                    
                    // Trigger option section
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