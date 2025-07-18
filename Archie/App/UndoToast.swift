//  UndoToast.swift

import SwiftUI

// MARK: - Undo Toast Component 100097
struct UndoToast: View {
    let pendingDeletion: PendingDeletion
    let onUndo: () -> Void
    @State private var timeRemaining: Double = 3.0
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 12) {
            toastIcon
            toastContent
            Spacer()
            undoButton
            progressIndicator
        }
        .padding(12)
        .background(toastBackground)
        .onAppear(perform: startTimer)
        .onDisappear(perform: stopTimer)
    }
}

// MARK: - Toast Components 100098
extension UndoToast {
    private var toastIcon: some View {
        Image(systemName: "trash")
            .foregroundColor(.red)
            .font(.system(size: 16, weight: .medium))
    }
    
    private var toastContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(pendingDeletion.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Undo in \(Int(timeRemaining))s")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }
    
    private var undoButton: some View {
        Button("Undo") {
            onUndo()
            stopTimer()
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.accentColor)
        )
        .buttonStyle(.plain)
    }
    
    private var progressIndicator: some View {
        VStack {
            Spacer()
            
            Rectangle()
                .fill(Color.accentColor)
                .frame(height: 3)
                .frame(width: CGFloat(timeRemaining / 3.0) * 200)
                .animation(.linear(duration: 0.1), value: timeRemaining)
        }
        .frame(width: 200, height: 40)
    }
    
    private var toastBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(NSColor.controlBackgroundColor))
            .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Timer Management 100099
extension UndoToast {
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            timeRemaining -= 0.1
            if timeRemaining <= 0 {
                stopTimer()
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Undo Toast Container 100100
struct UndoToastContainer: View {
    @StateObject private var snippetManager = SnippetManager.shared
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(snippetManager.pendingDeletions) { pendingDeletion in
                UndoToast(pendingDeletion: pendingDeletion) {
                    snippetManager.undoDeletion(pendingDeletion)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.trailing, 16)
        .padding(.bottom, 16)
        .animation(.easeInOut(duration: 0.3), value: snippetManager.pendingDeletions.count)
    }
}
