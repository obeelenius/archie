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
        
        // Create custom text view that handles image pasting
        let textView = ImageHandlingTextView()
        textView.coordinator = context.coordinator
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
                let currentText = textView.attributedString()
                
                // Only update if there's a significant difference and we're not just resizing
                // Check if the plain text content is the same - if so, don't recreate attributed text
                let currentPlainText = currentText.string
                
                // Check if we need to update from attributed text (external changes)
                if !currentText.isEqual(to: attributedText) && attributedText.length > 0 {
                    // Only update if the plain text is actually different, not just formatting
                    if currentPlainText != attributedText.string {
                        textView.textStorage?.setAttributedString(attributedText)
                        print("DEBUG SYNC: Updated text view from attributedText")
                    }
                }
                // Check if we need to update from plain text (when variables are added)
                // But only if the current text is significantly different
                else if currentPlainText != plainText && !plainText.isEmpty {
                    // If the current text view has rich formatting and the plain text is just
                    // a substring or superset, don't replace - the user is probably just editing
                    let hasRichFormatting = hasSignificantFormatting(currentText)
                    
                    if !hasRichFormatting || plainText.count < currentPlainText.count * Int(0.5) {
                        // Only replace if no rich formatting exists, or if text was significantly reduced
                        let newAttributedText = NSMutableAttributedString(string: plainText)
                        newAttributedText.addAttributes([
                            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                            .foregroundColor: NSColor.labelColor
                        ], range: NSRange(location: 0, length: newAttributedText.length))
                        textView.textStorage?.setAttributedString(newAttributedText)
                        print("DEBUG SYNC: Updated text view from plainText: '\(plainText)'")
                    } else {
                        print("DEBUG SYNC: Skipped update to preserve rich formatting")
                    }
                }
            }
        }
        
        // Helper function to detect if text has significant rich formatting
        private func hasSignificantFormatting(_ attributedString: NSAttributedString) -> Bool {
            let fullRange = NSRange(location: 0, length: attributedString.length)
            var hasFormatting = false
            
            // Check for paragraph styles (lists)
            attributedString.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, range, stop in
                if let paragraphStyle = value as? NSParagraphStyle {
                    if !paragraphStyle.textLists.isEmpty {
                        hasFormatting = true
                        stop.pointee = true
                    }
                }
            }
            
            // Check for font variations (bold, italic)
            attributedString.enumerateAttribute(.font, in: fullRange, options: []) { value, range, stop in
                if let font = value as? NSFont {
                    let traits = font.fontDescriptor.symbolicTraits
                    if traits.contains(.bold) || traits.contains(.italic) {
                        hasFormatting = true
                        stop.pointee = true
                    }
                }
            }
            
            // Check for other formatting
            let hasUnderline = attributedString.attribute(.underlineStyle, at: 0, effectiveRange: nil) != nil
            let hasStrikethrough = attributedString.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) != nil
            let hasLinks = attributedString.attribute(.link, at: 0, effectiveRange: nil) != nil
            
            return hasFormatting || hasUnderline || hasStrikethrough || hasLinks
        }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}

// MARK: - Rich Text Formatting Types 100601
enum RichTextFormatting {
    case bold
    case italic
    case underline
    case strikethrough
}

// MARK: - Custom Text View for Image Handling 100608
class ImageHandlingTextView: NSTextView {
    weak var coordinator: WYSIWYGRichTextEditor.Coordinator?
    
