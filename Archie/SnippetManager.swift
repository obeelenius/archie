//
//  SnippetManager.swift
//  Archie
//
//  Created by Amy Elenius on 17/7/2025.
//


import Foundation

class SnippetManager: ObservableObject {
    static let shared = SnippetManager()
    
    @Published var snippets: [Snippet] = [] {
        didSet {
            saveSnippets()
        }
    }
    
    private init() {
        loadSnippets()
        
        // Add some default snippets if none exist
        if snippets.isEmpty {
            snippets = [
                Snippet(shortcut: "@@", expansion: "your@email.com"),
                Snippet(shortcut: "addr", expansion: "123 Main St\nYour City, State 12345"),
                Snippet(shortcut: "phone", expansion: "+1 (555) 123-4567"),
                Snippet(shortcut: "sig", expansion: "Best regards,\nYour Name")
            ]
        }
    }
    
    func addSnippet(_ snippet: Snippet) {
        snippets.append(snippet)
    }
    
    func deleteSnippet(_ snippet: Snippet) {
        snippets.removeAll { $0.id == snippet.id }
    }
    
    func getExpansion(for shortcut: String) -> String? {
        return snippets.first { $0.shortcut == shortcut && $0.isEnabled }?.expansion
    }
    
    private func saveSnippets() {
        if let data = try? JSONEncoder().encode(snippets) {
            UserDefaults.standard.set(data, forKey: "snippets")
        }
    }
    
    private func loadSnippets() {
        if let data = UserDefaults.standard.data(forKey: "snippets"),
           let decoded = try? JSONDecoder().decode([Snippet].self, from: data) {
            snippets = decoded
        }
    }
}