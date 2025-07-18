// DragDropModels.swift

import Foundation
import UniformTypeIdentifiers

// MARK: - Snippet Drag Data for NSItemProvider 100201
class SnippetDragData: NSObject, NSItemProviderWriting {
    let snippet: Snippet
    
    init(snippet: Snippet) {
        self.snippet = snippet
        super.init()
    }
    
    static var writableTypeIdentifiersForItemProvider: [String] {
        return [UTType.json.identifier]
    }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        do {
            let data = try JSONEncoder().encode(snippet)
            completionHandler(data, nil)
        } catch {
            completionHandler(nil, error)
        }
        return nil
    }
}
