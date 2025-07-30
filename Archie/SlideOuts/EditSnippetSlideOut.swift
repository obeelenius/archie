// EditSnippetSlideOut.swift

import SwiftUI

// MARK: - Edit Snippet Slide Out with Enhanced Variables 100026

struct EditSnippetSlideOut: View {
    let snippet: Snippet
    @Binding var isShowing: Bool
    @StateObject private var snippetManager = SnippetManager.shared
    
    @State private var shortcut = ""
    @State private var expansion = ""
    @State private var expansionAttributed = NSAttributedString()
    @State private var triggerMode: TriggerMode = .spaceRequiredConsume
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var initializedSnippetId: UUID? = nil
    @State private var editorHeight: CGFloat = 120
    @State private var editorCoordinator: WYSIWYGRichTextEditor.Coordinator?
    
    // Get the current snippet data from the manager
    private var currentSnippet: Snippet {
        snippetManager.snippets.first { $0.id == snippet.id } ?? snippet
    }
    
    // Check if there are unsaved changes
    private var hasUnsavedChanges: Bool {
        let currentRequiresSpace = currentSnippet.requiresSpace
        let currentKeepDelimiter = currentSnippet.keepDelimiter
        let currentTriggerMode: TriggerMode = {
            if !currentRequiresSpace {
                return .instant
            } else if currentKeepDelimiter {
                return .spaceRequiredKeep
            } else {
                return .spaceRequiredConsume
            }
        }()
        
        return shortcut != currentSnippet.shortcut ||
               expansion != currentSnippet.expansion ||
               triggerMode != currentTriggerMode
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            formContent
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            loadSnippetDataIfNeeded()
        }
        .onChange(of: snippet.id) { oldValue, newValue in
            loadSnippetData()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Trigger Mode Enum 100027
extension EditSnippetSlideOut {
    enum TriggerMode: String, CaseIterable {
        case spaceRequiredConsume = "Space Required (Remove)"
        case spaceRequiredKeep = "Space Required (Keep)"
        case instant = "Instant"
        
        var description: String {
            switch self {
            case .spaceRequiredConsume:
                return "Type shortcut + space, removes the space after expansion"
            case .spaceRequiredKeep:
                return "Type shortcut + space, keeps the space after expansion"
            case .instant:
                return "Expands immediately after typing shortcut"
            }
        }
        
        var example: String {
            switch self {
            case .spaceRequiredConsume:
                return "addr + space → 'your address' (no trailing space)"
            case .spaceRequiredKeep:
                return "addr + space → 'your address ' (with trailing space)"
            case .instant:
                return "@@ → expands immediately"
            }
        }
        
        var icon: String {
            switch self {
            case .spaceRequiredConsume:
                return "space"
            case .spaceRequiredKeep:
                return "space"
            case .instant:
                return "bolt"
            }
        }
    }
}

// MARK: - Header Section 100028
extension EditSnippetSlideOut {
    private var headerSection: some View {
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

// MARK: - Form Content 100029
extension EditSnippetSlideOut {
    private var formContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                triggerBehaviorSection
                snippetDetailsSection // Combined shortcut and expansion
            }
            .padding(16)
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
    }
}

// MARK: - Trigger Behavior Section 100030
extension EditSnippetSlideOut {
    private var triggerBehaviorSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "keyboard.badge.ellipsis")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14))
                
                Text("Trigger Behavior")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            VStack(spacing: 8) {
                ForEach(TriggerMode.allCases, id: \.self) { mode in
                    EditTriggerModeRow(
                        mode: mode,
                        isSelected: triggerMode == mode,
                        onSelect: { triggerMode = mode }
                    )
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

// MARK: - Snippet Details Section 100032
extension EditSnippetSlideOut {
    private var snippetDetailsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Section header
            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14))
                
                Text("Snippet Details")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            // Shortcut field
            VStack(alignment: .leading, spacing: 8) {
                Text("Shortcut")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                TextField("Current: \(snippet.shortcut)", text: $shortcut)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(NSColor.textBackgroundColor))
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
            }
            
            // Expansion field with rich text editor and toolbar
            VStack(alignment: .leading, spacing: 8) {
                Text("Expansion")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                // Resizable container with same styling as add snippet
                ZStack(alignment: .bottomTrailing) {
                    VStack(spacing: 0) {
                        // Formatting toolbar
                        HStack(spacing: 4) {
                            // Bold
                            ToolbarButton(icon: "bold", format: "**text**") {
                                if let coordinator = editorCoordinator {
                                    coordinator.applyFormatting(.bold)
                                } else {
                                    print("DEBUG: No coordinator available for bold")
                                }
                            }
                            
                            // Italic
                            ToolbarButton(icon: "italic", format: "*text*") {
                                if let coordinator = editorCoordinator {
                                    coordinator.applyFormatting(.italic)
                                } else {
                                    print("DEBUG: No coordinator available for italic")
                                }
                            }
                            
                            // Underline
                            ToolbarButton(icon: "underline", format: "__text__") {
                                if let coordinator = editorCoordinator {
                                    coordinator.applyFormatting(.underline)
                                } else {
                                    print("DEBUG: No coordinator available for underline")
                                }
                            }
                            
                            // Strikethrough
                            ToolbarButton(icon: "strikethrough", format: "~~text~~") {
                                if let coordinator = editorCoordinator {
                                    coordinator.applyFormatting(.strikethrough)
                                } else {
                                    print("DEBUG: No coordinator available for strikethrough")
                                }
                            }
                            
                            Rectangle()
                                .fill(Color(NSColor.separatorColor))
                                .frame(width: 1, height: 20)
                                .padding(.horizontal, 4)
                            
                            // Bullet list
                            ToolbarButton(icon: "list.bullet", format: "- item") {
                                if let coordinator = editorCoordinator {
                                    coordinator.insertBulletList()
                                } else {
                                    print("DEBUG: No coordinator available for bullet list")
                                }
                            }
                            
                            // Numbered list
                            ToolbarButton(icon: "list.number", format: "1. item") {
                                if let coordinator = editorCoordinator {
                                    coordinator.insertNumberedList()
                                } else {
                                    print("DEBUG: No coordinator available for numbered list")
                                }
                            }
                            
                            Rectangle()
                                .fill(Color(NSColor.separatorColor))
                                .frame(width: 1, height: 20)
                                .padding(.horizontal, 4)
                            
                            // Link
                            ToolbarButton(icon: "link", format: "[text](url)") {
                                if let coordinator = editorCoordinator {
                                    coordinator.insertLink()
                                } else {
                                    print("DEBUG: No coordinator available for link")
                                }
                            }
                            
                            // Image
                            ToolbarButton(icon: "photo", format: "![alt](url)") {
                                if let coordinator = editorCoordinator {
                                    coordinator.insertImage()
                                } else {
                                    print("DEBUG: No coordinator available for image")
                                }
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        
                        // Separator line between toolbar and editor
                        Rectangle()
                            .fill(Color(NSColor.separatorColor))
                            .frame(height: 1)
                        
                        // WYSIWYG Rich text editor (no scroll, resizable)
                        WYSIWYGRichTextEditor(
                            attributedText: $expansionAttributed,
                            plainText: $expansion,
                            height: $editorHeight,
                            coordinator: $editorCoordinator
                        )
                        .padding(10)
                        .frame(height: editorHeight)
                    }
                    .background(Color(NSColor.textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                    )
                    
                    // Resize handle
                    resizeHandle
                }
                
                HStack {
                    Text("Supports variables and line breaks")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button("Preview") {
                        showFormattedPreview()
                    }
                    .font(.system(size: 10))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.opacity(0.1))
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .foregroundColor(.blue)
                    .buttonStyle(.plain)
                }
                
                enhancedVariablesSection
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private var resizeHandle: some View {
        VStack(spacing: 2) {
            HStack(spacing: 2) {
                Spacer()
                Rectangle()
                    .fill(Color.secondary.opacity(0.5))
                    .frame(width: 8, height: 1)
            }
            Rectangle()
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 12, height: 1)
        }
        .frame(width: 12, height: 6)
        .padding(6)
        .cursor(NSCursor.resizeUpDown)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let newHeight = max(80, min(400, editorHeight + value.translation.height))
                    editorHeight = newHeight
                }
        )
    }
    
    private func showFormattedPreview() {
        // Process the current text and show a preview with formatting
        let processedText = RichTextProcessor.shared.processRichText(expansion)
        
        let alert = NSAlert()
        alert.messageText = "Formatted Preview"
        alert.informativeText = processedText.string
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

// MARK: - Enhanced Variables Section 100033
extension EditSnippetSlideOut {
    private var enhancedVariablesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "curlybraces")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.purple)
                Text("Variables")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                Spacer()
                Text("Click to insert • Live examples")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                dateVariablesGroup
                timeVariablesGroup
                relativeVariablesGroup
                componentVariablesGroup
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.purple.opacity(0.03))
                .stroke(Color.purple.opacity(0.15), lineWidth: 1)
        )
    }
    
    private var dateVariablesGroup: some View {
        EditEnhancedVariableGroup(
            title: "📅 Dates",
            color: .blue,
            variables: [
                EditEnhancedVariableInfo(variable: "{{date}}", title: "Today's Date", example: getCurrentDateExample()),
                EditEnhancedVariableInfo(variable: "{{date-short}}", title: "Short (YYYY-MM-DD)", example: getCurrentShortDateExample()),
                EditEnhancedVariableInfo(variable: "{{date-long}}", title: "Full Date", example: getCurrentLongDateExample()),
                EditEnhancedVariableInfo(variable: "{{date-iso}}", title: "ISO Format", example: getCurrentISODateExample())
            ],
            expansion: $expansion
        )
    }
    
    private var timeVariablesGroup: some View {
        EditEnhancedVariableGroup(
            title: "🕐 Times",
            color: .green,
            variables: [
                EditEnhancedVariableInfo(variable: "{{time}}", title: "Current Time", example: getCurrentTimeExample()),
                EditEnhancedVariableInfo(variable: "{{time-24}}", title: "24-Hour", example: getCurrent24HourExample()),
                EditEnhancedVariableInfo(variable: "{{time-12}}", title: "12-Hour + AM/PM", example: getCurrent12HourExample()),
                EditEnhancedVariableInfo(variable: "{{time-seconds}}", title: "With Seconds", example: getCurrentTimeWithSecondsExample())
            ],
            expansion: $expansion
        )
    }
    
    private var relativeVariablesGroup: some View {
        EditEnhancedVariableGroup(
            title: "📆 Relative",
            color: .orange,
            variables: [
                EditEnhancedVariableInfo(variable: "{{date-1}}", title: "Yesterday", example: getYesterdayExample()),
                EditEnhancedVariableInfo(variable: "{{date+1}}", title: "Tomorrow", example: getTomorrowExample()),
                EditEnhancedVariableInfo(variable: "{{date-7}}", title: "Week Ago", example: getWeekAgoExample()),
                EditEnhancedVariableInfo(variable: "{{date+7}}", title: "Week From Now", example: getWeekFromNowExample())
            ],
            expansion: $expansion
        )
    }
    
    private var componentVariablesGroup: some View {
        EditEnhancedVariableGroup(
            title: "🔢 Components",
            color: .purple,
            variables: [
                EditEnhancedVariableInfo(variable: "{{day}}", title: "Day (Padded)", example: getCurrentDayExample()),
                EditEnhancedVariableInfo(variable: "{{day-short}}", title: "Day (Short)", example: getCurrentDayShortExample()),
                EditEnhancedVariableInfo(variable: "{{month}}", title: "Month (Padded)", example: getCurrentMonthExample()),
                EditEnhancedVariableInfo(variable: "{{month-short}}", title: "Month (Short)", example: getCurrentMonthShortExample()),
                EditEnhancedVariableInfo(variable: "{{year}}", title: "Year", example: getCurrentYearExample()),
                EditEnhancedVariableInfo(variable: "{{timestamp}}", title: "Unix Timestamp", example: getCurrentTimestampExample())
            ],
            expansion: $expansion
        )
    }
}

