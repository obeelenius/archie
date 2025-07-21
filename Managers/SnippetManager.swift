// SnippetManage.swift

import Foundation

// MARK: - Enhanced Snippet Manager with Default Collections 100101

class SnippetManager: ObservableObject {
    static let shared = SnippetManager()
    
    @Published var snippets: [Snippet] = [] {
        didSet {
            saveSnippets()
        }
    }
    
    @Published var collections: [SnippetCollection] = [] {
        didSet {
            saveCollections()
        }
    }
    
    // Collection expansion state persistence
    @Published var expandedCollections: Set<UUID> = [] {
        didSet {
            saveExpandedCollections()
        }
    }
    
    // Undo system
    @Published var pendingDeletions: [PendingDeletion] = []
    private var deletionTimers: [UUID: Timer] = [:]
    
    private init() {
        loadCollections()
        loadSnippets()
        loadExpandedCollections()
        setupDefaultCollections()
        fixOrphanedSnippets() // Fix any snippets without collectionId
    }
}

// MARK: - Default Collections Setup 100102
extension SnippetManager {
    private func setupDefaultCollections() {
        // Only create defaults if no collections exist
        if collections.isEmpty {
            createDefaultCollections()
        } else {
            // Ensure existing collections are expanded by default if no expansion state exists
            if expandedCollections.isEmpty {
                expandedCollections = Set(collections.map { $0.id })
                print("DEBUG: No expansion state found, expanding all existing collections")
            }
        }
    }
    
    private func createDefaultCollections() {
        // Create default collections with icons
        let generalCollection = SnippetCollection(name: "General", suffix: "", keepDelimiter: false, icon: "folder")
        let signatureCollection = SnippetCollection(name: "Signature", suffix: "", keepDelimiter: false, icon: "signature")
        let dateCollection = SnippetCollection(name: "Date", suffix: "", keepDelimiter: false, icon: "clock")
        let contactCollection = SnippetCollection(name: "Contact", suffix: "", keepDelimiter: false, icon: "at")
        
        collections = [generalCollection, signatureCollection, dateCollection, contactCollection]
        
        // Expand all default collections
        expandedCollections = Set(collections.map { $0.id })
        
        createDefaultSnippets(
            generalCollection: generalCollection,
            signatureCollection: signatureCollection,
            dateCollection: dateCollection,
            contactCollection: contactCollection
        )
    }
    
    private func createDefaultSnippets(
        generalCollection: SnippetCollection,
        signatureCollection: SnippetCollection,
        dateCollection: SnippetCollection,
        contactCollection: SnippetCollection
    ) {
        let defaultSnippets = [
            // Contact collection snippets
            Snippet(shortcut: "@@", expansion: "your@email.com", collectionId: contactCollection.id),
            Snippet(shortcut: "addr", expansion: "123 Main St\nYour City, State 12345", collectionId: contactCollection.id),
            Snippet(shortcut: "phone", expansion: "+1 (555) 123-4567", collectionId: contactCollection.id),
            
            // Signature collection snippet
            Snippet(shortcut: "sig", expansion: "Best regards,\nYour Name", collectionId: signatureCollection.id),
            
            // Date collection snippets
            Snippet(shortcut: "today", expansion: "{{date}}", collectionId: dateCollection.id),
            Snippet(shortcut: "nextweek", expansion: "{{date+7}}", collectionId: dateCollection.id)
        ]
        
        snippets = defaultSnippets
    }
}

// MARK: - Snippet Management 100103
extension SnippetManager {
    func addSnippet(_ snippet: Snippet) {
        snippets.append(snippet)
        SaveNotificationManager.shared.show("Snippet created")
    }
    
    func deleteSnippet(_ snippet: Snippet) {
        // Create pending deletion
        let pendingDeletion = PendingDeletion(
            type: .snippet(snippet),
            timestamp: Date()
        )
        pendingDeletions.append(pendingDeletion)
        
        // Remove from snippets immediately
        snippets.removeAll { $0.id == snippet.id }
        
        // Schedule auto-confirm after 3 seconds
        scheduleAutoConfirmDeletion(pendingDeletion)
    }
}

