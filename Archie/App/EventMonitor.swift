// EventMonitor.swift

import Cocoa
import Carbon

// MARK: - Event Monitoring Setup 100078
extension AppDelegate {
    private func setupEventMonitoring() {
        eventMonitor = EventMonitor()
        
        // Check for accessibility permissions
        if !AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeRetainedValue(): true] as CFDictionary) {
            showPermissionAlert()
        } else {
            eventMonitor?.start()
        }
    }
    
    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = """
        Archie requires accessibility permission to function as a text expansion tool.
        
        This permission allows Archie to:
        • Monitor when you type text shortcuts (like "addr" or "@@")
        • Automatically replace shortcuts with their full text expansions
        • Work seamlessly across all applications on your Mac
        
        Archie only monitors for your predefined shortcuts and does not store, transmit, or access any other typed content. All text expansion happens locally on your device.
        
        Please grant permission in System Settings > Privacy & Security > Accessibility.
        """
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}

// MARK: - Event Monitor Class 100079
class EventMonitor: ObservableObject {
    private var monitor: Any?
    private var typedBuffer = ""
    private let snippetManager = SnippetManager.shared
    
    func start() {
        // Always try to start the event monitor
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Only process events if we have accessibility permissions
            if AXIsProcessTrusted() {
                self?.handleKeyEvent(event)
            }
        }
    }
    
    func stop() {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}

// MARK: - Key Event Handling 100080
extension EventMonitor {
    private func handleKeyEvent(_ event: NSEvent) {
        let char = event.charactersIgnoringModifiers ?? ""
        
        // Handle backspace
        if event.keyCode == 51 { // Delete key
            handleBackspaceKey()
            return
        }
        
        // Handle space or return BEFORE adding to buffer - potential trigger for space-required snippets
        if char == " " || char == "\r" || char == "\n" {
            handleTriggerKey(delimiter: char)
            return
        }
        
        // Add character to buffer (only for non-space characters)
        if char.count == 1 && !char.isEmpty {
            addCharacterToBuffer(char)
        }
        
        // Check for instant expansion (snippets that don't require space)
        checkForInstantExpansion()
    }
    
    private func handleBackspaceKey() {
        if !typedBuffer.isEmpty {
            typedBuffer.removeLast()
        }
    }
    
    private func handleTriggerKey(delimiter: String) {
        // Remove the delimiter character we just added to buffer
        if !typedBuffer.isEmpty && typedBuffer.last == Character(delimiter) {
            typedBuffer.removeLast()
        }
        checkForSpaceTriggeredSnippets(delimiter: delimiter)
        typedBuffer = ""
    }
    
    private func addCharacterToBuffer(_ char: String) {
        typedBuffer += char
        
        // Keep buffer reasonable size
        if typedBuffer.count > 50 {
            typedBuffer = String(typedBuffer.suffix(25))
        }
    }
    
    private func checkForInstantExpansion() {
        // Check for snippets that don't require space (instant expansion)
        for snippet in snippetManager.snippets.filter({ $0.isEnabled && !$0.requiresSpace }) {
            if typedBuffer.hasSuffix(snippet.shortcut) {
                performTextReplacement(
                    shortcut: snippet.shortcut,
                    expansion: snippet.processedExpansion(),
                    keepDelimiter: snippet.keepDelimiter,
                    delimiter: "",
                    isInstant: true
                )
                // Remove the shortcut from buffer
                typedBuffer = String(typedBuffer.dropLast(snippet.shortcut.count))
                return
            }
        }
        
        // Check for collection suffix instant expansions
        for collection in snippetManager.collections.filter({ $0.isEnabled && !$0.suffix.isEmpty }) {
            if typedBuffer.hasSuffix(collection.suffix) {
                let prefixWithoutSuffix = String(typedBuffer.dropLast(collection.suffix.count))
                let collectionSnippets = snippetManager.snippets(for: collection).filter { $0.isEnabled && !$0.requiresSpace }
                
                for snippet in collectionSnippets {
                    if prefixWithoutSuffix.hasSuffix(snippet.shortcut) {
                        let fullShortcut = snippet.shortcut + collection.suffix
                        performTextReplacement(
                            shortcut: fullShortcut,
                            expansion: snippet.processedExpansion(),
                            keepDelimiter: collection.keepDelimiter,
                            delimiter: "",
                            isInstant: true
                        )
                        // Remove the full shortcut from buffer
                        typedBuffer = String(typedBuffer.dropLast(fullShortcut.count))
                        return
                    }
                }
            }
        }
    }
    