// MARK: - Helper Methods 100035
extension EditSnippetSlideOut {
    private func loadSnippetDataIfNeeded() {
        if initializedSnippetId != snippet.id {
            loadSnippetData()
            initializedSnippetId = snippet.id
        }
    }
    
    private func loadSnippetData() {
        shortcut = currentSnippet.shortcut
        expansion = currentSnippet.expansion
        
        // Load rich text representation if available
        if !expansion.isEmpty {
            expansionAttributed = RichTextProcessor.shared.processRichText(expansion)
        }
        
        // Determine trigger mode based on both requiresSpace and keepDelimiter
        if !currentSnippet.requiresSpace {
            triggerMode = .instant
        } else if currentSnippet.keepDelimiter {
            triggerMode = .spaceRequiredKeep
        } else {
            triggerMode = .spaceRequiredConsume
        }
    }
    
    private func saveChanges() {
        let finalShortcut = shortcut.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let newRequiresSpace = (triggerMode == .spaceRequiredConsume || triggerMode == .spaceRequiredKeep)
        let newKeepDelimiter = (triggerMode == .spaceRequiredKeep)
        
        if snippetManager.snippets.contains(where: { $0.shortcut == finalShortcut && $0.id != snippet.id }) {
            errorMessage = "A snippet with this shortcut already exists."
            showingError = true
            return
        }
        
        if let index = snippetManager.snippets.firstIndex(where: { $0.id == snippet.id }) {
            snippetManager.snippets[index].shortcut = finalShortcut
            
            // Use the rich text content from the editor
            let expansionText = expansionAttributed.length > 0 ? expansionAttributed.string : expansion
            snippetManager.snippets[index].expansion = expansionText
            
            snippetManager.snippets[index].requiresSpace = newRequiresSpace
            snippetManager.snippets[index].keepDelimiter = newKeepDelimiter
            // Don't modify collectionId - keep existing assignment
            
            // Store the attributed text separately for rich formatting if needed
            if expansionAttributed.length > 0 {
                if let rtfData = expansionAttributed.rtf(from: NSRange(location: 0, length: expansionAttributed.length), documentAttributes: [:]) {
                    UserDefaults.standard.set(rtfData, forKey: "snippet_rtf_\(snippet.id.uuidString)")
                }
            }
            
            // Explicitly save to ensure persistence
            snippetManager.saveAllData()
            
            // Trigger save notification
            SaveNotificationManager.shared.show("Snippet updated")
        }
        
        isShowing = false
    }
}
// MARK: - Live Example Functions 100036
extension EditSnippetSlideOut {
    private func getCurrentDateExample() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
    
