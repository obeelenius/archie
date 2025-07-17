//
//  AddSnippetSlideOut.swift
//  Archie
//
//  Created by Amy Elenius on 17/7/2025.
//


import SwiftUI

// MARK: - Add Snippet Slide Out
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
            
            // Form content
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
                    
                    // Tips
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