//  GeneralSettingsContentView.swift

import SwiftUI

// MARK: - General Settings Content View 100112
struct GeneralSettingsContentView: View {
    @AppStorage("startAtLogin") private var startAtLogin = false
    @AppStorage("soundEnabled") private var soundEnabled = false
    @AppStorage("selectedExpansionSound") private var selectedExpansionSound = SoundManager.ExpansionSound.pop.rawValue
    @StateObject private var appExclusionManager = AppExclusionManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    startupSection
                    audioSection
                    appExclusionsSection
                    aboutSection
                }
                .padding(16)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        }
        .onChange(of: startAtLogin) { oldValue, newValue in
            SaveNotificationManager.shared.show("Settings saved")
        }
        .onChange(of: soundEnabled) { oldValue, newValue in
            SaveNotificationManager.shared.show("Settings saved")
        }
        .onChange(of: selectedExpansionSound) { oldValue, newValue in
            SaveNotificationManager.shared.show("Settings saved")
        }
    }
}

// MARK: - Startup Section 100113
extension GeneralSettingsContentView {
    private var startupSection: some View {
        SettingsSection(title: "Startup", icon: "power") {
            SettingsRow(
                title: "Start Archie at login",
                subtitle: "Automatically start when you log in to your Mac"
            ) {
                Toggle("", isOn: $startAtLogin)
                    .toggleStyle(ModernToggleStyle())
            }
        }
    }
}

// MARK: - Audio Section 100117
extension GeneralSettingsContentView {
    private var audioSection: some View {
        SettingsSection(title: "Audio", icon: "speaker.wave.2") {
            SettingsRow(
                title: "Play sound",
                subtitle: "Audio feedback when text is expanded"
            ) {
                Toggle("", isOn: $soundEnabled)
                    .toggleStyle(ModernToggleStyle())
            }
            
            if soundEnabled {
                soundSelectionRow
            }
        }
    }
    
    private var soundSelectionRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Sound")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Picker("Sound", selection: $selectedExpansionSound) {
                    ForEach(SoundManager.ExpansionSound.allCases, id: \.rawValue) { sound in
                        Text(sound.displayName)
                            .tag(sound.rawValue)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }
            
            HStack {
                Button("Preview") {
                    let sound = SoundManager.ExpansionSound(rawValue: selectedExpansionSound) ?? .pop
                    SoundManager.shared.previewSound(sound)
                }
                .font(.system(size: 12))
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.accentColor.opacity(0.1))
                        .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                )
                .foregroundColor(.accentColor)
                .buttonStyle(.plain)
                
                Spacer()
            }
        }
        .padding(.leading, 16)
        .padding(.top, 8)
        .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
        .animation(.easeInOut(duration: 0.2), value: soundEnabled)
    }
}

