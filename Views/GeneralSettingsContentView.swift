//  GeneralSettingsContentView.swift

import SwiftUI

// MARK: - General Settings Content View
struct GeneralSettingsContentView: View {
    @State private var startAtLogin = false
    @State private var showNotifications = true
    @State private var soundEnabled = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    SettingsSection(title: "Startup", icon: "power") {
                        SettingsRow(
                            title: "Start Archie at login",
                            subtitle: "Automatically start when you log in to your Mac"
                        ) {
                            Toggle("", isOn: $startAtLogin)
                                .toggleStyle(ModernToggleStyle())
                        }
                    }
                    
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
                    
                    SettingsSection(title: "About", icon: "info.circle") {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Archie")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("Version 1.0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text("Text Expansion Made Simple")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Divider()
                                .padding(.vertical, 8)
                            
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
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
                        )
                    }
                }
                .padding(16)
            }
            .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        }
    }
}
