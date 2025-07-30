// SettingsHEaderView.swift

import SwiftUI

// MARK: - Settings Header View with Context-Aware Add Button 100126
struct SettingsHeaderView: View {
    @Binding var selectedView: SettingsView.MainView
    @Binding var showingAddSheet: Bool
    @Binding var showingAddCollectionSheet: Bool
    @Binding var editingSnippet: Snippet?
    @Binding var editingCollection: SnippetCollection?
    let onAddSnippetTapped: (() -> Void)?
    
    init(selectedView: Binding<SettingsView.MainView>,
         showingAddSheet: Binding<Bool>,
         showingAddCollectionSheet: Binding<Bool>,
         editingSnippet: Binding<Snippet?>,
         editingCollection: Binding<SnippetCollection?>,
         onAddSnippetTapped: (() -> Void)? = nil) {
        self._selectedView = selectedView
        self._showingAddSheet = showingAddSheet
        self._showingAddCollectionSheet = showingAddCollectionSheet
        self._editingSnippet = editingSnippet
        self._editingCollection = editingCollection
        self.onAddSnippetTapped = onAddSnippetTapped
    }
    
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
            Spacer(minLength: 8)
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
        .layoutPriority(1) // Give priority to app identity
    }
    
    private var appIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 35, height: 35)
                .shadow(color: Color.accentColor.opacity(0.2), radius: 4, x: 0, y: 2)
            
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 28, height: 28)
                    .cornerRadius(4)
            } else {
                Image(systemName: "text.cursor")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
        }
    }
        
    private var appInfo: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("Archie")
                .font(.custom("Lora", size: 16))
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text("Text Expansion")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .fixedSize(horizontal: true, vertical: false) // Prevent text compression
    }
}

// MARK: - Context-Aware Add Button 100128
extension SettingsHeaderView {
    private var contextAwareAddButton: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let useCompactButton = availableWidth < 140
            
            Button(action: {
                if selectedView == .collections {
                    // Close any open editors first
                    editingSnippet = nil
                    editingCollection = nil
                    showingAddCollectionSheet = true
                } else {
                    // Use the custom handler if provided (for snippet view)
                    if let handler = onAddSnippetTapped {
                        handler()
                    } else {
                        // Default behavior
                        editingSnippet = nil
                        editingCollection = nil
                        showingAddSheet = true
                    }
                }
            }) {
                HStack(spacing: useCompactButton ? 4 : 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    
                    if !useCompactButton {
                        Text(selectedView == .collections ? "Add Collection" : "Add Snippet")
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                    }
                }
                .foregroundColor(.white)
                .padding(.horizontal, useCompactButton ? 8 : 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedView == .collections ? Color.purple : Color.accentColor)
                )
            }
            .buttonStyle(.plain)
            .help(selectedView == .collections ? "Add Collection" : "Add Snippet")
        }
        .frame(height: 30)
        .frame(maxWidth: 200) // Prevent button from getting too wide
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
