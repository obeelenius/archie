// RichTextEditorView.swift

import SwiftUI
import AppKit

// MARK: - Rich Text Editor View 100410
struct RichTextEditorView: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = false
        scrollView.borderType = .noBorder
        
        // Configure text view
        textView.isEditable = true
        textView.isSelectable = true
        textView.isRichText = true
        textView.allowsUndo = true
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
        textView.delegate = context.coordinator
        textView.textContainer?.containerSize = CGSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.maxSize = CGSize(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude)
        
        scrollView.documentView = textView
        
        // Set initial text
        if !text.isEmpty {
            let richText = RichTextProcessor.shared.processRichText(text)
            textView.textStorage?.setAttributedString(richText)
        } else {
            textView.string = ""
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        
        if textView.string != text {
            let richText = RichTextProcessor.shared.processRichText(text)
            textView.textStorage?.setAttributedString(richText)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: RichTextEditorView
        
        init(_ parent: RichTextEditorView) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Convert attributed string back to plain text with formatting markers
            let plainText = RichTextProcessor.shared.convertToPlainText(textView.attributedString())
            
            if plainText != parent.text {
                parent.text = plainText
            }
        }
    }
}

// MARK: - Rich Text Preview 100411
struct RichTextPreview: View {
    let text: String
    
    var body: some View {
        RichTextDisplayView(attributedText: RichTextProcessor.shared.processRichText(text))
            .frame(maxHeight: 200)
    }
}

// MARK: - Rich Text Display View 100412
struct RichTextDisplayView: NSViewRepresentable {
    let attributedText: NSAttributedString
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        let textView = NSTextView()
        
        // Configure scroll view
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        
        // Configure text view for display only
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.textContainer?.containerSize = CGSize(width: scrollView.contentSize.width, height: .greatestFiniteMagnitude)
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.heightTracksTextView = false
        
        scrollView.documentView = textView
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        textView.textStorage?.setAttributedString(attributedText)
    }
}