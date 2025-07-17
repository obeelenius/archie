import SwiftUI
import Cocoa

@main
struct ArchieApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 600)
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
        
        // Set the dock icon to use our custom dock icon at high resolution
        if let dockIcon = NSImage(named: "DockIcon") {
            // Force high resolution for dock
            dockIcon.size = NSSize(width: 512, height: 512)
            NSApp.applicationIconImage = dockIcon
        } else if let appIcon = NSImage(named: "AppIcon") {
            // Fallback to AppIcon if DockIcon doesn't exist
            appIcon.size = NSSize(width: 512, height: 512)
            NSApp.applicationIconImage = appIcon
        }
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When dock icon is clicked, open preferences
        print("Dock icon clicked!") // Debug output
        DispatchQueue.main.async {
            self.openSettingsWindow()
        }
        return true
    }
    
    private func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            // Use dedicated menu bar icon if available, otherwise fallback to app icon or system symbol
            if let menuBarIcon = NSImage(named: "MenuBarIcon") {
                menuBarIcon.size = NSSize(width: 18, height: 18)
                button.image = menuBarIcon
            } else if let appIcon = NSImage(named: "AppIcon") {
                // Create a copy for menu bar with proper size
                let resizedAppIcon = appIcon.copy() as! NSImage
                resizedAppIcon.size = NSSize(width: 18, height: 18)
                button.image = resizedAppIcon
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
        
        menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Archie", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    @objc private func menuBarClicked() {
        statusBarItem?.menu?.popUp(positioning: nil, at: NSPoint.zero, in: statusBarItem?.button)
    }
    
    @objc private func openPreferences() {
        openSettingsWindow()
    }
    
    private func openSettingsWindow() {
        print("Attempting to open settings window") // Debug output
        
        // First try to find and bring existing settings window to front
        for window in NSApp.windows {
            print("Found window: \(window.title)") // Debug output
            if window.title.contains("Settings") || window.title.contains("Preferences") || window.title.contains("Archie") {
                print("Bringing existing window to front")
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        
        print("No existing window found, creating new one")
        
        // Use keyboard shortcut approach that works reliably
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