    private func getCurrentShortDateExample() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
    
    private func getCurrentLongDateExample() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private func getCurrentISODateExample() -> String {
        return ISO8601DateFormatter().string(from: Date())
    }
    
    private func getCurrentTimeExample() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
    
    private func getCurrent24HourExample() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    private func getCurrent12HourExample() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
    
    private func getCurrentTimeWithSecondsExample() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
    
    private func getYesterdayExample() -> String {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: yesterday)
    }
    
    private func getTomorrowExample() -> String {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: tomorrow)
    }
    
    private func getWeekAgoExample() -> String {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: weekAgo)
    }
    
    private func getWeekFromNowExample() -> String {
        let weekFromNow = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: weekFromNow)
    }
    
    private func getCurrentDayExample() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter.string(from: Date())
    }
    
    private func getCurrentDayShortExample() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: Date())
    }
    
    private func getCurrentMonthExample() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        return formatter.string(from: Date())
    }
    
    private func getCurrentMonthShortExample() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M"
        return formatter.string(from: Date())
    }
    
    private func getCurrentYearExample() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: Date())
    }
    
    private func getCurrentTimestampExample() -> String {
        return String(Int(Date().timeIntervalSince1970))
    }
}

// MARK: - Enhanced Variable Models 100037
struct EditEnhancedVariableInfo {
    let variable: String
    let title: String
    let example: String
}

