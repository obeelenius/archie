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
    @State private var triggerMode: TriggerMode = .spaceRequiredConsume
    @State private var showingError = false
    @State private var errorMessage = ""
    
    enum TriggerMode: String, CaseIterable {
        case spaceRequiredConsume = "Space Required (Remove)"
        case spaceRequiredKeep = "Space Required (Keep)"
        case instant = "Instant"
        case collectionSuffix = "Collection Suffix"
        
        var description: String {
            switch self {
            case .spaceRequiredConsume:
                return "Type shortcut + space, removes the space after expansion"
            case .spaceRequiredKeep:
                return "Type shortcut + space, keeps the space after expansion"
            case .instant:
                return "Expands immediately after typing shortcut"
            case .collectionSuffix:
                return "Uses collection suffix like ; or .. to trigger"
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
            case .collectionSuffix:
                return "addr; → expands (if ; is suffix)"
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
            case .collectionSuffix:
                return "textformat.subscript"
            }
        }
    }
    
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
                    // Trigger option section - MOVED TO TOP
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: "keyboard.badge.ellipsis")
                                .foregroundColor(.accentColor)
                                .font(.system(size: 12))
                            
                            Text("Trigger Behavior")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        
                        VStack(spacing: 8) {
                            ForEach(TriggerMode.allCases, id: \.self) { mode in
                                TriggerModeRow(
                                    mode: mode,
                                    isSelected: triggerMode == mode,
                                    onSelect: { triggerMode = mode }
                                )
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
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
                    
                    // Expansion section with variables
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
                        
                        // Variables section at the bottom of expansion
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 6) {
                                Image(systemName: "curlybraces")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.purple)
                                Text("Variables")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("Click to insert")
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                // Date group
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Dates")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    FlowLayout(spacing: 4) {
                                        VariableButton(variable: "{{date}}", description: "Current date", example: "Jan 15, 2025", expansion: $expansion)
                                        VariableButton(variable: "{{date-short}}", description: "YYYY-MM-DD", example: "2025-01-15", expansion: $expansion)
                                        VariableButton(variable: "{{date-long}}", description: "Full date", example: "Wednesday, January 15, 2025", expansion: $expansion)
                                        VariableButton(variable: "{{date-us}}", description: "US format", example: "01/15/2025", expansion: $expansion)
                                        VariableButton(variable: "{{date-uk}}", description: "UK format", example: "15/01/2025", expansion: $expansion)
                                        VariableButton(variable: "{{date-iso}}", description: "ISO format", example: "2025-01-15T14:30:00Z", expansion: $expansion)
                                    }
                                }
                                
                                // Time group
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Times")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    FlowLayout(spacing: 4) {
                                        VariableButton(variable: "{{time}}", description: "Current time", example: "2:30 PM", expansion: $expansion)
                                        VariableButton(variable: "{{time-24}}", description: "24-hour time", example: "14:30", expansion: $expansion)
                                        VariableButton(variable: "{{time-12}}", description: "12-hour + AM/PM", example: "2:30 PM", expansion: $expansion)
                                        VariableButton(variable: "{{time-seconds}}", description: "Time + seconds", example: "2:30:45 PM", expansion: $expansion)
                                        VariableButton(variable: "{{hour}}", description: "Hour", example: "2", expansion: $expansion)
                                        VariableButton(variable: "{{minute}}", description: "Minutes", example: "30", expansion: $expansion)
                                    }
                                }
                                
                                // Relative dates group
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Relative")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    FlowLayout(spacing: 4) {
                                        VariableButton(variable: "{{date-1}}", description: "Yesterday", example: "Jan 14, 2025", expansion: $expansion)
                                        VariableButton(variable: "{{date+1}}", description: "Tomorrow", example: "Jan 16, 2025", expansion: $expansion)
                                        VariableButton(variable: "{{date-7}}", description: "Week ago", example: "Jan 8, 2025", expansion: $expansion)
                                        VariableButton(variable: "{{date+7}}", description: "Week from now", example: "Jan 22, 2025", expansion: $expansion)
                                    }
                                }
                                
                                // Components group
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Components")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    
                                    FlowLayout(spacing: 4) {
                                        VariableButton(variable: "{{day}}", description: "Day number", example: "15", expansion: $expansion)
                                        VariableButton(variable: "{{month}}", description: "Month number", example: "1", expansion: $expansion)
                                        VariableButton(variable: "{{year}}", description: "Full year", example: "2025", expansion: $expansion)
                                        VariableButton(variable: "{{timestamp}}", description: "Unix timestamp", example: "1737033000", expansion: $expansion)
                                    }
                                }
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.purple.opacity(0.05))
                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
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
            triggerMode = snippet.requiresSpace ? .spaceRequiredConsume : .instant
        }
        .onChange(of: snippet.id) { oldValue, newValue in
            shortcut = snippet.shortcut
            expansion = snippet.expansion
            triggerMode = snippet.requiresSpace ? .spaceRequiredConsume : .instant
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
            snippetManager.snippets[index].requiresSpace = (triggerMode == .spaceRequiredConsume || triggerMode == .spaceRequiredKeep)
        }
        
        isShowing = false
    }
}

// MARK: - Trigger Mode Row Component
struct TriggerModeRow: View {
    let mode: EditSnippetSlideOut.TriggerMode
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 2)
                        .frame(width: 16, height: 16)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                    }
                }
                
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

// MARK: - Variable Button Component
struct VariableButton: View {
    let variable: String
    let description: String
    let example: String
    @Binding var expansion: String
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            insertVariableWithUndo()
        }) {
            Text(variable)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.purple)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.purple.opacity(0.1))
                        .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .help("\(description) - Example: \(example)")
    }
    
    private func insertVariableWithUndo() {
        let oldExpansion = expansion
        let newExpansion = expansion + variable
        
        // Update the binding
        expansion = newExpansion
        
        // Try to register undo with the current responder's undo manager
        DispatchQueue.main.async {
            if let window = NSApp.keyWindow,
               let firstResponder = window.firstResponder,
               let undoManager = firstResponder.undoManager {
                
                undoManager.registerUndo(withTarget: UndoHelper.shared) { helper in
                    expansion = oldExpansion
                }
                undoManager.setActionName("Insert Variable")
            }
        }
    }
}

// MARK: - Undo Helper Class
class UndoHelper: NSObject {
    static let shared = UndoHelper()
    private override init() { super.init() }
}

// MARK: - Flow Layout for Variables
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions(),
            subviews: subviews,
            spacing: spacing
        )
        return result.bounds
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
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

struct FlowResult {
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
