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
                                AddTriggerModeRow(
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
                        
                        // Variables section at the bottom of expansion
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "curlybraces")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.purple)
                                Text("Variables")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("Click to insert")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            
                            VStack(spacing: 8) {
                                // Date Variables
                                Text("Dates")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.purple)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                VariableButton(variable: "{{date}}", description: "Default date format", example: "Jan 15, 2025", expansion: $expansion)
                                VariableButton(variable: "{{date-short}}", description: "Short numeric date", example: "2025-01-15", expansion: $expansion)
                                VariableButton(variable: "{{date-long}}", description: "Full written date", example: "Wednesday, January 15, 2025", expansion: $expansion)
                                VariableButton(variable: "{{date-iso}}", description: "ISO 8601 format", example: "2025-01-15T14:30:00Z", expansion: $expansion)
                                VariableButton(variable: "{{date-us}}", description: "US format", example: "01/15/2025", expansion: $expansion)
                                VariableButton(variable: "{{date-uk}}", description: "UK format", example: "15/01/2025", expansion: $expansion)
                                VariableButton(variable: "{{date-compact}}", description: "Compact format", example: "20250115", expansion: $expansion)
                                
                                // Day/Month/Year Components
                                Text("Date Components")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.purple)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 8)
                                
                                VariableButton(variable: "{{day}}", description: "Day number", example: "15", expansion: $expansion)
                                VariableButton(variable: "{{day-name}}", description: "Day name", example: "Wednesday", expansion: $expansion)
                                VariableButton(variable: "{{day-short}}", description: "Short day name", example: "Wed", expansion: $expansion)
                                VariableButton(variable: "{{month}}", description: "Month number", example: "1", expansion: $expansion)
                                VariableButton(variable: "{{month-name}}", description: "Month name", example: "January", expansion: $expansion)
                                VariableButton(variable: "{{month-short}}", description: "Short month name", example: "Jan", expansion: $expansion)
                                VariableButton(variable: "{{year}}", description: "Full year", example: "2025", expansion: $expansion)
                                VariableButton(variable: "{{year-short}}", description: "Short year", example: "25", expansion: $expansion)
                                
                                // Time Variables
                                Text("Times")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.purple)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 8)
                                
                                VariableButton(variable: "{{time}}", description: "Default time format", example: "2:30 PM", expansion: $expansion)
                                VariableButton(variable: "{{time-24}}", description: "24-hour format", example: "14:30", expansion: $expansion)
                                VariableButton(variable: "{{time-12}}", description: "12-hour with AM/PM", example: "2:30 PM", expansion: $expansion)
                                VariableButton(variable: "{{time-12-no-space}}", description: "12-hour no space", example: "2:30PM", expansion: $expansion)
                                VariableButton(variable: "{{time-seconds}}", description: "With seconds", example: "2:30:45 PM", expansion: $expansion)
                                VariableButton(variable: "{{time-24-seconds}}", description: "24-hour with seconds", example: "14:30:45", expansion: $expansion)
                                VariableButton(variable: "{{hour}}", description: "Hour (12-format)", example: "2", expansion: $expansion)
                                VariableButton(variable: "{{hour-24}}", description: "Hour (24-format)", example: "14", expansion: $expansion)
                                VariableButton(variable: "{{minute}}", description: "Minutes", example: "30", expansion: $expansion)
                                
                                // Relative Dates
                                Text("Relative Dates")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.purple)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 8)
                                
                                VariableButton(variable: "{{date-1}}", description: "Yesterday", example: "Jan 14, 2025", expansion: $expansion)
                                VariableButton(variable: "{{date+1}}", description: "Tomorrow", example: "Jan 16, 2025", expansion: $expansion)
                                VariableButton(variable: "{{date-7}}", description: "One week ago", example: "Jan 8, 2025", expansion: $expansion)
                                VariableButton(variable: "{{date+7}}", description: "One week from now", example: "Jan 22, 2025", expansion: $expansion)
                                
                                // Technical Formats
                                Text("Technical")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.purple)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 8)
                                
                                VariableButton(variable: "{{timestamp}}", description: "Unix timestamp", example: "1737033000", expansion: $expansion)
                                VariableButton(variable: "{{timestamp-ms}}", description: "Timestamp with milliseconds", example: "1737033000000", expansion: $expansion)
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.purple.opacity(0.05))
                                .stroke(Color.purple.opacity(0.2), lineWidth: 1)
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
            requiresSpace: (triggerMode == .spaceRequiredConsume || triggerMode == .spaceRequiredKeep)
        )
        
        snippetManager.addSnippet(newSnippet)
        
        shortcut = ""
        expansion = ""
        triggerMode = .spaceRequiredConsume
        isShowing = false
    }
}

// MARK: - Add Trigger Mode Row Component
struct AddTriggerModeRow: View {
    let mode: AddSnippetSlideOut.TriggerMode
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
