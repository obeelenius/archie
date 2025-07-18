//
//  SaveNotificationManager.swift
//  Archie
//
//  Created by Amy Elenius on 18/7/2025.
//


//
//  SaveNotification.swift
//  Archie
//
//  Created by Amy Elenius on 18/7/2025.
//

import SwiftUI

// MARK: - Save Notification Manager
class SaveNotificationManager: ObservableObject {
    static let shared = SaveNotificationManager()
    
    @Published var isShowing = false
    @Published var message = ""
    
    private init() {}
    
    func show(_ message: String) {
        self.message = message
        withAnimation(.easeInOut(duration: 0.3)) {
            isShowing = true
        }
        
        // Auto-hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.isShowing = false
            }
        }
    }
}

// MARK: - Save Notification View
struct SaveNotification: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.system(size: 14, weight: .medium))
            
            Text(message)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.green.opacity(0.1))
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Save Notification Container
struct SaveNotificationContainer: View {
    @StateObject private var notificationManager = SaveNotificationManager.shared
    
    var body: some View {
        VStack {
            if notificationManager.isShowing {
                VStack {
                    SaveNotification(message: notificationManager.message)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: notificationManager.isShowing)
        .allowsHitTesting(false) // Don't block user interaction
    }
}