// MARK: - Collection Management 100104
extension SnippetManager {
    func addCollection(_ collection: SnippetCollection) {
        collections.append(collection)
        // Expand new collections by default
        expandNewCollection(collection.id)
        SaveNotificationManager.shared.show("Collection created")
    }
    
    func deleteCollection(_ collection: SnippetCollection) {
        // Move snippets to General collection first
        let generalCollection = collections.first { $0.name == "General" } ?? collections.first!
        let affectedSnippets = snippets.filter { $0.collectionId == collection.id }
        
        moveSnippetsToGeneralCollection(generalCollection: generalCollection, collectionId: collection.id)
        
        // Create pending deletion
        let pendingDeletion = PendingDeletion(
            type: .collection(collection, affectedSnippets),
            timestamp: Date()
        )
        pendingDeletions.append(pendingDeletion)
        
        // Remove from collections and expansion state
        collections.removeAll { $0.id == collection.id }
        expandedCollections.remove(collection.id)
        
        // Schedule auto-confirm after 3 seconds
        scheduleAutoConfirmDeletion(pendingDeletion)
    }
    
    private func moveSnippetsToGeneralCollection(generalCollection: SnippetCollection, collectionId: UUID) {
        for i in snippets.indices {
            if snippets[i].collectionId == collectionId {
                snippets[i].collectionId = generalCollection.id
            }
        }
    }
}

// MARK: - Undo System 100105
extension SnippetManager {
    func undoDeletion(_ pendingDeletion: PendingDeletion) {
        // Cancel the timer
        deletionTimers[pendingDeletion.id]?.invalidate()
        deletionTimers.removeValue(forKey: pendingDeletion.id)
        
        switch pendingDeletion.type {
        case .snippet(let snippet):
            undoSnippetDeletion(snippet)
        case .collection(let collection, let affectedSnippets):
            undoCollectionDeletion(collection: collection, affectedSnippets: affectedSnippets)
        }
        
        // Remove from pending deletions
        pendingDeletions.removeAll { $0.id == pendingDeletion.id }
    }
    
    private func undoSnippetDeletion(_ snippet: Snippet) {
        snippets.append(snippet)
    }
    
    private func undoCollectionDeletion(collection: SnippetCollection, affectedSnippets: [Snippet]) {
        collections.append(collection)
        // Restore snippets to their original collection
        for snippet in affectedSnippets {
            if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
                snippets[index].collectionId = collection.id
            }
        }
    }
    
    private func scheduleAutoConfirmDeletion(_ pendingDeletion: PendingDeletion) {
        let timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            self.confirmDeletion(pendingDeletion)
        }
        deletionTimers[pendingDeletion.id] = timer
    }
    
    private func confirmDeletion(_ pendingDeletion: PendingDeletion) {
        // Remove from pending deletions and timers
        pendingDeletions.removeAll { $0.id == pendingDeletion.id }
        deletionTimers.removeValue(forKey: pendingDeletion.id)
        
        // Item is already deleted from main arrays, so permanent deletion is complete
    }
}

// MARK: - Helper Methods 100106
extension SnippetManager {
    func collection(for snippet: Snippet) -> SnippetCollection? {
        guard let collectionId = snippet.collectionId else {
            print("DEBUG: Snippet '\(snippet.shortcut)' has nil collectionId")
            return nil
        }
        let collection = collections.first { $0.id == collectionId }
        if collection == nil {
            print("DEBUG: Snippet '\(snippet.shortcut)' has collectionId '\(collectionId)' but no matching collection found")
        }
        return collection
    }
    
    func snippets(for collection: SnippetCollection) -> [Snippet] {
        let collectionSnippets = snippets.filter { $0.collectionId == collection.id }
        print("DEBUG: Collection '\(collection.name)' has \(collectionSnippets.count) snippets")
        return collectionSnippets
    }
    
    func getExpansion(for shortcut: String) -> String? {
        // Check all enabled collections and their snippets
        for collection in collections.filter({ $0.isEnabled }) {
            let collectionSnippets = snippets(for: collection).filter { $0.isEnabled }
            
            for snippet in collectionSnippets {
                let fullShortcut = snippet.fullShortcut(with: collection)
                if fullShortcut == shortcut {
                    return snippet.processedExpansion()
                }
            }
        }
        return nil
    }
    
