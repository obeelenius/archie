//  GeneralSettingsContentView.swift

import SwiftUI

// MARK: - General Settings Content View 100112
struct GeneralSettingsContentView: View {
    @State private var startAtLogin = false
    @State private var showNotifications = true
    @State private var soundEnabled = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    startupSection
                    notificationsSection
                    aboutSection
                }
                .padding(16)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
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

// MARK: - Notifications Section 100114
extension GeneralSettingsContentView {
    private var notificationsSection: some View {
        SettingsSection(title: "Notifications", icon: "bell") {
            SettingsRow(
                title: "Show notifications",
                subtitle: "Display alerts when snippets are expanded"
            ) {
                Toggle("", isOn: $showNotifications)
                    .toggleStyle(ModernToggleStyle())
            }
            
            SettingsRow(
                title: "Play sound",
                subtitle: "Audio feedback when text is expanded"
            ) {
                Toggle("", isOn: $soundEnabled)
                    .toggleStyle(ModernToggleStyle())
            }
        }
    }
}

// MARK: - About Section 100115
extension GeneralSettingsContentView {
    private var aboutSection: some View {
        SettingsSection(title: "About", icon: "info.circle") {
            VStack(alignment: .leading, spacing: 12) {
                appInfoHeader
                appDescription
                Divider()
                    .padding(.vertical, 8)
                actionButtons
            }
            .padding(16)
            .background(aboutSectionBackground)
        }
    }
    
    private var appInfoHeader: some View {
        HStack {
            Text("Archie")
                .font(.headline)
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
    
    private var actionButtons: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button("Check for Updates") {
                // TODO: Implement update checking
            }
            .buttonStyle(.bordered)
            
            Button("Send Feedback") {
                // TODO: Implement feedback
            }
            .buttonStyle(.bordered)
        }
    }
    
    private var aboutSectionBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
}
