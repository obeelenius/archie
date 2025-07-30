// AddSnippetSlideout.swift

import SwiftUI

// MARK: - Add Snippet Slide Out with Enhanced Variables 100055

struct AddSnippetSlideOut: View {
    @Binding var isShowing: Bool
    @StateObject private var snippetManager = SnippetManager.shared
    
    // Use AppStorage for persistence across app lifecycle
    @AppStorage("draft_shortcut") private var shortcut = ""
    @AppStorage("draft_expansion_plain") private var expansionPlain = ""
    @AppStorage("draft_trigger_mode") private var triggerModeRaw = TriggerMode.instant.rawValue
    @State private var expansionAttributed = NSAttributedString()
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var editorHeight: CGFloat = 120
    @State private var editorCoordinator: WYSIWYGRichTextEditor.Coordinator?
    
    private var triggerMode: TriggerMode {
        get { TriggerMode(rawValue: triggerModeRaw) ?? .instant }
        set { triggerModeRaw = newValue.rawValue }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            formContent
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            // Load saved attributed text if available
            if !expansionPlain.isEmpty && expansionAttributed.length == 0 {
                expansionAttributed = RichTextProcessor.shared.processRichText(expansionPlain)
            }
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Trigger Mode Enum 100056
extension AddSnippetSlideOut {
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

// MARK: - Header Section 100057
extension AddSnippetSlideOut {
    private var headerSection: some View {
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
                    
                    Button("Create") {
                        saveSnippet()
                    }
                    .disabled(shortcut.isEmpty || expansionPlain.isEmpty)
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill((shortcut.isEmpty || expansionPlain.isEmpty) ? Color.gray : Color.accentColor)
                    )
                    .buttonStyle(.plain)
                    
                    if !shortcut.isEmpty || !expansionPlain.isEmpty {
                        Button("Clear") {
                            clearDraftData()
                        }
                        .foregroundColor(.orange)
                        .font(.system(size: 12))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                        .buttonStyle(.plain)
                    }
                }
            }
            
            Divider()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Form Content 100058
extension AddSnippetSlideOut {
    private var formContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                triggerBehaviorSection
                snippetDetailsSection // Combined shortcut and expansion
                tipsSection
            }
            .padding(16)
        }
        .background(Color.accentColor.opacity(0.02))
    }
}

// MARK: - Trigger Behavior Section 100059
extension AddSnippetSlideOut {
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
                    AddTriggerModeRow(
                        mode: mode,
                        isSelected: triggerMode == mode,
                        onSelect: {
                            triggerModeRaw = mode.rawValue
                        }
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

// MARK: - Snippet Details Section 100060
extension AddSnippetSlideOut {
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
            
            // Expansion field with toolbar
            VStack(alignment: .leading, spacing: 8) {
                Text("Expansion")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                // Resizable container with same styling as shortcut field
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
                            plainText: $expansionPlain,
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
                
                // Enhanced Variables Section
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
    
    private func insertFormatting(_ prefix: String, _ suffix: String) {
        // Simple insertion at the end for now
        expansionPlain += prefix + "text" + suffix
    }
    
    private func insertAtCursor(_ text: String) {
        expansionPlain += text
    }
    
    private func showFormattedPreview() {
        // Process the current text and show a preview with formatting
        let processedText = RichTextProcessor.shared.processRichText(expansionPlain)
        
        let alert = NSAlert()
        alert.messageText = "Formatted Preview"
        alert.informativeText = processedText.string
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}
// MARK: - Format Toolbar Button Component 100061
struct FormatToolbarButton: View {
    let format: String
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 24, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isPressed ? Color(NSColor.controlAccentColor).opacity(0.2) : Color.clear)
                        .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .help(formatHelpText)
    }
    
    private var formatHelpText: String {
        switch format {
        case "**": return "Bold text"
        case "*": return "Italic text"
        case "__": return "Underlined text"
        case "~~": return "Strikethrough text"
        case "- ": return "Bullet point"
        case "1. ": return "Numbered list"
        case "[text](url)": return "Link"
        case "![alt](url)": return "Image"
        default: return format
        }
    }
}

// MARK: - Enhanced Variables Section 100062
extension AddSnippetSlideOut {
    private var enhancedVariablesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "curlybraces")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.purple)
                Text("Variables")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                Spacer()
                Text("Click to insert")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                dateVariablesGroup
                timeVariablesGroup
                relativeVariablesGroup
                componentVariablesGroup
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.purple.opacity(0.03))
                .stroke(Color.purple.opacity(0.15), lineWidth: 1)
        )
    }
}