    private func checkForSpaceTriggeredSnippets(delimiter: String) {
        // Check for exact shortcut matches that require space
        for snippet in snippetManager.snippets.filter({ $0.isEnabled && $0.requiresSpace }) {
            if snippet.shortcut == typedBuffer {
                performTextReplacement(
                    shortcut: typedBuffer,
                    expansion: snippet.processedExpansion(),
                    keepDelimiter: snippet.keepDelimiter,
                    delimiter: delimiter,
                    isInstant: false
                )
                return
            }
        }
        
        // Check for collection suffix matches that require space
        for collection in snippetManager.collections.filter({ $0.isEnabled && !$0.suffix.isEmpty }) {
            if typedBuffer.hasSuffix(collection.suffix) {
                let baseShortcut = String(typedBuffer.dropLast(collection.suffix.count))
                let collectionSnippets = snippetManager.snippets(for: collection).filter { $0.isEnabled && $0.requiresSpace }
                
                for snippet in collectionSnippets {
                    if snippet.shortcut == baseShortcut {
                        // For collection snippets, use collection's keepDelimiter setting
                        performTextReplacement(
                            shortcut: typedBuffer,
                            expansion: snippet.processedExpansion(),
                            keepDelimiter: collection.keepDelimiter,
                            delimiter: delimiter,
                            isInstant: false
                        )
                        return
                    }
                }
            }
        }
    }
}

// MARK: - Text Replacement 100082
extension EventMonitor {
    private func performTextReplacement(shortcut: String, expansion: String, keepDelimiter: Bool, delimiter: String, isInstant: Bool) {
        if isInstant {
            // For instant expansion, just delete the shortcut
            deleteCharacters(count: shortcut.count)
        } else {
            // For space-triggered, delete shortcut + delimiter
            deleteTypedShortcutAndDelimiter(shortcut: shortcut, delimiter: delimiter)
        }
        
        // Get the snippet to check for rich text
        let snippet = getSnippetForShortcut(shortcut)
        
        // Check if there's saved rich text data for this snippet
        var finalText = expansion
        var hasRichText = false
        
        if let snippet = snippet,
           let rtfData = UserDefaults.standard.data(forKey: "snippet_rtf_\(snippet.id.uuidString)"),
           let attributedText = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
            // Use rich text insertion
            insertRichText(attributedText, keepDelimiter: keepDelimiter, delimiter: delimiter)
            hasRichText = true
            print("DEBUG EXPANSION: Using rich text for snippet \(snippet.shortcut)")
        }
        
        if !hasRichText {
            // Fallback to plain text
            if keepDelimiter && !delimiter.isEmpty {
                finalText += delimiter
            }
            insertPlainText(finalText)
            print("DEBUG EXPANSION: Using plain text for shortcut \(shortcut)")
        }
        
        // Play sound feedback if enabled
        SoundManager.shared.playExpansionSound()
    }
    
    private func getSnippetForShortcut(_ shortcut: String) -> Snippet? {
        // Check all enabled collections and their snippets
        for collection in snippetManager.collections.filter({ $0.isEnabled }) {
            let collectionSnippets = snippetManager.snippets(for: collection).filter { $0.isEnabled }
            
            for snippet in collectionSnippets {
                let fullShortcut = snippet.fullShortcut(with: collection)
                if fullShortcut == shortcut {
                    return snippet
                }
            }
        }
        
        // Also check uncollected snippets
        let uncollectedSnippets = snippetManager.snippets.filter { $0.collectionId == nil && $0.isEnabled }
        for snippet in uncollectedSnippets {
            if snippet.shortcut == shortcut {
                return snippet
            }
        }
        
        return nil
    }
    
    private func deleteTypedShortcutAndDelimiter(shortcut: String, delimiter: String) {
        let totalCharactersToDelete = shortcut.count + delimiter.count
        deleteCharacters(count: totalCharactersToDelete)
    }
    
    private func deleteCharacters(count: Int) {
        for _ in 0..<count {
            simulateKeyPress(keyCode: 51) // Backspace
        }
    }
}

