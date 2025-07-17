//
//  Snippet.swift
//  Archie
//
//  Created by Amy Elenius on 17/7/2025.
//


import Foundation

struct Snippet: Identifiable, Codable {
    var id = UUID()
    var shortcut: String
    var expansion: String
    var isEnabled: Bool = true
    
    init(shortcut: String, expansion: String) {
        self.shortcut = shortcut
        self.expansion = expansion
    }
}
