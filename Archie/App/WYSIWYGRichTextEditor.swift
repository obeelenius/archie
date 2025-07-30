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

// MARK: - Newline Handling 100603
extension WYSIWYGRichTextEditor.Coordinator {
    private func handleNewlineInsertion(_ textView: NSTextView) -> Bool {
        let currentRange = textView.selectedRange()
        
        // Safety check for valid range
        guard currentRange.location != NSNotFound &&
              currentRange.location <= textView.string.count else {
            return false
        }
        
        // Get the current line
        let text = textView.string
        let lineStart = findLineStart(in: text, from: currentRange.location)
        let lineEnd = findLineEnd(in: text, from: currentRange.location)
        
        guard lineStart <= lineEnd && lineEnd <= text.count else {
            return false
        }
        
        let currentLine = String(text[text.index(text.startIndex, offsetBy: lineStart)..<text.index(text.startIndex, offsetBy: lineEnd)])
        let trimmedLine = currentLine.trimmingCharacters(in: .whitespaces)
        
        // Check if current line is a bullet list item
        if trimmedLine.hasPrefix("• ") {
            let content = String(trimmedLine.dropFirst(2)).trimmingCharacters(in: .whitespaces)
            
            if content.isEmpty {
                // Empty bullet item - remove the bullet and exit list
                let bulletRange = NSRange(location: lineStart, length: lineEnd - lineStart)
                textView.replaceCharacters(in: bulletRange, with: "")
                return false // Let system handle the newline
            } else {
                // Non-empty bullet item - continue the list
                textView.insertText("\n• ", replacementRange: currentRange)
                
                // Update parent binding
                parent.attributedText = textView.attributedString()
                parent.plainText = textView.attributedString().string
                return true
            }
        }
        
        // Check if current line is a numbered list item
        let numberPattern = #"^(\d+)\.\s+"#
        if let regex = try? NSRegularExpression(pattern: numberPattern),
           let match = regex.firstMatch(in: trimmedLine, range: NSRange(location: 0, length: trimmedLine.count)) {
            
            let numberRange = match.range(at: 1)
            let numberString = (trimmedLine as NSString).substring(with: numberRange)
            
            if let currentNumber = Int(numberString) {
                let contentAfterNumber = (trimmedLine as NSString).substring(from: match.range.location + match.range.length)
                let content = contentAfterNumber.trimmingCharacters(in: .whitespaces)
                
                if content.isEmpty {
                    // Empty numbered item - remove the number and exit list
                    let numberItemRange = NSRange(location: lineStart, length: lineEnd - lineStart)
                    textView.replaceCharacters(in: numberItemRange, with: "")
                    return false // Let system handle the newline
                } else {
                    // Non-empty numbered item - continue the list with next number
                    let nextNumber = currentNumber + 1
                    textView.insertText("\n\(nextNumber). ", replacementRange: currentRange)
                    
                    // Update parent binding
                    parent.attributedText = textView.attributedString()
                    parent.plainText = textView.attributedString().string
                    return true
                }
            }
        }
        
        return false // Let the system handle the newline normally
    }
    
    private func findLineStart(in text: String, from position: Int) -> Int {
        guard position > 0 else { return 0 }
        
        var index = position - 1
        while index >= 0 && text[text.index(text.startIndex, offsetBy: index)] != "\n" {
            index -= 1
        }
        return index + 1
    }
    
    private func findLineEnd(in text: String, from position: Int) -> Int {
        var index = position
        while index < text.count && text[text.index(text.startIndex, offsetBy: index)] != "\n" {
            index += 1
        }
        return index
    }
}

// MARK: - Formatting Methods 100604
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

// MARK: - List Methods 100605
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
        let insertionPoint = range.location
        let text = textView.string
        
        let nextNumber = getNextListNumber(in: text, at: insertionPoint)
        var textToInsert = "\(nextNumber). "
        
        if insertionPoint > 0 && insertionPoint <= text.count {
            let previousChar = text[text.index(text.startIndex, offsetBy: insertionPoint - 1)]
            if previousChar != "\n" {
                textToInsert = "\n\(nextNumber). "
            }
        }
        
        textView.insertText(textToInsert, replacementRange: range)
    }
    
    private func getNextListNumber(in text: String, at position: Int) -> Int {
        let lines = text.components(separatedBy: .newlines)
        var maxNumber = 0
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if let match = trimmed.range(of: #"^\d+\."#, options: .regularExpression) {
                let numberString = String(trimmed[match]).dropLast()
                if let number = Int(numberString) {
                    maxNumber = max(maxNumber, number)
                }
            }
        }
        
        return maxNumber + 1
    }
    
    private func convertSelectionToBulletList(textView: NSTextView, range: NSRange) {
        let selectedText = (textView.string as NSString).substring(with: range)
        let lines = selectedText.components(separatedBy: .newlines)
        
        let isBulletList = lines.allSatisfy { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            return trimmed.isEmpty || trimmed.hasPrefix("• ")
        }
        
        var convertedLines: [String] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                if isBulletList {
                    let cleaned = cleanLineOfListMarkers(trimmed)
                    convertedLines.append(cleaned)
                } else {
                    let cleaned = cleanLineOfListMarkers(trimmed)
                    convertedLines.append("• \(cleaned)")
                }
            } else {
                convertedLines.append("")
            }
        }
        
        let convertedText = convertedLines.joined(separator: "\n")
        textView.insertText(convertedText, replacementRange: range)
    }
    
    private func convertSelectionToNumberedList(textView: NSTextView, range: NSRange) {
        let selectedText = (textView.string as NSString).substring(with: range)
        let lines = selectedText.components(separatedBy: .newlines)
        
        let isNumberedList = lines.allSatisfy { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { return true }
            
            let pattern = #"^\d+\.\s+"#
            return trimmed.range(of: pattern, options: .regularExpression) != nil
        }
        
        var convertedLines: [String] = []
        var itemNumber = 1
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if !trimmed.isEmpty {
                if isNumberedList {
                    let cleaned = cleanLineOfListMarkers(trimmed)
                    convertedLines.append(cleaned)
                } else {
                    let cleaned = cleanLineOfListMarkers(trimmed)
                    convertedLines.append("\(itemNumber). \(cleaned)")
                    itemNumber += 1
                }
            } else {
                convertedLines.append("")
            }
        }
        
        let convertedText = convertedLines.joined(separator: "\n")
        textView.insertText(convertedText, replacementRange: range)
    }
    
    private func cleanLineOfListMarkers(_ line: String) -> String {
        var cleanedLine = line
        
        // Remove bullet markers (• character)
        if cleanedLine.hasPrefix("• ") {
            cleanedLine = String(cleanedLine.dropFirst(2))
        }
        
        // Remove numbered list markers (1. 2. etc.)
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
