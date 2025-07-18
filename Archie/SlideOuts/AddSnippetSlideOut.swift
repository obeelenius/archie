// AddSnippetSlideout.swift

import SwiftUI

// MARK: - Add Snippet Slide Out with Enhanced Variables 100055

struct AddSnippetSlideOut: View {
    @Binding var isShowing: Bool
    @StateObject private var snippetManager = SnippetManager.shared
    
    @State private var shortcut = ""
    @State private var expansion = ""
    @State private var triggerMode: TriggerMode = .spaceRequiredConsume
    @State private var showingError = false
    @State private var errorMessage = ""
    
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
                    .disabled(shortcut.isEmpty || expansion.isEmpty)
                    .foregroundColor(.white)
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 5)
                            .fill((shortcut.isEmpty || expansion.isEmpty) ? Color.gray : Color.accentColor)
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

// MARK: - Form Content 100058
extension AddSnippetSlideOut {
    private var formContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                collectionSelectionSection
                snippetDetailsSection
                triggerBehaviorSection
                expansionSection
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

// MARK: - Expansion Section 100061
extension AddSnippetSlideOut {
    private var expansionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14))
                
                Text("Expansion")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                expansionEditor
                
                Text("Supports line breaks and variables")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                
                enhancedVariablesSection
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private var expansionEditor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.textBackgroundColor))
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                .frame(minHeight: 100)
            
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
    }
}

// MARK: - Shortcut Section 100060
extension AddSnippetSlideOut {
    private var shortcutSection: some View {
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
    }
}

// MARK: - Expansion Section 100061
extension AddSnippetSlideOut {
    private var expansionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "text.alignleft")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 12))
                
                Text("Expansion")
                    .font(.system(size: 13, weight: .semibold))
            }
            
            expansionEditor
            
            Text("Supports line breaks and variables")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            enhancedVariablesSection
        }
    }
    
    private var expansionEditor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.textBackgroundColor))
                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                .frame(minHeight: 100)
            
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
    }
}

// MARK: - Enhanced Variables Section 100062
extension AddSnippetSlideOut {
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
        EnhancedVariableGroup(
            title: "📅 Dates",
            color: .blue,
            variables: [
                EnhancedVariableInfo(variable: "{{date}}", title: "Today's Date", example: getCurrentDateExample()),
                EnhancedVariableInfo(variable: "{{date-short}}", title: "Short (YYYY-MM-DD)", example: getCurrentShortDateExample()),
                EnhancedVariableInfo(variable: "{{date-long}}", title: "Full Date", example: getCurrentLongDateExample()),
                EnhancedVariableInfo(variable: "{{date-iso}}", title: "ISO Format", example: getCurrentISODateExample())
            ],
            expansion: $expansion
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
            expansion: $expansion
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
            expansion: $expansion
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
                expansion: $expansion
            )
        }
}

// MARK: - Tips Section 100063
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
        
        // Find the General collection (or first collection as fallback)
        let generalCollection = snippetManager.collections.first { $0.name == "General" } ?? snippetManager.collections.first
        
        let newSnippet = Snippet(
            shortcut: shortcut.trimmingCharacters(in: .whitespacesAndNewlines),
            expansion: expansion,
            requiresSpace: (triggerMode == .spaceRequiredConsume || triggerMode == .spaceRequiredKeep),
            keepDelimiter: (triggerMode == .spaceRequiredKeep),
            collectionId: generalCollection?.id
        )
        
        snippetManager.addSnippet(newSnippet)
        
        shortcut = ""
        expansion = ""
        triggerMode = .spaceRequiredConsume
        isShowing = false
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
    @Binding var expansion: String
    
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
                        expansion: $expansion
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
    @Binding var expansion: String
    @State private var isPressed = false
    @State private var isHovered = false
    
    var body: some View {
        Button(action: {
            expansion += variableInfo.variable
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


// MARK: - Collection Selection Section 100073
extension AddSnippetSlideOut {
    private var collectionSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14))
                
                Text("Collection")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            Menu {
                ForEach(snippetManager.collections) { collection in
                    Button(action: {
                        selectedCollectionId = collection.id
                    }) {
                        HStack {
                            Image(systemName: collection.icon.isEmpty ? "folder" : collection.icon)
                            Text(collection.name)
                            if selectedCollectionId == collection.id {
                                Spacer()
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    if let selectedCollection = snippetManager.collections.first(where: { $0.id == selectedCollectionId }) {
                        Image(systemName: selectedCollection.icon.isEmpty ? "folder" : selectedCollection.icon)
                            .foregroundColor(getCollectionColor(selectedCollection))
                            .font(.system(size: 12))
                        
                        Text(selectedCollection.name)
                            .font(.system(size: 12))
                            .foregroundColor(.primary)
                    } else {
                        Text("Select Collection")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.textBackgroundColor))
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            
            Text("Choose which collection this snippet belongs to")
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private var snippetDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "keyboard")
                    .foregroundColor(.accentColor)
                    .font(.system(size: 14))
                
                Text("Snippet Details")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shortcut")
                        .font(.system(size: 13, weight: .semibold))
                    
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
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
    
    private func getCollectionColor(_ collection: SnippetCollection) -> Color {
        switch collection.color {
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
}
