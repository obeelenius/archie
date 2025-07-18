//
//  AddCollectionSlideOut.swift
//  Archie
//
//  Created by Amy Elenius on 18/7/2025.
//


// AddCollectionSlideOut.swift

import SwiftUI

// MARK: - Add Collection Slide Out 100155
struct AddCollectionSlideOut: View {
    @Binding var isShowing: Bool
    @StateObject private var snippetManager = SnippetManager.shared
    
    @State private var name = ""
    @State private var suffix = ""
    @State private var keepDelimiter = false
    @State private var selectedIcon = "folder"
    @State private var selectedColor = "blue"
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let availableIcons = [
        CollectionIcon(name: "folder", category: "General"),
        CollectionIcon(name: "folder.badge.person.crop", category: "General"),
        CollectionIcon(name: "tray.full", category: "General"),
        CollectionIcon(name: "archivebox", category: "General"),
        CollectionIcon(name: "doc.text", category: "General"),
        
        CollectionIcon(name: "person.crop.circle", category: "Contact"),
        CollectionIcon(name: "at", category: "Contact"),
        CollectionIcon(name: "phone", category: "Contact"),
        CollectionIcon(name: "location", category: "Contact"),
        CollectionIcon(name: "envelope", category: "Contact"),
        
        CollectionIcon(name: "signature", category: "Business"),
        CollectionIcon(name: "briefcase", category: "Business"),
        CollectionIcon(name: "building.2", category: "Business"),
        CollectionIcon(name: "chart.bar", category: "Business"),
        CollectionIcon(name: "dollarsign.circle", category: "Business"),
        
        CollectionIcon(name: "clock", category: "Time"),
        CollectionIcon(name: "calendar", category: "Time"),
        CollectionIcon(name: "timer", category: "Time"),
        CollectionIcon(name: "hourglass", category: "Time"),
        CollectionIcon(name: "stopwatch", category: "Time"),
        
        CollectionIcon(name: "star", category: "Special"),
        CollectionIcon(name: "heart", category: "Special"),
        CollectionIcon(name: "bolt", category: "Special"),
        CollectionIcon(name: "flame", category: "Special"),
        CollectionIcon(name: "sparkles", category: "Special"),
        
        CollectionIcon(name: "keyboard", category: "Tech"),
        CollectionIcon(name: "laptopcomputer", category: "Tech"),
        CollectionIcon(name: "terminal", category: "Tech"),
        CollectionIcon(name: "gear", category: "Tech"),
        CollectionIcon(name: "cpu", category: "Tech")
    ]
    
    private let availableColors = [
        "blue", "green", "red", "orange", "purple", "pink",
        "yellow", "indigo", "teal", "mint", "cyan", "brown",
        "gray", "black", "white", "accentColor"
    ]
    
    private var groupedIcons: [String: [CollectionIcon]] {
        Dictionary(grouping: availableIcons, by: { $0.category })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            formContent
        }
        .background(Color(NSColor.windowBackgroundColor))
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Header Section 100156
extension AddCollectionSlideOut {
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Add Collection")
                        .font(.system(size: 16, weight: .bold))
                    
                    Text("Create snippet collection")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
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
                    
                    Button("Create Collection") {
                        createCollection()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(name.isEmpty ? Color.gray : Color.purple)
                    )
                    .buttonStyle(.plain)
                }
            }
            
            Divider()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Form Content 100157
extension AddCollectionSlideOut {
    private var formContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                collectionNameSection
                iconAndColorSection
                suffixAndBehaviorSection
                collectionTipsSection
            }
            .padding(16)
        }
        .background(Color.purple.opacity(0.02))
    }
}

// MARK: - Collection Name Section 100158
extension AddCollectionSlideOut {
    private var collectionNameSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "folder.badge.plus")
                    .foregroundColor(.purple)
                    .font(.system(size: 14))
                
                Text("Collection Name")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            TextField("Enter collection name", text: $name)
                .textFieldStyle(.plain)
                .font(.system(.body))
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.textBackgroundColor))
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
            
            Text("Choose a descriptive name like 'Work Emails' or 'Code Snippets'")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Icon and Color Section 100159
extension AddCollectionSlideOut {
    private var iconAndColorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "paintpalette")
                    .foregroundColor(.purple)
                    .font(.system(size: 14))
                
                Text("Appearance")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Icon selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Icon")
                    .font(.system(size: 13, weight: .semibold))
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 8), count: 8), spacing: 8) {
                    ForEach(Array(availableIcons.prefix(16)), id: \.name) { icon in
                        Button(action: {
                            selectedIcon = icon.name
                        }) {
                            Image(systemName: icon.name)
                                .foregroundColor(selectedIcon == icon.name ? .white : .primary)
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 32, height: 32)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedIcon == icon.name ? Color.purple : Color(NSColor.controlBackgroundColor))
                                        .stroke(selectedIcon == icon.name ? Color.purple : Color(NSColor.separatorColor), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Color selection
            VStack(alignment: .leading, spacing: 8) {
                Text("Color")
                    .font(.system(size: 13, weight: .semibold))
                
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 8), count: 8), spacing: 8) {
                    ForEach(availableColors, id: \.self) { colorName in
                        Button(action: {
                            selectedColor = colorName
                        }) {
                            Circle()
                                .fill(getColor(from: colorName))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == colorName ? Color.primary : Color(NSColor.separatorColor), lineWidth: selectedColor == colorName ? 3 : 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Suffix and Behavior Section 100160
extension AddCollectionSlideOut {
    private var suffixAndBehaviorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "textformat.subscript")
                    .foregroundColor(.purple)
                    .font(.system(size: 14))
                
                Text("Advanced Settings")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Collection Suffix (Optional)")
                        .font(.system(size: 13, weight: .semibold))
                    
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
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

// MARK: - Collection Tips Section 100161
extension AddCollectionSlideOut {
    private var collectionTipsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb")
                    .foregroundColor(.orange)
                    .font(.system(size: 14))
                
                Text("Tips")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                CompactTip(text: "Collections help organize related snippets")
                CompactTip(text: "Use descriptive names like 'Work' or 'Personal'")
                CompactTip(text: "Suffixes create collection-specific triggers")
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.05))
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Helper Methods 100162
extension AddCollectionSlideOut {
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
    
    private func createCollection() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if snippetManager.collections.contains(where: { $0.name == trimmedName }) {
            errorMessage = "A collection with this name already exists."
            showingError = true
            return
        }
        
        var newCollection = SnippetCollection(
            name: trimmedName,
            suffix: suffix.trimmingCharacters(in: .whitespacesAndNewlines),
            keepDelimiter: keepDelimiter,
            icon: selectedIcon
        )
        newCollection.color = selectedColor
        
        snippetManager.addCollection(newCollection)
        
        // Clear form
        name = ""
        suffix = ""
        keepDelimiter = false
        selectedIcon = "folder"
        selectedColor = "blue"
        isShowing = false
    }
}
