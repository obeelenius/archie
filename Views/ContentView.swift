//  ContentView.swift

import SwiftUI

// MARK: - Main Content View 100116
struct ContentView: View {
    @StateObject private var eventMonitor = EventMonitor()
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            mainContentArea
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            eventMonitor.start()
        }
        .onDisappear {
            eventMonitor.stop()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - Main Content Area 100117
extension ContentView {
    private var mainContentArea: some View {
        ZStack {
            backgroundGradient
            contentLayout
        }
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color.accentColor.opacity(0.05),
                Color.accentColor.opacity(0.02)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    private var contentLayout: some View {
        VStack(spacing: 32) {
            heroSection
            QuickStatsView()
            Spacer()
            actionButtons
        }
        .padding(40)
    }
}

// MARK: - Hero Section 100118
extension ContentView {
    private var heroSection: some View {
        VStack(spacing: 24) {
            appIconAndTitle
            StatusIndicatorView()
        }
    }
    
    private var appIconAndTitle: some View {
        VStack(spacing: 16) {
            appIcon
            appTitleSection
        }
    }
    
    private var appIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(
                    colors: [Color.accentColor, Color.accentColor.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ))
                .frame(width: 80, height: 80)
                .shadow(color: Color.accentColor.opacity(0.3), radius: 12, x: 0, y: 6)
            
            Image(systemName: "text.cursor")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    private var appTitleSection: some View {
        VStack(spacing: 8) {
            Text("Archie")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Text Expansion Made Simple")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Action Buttons 100119
extension ContentView {
    private var actionButtons: some View {
        VStack(spacing: 16) {
            PrimaryButton(
                title: "Open Settings",
                icon: "gearshape.fill"
            ) {
                showingSettings = true
            }
            
            SecondaryButton(
                title: "About Text Expansion",
                icon: "questionmark.circle"
            ) {
                showAboutAlert()
            }
        }
    }
    
    private func showAboutAlert() {
        let alert = NSAlert()
        alert.messageText = "About Text Expansion"
        alert.informativeText = """
        Text expansion lets you type short shortcuts that automatically expand into longer text. 
        
        For example, typing "@@" followed by a space could expand to your email address.
        
        Archie monitors your typing and replaces shortcuts with their expansions automatically.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Got it!")
        alert.runModal()
    }
}

// MARK: - Status Indicator View 100120
struct StatusIndicatorView: View {
    @StateObject private var eventMonitor = EventMonitor()
    
    var body: some View {
        HStack(spacing: 12) {
            statusDot
            statusText
            Spacer()
        }
        .padding(16)
        .background(statusBackground)
    }
    
    private var statusDot: some View {
        Circle()
            .fill(Color.green)
            .frame(width: 12, height: 12)
            .shadow(color: Color.green.opacity(0.4), radius: 4, x: 0, y: 2)
    }
    
    private var statusText: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Archie is Active")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Monitoring keystrokes for text expansion")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.green.opacity(0.05))
            .stroke(Color.green.opacity(0.2), lineWidth: 1)
    }
}

// MARK: - Quick Stats View 100121
struct QuickStatsView: View {
    @StateObject private var snippetManager = SnippetManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            StatCard(
                title: "Total Snippets",
                value: "\(snippetManager.snippets.count)",
                icon: "doc.text",
                color: .blue
            )
            
            StatCard(
                title: "Enabled",
                value: "\(snippetManager.snippets.filter(\.isEnabled).count)",
                icon: "checkmark.circle",
                color: .green
            )
            
            StatCard(
                title: "Disabled",
                value: "\(snippetManager.snippets.count - snippetManager.snippets.filter(\.isEnabled).count)",
                icon: "xmark.circle",
                color: .orange
            )
        }
    }
}

// MARK: - Stat Card 100122
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(statCardBackground)
    }
    
    private var statCardBackground: some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(color.opacity(0.05))
            .stroke(color.opacity(0.2), lineWidth: 1)
    }
}

// MARK: - Primary Button 100123
struct PrimaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(primaryButtonBackground)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
    
    private var primaryButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.accentColor)
            .shadow(
                color: Color.accentColor.opacity(0.3),
                radius: isPressed ? 4 : 8,
                x: 0,
                y: isPressed ? 2 : 4
            )
    }
}

// MARK: - Secondary Button 100124
struct SecondaryButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(secondaryButtonBackground)
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private var secondaryButtonBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color.accentColor.opacity(isHovered ? 0.1 : 0.05))
            .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
    }
}

// MARK: - Preview 100125
#Preview {
    ContentView()
}
