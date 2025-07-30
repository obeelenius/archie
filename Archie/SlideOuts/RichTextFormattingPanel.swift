//
//  RichTextFormattingPanel.swift
//  Archie
//
//  Created by Amy Elenius on 30/7/2025.
//


// RichTextFormattingPanel.swift

import SwiftUI

// MARK: - Rich Text Formatting Panel 100415
struct RichTextFormattingPanel: View {
    let onFormatSelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            formattingContent
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Header Section 100416
extension RichTextFormattingPanel {
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Rich Text Formatting")
                    .font(.system(size: 14, weight: .bold))
                
                Text("Click to insert formatting")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Formatting Content 100417
extension RichTextFormattingPanel {
    private var formattingContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                FormattingSection(
                    title: "Text Styles",
                    icon: "textformat",
                    items: textStyleItems,
                    onFormatSelected: onFormatSelected
                )
                
                FormattingSection(
                    title: "Lists",
                    icon: "list.bullet",
                    items: listItems,
                    onFormatSelected: onFormatSelected
                )
                
                FormattingSection(
                    title: "Examples",
                    icon: "doc.text",
                    items: exampleItems,
                    onFormatSelected: onFormatSelected
                )
            }
            .padding(16)
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.5))
    }
}

// MARK: - Formatting Items 100418
extension RichTextFormattingPanel {
    private var textStyleItems: [FormattingItem] {
        [
            FormattingItem(
                format: "**text**",
                title: "Bold",
                example: "**Important note**",
                icon: "bold",
                color: .blue
            ),
            FormattingItem(
                format: "*text*",
                title: "Italic",
                example: "*Emphasis*",
                icon: "italic",
                color: .green
            ),
            FormattingItem(
                format: "__text__",
                title: "Underline",
                example: "__Underlined text__",
                icon: "underline",
                color: .purple
            ),
            FormattingItem(
                format: "~~text~~",
                title: "Strikethrough",
                example: "~~Deleted text~~",
                icon: "strikethrough",
                color: .red
            )
        ]
    }
    
    private var listItems: [FormattingItem] {
        [
            FormattingItem(
                format: "- ",
                title: "Bullet Point",
                example: "- First item",
                icon: "list.bullet",
                color: .orange
            ),
            FormattingItem(
                format: "* ",
                title: "Alternative Bullet",
                example: "* Another item",
                icon: "list.bullet.circle",
                color: .orange
            ),
            FormattingItem(
                format: "1. ",
                title: "Numbered List",
                example: "1. First step",
                icon: "list.number",
                color: .indigo
            )
        ]
    }
    
    private var exampleItems: [FormattingItem] {
        [
            FormattingItem(
                format: """
                **Meeting Notes**
                
                *Date: {{date}}*
                
                __Attendees:__
                - John Smith
                - Jane Doe
                
                **Action Items:**
                1. ~~Review budget~~ ✓
                2. Schedule follow-up
                """,
                title: "Meeting Template",
                example: "Complete formatted meeting notes",
                icon: "doc.text",
                color: .teal
            )
        ]
    }
}

// MARK: - Formatting Item Model 100419
struct FormattingItem {
    let format: String
    let title: String
    let example: String
    let icon: String
    let color: Color
}

// MARK: - Formatting Section Component 100420
struct FormattingSection: View {
    let title: String
    let icon: String
    let items: [FormattingItem]
    let onFormatSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader
            itemsGrid
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
        )
    }
    
    private var sectionHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.system(size: 12, weight: .medium))
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private var itemsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 10) {
            ForEach(items, id: \.format) { item in
                FormattingButton(
                    item: item,
                    onTap: {
                        onFormatSelected(item.format)
                    }
                )
            }
        }
    }
}

// MARK: - Formatting Button Component 100421
struct FormattingButton: View {
    let item: FormattingItem
    let onTap: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Format code at top
                Text(item.format.components(separatedBy: .newlines).first ?? item.format)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(item.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.color.opacity(0.12))
                    )
                    .lineLimit(1)
                
                // Title and example
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(item.example.components(separatedBy: .newlines).first ?? item.example)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(buttonBackground)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .help("\(item.title) - Example: \(item.example)")
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(buttonBackgroundColor)
            .stroke(buttonBorderColor, lineWidth: 1)
            .shadow(
                color: .black.opacity(isPressed ? 0.08 : 0.03),
                radius: isPressed ? 2 : 4,
                x: 0,
                y: isPressed ? 1 : 2
            )
    }
    
    private var buttonBackgroundColor: Color {
        if isPressed {
            return item.color.opacity(0.12)
        } else if isHovered {
            return item.color.opacity(0.06)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
    
    private var buttonBorderColor: Color {
        if isPressed {
            return item.color.opacity(0.4)
        } else if isHovered {
            return item.color.opacity(0.25)
        } else {
            return Color(NSColor.separatorColor).opacity(0.3)
        }
    }
}