// MARK: - Variable Groups 100063A
extension AddSnippetSlideOut {
    private var dateVariablesGroup: some View {
        EnhancedVariableGroup(
            title: "📅 Dates",
            color: .blue,
            variables: [
                EnhancedVariableInfo(variable: "{{date}}", title: "Today's Date", example: getCurrentDateExample()),
                EnhancedVariableInfo(variable: "{{date-short}}", title: "Short (YYYY-MM-DD)", example: getCurrentShortDateExample()),
                EnhancedVariableInfo(variable: "{{date-long}}", title: "Full Date", example: getCurrentLongDateExample()),
                EnhancedVariableInfo(variable: "{{date-iso}}", title: "ISO Format", example: getCurrentISODateExample())
            ],
            expansionPlain: $expansionPlain
        )
    }
    
    private var timeVariablesGroup: some View {
        EnhancedVariableGroup(
            title: "🕐 Times",
            color: .green,
            variables: [
                EnhancedVariableInfo(variable: "{{time}}", title: "Current Time", example: getCurrentTimeExample()),
                EnhancedVariableInfo(variable: "{{time-24}}", title: "24-Hour", example: getCurrent24HourExample()),
                EnhancedVariableInfo(variable: "{{time-12}}", title: "12-Hour + AM/PM", example: getCurrent12HourExample()),
                EnhancedVariableInfo(variable: "{{time-seconds}}", title: "With Seconds", example: getCurrentTimeWithSecondsExample())
            ],
            expansionPlain: $expansionPlain
        )
    }
    
    private var relativeVariablesGroup: some View {
        EnhancedVariableGroup(
            title: "📆 Relative",
            color: .orange,
            variables: [
                EnhancedVariableInfo(variable: "{{date-1}}", title: "Yesterday", example: getYesterdayExample()),
                EnhancedVariableInfo(variable: "{{date+1}}", title: "Tomorrow", example: getTomorrowExample()),
                EnhancedVariableInfo(variable: "{{date-7}}", title: "Week Ago", example: getWeekAgoExample()),
                EnhancedVariableInfo(variable: "{{date+7}}", title: "Week From Now", example: getWeekFromNowExample())
            ],
            expansionPlain: $expansionPlain
        )
    }
    
    private var componentVariablesGroup: some View {
        EnhancedVariableGroup(
            title: "🔢 Components",
            color: .purple,
            variables: [
                EnhancedVariableInfo(variable: "{{day}}", title: "Day (Padded)", example: getCurrentDayExample()),
                EnhancedVariableInfo(variable: "{{day-short}}", title: "Day (Short)", example: getCurrentDayShortExample()),
                EnhancedVariableInfo(variable: "{{month}}", title: "Month (Padded)", example: getCurrentMonthExample()),
                EnhancedVariableInfo(variable: "{{month-short}}", title: "Month (Short)", example: getCurrentMonthShortExample()),
                EnhancedVariableInfo(variable: "{{year}}", title: "Year", example: getCurrentYearExample()),
                EnhancedVariableInfo(variable: "{{timestamp}}", title: "Unix Timestamp", example: getCurrentTimestampExample())
            ],
            expansionPlain: $expansionPlain
        )
    }
}

// MARK: - Tips Section 100063B
extension AddSnippetSlideOut {
    private var tipsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb")
                    .foregroundColor(.orange)
                    .font(.system(size: 12))
                
