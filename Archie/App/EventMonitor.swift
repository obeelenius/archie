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
        
        // Handle space or return - potential trigger
        if char == " " || char == "\r" || char == "\n" {
            handleTriggerKey(delimiter: char)
            return
        }
        
        // Add character to buffer (including special characters for collection suffixes)
        if char.count == 1 {
            addCharacterToBuffer(char)
        }
    }
    
    private func handleBackspaceKey() {
        if !typedBuffer.isEmpty {
            typedBuffer.removeLast()
        }
    }
    
    private func handleTriggerKey(delimiter: String) {
        checkForSnippetMatch(delimiter: delimiter)
        typedBuffer = ""
    }
    
    private func addCharacterToBuffer(_ char: String) {
        typedBuffer += char
        
        // Keep buffer reasonable size
        if typedBuffer.count > 50 {
            typedBuffer = String(typedBuffer.suffix(25))
        }
    }
}

// MARK: - Snippet Matching 100081
extension EventMonitor {
    private func checkForSnippetMatch(delimiter: String) {
        // Check for matches with different possible suffix combinations
        var potentialShortcuts: [String] = [typedBuffer]
        
        // Add variations with collection suffixes
        addCollectionSuffixVariations(&potentialShortcuts)
        
        // Try to find a matching snippet
        for shortcut in potentialShortcuts {
            if let expansion = snippetManager.getExpansion(for: shortcut) {
                // Find the collection to check keep delimiter setting
                let collection = findCollectionForShortcut(shortcut)
                let keepDelimiter = collection?.keepDelimiter ?? false
                
                performTextReplacement(
                    shortcut: shortcut,
                    expansion: expansion,
                    keepDelimiter: keepDelimiter,
                    delimiter: delimiter
                )
                return
            }
        }
    }
    
    private func addCollectionSuffixVariations(_ potentialShortcuts: inout [String]) {
        for collection in snippetManager.collections.filter({ $0.isEnabled }) {
            if !collection.suffix.isEmpty && typedBuffer.hasSuffix(collection.suffix) {
                let baseShortcut = String(typedBuffer.dropLast(collection.suffix.count))
                potentialShortcuts.append(baseShortcut + collection.suffix)
            }
        }
    }
    
    private func findCollectionForShortcut(_ shortcut: String) -> SnippetCollection? {
        for collection in snippetManager.collections {
            let collectionSnippets = snippetManager.snippets(for: collection)
            for snippet in collectionSnippets {
                if snippet.fullShortcut(with: collection) == shortcut {
                    return collection
                }
            }
        }
        return nil
    }
}

// MARK: - Text Replacement 100082
extension EventMonitor {
    private func performTextReplacement(shortcut: String, expansion: String, keepDelimiter: Bool, delimiter: String) {
        // Delete the typed shortcut
        deleteTypedShortcut(shortcut)
        
        // Insert the expansion
        var finalText = expansion
        if keepDelimiter {
            finalText += delimiter
        }
        
        insertText(finalText)
    }
    
    private func deleteTypedShortcut(_ shortcut: String) {
        for _ in 0..<shortcut.count {
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
        // Copy to pasteboard and paste
        let pasteboard = NSPasteboard.general
        let originalContents = pasteboard.string(forType: .string)
        
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Simulate Cmd+V
        simulatePasteCommand()
        
        // Restore original pasteboard contents after a delay
        restoreOriginalPasteboardContents(originalContents)
    }
    
    private func simulatePasteCommand() {
        let cmdVDown = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true) // V key
        let cmdVUp = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false)
        
        cmdVDown?.flags = .maskCommand
        cmdVUp?.flags = .maskCommand
        
        cmdVDown?.post(tap: .cghidEventTap)
        cmdVUp?.post(tap: .cghidEventTap)
    }
    
    private func restoreOriginalPasteboardContents(_ originalContents: String?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let original = originalContents {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(original, forType: .string)
            }
        }
    }
}
