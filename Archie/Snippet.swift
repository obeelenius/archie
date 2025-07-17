import Foundation

struct Snippet: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var shortcut: String
    var expansion: String
    var isEnabled: Bool = true
    var collectionId: UUID? // Reference to collection
    var variables: [SnippetVariable] = [] // Variables used in this snippet
    
    init(shortcut: String, expansion: String, collectionId: UUID? = nil) {
        self.shortcut = shortcut
        self.expansion = expansion
        self.collectionId = collectionId
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    static func == (lhs: Snippet, rhs: Snippet) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Get the full shortcut including collection suffix
    func fullShortcut(with collection: SnippetCollection?) -> String {
        guard let collection = collection, !collection.suffix.isEmpty else {
            return shortcut
        }
        return shortcut + collection.suffix
    }
    
    // Process variables in expansion text
    func processedExpansion() -> String {
        var processed = expansion
        
        // Replace built-in variables
        let now = Date()
        let formatter = DateFormatter()
        
        // Date variables
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        processed = processed.replacingOccurrences(of: "{{date}}", with: formatter.string(from: now))
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        processed = processed.replacingOccurrences(of: "{{date-1}}", with: formatter.string(from: yesterday))
        
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        processed = processed.replacingOccurrences(of: "{{date+1}}", with: formatter.string(from: tomorrow))
        
        // Time variables
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        processed = processed.replacingOccurrences(of: "{{time}}", with: formatter.string(from: now))
        
        // ISO date
        let isoFormatter = ISO8601DateFormatter()
        processed = processed.replacingOccurrences(of: "{{date-iso}}", with: isoFormatter.string(from: now))
        
        // Timestamp
        processed = processed.replacingOccurrences(of: "{{timestamp}}", with: String(Int(now.timeIntervalSince1970)))
        
        // Custom format dates
        formatter.dateFormat = "yyyy-MM-dd"
        processed = processed.replacingOccurrences(of: "{{date-short}}", with: formatter.string(from: now))
        
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        processed = processed.replacingOccurrences(of: "{{date-long}}", with: formatter.string(from: now))
        
        return processed
    }
}

struct SnippetCollection: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var name: String
    var suffix: String = "" // e.g., ";" or ".."
    var keepDelimiter: Bool = false // Keep the trigger delimiter (space)
    var color: String = "blue" // For UI theming
    var isEnabled: Bool = true
    
    init(name: String, suffix: String = "", keepDelimiter: Bool = false) {
        self.name = name
        self.suffix = suffix
        self.keepDelimiter = keepDelimiter
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // Equatable conformance
    static func == (lhs: SnippetCollection, rhs: SnippetCollection) -> Bool {
        return lhs.id == rhs.id
    }
}

struct SnippetVariable: Identifiable, Codable {
    var id = UUID()
    var name: String
    var type: VariableType
    var format: String? // For date formatting
    
    enum VariableType: String, CaseIterable, Codable {
        case currentDate = "date"
        case currentTime = "time"
        case dateYesterday = "date-1"
        case dateTomorrow = "date+1"
        case dateISO = "date-iso"
        case dateShort = "date-short"
        case dateLong = "date-long"
        case timestamp = "timestamp"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .currentDate: return "Current Date"
            case .currentTime: return "Current Time"
            case .dateYesterday: return "Yesterday"
            case .dateTomorrow: return "Tomorrow"
            case .dateISO: return "ISO Date"
            case .dateShort: return "Short Date (YYYY-MM-DD)"
            case .dateLong: return "Long Date"
            case .timestamp: return "Unix Timestamp"
            case .custom: return "Custom"
            }
        }
        
        var placeholder: String {
            return "{{\(self.rawValue)}}"
        }
    }
}
