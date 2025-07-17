//
//  ContentView.swift
//  Archie
//
//  Created by Amy Elenius on 17/7/2025.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var eventMonitor = EventMonitor()
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Main content area
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color.accentColor.opacity(0.05),
                        Color.accentColor.opacity(0.02)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Hero section
                    VStack(spacing: 24) {
                        // App icon and title
                        VStack(spacing: 16) {
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
                        
                        // Status indicator
                        StatusIndicatorView()
                    }
                    
                    // Quick stats
                    QuickStatsView()
                    
                    Spacer()
                    
                    // Action buttons
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
                .padding(40)
            }
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

struct StatusIndicatorView: View {
    @StateObject private var eventMonitor = EventMonitor()
    
    var body: some View {
        HStack(spacing: 12) {
            // Status dot
            Circle()
                .fill(Color.green)
                .frame(width: 12, height: 12)
                .shadow(color: Color.green.opacity(0.4), radius: 4, x: 0, y: 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Archie is Active")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text("Monitoring keystrokes for text expansion")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.05))
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }
}

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
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.05))
                .stroke(color.opacity(0.2), lineWidth: 1)
        )
    }
}

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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor)
                    .shadow(
                        color: Color.accentColor.opacity(0.3),
                        radius: isPressed ? 4 : 8,
                        x: 0,
                        y: isPressed ? 2 : 4
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(isHovered ? 0.1 : 0.05))
                    .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#Preview {
    ContentView()
}