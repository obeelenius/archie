// RichTextEditorView.swift

import SwiftUI
import AppKit

// MARK: - Rich Text Editor View 100410
struct RichTextEditorView: NSViewRepresentable {
    @Binding var attributedText: NSAttributedString
    let placeholder: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        
        // Configure text view for rich text editing
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.allowsUndo = true
        textView.usesFindPanel = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.delegate = context.coordinator
        
        // Configure text container
        textView.textContainer?.containerSize = CGSize(width: scrollView.contentSize.width, height: CGFloat.greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        scrollView.documentView = textView
        
        // Set initial text
        if attributedText.length > 0 {
            textView.textStorage?.setAttributedString(attributedText)
        } else {
            textView.string = ""
        }
        
        // Store reference for coordinator
        context.coordinator.textView = textView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        // Only update if the attributed text is different
        if !textView.attributedString().isEqual(to: attributedText) {
            textView.textStorage?.setAttributedString(attributedText)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: RichTextEditorView
        weak var textView: NSTextView?
        
        init(_ parent: RichTextEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Update the binding with the current attributed string
            let newAttributedText = textView.attributedString()
            if !newAttributedText.isEqual(to: parent.attributedText) {
                parent.attributedText = newAttributedText
            }
        }
        
        // Apply formatting to selected text
        func applyFormatting(_ formatting: RichTextFormatting) {
            guard let textView = textView else { return }
            
            let selectedRange = textView.selectedRange()
            guard selectedRange.length > 0 else { return }
            
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
        }
        
        private func toggleBold(in range: NSRange) {
            guard let textView = textView else { return }
            
            textView.textStorage?.enumerateAttribute(.font, in: range, options: []) { font, subRange, _ in
                if let currentFont = font as? NSFont {
                    let isBold = currentFont.fontDescriptor.symbolicTraits.contains(.bold)
                    let newFont = isBold ?
                        NSFontManager.shared.convert(currentFont, toNotHaveTrait: .boldFontMask) :
                        NSFontManager.shared.convert(currentFont, toHaveTrait: .boldFontMask)
                    
                    textView.textStorage?.addAttribute(.font, value: newFont, range: subRange)
                }
            }
        }
        
        private func toggleItalic(in range: NSRange) {
            guard let textView = textView else { return }
            
            textView.textStorage?.enumerateAttribute(.font, in: range, options: []) { font, subRange, _ in
                if let currentFont = font as? NSFont {
                    let isItalic = currentFont.fontDescriptor.symbolicTraits.contains(.italic)
                    let newFont = isItalic ?
                        NSFontManager.shared.convert(currentFont, toNotHaveTrait: .italicFontMask) :
                        NSFontManager.shared.convert(currentFont, toHaveTrait: .italicFontMask)
                    
                    textView.textStorage?.addAttribute(.font, value: newFont, range: subRange)
                }
            }
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
}

// MARK: - Rich Text Formatting Types 100411
enum RichTextFormatting {
    case bold
    case italic
    case underline
    case strikethrough
}

// MARK: - Rich Text Editor with Toolbar 100412
struct RichTextEditorWithToolbar: View {
    @Binding var attributedText: NSAttributedString
    let placeholder: String
    @State private var coordinator: RichTextEditorView.Coordinator?
    
    var body: some View {
        VStack(spacing: 0) {
            // Formatting toolbar
            formattingToolbar
            
            // Rich text editor
            RichTextEditorView(attributedText: $attributedText, placeholder: placeholder)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(NSColor.textBackgroundColor))
                        .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                )
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RichTextEditorCoordinator"))) { notification in
                    if let coord = notification.object as? RichTextEditorView.Coordinator {
                        coordinator = coord
                    }
                }
        }
    }
    
    private var formattingToolbar: some View {
        HStack(spacing: 4) {
            RichTextToolbarButton(icon: "bold", formatting: .bold, coordinator: coordinator)
            RichTextToolbarButton(icon: "italic", formatting: .italic, coordinator: coordinator)
            RichTextToolbarButton(icon: "underline", formatting: .underline, coordinator: coordinator)
            RichTextToolbarButton(icon: "strikethrough", formatting: .strikethrough, coordinator: coordinator)
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Rich Text Toolbar Button 100413
struct RichTextToolbarButton: View {
    let icon: String
    let formatting: RichTextFormatting
    let coordinator: RichTextEditorView.Coordinator?
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            coordinator?.applyFormatting(formatting)
        }) {
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
        .help(helpText)
    }
    
    private var helpText: String {
        switch formatting {
        case .bold: return "Bold"
        case .italic: return "Italic"
        case .underline: return "Underline"
        case .strikethrough: return "Strikethrough"
        }
    }
}
