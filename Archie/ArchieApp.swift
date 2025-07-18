// ArchieApp.swift

import SwiftUI
import Cocoa

// MARK: - Main App Structure 100073
@main
struct ArchieApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup("Archie Settings") {
            SettingsView()
                .frame(minWidth: 900, minHeight: 600)
        }
        .windowStyle(.automatic)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
}

// MARK: - App Delegate 100074
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem?
    var eventMonitor: EventMonitor?
    var snippetManager = SnippetManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupEventMonitoring()
        setupAppIcons()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When dock icon is clicked, open preferences
        print("Dock icon clicked!") // Debug output
        DispatchQueue.main.async {
            self.openSettingsWindow()
        }
        return true
    }
}

// MARK: - App Icon Setup 100075
extension AppDelegate {
    private func setupAppIcons() {
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
}

// MARK: - Menu Bar Setup 100076
extension AppDelegate {
    private func setupMenuBar() {
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusBarItem?.button {
            configureMenuBarButton(button)
            button.action = #selector(menuBarClicked)
            button.target = self
        }
        
        setupMenu()
    }
    
    private func configureMenuBarButton(_ button: NSStatusBarButton) {
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
}

// MARK: - Window Management 100077
extension AppDelegate {
    private func openSettingsWindow() {
        // Look for existing settings window
        for window in NSApp.windows {
            if window.title.contains("Archie Settings") {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
                return
            }
        }
        
        // If no window found, create new one by opening a new window
        if (NSApp.windows.first?.windowController) != nil {
            // Try to open new window
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // Fallback: activate app which should show the window
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

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
        alert.informativeText = "Archie needs accessibility permission to monitor keystrokes and expand text. Please grant permission in System Preferences > Security & Privacy > Accessibility."
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}
