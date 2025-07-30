//
//  WYSIWYGRichTextEditor.swift
//  Archie
//
//  Created by Amy Elenius on 31/7/2025.
//


// WYSIWYGRichTextEditor.swift

import SwiftUI
import AppKit

// MARK: - WYSIWYG Rich Text Editor 100600
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

// MARK: - Text View Configuration 100601
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

// MARK: - Coordinator Base 100602
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

// MARK: - Formatting Methods 100603
extension WYSIWYGRichTextEditor.Coordinator {
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
        parent.plainText = textView.attributedString().string
    }
    
    private func toggleBold(in range: NSRange) {
        guard let textView = textView else { return }
        
        var currentFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        if let existingFont = textView.textStorage?.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
            currentFont = existingFont
        }
        
        let isBold = currentFont.fontDescriptor.symbolicTraits.contains(.bold)
        let newFont: NSFont
        
        if isBold {
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
    }
    
    private func toggleItalic(in range: NSRange) {
        guard let textView = textView else { return }
        
        var currentFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        if let existingFont = textView.textStorage?.attribute(.font, at: range.location, effectiveRange: nil) as? NSFont {
            currentFont = existingFont
        }
        
        let isItalic = currentFont.fontDescriptor.symbolicTraits.contains(.italic)
        let newFont: NSFont
        
        if isItalic {
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
            if let italicFont = NSFontManager.shared.font(
                withFamily: currentFont.familyName ?? "SF Pro",
                traits: .italicFontMask,
                weight: 5,
                size: currentFont.pointSize
            ) {
                newFont = italicFont
            } else {
                let descriptor = currentFont.fontDescriptor.withSymbolicTraits(.italic)
                newFont = NSFont(descriptor: descriptor, size: currentFont.pointSize) ?? currentFont
            }
        }
        
        textView.textStorage?.addAttribute(.font, value: newFont, range: range)
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

// MARK: - List Methods 100604
extension WYSIWYGRichTextEditor.Coordinator {
    func insertBulletList() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange()
        
        if selectedRange.length > 0 {
            convertSelectionToBulletList(textView: textView, range: selectedRange)
        } else {
            insertBulletPointAtCursor(textView: textView, range: selectedRange)
        }
        
        // Update parent binding
        parent.attributedText = textView.attributedString()
        parent.plainText = textView.attributedString().string
    }
    
    func insertNumberedList() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange()
        
        if selectedRange.length > 0 {
            convertSelectionToNumberedList(textView: textView, range: selectedRange)
        } else {
            insertNumberedItemAtCursor(textView: textView, range: selectedRange)
        }
        
        // Update parent binding
        parent.attributedText = textView.attributedString()
        parent.plainText = textView.attributedString().string
    }
    
    func insertLink() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange()
        
        if selectedRange.length > 0 {
            let selectedText = textView.attributedString().attributedSubstring(from: selectedRange)
            let linkText = "[\(selectedText.string)](url)"
            textView.insertText(linkText, replacementRange: selectedRange)
        } else {
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
    
    // Helper methods for list insertion
    private func insertBulletPointAtCursor(textView: NSTextView, range: NSRange) {
        let insertionPoint = range.location
        let text = textView.string
        
        var textToInsert = "• "
        
        if insertionPoint > 0 && insertionPoint <= text.count {
            let previousChar = text[text.index(text.startIndex, offsetBy: insertionPoint - 1)]
            if previousChar != "\n" {
                textToInsert = "\n• "
            }
        }
        
        textView.insertText(textToInsert, replacementRange: range)
    }
    
    private func insertNumberedItemAtCursor(textView: NSTextView, range: NSRange) {
        let nextNumber = 1 // Simplified - could be enhanced to detect existing numbers
        var textToInsert = "\(nextNumber). "
        
        let insertionPoint = range.location
        let text = textView.string
        
        if insertionPoint > 0 && insertionPoint <= text.count {
            let previousChar = text[text.index(text.startIndex, offsetBy: insertionPoint - 1)]
            if previousChar != "\n" {
                textToInsert = "\n\(nextNumber). "
            }
        }
        
        textView.insertText(textToInsert, replacementRange: range)
    }
    
    private func convertSelectionToBulletList(textView: NSTextView, range: NSRange) {
        let selectedText = (textView.string as NSString).substring(with: range)
        let lines = selectedText.components(separatedBy: .newlines)
        
        let convertedLines = lines.map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty ? "" : "• \(trimmed)"
        }
        
        let convertedText = convertedLines.joined(separator: "\n")
        textView.insertText(convertedText, replacementRange: range)
    }
    
    private func convertSelectionToNumberedList(textView: NSTextView, range: NSRange) {
        let selectedText = (textView.string as NSString).substring(with: range)
        let lines = selectedText.components(separatedBy: .newlines)
        
        var itemNumber = 1
        let convertedLines = lines.map { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                return ""
            } else {
                let numbered = "\(itemNumber). \(trimmed)"
                itemNumber += 1
                return numbered
            }
        }
        
        let convertedText = convertedLines.joined(separator: "\n")
        textView.insertText(convertedText, replacementRange: range)
    }
    
    private func handleNewlineInsertion(_ textView: NSTextView) -> Bool {
        // Simplified newline handling - could be enhanced for auto-continuing lists
        return false
    }
}