// MARK: - Enhanced Variable Group Component 100038
struct EditEnhancedVariableGroup: View {
    let title: String
    let color: Color
    let variables: [EditEnhancedVariableInfo]
    @Binding var expansion: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
            
            EditFlowLayout(spacing: 6) {
                ForEach(variables, id: \.variable) { variableInfo in
                    EditEnhancedVariableButton(
                        variableInfo: variableInfo,
                        color: color,
                        expansion: $expansion
                    )
                }
            }
        }
    }
}

// MARK: - Enhanced Variable Button Component 100039
struct EditEnhancedVariableButton: View {
    let variableInfo: EditEnhancedVariableInfo
    let color: Color
    @Binding var expansion: String
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            insertVariableWithUndo()
        }) {
            VStack(alignment: .leading, spacing: 4) {
                // Variable code
                Text(variableInfo.variable)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                
                // Title
                Text(variableInfo.title)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Live example
                Text(variableInfo.example)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(width: 100, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(buttonBackgroundColor)
                    .stroke(buttonBorderColor, lineWidth: 1)
                    .shadow(
                        color: .black.opacity(isPressed ? 0.1 : 0.04),
                        radius: isPressed ? 1 : 3,
                        x: 0,
                        y: isPressed ? 0.5 : 1.5
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : (isHovered ? 1.02 : 1.0))
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .help("\(variableInfo.title) - Example: \(variableInfo.example)")
    }
    
    private var buttonBackgroundColor: Color {
        if isPressed {
            return color.opacity(0.15)
        } else if isHovered {
            return color.opacity(0.08)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
    
    private var buttonBorderColor: Color {
        if isPressed {
            return color.opacity(0.4)
        } else if isHovered {
            return color.opacity(0.3)
        } else {
            return Color(NSColor.separatorColor).opacity(0.3)
        }
    }
    
    private func insertVariableWithUndo() {
        let oldExpansion = expansion
        let newExpansion = expansion + variableInfo.variable
        
        // Update the binding
        expansion = newExpansion
        
        // Try to register undo with the current responder's undo manager
        DispatchQueue.main.async {
            if let window = NSApp.keyWindow,
               let firstResponder = window.firstResponder,
               let undoManager = firstResponder.undoManager {
                
                undoManager.registerUndo(withTarget: EditUndoHelper.shared) { helper in
                    expansion = oldExpansion
                }
                undoManager.setActionName("Insert Variable")
            }
        }
    }
}

// MARK: - Undo Helper Class 100040
class EditUndoHelper: NSObject {
    static let shared = EditUndoHelper()
    private override init() { super.init() }
}

// MARK: - Trigger Mode Row Component 100041
struct EditTriggerModeRow: View {
    let mode: EditSnippetSlideOut.TriggerMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Mode icon
                Image(systemName: mode.icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 20)
                
                // Mode info
                VStack(alignment: .leading, spacing: 2) {
                    Text(mode.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isSelected ? .accentColor : .primary)
                    
                    Text(mode.description)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(mode.example)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(isSelected ? .accentColor : .secondary)
                        .padding(.top, 1)
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Flow Layout for Variables 100042
struct EditFlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = EditFlowResult(
            in: proposal.replacingUnspecifiedDimensions(),
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = EditFlowResult(
            in: proposal.replacingUnspecifiedDimensions(),
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX,
                                     y: bounds.minY + result.frames[index].minY),
                         proposal: ProposedViewSize(result.frames[index].size))
        }
    }
}

// MARK: - Flow Result Helper 100043
struct EditFlowResult {
    var frames: [CGRect] = []
    var bounds: CGSize = .zero
    
    init(in rect: CGSize, subviews: LayoutSubviews, spacing: CGFloat) {
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > rect.width && currentX > 0 {
                // Move to next line
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            frames.append(CGRect(origin: CGPoint(x: currentX, y: currentY), size: size))
            
            currentX += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
        
        bounds = CGSize(width: rect.width, height: currentY + lineHeight)
    }
}
