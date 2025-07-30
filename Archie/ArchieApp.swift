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
    
    // Track the last viewed tab for proper restoration
    @AppStorage("lastViewedTab") private var lastViewedTabRaw = SettingsView.MainView.snippets.rawValue
    
    private var lastViewedTab: SettingsView.MainView {
        get { SettingsView.MainView(rawValue: lastViewedTabRaw) ?? .snippets }
        set { lastViewedTabRaw = newValue.rawValue }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupEventMonitoring()
        setupAppIcons()
        
        // Listen for tab changes to track current view
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTabChange(_:)),
            name: NSNotification.Name("TabChanged"),
            object: nil
        )
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // When dock icon is clicked, reopen to the last viewed tab
        print("Dock icon clicked! Reopening to last viewed tab: \(lastViewedTab)")
        DispatchQueue.main.async {
            self.openWindow(selectedTab: self.lastViewedTab)
        }
        return true
    }
    
    @objc private func handleTabChange(_ notification: Notification) {
        if let newTab = notification.object as? SettingsView.MainView {
            lastViewedTab = newTab
            print("Tab changed to: \(newTab), saved to preferences")
        }
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
        lastViewedTab = .snippets
        openWindow(selectedTab: .snippets)
    }
    
    func openCollectionsView() {
        lastViewedTab = .collections
        openWindow(selectedTab: .collections)
    }
    
    func openSettingsWindow() {
        lastViewedTab = .general
        openWindow(selectedTab: .general)
    }
    
    private func openWindow(selectedTab: SettingsView.MainView) {
        // Update the last viewed tab
        lastViewedTab = selectedTab
        
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
        if !AXIsProcessTrusted() {
            // Request permissions with system prompt - this works perfectly
            _ = AXIsProcessTrustedWithOptions([
                kAXTrustedCheckOptionPrompt.takeRetainedValue(): true
            ] as CFDictionary)
        }
        
        // Always start monitoring
        eventMonitor?.start()
    }
}
