// SettingsHEaderView.swift

import SwiftUI

// MARK: - Settings Header View with Context-Aware Add Button 100126
struct SettingsHeaderView: View {
    @Binding var selectedView: SettingsView.MainView
    @Binding var showingAddSheet: Bool
    @Binding var showingAddCollectionSheet: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            headerContent
            navigationTabs
            Divider()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Header Content 100127
extension SettingsHeaderView {
    private var headerContent: some View {
        HStack {
            appIdentity
            Spacer()
            contextAwareAddButton
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private var appIdentity: some View {
        HStack(spacing: 8) {
            appIcon
            appInfo
        }
    }
    
    private var appIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 28, height: 28)
                .shadow(color: Color.accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
            
            Image(systemName: "text.cursor")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    private var appInfo: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Archie")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Text Expansion")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Context-Aware Add Button 100128
extension SettingsHeaderView {
    private var contextAwareAddButton: some View {
        Button(action: {
            if selectedView == .collections {
                showingAddCollectionSheet = true
            } else {
                showingAddSheet = true
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                Text(selectedView == .collections ? "Add Collection" : "Add Snippet")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Navigation Tabs 100129
extension SettingsHeaderView {
    private var navigationTabs: some View {
        HStack(spacing: 0) {
            ForEach(SettingsView.MainView.allCases) { view in
                navigationTab(for: view)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
    
    private func navigationTab(for view: SettingsView.MainView) -> some View {
        Button(action: { selectedView = view }) {
            HStack(spacing: 4) {
                Image(systemName: view.icon)
                    .font(.system(size: 11, weight: .medium))
                Text(view.rawValue)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(selectedView == view ? .accentColor : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(selectedView == view ? Color.accentColor.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