    override func paste(_ sender: Any?) {
        print("DEBUG: paste() called")
        let pasteboard = NSPasteboard.general
        
        // Debug: Print all available types
        print("DEBUG: Available pasteboard types: \(pasteboard.types ?? [])")
        
        // Check if pasteboard contains an image
        let hasImage = pasteboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.tiff.rawValue, NSPasteboard.PasteboardType.png.rawValue])
        print("DEBUG: Has image data: \(hasImage)")
        
        if hasImage {
            print("DEBUG: Handling image paste")
            coordinator?.handleImagePaste(textView: self, affectedRanges: [NSValue(range: self.selectedRange())])
        } else {
            print("DEBUG: Handling text paste")
            // Let the text view handle normal text paste
            super.paste(sender)
        }
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        print("DEBUG: performDragOperation called")
        let pasteboard = sender.draggingPasteboard
        print("DEBUG: Drag pasteboard types: \(pasteboard.types ?? [])")
        
        // Check for file URLs first (most common when dragging from Finder)
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            for url in urls {
                print("DEBUG: Processing dragged file: \(url.path)")
                
                // Check if it's an image file
                let imageExtensions = ["png", "jpg", "jpeg", "gif", "tiff", "bmp", "heic", "webp"]
                let fileExtension = url.pathExtension.lowercased()
                
                if imageExtensions.contains(fileExtension) {
                    print("DEBUG: Found image file: \(url.path)")
                    
                    // Load image data and process it
                    if let imageData = try? Data(contentsOf: url) {
                        if let savedImagePath = coordinator?.saveImageToAppDirectory(data: imageData, type: fileExtension.isEmpty ? "png" : fileExtension) {
                            print("DEBUG: Image saved, inserting reference")
                            coordinator?.insertImageReference(at: NSRange(location: self.selectedRange().location, length: 0), imagePath: savedImagePath, textView: self)
                            return true
                        }
                    }
                }
            }
        }
        
        // Check if dragged item contains image data directly
        if pasteboard.canReadItem(withDataConformingToTypes: [NSPasteboard.PasteboardType.tiff.rawValue, NSPasteboard.PasteboardType.png.rawValue]) {
            print("DEBUG: Handling image data drag")
            coordinator?.handleImagePaste(textView: self, affectedRanges: [NSValue(range: self.selectedRange())])
            return true
        }
        
        return super.performDragOperation(sender)
    }
}