                Text("Tips")
                    .font(.system(size: 13, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                CompactTip(text: "Use @ or # prefixes for email/social")
                CompactTip(text: "Keep shortcuts short and memorable")
                CompactTip(text: "Variables update automatically")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.orange.opacity(0.05))
                .stroke(Color.orange.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Helper Methods 100065
extension AddSnippetSlideOut {
    private func saveSnippet() {
        if snippetManager.snippets.contains(where: { $0.shortcut == shortcut }) {
            errorMessage = "A snippet with this shortcut already exists."
            showingError = true
            return
        }
        
        // Create snippet without assigning to any collection
        // Store the rich text as RTF data in the expansion field
        let expansionText = expansionAttributed.length > 0 ? expansionAttributed.string : expansionPlain
        
        let newSnippet = Snippet(
            shortcut: shortcut.trimmingCharacters(in: .whitespacesAndNewlines),
            expansion: expansionText,
            requiresSpace: (triggerMode == .spaceRequiredConsume || triggerMode == .spaceRequiredKeep),
            keepDelimiter: (triggerMode == .spaceRequiredKeep),
            collectionId: nil // No collection assignment
        )
        
        // Store the attributed text separately for rich formatting
        if expansionAttributed.length > 0 {
            // We'll need to extend the Snippet model to store rich text data
            // For now, store the attributed string data in UserDefaults with the snippet ID
            if let rtfData = expansionAttributed.rtf(from: NSRange(location: 0, length: expansionAttributed.length), documentAttributes: [:]) {
                UserDefaults.standard.set(rtfData, forKey: "snippet_rtf_\(newSnippet.id.uuidString)")
            }
        }
        
        snippetManager.addSnippet(newSnippet)
        
        // Clear both state and persistent storage
        clearDraftData()
        isShowing = false
    }
    
    private func clearDraftData() {
        shortcut = ""
        expansionPlain = ""
        expansionAttributed = NSAttributedString()
        triggerModeRaw = TriggerMode.instant.rawValue
        
        // Clear AppStorage
        UserDefaults.standard.removeObject(forKey: "draft_shortcut")
        UserDefaults.standard.removeObject(forKey: "draft_expansion_plain")
        UserDefaults.standard.removeObject(forKey: "draft_trigger_mode")
    }
}

// MARK: - Live Example Functions 100066
extension AddSnippetSlideOut {
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

// MARK: - Enhanced Variable Models 100067
struct EnhancedVariableInfo {
    let variable: String
    let title: String
    let example: String
}

// MARK: - Enhanced Variable Group Component 100068
struct EnhancedVariableGroup: View {
    let title: String
    let color: Color
    let variables: [EnhancedVariableInfo]
    @Binding var expansionPlain: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
            
            AddFlowLayout(spacing: 6) {
                ForEach(variables, id: \.variable) { variableInfo in
                    EnhancedAddVariableButton(
                        variableInfo: variableInfo,
                        color: color,
                        expansionPlain: $expansionPlain
                    )
                }
            }
        }
    }
}

// MARK: - Enhanced Add Variable Button Component 100069
struct EnhancedAddVariableButton: View {
    let variableInfo: EnhancedVariableInfo
    let color: Color
    @Binding var expansionPlain: String
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            expansionPlain += variableInfo.variable
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
            .background(buttonBackground)
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
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(buttonBackgroundColor)
            .stroke(buttonBorderColor, lineWidth: 1)
            .shadow(
                color: .black.opacity(isPressed ? 0.1 : 0.04),
                radius: isPressed ? 1 : 3,
                x: 0,
                y: isPressed ? 0.5 : 1.5
            )
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
}

// MARK: - Add Trigger Mode Row Component 100070
struct AddTriggerModeRow: View {
    let mode: AddSnippetSlideOut.TriggerMode
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

// MARK: - Add Flow Layout for Variables 100071
struct AddFlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = AddFlowResult(
            in: proposal.replacingUnspecifiedDimensions(),
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = AddFlowResult(
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

// MARK: - Add Flow Result Helper 100072
struct AddFlowResult {
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

// MARK: - Rich Text Format Models 100073
struct RichTextFormatInfo {
    let format: String
    let title: String
    let example: String
    let color: Color
}

// MARK: - Rich Text Format Button Component 100074
struct RichTextFormatButton: View {
    let formatInfo: RichTextFormatInfo
    @Binding var expansionPlain: String
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            expansionPlain += formatInfo.format
        }) {
            VStack(alignment: .leading, spacing: 4) {
                // Format code
                Text(formatInfo.format)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(formatInfo.color)
                
                // Title
                Text(formatInfo.title)
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                // Example
                Text(formatInfo.example)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(width: 100, alignment: .leading)
            .background(buttonBackground)
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
        .help("\(formatInfo.title) - Example: \(formatInfo.example)")
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(buttonBackgroundColor)
            .stroke(buttonBorderColor, lineWidth: 1)
            .shadow(
                color: .black.opacity(isPressed ? 0.1 : 0.04),
                radius: isPressed ? 1 : 3,
                x: 0,
                y: isPressed ? 0.5 : 1.5
            )
    }
    
    private var buttonBackgroundColor: Color {
        if isPressed {
            return formatInfo.color.opacity(0.15)
        } else if isHovered {
            return formatInfo.color.opacity(0.08)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
    
    private var buttonBorderColor: Color {
        if isPressed {
            return formatInfo.color.opacity(0.4)
        } else if isHovered {
            return formatInfo.color.opacity(0.3)
        } else {
            return Color(NSColor.separatorColor).opacity(0.3)
        }
    }
}

// MARK: - Toolbar Button Component 100075
struct ToolbarButton: View {
    let icon: String
    let format: String
    let action: () -> Void
    
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 28, height: 28)
                .background(buttonBackgroundColor)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onHover { hovering in
            isHovered = hovering
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .help(helpText)
    }
    
    private var buttonBackgroundColor: Color {
        if isPressed {
            return Color(NSColor.controlAccentColor).opacity(0.3)
        } else if isHovered {
            return Color(NSColor.controlBackgroundColor).opacity(0.8)
        } else {
            return Color.clear
        }
    }
    
    private var helpText: String {
        switch icon {
        case "bold": return "Bold (**text**)"
        case "italic": return "Italic (*text*)"
        case "underline": return "Underline (__text__)"
        case "strikethrough": return "Strikethrough (~~text~~)"
        case "list.bullet": return "Bullet List (- item)"
        case "list.number": return "Numbered List (1. item)"
        case "link": return "Link ([text](url))"
        case "photo": return "Image (![alt](url))"
        default: return format
        }
    }
}

// MARK: - WYSIWYG Rich Text Editor 100078
struct WYSIWYGRichTextEditor: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    @Binding var plainText: String
    @Binding var height: CGFloat
    @Binding var coordinator: Coordinator?
    
    func makeNSView(context: Context) -> NSView {
        let containerView = NSView()
        
        // Create text view without scroll view wrapper
        let textView = NSTextView()
        configureTextView(textView, context: context)
        textView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(textView)
        
        // Setup constraints to fill container
        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: containerView.topAnchor),
            textView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Store reference in coordinator
        context.coordinator.textView = textView
        
        // Set coordinator binding after view creation is complete
        DispatchQueue.main.async {
            coordinator = context.coordinator
            print("DEBUG: Coordinator set via async dispatch")
        }
        
        return containerView
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Update text view content if needed
        if let textView = context.coordinator.textView {
            if !textView.attributedString().isEqual(to: attributedText) {
                textView.textStorage?.setAttributedString(attributedText)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - WYSIWYG Text View Configuration 100079
extension WYSIWYGRichTextEditor {
    private func configureTextView(_ textView: NSTextView, context: Context) {
        // Configure for rich text editing
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.delegate = context.coordinator
        
        // Disable automatic text replacement and formatting that might interfere
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isGrammarCheckingEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        
        // Set default text color to prevent blue underlined text
        textView.textColor = NSColor.labelColor
        textView.insertionPointColor = NSColor.labelColor
        
        // Configure text container for proper sizing
        textView.textContainer?.containerSize = CGSize(width: 0, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        // Hide scroll bars
        textView.enclosingScrollView?.hasVerticalScroller = false
        textView.enclosingScrollView?.hasHorizontalScroller = false
        textView.enclosingScrollView?.autohidesScrollers = true
        
        // Set initial content with proper attributes
        if attributedText.length > 0 {
            textView.textStorage?.setAttributedString(attributedText)
        } else {
            textView.string = ""
            // Set default typing attributes to prevent formatting issues
            textView.typingAttributes = [
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                .foregroundColor: NSColor.labelColor
            ]
        }
    }
}

// MARK: - WYSIWYG Coordinator Base 100080
extension WYSIWYGRichTextEditor {
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: WYSIWYGRichTextEditor
        weak var textView: NSTextView?
        
        init(_ parent: WYSIWYGRichTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            let newAttributedText = textView.attributedString()
            if !newAttributedText.isEqual(to: parent.attributedText) {
                parent.attributedText = newAttributedText
                parent.plainText = newAttributedText.string
            }
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Handle Enter key press for auto-continuing lists
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                return handleNewlineInsertion(textView)
            }
            return false
        }
    }
}

// MARK: - WYSIWYG Newline Handling 100081
extension WYSIWYGRichTextEditor.Coordinator {
    private func handleNewlineInsertion(_ textView: NSTextView) -> Bool {
        let currentRange = textView.selectedRange()
        
        // Safety check for valid range
        guard currentRange.location != NSNotFound &&
              currentRange.location <= textView.string.count else {
            return false
        }
        
        // Check if we're in a list by examining paragraph style
        let paragraphRange = (textView.string as NSString).paragraphRange(for: currentRange)
        
        // Safety check for paragraph range
        guard paragraphRange.location != NSNotFound &&
              paragraphRange.location < textView.string.count &&
              paragraphRange.location + paragraphRange.length <= textView.string.count else {
            return false
        }
        
        // Only check attributes if we have a valid location
        guard currentRange.location < textView.textStorage?.length ?? 0 else {
            return false
        }
        
        if let paragraphStyle = textView.textStorage?.attribute(.paragraphStyle, at: currentRange.location, effectiveRange: nil) as? NSParagraphStyle,
           !paragraphStyle.textLists.isEmpty {
            
            let textList = paragraphStyle.textLists.first!
            let currentText = (textView.string as NSString).substring(with: paragraphRange).trimmingCharacters(in: .whitespacesAndNewlines)
            
            if currentText.isEmpty {
                // Empty list item - exit the list
                let newParagraphStyle = NSMutableParagraphStyle()
                newParagraphStyle.textLists = []
                newParagraphStyle.headIndent = 0
                newParagraphStyle.firstLineHeadIndent = 0
                
                textView.textStorage?.addAttribute(.paragraphStyle, value: newParagraphStyle, range: paragraphRange)
                return false // Let system handle the newline
            } else {
                // Non-empty list item - continue the list
                textView.insertText("\n", replacementRange: currentRange)
                
                // Apply same list formatting to new paragraph
                let newCursorLocation = currentRange.location + 1
                
                // Safety check for new cursor location
                guard newCursorLocation <= textView.string.count else {
                    return true
                }
                
                let newParagraphRange = NSRange(location: newCursorLocation, length: 0)
                let newParagraphStyle = NSMutableParagraphStyle()
                newParagraphStyle.textLists = [textList]
                newParagraphStyle.headIndent = paragraphStyle.headIndent
                newParagraphStyle.firstLineHeadIndent = paragraphStyle.firstLineHeadIndent
                
                let extendedRange = (textView.string as NSString).paragraphRange(for: newParagraphRange)
                
                // Safety check for extended range
                guard extendedRange.location != NSNotFound &&
                      extendedRange.location + extendedRange.length <= textView.string.count else {
                    return true
                }
                
                textView.textStorage?.addAttribute(.paragraphStyle, value: newParagraphStyle, range: extendedRange)
                
                parent.attributedText = textView.attributedString()
                parent.plainText = textView.attributedString().string
                return true
            }
        }
        
        return false // Let the system handle the newline normally
    }
}

// MARK: - WYSIWYG Formatting Methods 100082
extension WYSIWYGRichTextEditor.Coordinator {
    func applyFormatting(_ formatting: RichTextFormatting) {
        guard let textView = textView else {
            print("DEBUG: No textView available in applyFormatting")
            return
        }
        
        let selectedRange = textView.selectedRange()
        print("DEBUG: Applying \(formatting) to range: \(selectedRange)")
        
        guard selectedRange.length > 0 else {
            print("DEBUG: No text selected for formatting")
            return
        }
        
        textView.textStorage?.beginEditing()
        
        switch formatting {
        case .bold:
            toggleBold(in: selectedRange)
        case .italic:
            toggleItalic(in: selectedRange)
        case .underline:
            toggleUnderline(in: selectedRange)
        case .strikethrough:
            toggleStrikethrough(in: selectedRange)
        }
        
        textView.textStorage?.endEditing()
        
        // Update parent binding
        parent.attributedText = textView.attributedString()
        parent.plainText = textView.attributedString().string
        
        print("DEBUG: Formatting applied successfully")
    }
    
    private func toggleBold(in range: NSRange) {
        guard let textView = textView else { return }
        
        // Get the current font at the selection
        var currentFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        if let existingFont = textView.textStorage?.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
            currentFont = existingFont
        }
        
        // Create bold or unbold version
        let isBold = currentFont.fontDescriptor.symbolicTraits.contains(.bold)
        let newFont: NSFont
        
        if isBold {
            // Remove bold
            if let unboldFont = NSFontManager.shared.font(
                withFamily: currentFont.familyName ?? "SF Pro",
                traits: [],
                weight: 5,
                size: currentFont.pointSize
            ) {
                newFont = unboldFont
            } else {
                newFont = NSFont.systemFont(ofSize: currentFont.pointSize)
            }
        } else {
            // Add bold
            if let boldFont = NSFontManager.shared.font(
                withFamily: currentFont.familyName ?? "SF Pro",
                traits: .boldFontMask,
                weight: 9,
                size: currentFont.pointSize
            ) {
                newFont = boldFont
            } else {
                newFont = NSFont.boldSystemFont(ofSize: currentFont.pointSize)
            }
        }
        
        textView.textStorage?.addAttribute(.font, value: newFont, range: range)
        print("DEBUG: Bold toggle - was bold: \(isBold), new font: \(newFont)")
    }
    
    private func toggleItalic(in range: NSRange) {
        guard let textView = textView else { return }
        
        // Get the current font at the selection
        var currentFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        if let existingFont = textView.textStorage?.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
            currentFont = existingFont
        }
        
        // Create italic or unitalic version
        let isItalic = currentFont.fontDescriptor.symbolicTraits.contains(.italic)
        let newFont: NSFont
        
        if isItalic {
            // Remove italic
            if let unitalicFont = NSFontManager.shared.font(
                withFamily: currentFont.familyName ?? "SF Pro",
                traits: [],
                weight: 5,
                size: currentFont.pointSize
            ) {
                newFont = unitalicFont
            } else {
                newFont = NSFont.systemFont(ofSize: currentFont.pointSize)
            }
        } else {
            // Add italic
            if let italicFont = NSFontManager.shared.font(
                withFamily: currentFont.familyName ?? "SF Pro",
                traits: .italicFontMask,
                weight: 5,
                size: currentFont.pointSize
            ) {
                newFont = italicFont
            } else {
                // Fallback - try to get italic version another way
                let descriptor = currentFont.fontDescriptor.withSymbolicTraits(.italic)
                newFont = NSFont(descriptor: descriptor, size: currentFont.pointSize) ?? currentFont
            }
        }
        
        textView.textStorage?.addAttribute(.font, value: newFont, range: range)
        print("DEBUG: Italic toggle - was italic: \(isItalic), new font: \(newFont)")
    }
    
    private func toggleUnderline(in range: NSRange) {
        guard let textView = textView else { return }
        
        textView.textStorage?.enumerateAttribute(.underlineStyle, in: range, options: []) { underline, subRange, _ in
            let currentUnderline = underline as? Int ?? 0
            let newUnderline = currentUnderline == 0 ? NSUnderlineStyle.single.rawValue : 0
            
            if newUnderline == 0 {
                textView.textStorage?.removeAttribute(.underlineStyle, range: subRange)
            } else {
                textView.textStorage?.addAttribute(.underlineStyle, value: newUnderline, range: subRange)
            }
        }
    }
    
    private func toggleStrikethrough(in range: NSRange) {
        guard let textView = textView else { return }
        
        textView.textStorage?.enumerateAttribute(.strikethroughStyle, in: range, options: []) { strikethrough, subRange, _ in
            let currentStrike = strikethrough as? Int ?? 0
            let newStrike = currentStrike == 0 ? NSUnderlineStyle.single.rawValue : 0
            
            if newStrike == 0 {
                textView.textStorage?.removeAttribute(.strikethroughStyle, range: subRange)
            } else {
                textView.textStorage?.addAttribute(.strikethroughStyle, value: newStrike, range: subRange)
            }
        }
    }
}

// MARK: - WYSIWYG List Methods 100083
extension WYSIWYGRichTextEditor.Coordinator {
    func insertBulletList() {
        guard let textView = textView else {
            print("DEBUG: No textView available in insertBulletList")
            return
        }
        
        print("DEBUG: Inserting bullet list")
        
        let selectedRange = textView.selectedRange()
        
        if selectedRange.length > 0 {
            // Text is selected - convert selected lines to bullet list
            convertSelectionToBulletList(textView: textView, range: selectedRange)
        } else {
            // No selection - insert bullet point at cursor
            insertBulletPointAtCursor(textView: textView, range: selectedRange)
        }
        
        // Update parent binding
        parent.attributedText = textView.attributedString()
        parent.plainText = textView.attributedString().string
        
        print("DEBUG: Bullet list inserted successfully")
    }
    
    func insertNumberedList() {
        guard let textView = textView else {
            print("DEBUG: No textView available in insertNumberedList")
            return
        }
        
        print("DEBUG: Inserting numbered list")
        
        let selectedRange = textView.selectedRange()
        
        if selectedRange.length > 0 {
            // Text is selected - convert selected lines to numbered list
            convertSelectionToNumberedList(textView: textView, range: selectedRange)
        } else {
            // No selection - insert numbered item at cursor
            insertNumberedItemAtCursor(textView: textView, range: selectedRange)
        }
        
        // Update parent binding
        parent.attributedText = textView.attributedString()
        parent.plainText = textView.attributedString().string
        
        print("DEBUG: Numbered list inserted successfully")
    }
    
    private func insertBulletPointAtCursor(textView: NSTextView, range: NSRange) {
        let insertionPoint = range.location
        let text = textView.string
        
        var textToInsert = "• "
        
        // Check if we need a newline before the bullet
        if insertionPoint > 0 && insertionPoint <= text.count {
            let previousChar = text[text.index(text.startIndex, offsetBy: insertionPoint - 1)]
            if previousChar != "\n" {
                textToInsert = "\n• "
            }
        }
        
        // Insert the bullet point
        textView.insertText(textToInsert, replacementRange: range)
        
        print("DEBUG: Inserted bullet point: '\(textToInsert)'")
    }
    
    private func insertNumberedItemAtCursor(textView: NSTextView, range: NSRange) {
        let insertionPoint = range.location
        let text = textView.string
        
        // Find the next number to use
        let nextNumber = getNextListNumber(in: text, at: insertionPoint)
        var textToInsert = "\(nextNumber). "
        
        // Check if we need a newline before the number
        if insertionPoint > 0 && insertionPoint <= text.count {
            let previousChar = text[text.index(text.startIndex, offsetBy: insertionPoint - 1)]
            if previousChar != "\n" {
                textToInsert = "\n\(nextNumber). "
            }
        }
        
        // Insert the numbered item
        textView.insertText(textToInsert, replacementRange: range)
        
        print("DEBUG: Inserted numbered item: '\(textToInsert)'")
    }
    
    private func getNextListNumber(in text: String, at position: Int) -> Int {
        // Look backwards to find existing numbered list items
        let lines = text.components(separatedBy: .newlines)
        var maxNumber = 0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let match = trimmed.range(of: #"^\d+\."#, options: .regularExpression) {
                let numberString = String(trimmed[match]).dropLast() // Remove the period
                if let number = Int(numberString) {
                    maxNumber = max(maxNumber, number)
                }
            }
        }
        
        return maxNumber + 1
    }
    
    func insertLink() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange()
        
        if selectedRange.length > 0 {
            // Text is selected, wrap it in a link
            let selectedText = textView.attributedString().attributedSubstring(from: selectedRange)
            let linkText = "[\(selectedText.string)](url)"
            
            textView.insertText(linkText, replacementRange: selectedRange)
        } else {
            // No selection, insert link template
            let linkText = "[link text](url)"
            textView.insertText(linkText, replacementRange: selectedRange)
        }
        
        // Update parent binding
        parent.attributedText = textView.attributedString()
        parent.plainText = textView.attributedString().string
    }
    
    func insertImage() {
        guard let textView = textView else { return }
        
        let currentRange = textView.selectedRange()
        let imageText = "![image description](image-url)"
        
        textView.insertText(imageText, replacementRange: currentRange)
        
        // Update parent binding
        parent.attributedText = textView.attributedString()
        parent.plainText = textView.attributedString().string
    }
}

// MARK: - WYSIWYG List Conversion Methods 100084
extension WYSIWYGRichTextEditor.Coordinator {
    private func convertSelectionToBulletList(textView: NSTextView, range: NSRange) {
        let selectedText = (textView.string as NSString).substring(with: range)
        let lines = selectedText.components(separatedBy: .newlines)
        
        // Check if selection is already a bullet list
        let isBulletList = lines.allSatisfy { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty || trimmed.hasPrefix("• ")
        }
        
        var convertedLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                if isBulletList {
                    // Remove bullet markers
                    let cleaned = cleanLineOfListMarkers(trimmed)
                    convertedLines.append(cleaned)
                    print("DEBUG: Removed bullet from: '\(trimmed)' -> '\(cleaned)'")
                } else {
                    // Add bullet markers
                    let cleaned = cleanLineOfListMarkers(trimmed)
                    convertedLines.append("• \(cleaned)")
                    print("DEBUG: Added bullet to: '\(trimmed)' -> '• \(cleaned)'")
                }
            } else {
                convertedLines.append("")
            }
        }
        
        let convertedText = convertedLines.joined(separator: "\n")
        textView.insertText(convertedText, replacementRange: range)
        
        print("DEBUG: Converted selection - was bullet list: \(isBulletList)")
    }
    
    private func convertSelectionToNumberedList(textView: NSTextView, range: NSRange) {
        let selectedText = (textView.string as NSString).substring(with: range)
        let lines = selectedText.components(separatedBy: .newlines)
        
        // Check if selection is already a numbered list
        let isNumberedList = lines.allSatisfy { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return true }
            
            // Check if line starts with number followed by period and space
            let pattern = #"^\d+\.\s+"#
            return trimmed.range(of: pattern, options: .regularExpression) != nil
        }
        
        var convertedLines: [String] = []
        var itemNumber = 1
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                if isNumberedList {
                    // Remove number markers
                    let cleaned = cleanLineOfListMarkers(trimmed)
                    convertedLines.append(cleaned)
                    print("DEBUG: Removed number from: '\(trimmed)' -> '\(cleaned)'")
                } else {
                    // Add number markers
                    let cleaned = cleanLineOfListMarkers(trimmed)
                    convertedLines.append("\(itemNumber). \(cleaned)")
                    print("DEBUG: Added number to: '\(trimmed)' -> '\(itemNumber). \(cleaned)'")
                    itemNumber += 1
                }
            } else {
                convertedLines.append("")
            }
        }
        
        let convertedText = convertedLines.joined(separator: "\n")
        textView.insertText(convertedText, replacementRange: range)
        
        print("DEBUG: Converted selection - was numbered list: \(isNumberedList)")
    }
    
    private func cleanLineOfListMarkers(_ line: String) -> String {
        var cleanedLine = line
        
        // Remove bullet markers (• character)
        if cleanedLine.hasPrefix("• ") {
            cleanedLine = String(cleanedLine.dropFirst(2))
        }
        
        // Remove numbered list markers (1. 2. etc.) - more precise pattern
        let numberPattern = #"^\d+\.\s+"#
        if let regex = try? NSRegularExpression(pattern: numberPattern) {
            let range = NSRange(location: 0, length: cleanedLine.count)
            let matches = regex.matches(in: cleanedLine, range: range)
            if let match = matches.first {
                cleanedLine = (cleanedLine as NSString).replacingCharacters(in: match.range, with: "")
            }
        }
        
        // Remove dash markers (- )
        if cleanedLine.hasPrefix("- ") {
            cleanedLine = String(cleanedLine.dropFirst(2))
        }
        
        // Remove asterisk markers (* )
        if cleanedLine.hasPrefix("* ") {
            cleanedLine = String(cleanedLine.dropFirst(2))
        }
        
        return cleanedLine
    }
}