    // Add a method to fix orphaned snippets
    func fixOrphanedSnippets() {
        let generalCollection = collections.first { $0.name == "General" }
        guard let generalCollection = generalCollection else { return }
        
        for i in snippets.indices {
            if snippets[i].collectionId == nil {
                print("DEBUG: Fixing orphaned snippet '\(snippets[i].shortcut)' - assigning to General collection")
                snippets[i].collectionId = generalCollection.id
            }
        }
    }
}

// MARK: - Persistence 100107
extension SnippetManager {
    private func saveSnippets() {
        if let data = try? JSONEncoder().encode(snippets) {
            UserDefaults.standard.set(data, forKey: "snippets")
            print("DEBUG SAVE: Saved \(snippets.count) snippets to UserDefaults")
        }
    }
    
    private func loadSnippets() {
        if let data = UserDefaults.standard.data(forKey: "snippets"),
           let decoded = try? JSONDecoder().decode([Snippet].self, from: data) {
            snippets = decoded
            print("DEBUG LOAD: Loaded \(snippets.count) snippets from UserDefaults")
        }
    }
    
    private func saveCollections() {
        if let data = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(data, forKey: "collections")
            print("DEBUG SAVE: Saved \(collections.count) collections to UserDefaults")
        }
    }
    
    private func loadCollections() {
        if let data = UserDefaults.standard.data(forKey: "collections"),
           let decoded = try? JSONDecoder().decode([SnippetCollection].self, from: data) {
            collections = decoded
            print("DEBUG LOAD: Loaded \(collections.count) collections from UserDefaults")
        }
    }
    
    private func saveExpandedCollections() {
        let expandedArray = Array(expandedCollections).map { $0.uuidString }
        UserDefaults.standard.set(expandedArray, forKey: "expandedCollections")
        print("DEBUG: Saved expandedCollections: \(expandedArray)")
    }
    
    private func loadExpandedCollections() {
        if let expandedArray = UserDefaults.standard.array(forKey: "expandedCollections") as? [String] {
            expandedCollections = Set(expandedArray.compactMap { UUID(uuidString: $0) })
            print("DEBUG: Loaded expandedCollections: \(expandedCollections)")
        } else {
            // Default: expand all collections on first launch only
            print("DEBUG: No saved expansion state, will expand collections as they are created")
            expandedCollections = Set()
        }
    }
    
    // Call this when a new collection is created to expand it by default
    func expandNewCollection(_ collectionId: UUID) {
        if !expandedCollections.contains(collectionId) {
            expandedCollections.insert(collectionId)
        }
    }
    
    // Add explicit save methods that can be called manually
    func saveAllData() {
        saveSnippets()
        saveCollections()
        saveExpandedCollections()
        print("DEBUG SAVE: Explicitly saved all data to UserDefaults")
    }
}

// MARK: - Pending Deletion System 100108
struct PendingDeletion: Identifiable {
    let id = UUID()
    let type: DeletionType
    let timestamp: Date
    
    enum DeletionType {
        case snippet(Snippet)
        case collection(SnippetCollection, [Snippet]) // collection and affected snippets
    }
    
    var title: String {
        switch type {
        case .snippet(let snippet):
            return "Deleted '\(snippet.shortcut)'"
        case .collection(let collection, _):
            return "Deleted '\(collection.name)' collection"
        }
    }
}

// MARK: - Drag and Drop Support 100109
extension SnippetManager {
    func moveSnippet(_ snippet: Snippet, toCollection collection: SnippetCollection) {
        if let index = snippets.firstIndex(where: { $0.id == snippet.id }) {
            // Only move if it's a different collection
            if snippets[index].collectionId != collection.id {
                _ = snippets[index].collectionId
                snippets[index].collectionId = collection.id
                
                // Log the move for potential undo functionality
                print("Moved snippet '\(snippet.shortcut)' to collection '\(collection.name)'")
            }
        }
    }
}