// MARK: - Text View Configuration 100602
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
        textView.maxSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        
        // Configure resizing properties - these are NSTextView properties
        textView.autoresizingMask = [.width]
        
        // Hide scroll bars if the text view is in a scroll view
        textView.enclosingScrollView?.hasVerticalScroller = false
        textView.enclosingScrollView?.hasHorizontalScroller = false
        textView.enclosingScrollView?.autohidesScrollers = true
        
        // Set initial content with proper attributes
        if attributedText.length > 0 {
            textView.textStorage?.setAttributedString(attributedText)
        } else if !plainText.isEmpty {
            // If we have plain text but no attributed text, create attributed text from plain text
            let newAttributedText = NSMutableAttributedString(string: plainText)
            newAttributedText.addAttributes([
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                .foregroundColor: NSColor.labelColor
            ], range: NSRange(location: 0, length: newAttributedText.length))
            textView.textStorage?.setAttributedString(newAttributedText)
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

// MARK: - Coordinator Class 100603
extension WYSIWYGRichTextEditor {
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: WYSIWYGRichTextEditor
        weak var textView: NSTextView?
        
        init(_ parent: WYSIWYGRichTextEditor) {
            self.parent = parent
            super.init()
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
            // Handle Command+K for hyperlinks
            if commandSelector == #selector(NSResponder.keyDown(with:)) {
                return false
            }
            
            // Handle Enter key press for auto-continuing lists
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                return handleNewlineInsertion(textView)
            }
            return false
        }
        
        func textView(_ textView: NSTextView, shouldChangeTextIn affectedCharRange: NSRange, replacementString: String?) -> Bool {
            // Handle Command+K shortcut
            if let event = NSApp.currentEvent,
               event.type == .keyDown,
               event.modifierFlags.contains(.command),
               event.charactersIgnoringModifiers == "k" {
                showHyperlinkDialog()
                return false
            }
            
            // Check if user is pasting a URL when text is selected
            guard let replacementString = replacementString,
                  affectedCharRange.length > 0,
                  isValidURL(replacementString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                return true
            }
            
            // User is pasting a URL over selected text - create hyperlink
            let selectedText = (textView.string as NSString).substring(with: affectedCharRange)
            createHyperlink(text: selectedText, url: replacementString.trimmingCharacters(in: .whitespacesAndNewlines), range: affectedCharRange)
            
            // Update parent binding
            parent.attributedText = textView.attributedString()
            parent.plainText = textView.attributedString().string
            
            return false // We handled the change
        }
        
        // MARK: - Image Pasting Support
        func textView(_ textView: NSTextView, shouldChangeTextInRanges affectedRanges: [NSValue], replacementStrings: [String]?) -> Bool {
            // This method is called for multiple range replacements
            return true // Let the system handle normal text operations
        }
        
        func handleImagePaste(textView: NSTextView, affectedRanges: [NSValue]) {
            print("DEBUG: handleImagePaste called")
            let pasteboard = NSPasteboard.general
            
            // Try to get image data from pasteboard
            var imageData: Data?
            var imageType = "png"
            
            print("DEBUG: Checking for TIFF data")
            if let tiffData = pasteboard.data(forType: .tiff) {
                print("DEBUG: Found TIFF data, converting to PNG")
                // Convert TIFF to PNG for better compatibility
                if let image = NSImage(data: tiffData),
                   let pngData = image.pngData() {
                    imageData = pngData
                    imageType = "png"
                    print("DEBUG: Successfully converted TIFF to PNG")
                } else {
                    print("DEBUG: Failed to convert TIFF to PNG")
                }
            } else if let pngData = pasteboard.data(forType: .png) {
                print("DEBUG: Found PNG data directly")
                imageData = pngData
                imageType = "png"
            } else {
                print("DEBUG: No image data found")
            }
            
            guard let data = imageData else {
                print("DEBUG: No image data to process")
                return
            }
            
            print("DEBUG: Image data size: \(data.count) bytes")
            
            // Save image to temporary location or app support directory
            if let savedImagePath = saveImageToAppDirectory(data: data, type: imageType) {
                print("DEBUG: Image saved to: \(savedImagePath)")
                // Insert image reference at paste location
                let insertionRange = affectedRanges.first?.rangeValue ?? NSRange(location: textView.selectedRange().location, length: 0)
                insertImageReference(at: insertionRange, imagePath: savedImagePath, textView: textView)
            } else {
                print("DEBUG: Failed to save image")
            }
        }
        
        func saveImageToAppDirectory(data: Data, type: String) -> String? {
            // Create images directory in app support
            guard let appSupportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                return nil
            }
            
            let archieDir = appSupportDir.appendingPathComponent("Archie")
            let imagesDir = archieDir.appendingPathComponent("Images")
            
            // Create directories if they don't exist
            try? FileManager.default.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            
            // Generate unique filename
            let filename = "image_\(UUID().uuidString).\(type)"
            let imageURL = imagesDir.appendingPathComponent(filename)
            
            do {
                try data.write(to: imageURL)
                return imageURL.path
            } catch {
                print("Failed to save image: \(error)")
                return nil
            }
        }
        
        func insertImageReference(at range: NSRange, imagePath: String, textView: NSTextView) {
            // Create image attachment
            let attachment = NSTextAttachment()
            
            // Load and resize image for display
            if let image = NSImage(contentsOfFile: imagePath) {
                // Resize image to reasonable size for text editor
                let maxWidth: CGFloat = 300
                let maxHeight: CGFloat = 200
                
                let imageSize = image.size
                var newSize = imageSize
                
                if imageSize.width > maxWidth || imageSize.height > maxHeight {
                    let widthRatio = maxWidth / imageSize.width
                    let heightRatio = maxHeight / imageSize.height
                    let ratio = min(widthRatio, heightRatio)
                    
                    newSize = CGSize(width: imageSize.width * ratio, height: imageSize.height * ratio)
                }
                
                // Create resized image
                let resizedImage = NSImage(size: newSize)
                resizedImage.lockFocus()
                image.draw(in: NSRect(origin: .zero, size: newSize))
                resizedImage.unlockFocus()
                
                attachment.image = resizedImage
            }
            
            // Fix: Don't create file wrapper - just use the image directly
            // The error was caused by creating a file wrapper without a filename
            
            // Create attributed string with attachment
            let attachmentString = NSAttributedString(attachment: attachment)
            
            // Insert the image
            textView.textStorage?.replaceCharacters(in: range, with: attachmentString)
            
            // Update parent binding
            parent.attributedText = textView.attributedString()
            parent.plainText = textView.attributedString().string
        }
        
        private func isValidURL(_ string: String) -> Bool {
            // Check if string is a valid URL
            if let url = URL(string: string) {
                return url.scheme != nil && (url.scheme == "http" || url.scheme == "https" || url.scheme == "mailto" || url.scheme == "ftp")
            }
            
            // Check if it's a URL without scheme
            if string.contains(".") && (string.hasPrefix("www.") || string.contains("@")) {
                return true
            }
            
            return false
        }
        
        private func createHyperlink(text: String, url: String, range: NSRange) {
            guard let textView = textView else { return }
            
            // Ensure URL has a scheme
            var finalURL = url
            if !url.hasPrefix("http://") && !url.hasPrefix("https://") && !url.hasPrefix("mailto:") {
                if url.contains("@") {
                    finalURL = "mailto:\(url)"
                } else {
                    finalURL = "https://\(url)"
                }
            }
            
            // Create attributed string with link
            let linkAttributes: [NSAttributedString.Key: Any] = [
                .link: finalURL,
                .foregroundColor: NSColor.systemBlue,
                .underlineStyle: NSUnderlineStyle.single.rawValue,
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize)
            ]
            
            let linkAttributedString = NSAttributedString(string: text, attributes: linkAttributes)
            
            // Replace the text with the hyperlink
            textView.textStorage?.replaceCharacters(in: range, with: linkAttributedString)
        }
        
        private func showHyperlinkDialog() {
            guard let textView = textView else { return }
            
            let selectedRange = textView.selectedRange()
            guard selectedRange.length > 0 else {
                // No text selected, show alert
                showNoTextSelectedAlert()
                return
            }
            
            let selectedText = (textView.string as NSString).substring(with: selectedRange)
            
            // Show URL input dialog
            showURLInputDialog(for: selectedText, range: selectedRange)
        }
        
        private func showNoTextSelectedAlert() {
            let alert = NSAlert()
            alert.messageText = "No Text Selected"
            alert.informativeText = "Please select the text you want to turn into a hyperlink first."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
        
        private func showURLInputDialog(for text: String, range: NSRange) {
            let alert = NSAlert()
            alert.messageText = "Add Hyperlink"
            alert.informativeText = "Enter the URL for '\(text)'"
            alert.alertStyle = .informational
            
            // Create input field
            let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
            inputField.placeholderString = "https://example.com"
            alert.accessoryView = inputField
            
            alert.addButton(withTitle: "Add Link")
            alert.addButton(withTitle: "Cancel")
            
            // Focus the input field
            alert.window.initialFirstResponder = inputField
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                let urlString = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !urlString.isEmpty {
                    if isValidURL(urlString) || urlString.contains(".") {
                        createHyperlink(text: text, url: urlString, range: range)
                        
                        // Update parent binding
                        parent.attributedText = textView?.attributedString() ?? NSAttributedString()
                        parent.plainText = textView?.attributedString().string ?? ""
                    } else {
                        showInvalidURLAlert()
                    }
                }
            }
        }
        
        private func showInvalidURLAlert() {
            let alert = NSAlert()
            alert.messageText = "Invalid URL"
            alert.informativeText = "Please enter a valid URL (e.g., https://example.com)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}

// MARK: - Newline Handling 100604
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

// MARK: - Formatting Methods 100605
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

// MARK: - List Methods 100606
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
            // Text is selected - show URL input dialog
            let selectedText = (textView.string as NSString).substring(with: selectedRange)
            showURLInputDialog(for: selectedText, range: selectedRange)
        } else {
            // No text selected - insert placeholder link
            let linkText = "[link text](url)"
            textView.insertText(linkText, replacementRange: selectedRange)
            
            // Update parent binding
            parent.attributedText = textView.attributedString()
            parent.plainText = textView.attributedString().string
        }
    }
    
    func insertImage() {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange()
        
        // Show file picker to select image
        showImageFilePicker(insertionRange: selectedRange)
    }
    
    private func showImageFilePicker(insertionRange: NSRange) {
        print("DEBUG: showImageFilePicker called")
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Image"
        openPanel.message = "Choose an image to insert into your snippet"
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.image, .png, .jpeg, .gif, .tiff, .bmp, .heic, .webP]
        
        let response = openPanel.runModal()
        print("DEBUG: File picker response: \(response.rawValue)")
        
        if response == .OK {
            guard let selectedURL = openPanel.url else {
                print("DEBUG: No URL selected")
                return
            }
            
            print("DEBUG: Selected file: \(selectedURL.path)")
            
            // Copy image to app directory and insert reference
            if let imageData = try? Data(contentsOf: selectedURL) {
                print("DEBUG: Loaded image data: \(imageData.count) bytes")
                let fileExtension = selectedURL.pathExtension.lowercased()
                if let savedImagePath = saveImageToAppDirectory(data: imageData, type: fileExtension.isEmpty ? "png" : fileExtension) {
                    print("DEBUG: Image saved to: \(savedImagePath)")
                    insertImageReference(at: insertionRange, imagePath: savedImagePath, textView: textView!)
                } else {
                    print("DEBUG: Failed to save image")
                }
            } else {
                print("DEBUG: Failed to load image data from URL")
            }
        }
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

// MARK: - NSImage Extension for PNG Data 100607
extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}
