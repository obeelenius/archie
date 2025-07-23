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
        setupMainMenu()
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
        
        menu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit Archie", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        statusBarItem?.menu = menu
    }
    
    @objc private func menuBarClicked() {
        statusBarItem?.menu?.popUp(positioning: nil, at: NSPoint.zero, in: statusBarItem?.button)
    }
    
    @objc private func openSettings() {
        openSettingsWindow()
    }
}

// MARK: - Window Management 100077
extension AppDelegate {
    private func openSettingsWindow() {
        // Activate the app first
        NSApp.activate(ignoringOtherApps: true)
        
        // Look for existing settings window
        for window in NSApp.windows {
            if window.title.contains("Archie Settings") {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
        
        // If no window exists, create a new one using NSWindow directly
        DispatchQueue.main.async {
            self.createSettingsWindow()
        }
    }
    
    private func createSettingsWindow() {
        let settingsView = SettingsView()
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
        // Note: In a production app, you'd want to manage this reference properly
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
        alert.informativeText = "Archie needs accessibility permission to monitor keystrokes and expand text. Please grant permission in System Preferences > Security & Privacy > Accessibility."
        alert.addButton(withTitle: "Open System Preferences")
        alert.addButton(withTitle: "Cancel")
        
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
        }
    }
}

// MARK: - Main Menu Setup 100079
extension AppDelegate {
    private func setupMainMenu() {
        let mainMenu = NSMenu()
        
        // Archie menu (first menu item)
        let appMenuItem = NSMenuItem()
        appMenuItem.title = "Archie"
        let appMenu = NSMenu(title: "Archie")
        
        appMenu.addItem(NSMenuItem(title: "About Archie", action: #selector(showAbout), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ","))
        appMenu.addItem(NSMenuItem.separator())
        
        // Services submenu
        let servicesItem = NSMenuItem(title: "Services", action: nil, keyEquivalent: "")
        let servicesMenu = NSMenu(title: "Services")
        appMenu.setSubmenu(servicesMenu, for: servicesItem)
        appMenu.addItem(servicesItem)
        NSApp.servicesMenu = servicesMenu
        
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Hide Archie", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        
        let hideOthersItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        
        appMenu.addItem(NSMenuItem(title: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: ""))
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(NSMenuItem(title: "Quit Archie", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // Set the target for menu items that need it
        for item in appMenu.items {
            if item.action == #selector(showAbout) || item.action == #selector(openSettings) {
                item.target = self
            }
        }
        
        NSApp.mainMenu = mainMenu
    }
    
    @objc private func showAbout() {
        NSApp.orderFrontStandardAboutPanel(nil)
    }
}
