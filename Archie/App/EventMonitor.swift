// EventMonitor.swift

import Cocoa
import Carbon

// MARK: - Event Monitor Class 100079
class EventMonitor: ObservableObject {
    private var monitor: Any?
    private var typedBuffer = ""
    private let snippetManager = SnippetManager.shared
    
    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.handleKeyEvent(event)
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
        
        // Add character to buffer first
        if char.count == 1 && !char.isEmpty {
            addCharacterToBuffer(char)
        }
        
        // Check for instant expansion (snippets that don't require space)
        checkForInstantExpansion()
        
        // Handle space or return - potential trigger for space-required snippets
        if char == " " || char == "\r" || char == "\n" {
            handleTriggerKey(delimiter: char)
            return
        }
    }
    
    private func handleBackspaceKey() {
        if !typedBuffer.isEmpty {
            typedBuffer.removeLast()
            print("DEBUG: Buffer after backspace: '\(typedBuffer)'")
        }
    }
    
    private func handleTriggerKey(delimiter: String) {
        print("DEBUG: Space trigger - buffer before space: '\(typedBuffer)', delimiter: '\(delimiter)'")
        // Remove the delimiter character we just added to buffer
        if !typedBuffer.isEmpty && typedBuffer.last == Character(delimiter) {
            typedBuffer.removeLast()
        }
        checkForSpaceTriggeredSnippets(delimiter: delimiter)
        typedBuffer = ""
    }
    
    private func addCharacterToBuffer(_ char: String) {
        typedBuffer += char
        print("DEBUG: Added '\(char)' to buffer: '\(typedBuffer)'")
        
        // Keep buffer reasonable size
        if typedBuffer.count > 50 {
            typedBuffer = String(typedBuffer.suffix(25))
        }
    }
    
    private func checkForInstantExpansion() {
        // Check for snippets that don't require space (instant expansion)
        for snippet in snippetManager.snippets.filter({ $0.isEnabled && !$0.requiresSpace }) {
            if typedBuffer.hasSuffix(snippet.shortcut) {
                print("DEBUG: Found instant expansion for '\(snippet.shortcut)' -> '\(snippet.expansion)'")
                performTextReplacement(
                    shortcut: snippet.shortcut,
                    expansion: snippet.processedExpansion(),
                    keepDelimiter: false,
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
                        print("DEBUG: Found instant collection expansion for '\(fullShortcut)' -> '\(snippet.expansion)'")
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
            print("DEBUG: Checking space-triggered snippets for buffer: '\(typedBuffer)'")
            
            // Check for exact shortcut matches that require space
            for snippet in snippetManager.snippets.filter({ $0.isEnabled && $0.requiresSpace }) {
                if snippet.shortcut == typedBuffer {
                    print("DEBUG: Found space-triggered match for '\(typedBuffer)' -> '\(snippet.expansion)', keepDelimiter: \(snippet.keepDelimiter)")
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
                            print("DEBUG: Found space-triggered collection match for '\(baseShortcut)' in '\(collection.name)' -> '\(snippet.expansion)'")
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
            
            print("DEBUG: No space-triggered snippet match found for '\(typedBuffer)'")
        }
}

// MARK: - Text Replacement 100082
extension EventMonitor {
    private func performTextReplacement(shortcut: String, expansion: String, keepDelimiter: Bool, delimiter: String, isInstant: Bool) {
        print("DEBUG: Performing replacement - shortcut: '\(shortcut)', expansion: '\(expansion)', delimiter: '\(delimiter)', instant: \(isInstant), keepDelimiter: \(keepDelimiter)")
        
        if isInstant {
            // For instant expansion, just delete the shortcut
            deleteCharacters(count: shortcut.count)
        } else {
            // For space-triggered, delete shortcut + delimiter
            deleteTypedShortcutAndDelimiter(shortcut: shortcut, delimiter: delimiter)
        }
        
        // Insert the expansion
        var finalText = expansion
        if keepDelimiter && !delimiter.isEmpty {
            finalText += delimiter
        }
        
        print("DEBUG: Inserting final text: '\(finalText)'")
        insertText(finalText)
    }
    
    private func deleteTypedShortcutAndDelimiter(shortcut: String, delimiter: String) {
        let totalCharactersToDelete = shortcut.count + delimiter.count
        print("DEBUG: Deleting \(totalCharactersToDelete) characters (\(shortcut.count) shortcut + \(delimiter.count) delimiter)")
        deleteCharacters(count: totalCharactersToDelete)
    }
    
    private func deleteCharacters(count: Int) {
        for i in 0..<count {
            print("DEBUG: Sending backspace \(i+1)/\(count)")
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
        print("DEBUG INSERT: About to insert text: '\(text)'")
        
        // Save current pasteboard contents
        let pasteboard = NSPasteboard.general
        let originalContents = pasteboard.string(forType: .string)
        print("DEBUG INSERT: Saved original clipboard: '\(originalContents ?? "nil")'")
        
        // Clear pasteboard and set our text
        pasteboard.clearContents()
        let success = pasteboard.setString(text, forType: .string)
        print("DEBUG INSERT: Set clipboard to '\(text)', success: \(success)")
        
        // Verify the clipboard was set correctly
        let verifyText = pasteboard.string(forType: .string)
        print("DEBUG INSERT: Verified clipboard contains: '\(verifyText ?? "nil")'")
        
        // Small delay to ensure clipboard is ready
        usleep(10000) // 10ms delay
        
        // Simulate Cmd+V
        print("DEBUG INSERT: Simulating Cmd+V")
        simulatePasteCommand()
        
        // Restore original pasteboard contents after a longer delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("DEBUG INSERT: Restoring original clipboard: '\(originalContents ?? "nil")'")
            pasteboard.clearContents()
            if let original = originalContents {
                pasteboard.setString(original, forType: .string)
            }
            print("DEBUG INSERT: Clipboard restoration complete")
        }
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
