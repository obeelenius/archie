import Cocoa
import Carbon

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
    
    private func handleKeyEvent(_ event: NSEvent) {
        let char = event.charactersIgnoringModifiers ?? ""
        
        // Handle backspace
        if event.keyCode == 51 { // Delete key
            if !typedBuffer.isEmpty {
                typedBuffer.removeLast()
            }
            return
        }
        
        // Handle space or return - potential trigger
        if char == " " || char == "\r" || char == "\n" {
            checkForSnippetMatch()
            typedBuffer = ""
            return
        }
        
        // Add character to buffer
        if char.count == 1 && char.rangeOfCharacter(from: .alphanumerics) != nil {
            typedBuffer += char
            
            // Keep buffer reasonable size
            if typedBuffer.count > 50 {
                typedBuffer = String(typedBuffer.suffix(25))
            }
        }
    }
    
    private func checkForSnippetMatch() {
        if let expansion = snippetManager.getExpansion(for: typedBuffer) {
            performTextReplacement(shortcut: typedBuffer, expansion: expansion)
        }
    }
    
    private func performTextReplacement(shortcut: String, expansion: String) {
        // Delete the typed shortcut
        for _ in 0..<shortcut.count {
            simulateKeyPress(keyCode: 51) // Backspace
        }
        
        // Insert the expansion
        insertText(expansion)
    }
    
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
        let cmdVDown = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true) // V key
        let cmdVUp = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false)
        
        cmdVDown?.flags = .maskCommand
        cmdVUp?.flags = .maskCommand
        
        cmdVDown?.post(tap: .cghidEventTap)
        cmdVUp?.post(tap: .cghidEventTap)
        
        // Restore original pasteboard contents after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let original = originalContents {
                pasteboard.clearContents()
                pasteboard.setString(original, forType: .string)
            }
        }
    }
}