import SwiftUI
import Cocoa

@main
struct ArchieApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var eventMonitor: EventMonitor?
    var snippetManager = SnippetManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupEventMonitoring()
        
        // Show in both dock and menu bar
        NSApp.setActivationPolicy(.regular)
        
        // Set the dock icon to use our custom app icon at high resolution
        if let appIcon = NSImage(named: "AppIcon") {
            // Force high resolution for dock
            appIcon.size = NSSize(width: 512, height: 512)
            NSApp.applicationIconImage = appIcon
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When dock icon is clicked, open preferences using modern approach
        Task { @MainActor in
            NSApp.activate(ignoringOtherApps: true)
            NSApp.keyWindow?.makeKeyAndOrderFront(nil)
        }
        return true
    }
    
    private func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            // Try to use custom app icon first, fallback to system symbol
            if let appIcon = NSImage(named: "AppIcon") {
                button.image = appIcon
                // Resize for menu bar (typically 22x22 points)
                appIcon.size = NSSize(width: 22, height: 22)
            } else {
                button.image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: "Archie")
            }
            button.action = #selector(menuBarClicked)
            button.target = self
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // Create a SwiftUI-based menu item for preferences
        let preferencesItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        menu.addItem(preferencesItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Archie", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    @objc private func menuBarClicked() {
        statusBarItem?.menu?.popUp(positioning: nil, at: NSPoint.zero, in: statusBarItem?.button)
    }
    
    @objc private func openPreferences() {
        // Open settings using keyboard shortcut (Cmd+,) which SwiftUI handles natively
        let event = NSEvent.keyEvent(with: .keyDown,
                                   location: NSPoint.zero,
                                   modifierFlags: .command,
                                   timestamp: 0,
                                   windowNumber: 0,
                                   context: nil,
                                   characters: ",",
                                   charactersIgnoringModifiers: ",",
                                   isARepeat: false,
                                   keyCode: 43)
        
        if let event = event {
            NSApp.sendEvent(event)
        }
        
        NSApp.activate(ignoringOtherApps: true)
    }
    
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
        alert.informativeText = "Archie needs accessibility permission to monitor keystrokes and expand text. Please grant permission in System Preferences > Security & Privacy > Accessibility."
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}
