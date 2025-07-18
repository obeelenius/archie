//  EditCollectionSlideOut.swift

import SwiftUI

// MARK: - Edit Collection Slide Out 100013
struct EditCollectionSlideOut: View {
    let collection: SnippetCollection
    @Binding var isShowing: Bool
    @StateObject private var snippetManager = SnippetManager.shared
    
    @State private var name = ""
    @State private var suffix = ""
    @State private var keepDelimiter = false
    @State private var isEnabled = true
    @State private var selectedIcon = ""
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
    
    private var groupedIcons: [String: [CollectionIcon]] {
        Dictionary(grouping: availableIcons, by: { $0.category })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header section
            headerSection
            
            // Form content
            formContent
            
            // Footer with buttons
            footerSection
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear(perform: loadCollectionData)
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Header Section 100014
extension EditCollectionSlideOut {
    private var headerSection: some View {
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
    }
}

// MARK: - Form Content 100015
extension EditCollectionSlideOut {
    private var formContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                collectionStatusSection
                collectionNameSection
                iconSelectionSection
                suffixSection
                delimiterBehaviorSection
                collectionInfoSection
            }
            .padding(16)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
}

// MARK: - Collection Status Section 100016
extension EditCollectionSlideOut {
    private var collectionStatusSection: some View {
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
    }
}

// MARK: - Collection Name Section 100017
extension EditCollectionSlideOut {
    private var collectionNameSection: some View {
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
    }
}

// MARK: - Icon Selection Section 100018
extension EditCollectionSlideOut {
    private var iconSelectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "app.badge")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 12))
                
                Text("Collection Icon")
                    .font(.system(size: 13, weight: .semibold))
            }
            
            // Current selection preview
            currentIconPreview
            
            // Icon grid by category
            iconCategoriesGrid
            
            Text("Choose an icon to represent this collection")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
    
    private var currentIconPreview: some View {
        HStack(spacing: 8) {
            Image(systemName: selectedIcon.isEmpty ? getDefaultIcon(for: name) : selectedIcon)
                .foregroundColor(.accentColor)
                .font(.system(size: 16, weight: .medium))
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor.opacity(0.1))
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            
            Text("Selected Icon")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
    }
    
    private var iconCategoriesGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(groupedIcons.keys.sorted()), id: \.self) { category in
                IconCategorySection(
                    category: category,
                    icons: groupedIcons[category] ?? [],
                    selectedIcon: $selectedIcon
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor))
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
        )
    }
}

// MARK: - Suffix Section 100019
extension EditCollectionSlideOut {
    private var suffixSection: some View {
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
    }
}

// MARK: - Delimiter Behavior Section 100020
extension EditCollectionSlideOut {
    private var delimiterBehaviorSection: some View {
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
    }
}

// MARK: - Collection Info Section 100021
extension EditCollectionSlideOut {
    private var collectionInfoSection: some View {
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
}

// MARK: - Footer Section 100022
extension EditCollectionSlideOut {
    private var footerSection: some View {
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
}

// MARK: - Helper Methods 100023
extension EditCollectionSlideOut {
    private func loadCollectionData() {
        name = collection.name
        suffix = collection.suffix
        keepDelimiter = collection.keepDelimiter
        isEnabled = collection.isEnabled
        selectedIcon = collection.icon
    }
    
    private func getDefaultIcon(for name: String) -> String {
        switch name {
        case "General": return "folder"
        case "Contact": return "person.crop.circle"
        case "Signature": return "signature"
        case "Date": return "clock"
        default: return "folder"
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
            snippetManager.collections[index].icon = selectedIcon
        }
        
        isShowing = false
    }
}

// MARK: - Collection Icon Model 100024
struct CollectionIcon {
    let name: String
    let category: String
}

// MARK: - Icon Category Section 100025
struct IconCategorySection: View {
    let category: String
    let icons: [CollectionIcon]
    @Binding var selectedIcon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 8), count: 6), spacing: 8) {
                ForEach(icons, id: \.name) { icon in
                    Button(action: {
                        selectedIcon = icon.name
                    }) {
                        Image(systemName: icon.name)
                            .foregroundColor(selectedIcon == icon.name ? .white : .primary)
                            .font(.system(size: 14, weight: .medium))
                            .frame(width: 32, height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(selectedIcon == icon.name ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                    .stroke(selectedIcon == icon.name ? Color.accentColor : Color(NSColor.separatorColor), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(icon.name)
                }
            }
        }
    }
}
