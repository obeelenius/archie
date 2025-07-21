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
    @State private var selectedColor = "blue"
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var loadedCollectionId: UUID? = nil
    
    // Get the current collection data from the manager
    private var currentCollection: SnippetCollection {
        snippetManager.collections.first { $0.id == collection.id } ?? collection
    }
    
    // Check if there are unsaved changes
    private var hasUnsavedChanges: Bool {
        return name != currentCollection.name ||
               suffix != currentCollection.suffix ||
               keepDelimiter != currentCollection.keepDelimiter ||
               isEnabled != currentCollection.isEnabled ||
               selectedIcon != currentCollection.icon ||
               selectedColor != currentCollection.color
    }
    
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
        .onAppear {
            loadCollectionDataIfNeeded()
        }
        .onChange(of: collection.id) { oldValue, newValue in
            loadCollectionDataIfNeeded()
        }
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
                
                HStack(spacing: 8) {
                    Button("Delete") {
                        deleteCollection()
                    }
                    .foregroundColor(.red)
                    .font(.system(size: 12, weight: .medium))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .buttonStyle(.plain)
                    
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
                    
                    Button("Save Changes") {
                        saveChanges()
                    }
                    .disabled(!hasUnsavedChanges)
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill(!hasUnsavedChanges ? Color.gray : Color.accentColor)
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

// MARK: - Form Content 100015
extension EditCollectionSlideOut {
    private var formContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                collectionNameSection
                collectionIconSection
                collectionColorSection
                collectionInfoSection
            }
            .padding(16)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
}

// MARK: - Collection Name Section 100017
extension EditCollectionSlideOut {
    private var collectionNameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Aa")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.accentColor)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.accentColor.opacity(0.1)))
                
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

// MARK: - Collection Suffix Section 100270
extension EditCollectionSlideOut {
    private var collectionSuffixSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("A₁")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.accentColor)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.accentColor.opacity(0.1)))
                
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
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentColor)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.accentColor.opacity(0.1)))
                
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

// MARK: - Collection Icon Section 100271
extension EditCollectionSlideOut {
    private var collectionIconSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "app.badge")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentColor)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.accentColor.opacity(0.1)))
                
                Text("Collection Icon")
                    .font(.system(size: 13, weight: .semibold))
            }
            
            // Current selection preview
            HStack(spacing: 8) {
                Image(systemName: selectedIcon.isEmpty ? getDefaultIcon(for: name) : selectedIcon)
                    .foregroundColor(getColor(from: selectedColor))
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(getColor(from: selectedColor).opacity(0.1))
                            .stroke(getColor(from: selectedColor).opacity(0.3), lineWidth: 1)
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
            
            // Icon grid by category
            iconCategoriesGrid
            
            Text("Choose an icon to represent this collection")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
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

// MARK: - Collection Color Section 100272
extension EditCollectionSlideOut {
    private var collectionColorSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "paintpalette")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.accentColor)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.accentColor.opacity(0.1)))
                
                Text("Collection Color")
                    .font(.system(size: 13, weight: .semibold))
            }
            
            // Current color preview
            HStack(spacing: 8) {
                Circle()
                    .fill(getColor(from: selectedColor))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                
                Text("Selected Color")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
            )
            
            // Color grid - two rows
            VStack(spacing: 8) {
                // First row
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 8), count: 8), spacing: 8) {
                    ForEach(Array(availableColors.prefix(8)), id: \.self) { colorName in
                        colorButton(colorName: colorName)
                    }
                }
                
                // Second row
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 8), count: 8), spacing: 8) {
                    ForEach(Array(availableColors.dropFirst(8)), id: \.self) { colorName in
                        colorButton(colorName: colorName)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.textBackgroundColor))
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            
            Text("Choose a color to represent this collection")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
    
    private func colorButton(colorName: String) -> some View {
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
                .overlay(
                    selectedColor == colorName ?
                    Image(systemName: "checkmark")
                        .foregroundColor(.white)
                        .font(.system(size: 12, weight: .bold))
                    : nil
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Collection Info Section 100021
extension EditCollectionSlideOut {
    private var collectionInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                    .frame(width: 16, height: 16)
                    .background(Circle().fill(Color.blue.opacity(0.1)))
                
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

// MARK: - Helper Methods 100023
extension EditCollectionSlideOut {
    private func loadCollectionDataIfNeeded() {
        // Only load if we haven't loaded this collection yet or if the collection changed
        if loadedCollectionId != collection.id {
            loadCollectionData()
            loadedCollectionId = collection.id
        }
    }
    
    private func loadCollectionData() {
        print("DEBUG EDIT COLLECTION: Loading data for collection '\(currentCollection.name)' (ID: \(currentCollection.id.uuidString))")
        
        name = currentCollection.name
        isEnabled = currentCollection.isEnabled
        selectedIcon = currentCollection.icon
        selectedColor = currentCollection.color
        
        print("DEBUG EDIT COLLECTION: Loaded - name: '\(name)', icon: '\(selectedIcon)', color: '\(selectedColor)'")
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
    
    private func deleteCollection() {
        // Prevent deletion of "General" collection
        if currentCollection.name == "General" {
            errorMessage = "Cannot delete the General collection."
            showingError = true
            return
        }
        
        // Show confirmation alert
        let alert = NSAlert()
        alert.messageText = "Delete Collection"
        alert.informativeText = "Are you sure you want to delete '\(currentCollection.name)'? Any snippets in this collection will be moved to the General collection."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            // User confirmed deletion
            snippetManager.deleteCollection(currentCollection)
            isShowing = false
        }
    }
    
    private func saveChanges() {
        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("DEBUG EDIT COLLECTION: Saving changes for collection ID: \(collection.id.uuidString)")
        print("DEBUG EDIT COLLECTION: Final name: '\(finalName)'")
        
        // Check for name conflicts with OTHER collections (exclude current collection)
        if snippetManager.collections.contains(where: { $0.name == finalName && $0.id != collection.id }) {
            errorMessage = "A collection with this name already exists."
            showingError = true
            return
        }
        
        if let index = snippetManager.collections.firstIndex(where: { $0.id == collection.id }) {
            print("DEBUG EDIT COLLECTION: Found collection at index \(index)")
            print("DEBUG EDIT COLLECTION: Before save - name: '\(snippetManager.collections[index].name)'")
            
            snippetManager.collections[index].name = finalName
            snippetManager.collections[index].isEnabled = isEnabled
            snippetManager.collections[index].icon = selectedIcon
            snippetManager.collections[index].color = selectedColor
            // Keep existing suffix and keepDelimiter values
            
            print("DEBUG EDIT COLLECTION: After save - name: '\(snippetManager.collections[index].name)'")
            
            // Trigger save notification
            SaveNotificationManager.shared.show("Collection updated")
        } else {
            print("DEBUG EDIT COLLECTION: ERROR - Could not find collection with ID: \(collection.id.uuidString)")
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
