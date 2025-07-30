// RichTextProcessor.swift

import Foundation
import AppKit

// MARK: - Rich Text Processor 100400
class RichTextProcessor {
    static let shared = RichTextProcessor()
    
    private init() {}
    
    // Process rich text formatting in expansion text
    func processRichText(_ text: String) -> NSAttributedString {
        let mutableAttributedString = NSMutableAttributedString(string: text)
        let range = NSRange(location: 0, length: text.count)
        
        // Set default font
        let defaultFont = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        mutableAttributedString.addAttribute(.font, value: defaultFont, range: range)
        
        // Process formatting in order of precedence
        processLists(mutableAttributedString)
        processBoldText(mutableAttributedString)
        processItalicText(mutableAttributedString)
        processUnderlineText(mutableAttributedString)
        processStrikethroughText(mutableAttributedString)
        
        return mutableAttributedString
    }
    
    // Convert rich text back to plain text with formatting markers
    func convertToPlainText(_ attributedString: NSAttributedString) -> String {
        var result = attributedString.string
        
        // This is a simplified conversion - in practice you'd want to
        // preserve the formatting markers when editing
        return result
    }
}

// MARK: - Bold Text Processing 100401
extension RichTextProcessor {
    private func processBoldText(_ attributedString: NSMutableAttributedString) {
        let pattern = #"\*\*(.*?)\*\*"#
        processTextFormatting(
            attributedString,
            pattern: pattern,
            attributes: [.font: NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)]
        )
    }
}

// MARK: - Italic Text Processing 100402
extension RichTextProcessor {
    private func processItalicText(_ attributedString: NSMutableAttributedString) {
        let pattern = #"\*(.*?)\*"#
        let italicFont = NSFontManager.shared.font(
            withFamily: NSFont.systemFont(ofSize: NSFont.systemFontSize).familyName!,
            traits: .italicFontMask,
            weight: 5,
            size: NSFont.systemFontSize
        ) ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        
        processTextFormatting(
            attributedString,
            pattern: pattern,
            attributes: [.font: italicFont]
        )
    }
}

// MARK: - Underline Text Processing 100403
extension RichTextProcessor {
    private func processUnderlineText(_ attributedString: NSMutableAttributedString) {
        let pattern = #"__(.*?)__"#
        processTextFormatting(
            attributedString,
            pattern: pattern,
            attributes: [.underlineStyle: NSUnderlineStyle.single.rawValue]
        )
    }
}

// MARK: - Strikethrough Text Processing 100404
extension RichTextProcessor {
    private func processStrikethroughText(_ attributedString: NSMutableAttributedString) {
        let pattern = #"~~(.*?)~~"#
        processTextFormatting(
            attributedString,
            pattern: pattern,
            attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
        )
    }
}

// MARK: - List Processing 100405
extension RichTextProcessor {
    private func processLists(_ attributedString: NSMutableAttributedString) {
        let text = attributedString.string
        let lines = text.components(separatedBy: .newlines)
        var processedLines: [String] = []
        var numberedListCounter = 1
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)
            
            if trimmedLine.hasPrefix("- ") || trimmedLine.hasPrefix("* ") {
                // Bullet point
                let content = String(trimmedLine.dropFirst(2))
                processedLines.append("• \(content)")
            } else if trimmedLine.hasPrefix("1. ") || 
                      (trimmedLine.hasPrefix("\(numberedListCounter). ")) {
                // Numbered list
                let content = String(trimmedLine.dropFirst(3))
                processedLines.append("\(numberedListCounter). \(content)")
                numberedListCounter += 1
            } else {
                // Reset counter if not a numbered list
                if !trimmedLine.isEmpty {
                    numberedListCounter = 1
                }
                processedLines.append(line)
            }
        }
        
        let processedText = processedLines.joined(separator: "\n")
        attributedString.replaceCharacters(in: NSRange(location: 0, length: text.count), with: processedText)
    }
}

// MARK: - Generic Text Formatting 100406
extension RichTextProcessor {
    private func processTextFormatting(
        _ attributedString: NSMutableAttributedString,
        pattern: String,
        attributes: [NSAttributedString.Key: Any]
    ) {
        let text = attributedString.string
        
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [])
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            // Process matches in reverse order to maintain string indices
            for match in matches.reversed() {
                let fullRange = match.range
                let contentRange = match.range(at: 1)
                
                if contentRange.location != NSNotFound {
                    let content = (text as NSString).substring(with: contentRange)
                    
                    // Replace the full match (including markers) with just the content
                    attributedString.replaceCharacters(in: fullRange, with: content)
                    
                    // Apply formatting to the content
                    let newContentRange = NSRange(location: fullRange.location, length: content.count)
                    for (key, value) in attributes {
                        attributedString.addAttribute(key, value: value, range: newContentRange)
                    }
                }
            }
        } catch {
            print("Rich text processing error: \(error)")
        }
    }
}

// MARK: - Rich Text Examples 100407
extension RichTextProcessor {
    static let formattingExamples = [
        "**Bold text**",
        "*Italic text*",
        "__Underlined text__",
        "~~Strikethrough text~~",
        "- Bullet point",
        "* Another bullet",
        "1. Numbered item",
        "2. Second item"
    ]
    
    static let formattingHelp = """
    Rich Text Formatting:
    **bold** - Bold text
    *italic* - Italic text
    __underline__ - Underlined text
    ~~strikethrough~~ - Strikethrough text
    - or * - Bullet points
    1. 2. 3. - Numbered lists
    """
}