// MARK: - System Event Simulation 100083
extension EventMonitor {
    private func simulateKeyPress(keyCode: UInt16) {
        let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true)
        let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false)
        
        keyDownEvent?.post(tap: .cghidEventTap)
        keyUpEvent?.post(tap: .cghidEventTap)
    }
    
    private func insertText(_ text: String) {
        // Check if text contains rich formatting
        let richText = RichTextProcessor.shared.processRichText(text)
        let hasFormatting = richText.length > 0 && richText.string != text
        
        if hasFormatting {
            insertRichText(richText)
        } else {
            insertPlainText(text)
        }
    }
    
    private func insertPlainText(_ text: String) {
        // Save current pasteboard contents
        let pasteboard = NSPasteboard.general
        let originalContents = pasteboard.string(forType: .string)
        
        // Clear pasteboard and set our text
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Small delay to ensure clipboard is ready
        usleep(10000) // 10ms delay
        
        // Simulate Cmd+V
        simulatePasteCommand()
        
        // Restore original pasteboard contents after a longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            pasteboard.clearContents()
            if let original = originalContents {
                pasteboard.setString(original, forType: .string)
            }
        }
    }
    
    private func insertRichText(_ attributedString: NSAttributedString, keepDelimiter: Bool = false, delimiter: String = "") {
        // Add delimiter if needed
        let finalAttributedString: NSAttributedString
        if keepDelimiter && !delimiter.isEmpty {
            let mutableString = NSMutableAttributedString(attributedString: attributedString)
            let delimiterAttributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
                .foregroundColor: NSColor.labelColor
            ]
            mutableString.append(NSAttributedString(string: delimiter, attributes: delimiterAttributes))
            finalAttributedString = mutableString
        } else {
            finalAttributedString = attributedString
        }
        
        // Save current pasteboard contents
        let pasteboard = NSPasteboard.general
        let originalStringContents = pasteboard.string(forType: .string)
        let originalRTFContents = pasteboard.data(forType: .rtf)
        
        // Clear pasteboard and set our rich text
        pasteboard.clearContents()
        
        // Add both RTF and plain text representations
        if let rtfData = finalAttributedString.rtf(from: NSRange(location: 0, length: finalAttributedString.length), documentAttributes: [:]) {
            pasteboard.setData(rtfData, forType: .rtf)
            print("DEBUG RICH TEXT: Set RTF data on pasteboard")
        } else {
            print("DEBUG RICH TEXT: Failed to create RTF data")
        }
        pasteboard.setString(finalAttributedString.string, forType: .string)
        
        // Small delay to ensure clipboard is ready
        usleep(15000) // 15ms delay for rich text
        
        // Simulate Cmd+V
        simulatePasteCommand()
        
        // Restore original pasteboard contents after a longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            pasteboard.clearContents()
            if let originalRTF = originalRTFContents {
                pasteboard.setData(originalRTF, forType: .rtf)
            }
            if let originalString = originalStringContents {
                pasteboard.setString(originalString, forType: .string)
            }
        }
    }
    
    // Overloaded version without delimiter parameters for backward compatibility
    private func insertRichText(_ attributedString: NSAttributedString) {
        insertRichText(attributedString, keepDelimiter: false, delimiter: "")
    }
    
    private func simulatePasteCommand() {
        let cmdVDown = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true) // V key
        let cmdVUp = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false)
        
        cmdVDown?.flags = .maskCommand
        cmdVUp?.flags = .maskCommand
        
        cmdVDown?.post(tap: .cghidEventTap)
        usleep(5000) // 5ms delay between key down and up
        cmdVUp?.post(tap: .cghidEventTap)
    }
}