// MARK: - About Section 100115
extension GeneralSettingsContentView {
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle") {
            VStack(alignment: .leading, spacing: 12) {
                appInfoHeader
                appDescription
            }
            .padding(16)
            .background(aboutSectionBackground)
        }
    }
    
    private var appInfoHeader: some View {
            HStack {
                Text("Archie")
                    .font(.custom("Lora", size: 18))
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Version 1.0")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    
    private var appDescription: some View {
        Text("Text Expansion Made Simple")
            .font(.subheadline)
            .foregroundColor(.secondary)
    }
    
    private var aboutSectionBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
}

// MARK: - App Exclusions Section 100503
extension GeneralSettingsContentView {
    private var appExclusionsSection: some View {
        SettingsSection(title: "App Exclusions", icon: "app.badge.checkmark") {
            VStack(alignment: .leading, spacing: 16) {
                SettingsRow(
                    title: "Disable Archie in specific apps",
                    subtitle: "Text expansion will be disabled in selected applications"
                ) {
                    EmptyView()
                }
                
                // Excluded apps list
                if !appExclusionManager.excludedApps.isEmpty {
                    excludedAppsList
                }
                
                // Add app button
                addAppButton
            }
        }
    }
    
    private var excludedAppsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Excluded Apps")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            
            LazyVStack(spacing: 6) {
                ForEach(appExclusionManager.getExcludedAppInfos()) { appInfo in
                    ExcludedAppRow(appInfo: appInfo) {
                        // Remove app from exclusions
                        appExclusionManager.removeExcludedApp(appInfo.bundleIdentifier)
                        SaveNotificationManager.shared.show("Removed \(appInfo.name) from exclusions")
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(NSColor.textBackgroundColor))
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
        }
    }
    
    private var addAppButton: some View {
        Button("Add App to Exclusions") {
            showAddAppSheet()
        }
        .font(.system(size: 12))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.blue.opacity(0.1))
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
        .foregroundColor(.blue)
        .buttonStyle(.plain)
    }
    
    private func showAddAppSheet() {
        let runningApps = appExclusionManager.getRunningApps()
        
        // Filter out already excluded apps
        let availableApps = runningApps.filter { app in
            !appExclusionManager.excludedApps.contains(app.bundleIdentifier) &&
            !appExclusionManager.excludedApps.contains(app.name)
        }
        
        if availableApps.isEmpty {
            showNoAppsAlert()
            return
        }
        
        showAppSelectionAlert(apps: availableApps)
    }
    
    private func showNoAppsAlert() {
        let alert = NSAlert()
        alert.messageText = "No Apps Available"
        alert.informativeText = "All currently running applications are already excluded, or no compatible applications are running."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    private func showAppSelectionAlert(apps: [AppInfo]) {
            let alert = NSAlert()
            alert.messageText = "Select App to Exclude"
            alert.informativeText = "Choose an application to disable Archie text expansion:"
            alert.alertStyle = .informational
            
            // Create a custom view with a table view for better icon display
            let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 350, height: 200))
            
            // Create scroll view and table view
            let scrollView = NSScrollView(frame: containerView.bounds)
            let tableView = NSTableView()
            
            // Configure table view
            tableView.headerView = nil
            tableView.intercellSpacing = NSSize(width: 0, height: 2)
            tableView.rowHeight = 32
            tableView.selectionHighlightStyle = .regular
            
            // Create column
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("AppColumn"))
            column.width = 330
            tableView.addTableColumn(column)
            
            // Create data source
            let dataSource = AppTableDataSource(apps: apps)
            tableView.dataSource = dataSource
            tableView.delegate = dataSource
            
            // Setup scroll view
            scrollView.documentView = tableView
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = false
            
            containerView.addSubview(scrollView)
            
            alert.accessoryView = containerView
            alert.addButton(withTitle: "Add to Exclusions")
            alert.addButton(withTitle: "Cancel")
            
            let response = alert.runModal()
            
            if response == .alertFirstButtonReturn {
                let selectedRow = tableView.selectedRow
                guard selectedRow >= 0 && selectedRow < apps.count else { return }
                
                let selectedApp = apps[selectedRow]
                appExclusionManager.addExcludedApp(selectedApp.bundleIdentifier)
                SaveNotificationManager.shared.show("Added \(selectedApp.name) to exclusions")
            }
        }
}

// MARK: - Excluded App Row Component 100504
struct ExcludedAppRow: View {
    let appInfo: AppInfo
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon
            if let icon = appInfo.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
                    .cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "app")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    )
            }
            
            // App info
            VStack(alignment: .leading, spacing: 2) {
                Text(appInfo.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(appInfo.bundleIdentifier)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .help("Remove from exclusions")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
        )
    }
}

// MARK: - App Table Data Source 100505
class AppTableDataSource: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    let apps: [AppInfo]
    
    init(apps: [AppInfo]) {
        self.apps = apps
        super.init()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return apps.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let app = apps[row]
        
        let cellView = NSView(frame: NSRect(x: 0, y: 0, width: 330, height: 32))
        
        // App icon
        let iconImageView = NSImageView(frame: NSRect(x: 8, y: 4, width: 24, height: 24))
        if let icon = app.icon {
            iconImageView.image = icon
        } else {
            // Create a default app icon
            let defaultIcon = NSImage(systemSymbolName: "app", accessibilityDescription: "App")
            iconImageView.image = defaultIcon
        }
        iconImageView.imageScaling = .scaleProportionallyUpOrDown
        cellView.addSubview(iconImageView)
        
        // App name
        let nameLabel = NSTextField(frame: NSRect(x: 40, y: 8, width: 280, height: 16))
        nameLabel.stringValue = app.name
        nameLabel.font = NSFont.systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = NSColor.labelColor
        nameLabel.isBezeled = false
        nameLabel.isEditable = false
        nameLabel.backgroundColor = NSColor.clear
        cellView.addSubview(nameLabel)
        
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        return true
    }
}
