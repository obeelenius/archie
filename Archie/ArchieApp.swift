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
            CommandGroup(after: .appInfo) {
                Divider()
                
                Button("Snippets") {
                    appDelegate.openSnippetsView()
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Collections") {
                    appDelegate.openCollectionsView()
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Settings") {
                    appDelegate.openSettingsWindow()
                }
                .keyboardShortcut(",", modifiers: .command)
                
                Divider()
            }
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
            // Use AppIcon asset - it contains all sizes including 16x16 and 32x32 for menu bar
            if let appIcon = NSImage(named: "AppIcon") {
                // Create a copy and resize for menu bar
                let menuBarIcon = appIcon.copy() as! NSImage
                menuBarIcon.size = NSSize(width: 18, height: 18)
                button.image = menuBarIcon
            } else {
                // Fallback to system symbol if AppIcon not found
                button.image = NSImage(systemSymbolName: "text.cursor", accessibilityDescription: "Archie")
            }
        }
    
    private func setupMenu() {
            let menu = NSMenu()
            
            menu.addItem(NSMenuItem(title: "Snippets", action: #selector(openSnippets), keyEquivalent: "1"))
            menu.addItem(NSMenuItem(title: "Collections", action: #selector(openCollections), keyEquivalent: "2"))
            menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit Archie", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
            
            statusBarItem?.menu = menu
        }
        
        @objc private func menuBarClicked() {
            statusBarItem?.menu?.popUp(positioning: nil, at: NSPoint.zero, in: statusBarItem?.button)
        }
        
        @objc private func openSnippets() {
            openSnippetsView()
        }
        
        @objc private func openCollections() {
            openCollectionsView()
        }
        
        @objc private func openSettings() {
            openSettingsWindow()
        }
}

// MARK: - Window Management 100077
extension AppDelegate {
    func openSnippetsView() {
        openWindow(selectedTab: .snippets)
    }
    
    func openCollectionsView() {
        openWindow(selectedTab: .collections)
    }
    
    func openSettingsWindow() {
        openWindow(selectedTab: .settings)
    }
    
    private func openWindow(selectedTab: SettingsView.MainView) {
        // Activate the app first
        NSApp.activate(ignoringOtherApps: true)
        
        // Look for existing settings window
        for window in NSApp.windows {
            if window.title.contains("Archie Settings") {
                window.makeKeyAndOrderFront(nil)
                // Send notification to switch tabs
                NotificationCenter.default.post(
                    name: NSNotification.Name("SwitchToTab"),
                    object: selectedTab
                )
                return
            }
        }
        
        // If no window exists, create a new one
        DispatchQueue.main.async {
            self.createSettingsWindow(selectedTab: selectedTab)
        }
    }
    
    private func createSettingsWindow(selectedTab: SettingsView.MainView) {
        let settingsView = SettingsView(initialSelectedView: selectedTab)
        let hostingController = NSHostingController(rootView: settingsView)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 600),
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Archie Settings"
        window.contentViewController = hostingController
        window.center()
        window.setFrameAutosaveName("ArchieSettings")
        window.makeKeyAndOrderFront(nil)
        
        // Keep a reference to prevent the window from being deallocated
        objc_setAssociatedObject(self, "settingsWindow", window, .OBJC_ASSOCIATION_RETAIN)
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
