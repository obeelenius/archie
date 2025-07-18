// DragDropModels.swift

import Foundation
import UniformTypeIdentifiers

// MARK: - Snippet Drag Data for NSItemProvider 100201
class SnippetDragData: NSObject, NSItemProviderWriting {
    let snippet: Snippet
    
    init(snippet: Snippet) {
        self.snippet = snippet
        super.init()
        print("DEBUG DRAG DATA: Created drag data for snippet '\(snippet.shortcut)'")
    }
    
    static var writableTypeIdentifiersForItemProvider: [String] {
        print("DEBUG DRAG DATA: Requested writable type identifiers")
        return [UTType.json.identifier]
    }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        print("DEBUG DRAG DATA: loadData called with typeIdentifier: \(typeIdentifier)")
        
        do {
            let data = try JSONEncoder().encode(snippet)
            print("DEBUG DRAG DATA: Successfully encoded snippet data (\(data.count) bytes)")
            completionHandler(data, nil)
        } catch {
            print("DEBUG DRAG DATA: Failed to encode snippet: \(error)")
            completionHandler(nil, error)
        }
        return nil
    }
}
