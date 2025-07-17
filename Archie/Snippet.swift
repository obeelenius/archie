import Foundation

struct Snippet: Identifiable, Codable {
    let id = UUID()
    var shortcut: String
    var expansion: String
    var isEnabled: Bool = true
    
    init(shortcut: String, expansion: String) {
        self.shortcut = shortcut
        self.expansion = expansion
    }
}