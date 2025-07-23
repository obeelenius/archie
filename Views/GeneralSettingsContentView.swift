//  GeneralSettingsContentView.swift

import SwiftUI

// MARK: - General Settings Content View 100112
struct GeneralSettingsContentView: View {
    @AppStorage("startAtLogin") private var startAtLogin = false
    @AppStorage("soundEnabled") private var soundEnabled = false
    @AppStorage("selectedExpansionSound") private var selectedExpansionSound = SoundManager.ExpansionSound.pop.rawValue
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 24) {
                    startupSection
                    audioSection
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
    
    private var aboutSectionBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color(NSColor.controlBackgroundColor).opacity(0.5))
    }
}
