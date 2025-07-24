//
//  PermissionBannerManager.swift
//  Archie
//
//  Created by Amy Elenius on 24/7/2025.
//


// PermissionBanner.swift

import SwiftUI
import Cocoa

// MARK: - Permission Banner Manager 100169
class PermissionBannerManager: ObservableObject {
    static let shared = PermissionBannerManager()
    
    @Published var showBanner = false
    private var timer: Timer?
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Check immediately
        checkPermissions()
        
        // Check every 2 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.checkPermissions()
        }
    }
    
    private func checkPermissions() {
        DispatchQueue.main.async {
            self.showBanner = !AXIsProcessTrusted()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

// MARK: - Permission Banner View 100170
struct PermissionBanner: View {
    @StateObject private var bannerManager = PermissionBannerManager.shared
    
    var body: some View {
        if bannerManager.showBanner {
            VStack(spacing: 0) {
                bannerContent
                Divider()
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeInOut(duration: 0.3), value: bannerManager.showBanner)
        }
    }
    
    private var bannerContent: some View {
        HStack(spacing: 12) {
            // Warning icon
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
                .font(.system(size: 16, weight: .medium))
            
            // Message content
            VStack(alignment: .leading, spacing: 2) {
                Text("Accessibility Permission Required")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Archie needs accessibility permission to expand text shortcuts")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                Button("Open Settings") {
                    openAccessibilitySettings()
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.orange)
                )
                .buttonStyle(.plain)
                
                Button("Learn More") {
                    showPermissionInfo()
                }
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.orange, lineWidth: 1)
                )
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.orange.opacity(0.05))
    }
    
    private func openAccessibilitySettings() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    
    private func showPermissionInfo() {
        let alert = NSAlert()
        alert.messageText = "About Accessibility Permission"
        alert.informativeText = """
        Archie needs accessibility permission to function as a text expansion tool.
        
        This permission allows Archie to:
        • Monitor when you type text shortcuts (like "addr" or "@@")
        • Automatically replace shortcuts with their full text expansions
        • Work seamlessly across all applications on your Mac
        
        Archie only monitors for your predefined shortcuts and does not store, transmit, or access any other typed content. All text expansion happens locally on your device.
        
        To grant permission:
        1. Click "Open Settings" to go to System Settings
        2. Find "Archie" in the list
        3. Toggle the switch to enable accessibility access
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Got it!")
        alert.addButton(withTitle: "Open Settings")
        
        if alert.runModal() == .alertSecondButtonReturn {
            openAccessibilitySettings()
        }
    }
}