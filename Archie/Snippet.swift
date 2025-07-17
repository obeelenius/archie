import Foundation

struct Snippet: Identifiable, Codable, Hashable, Equatable {
    var id = UUID()
    var shortcut: String
    var expansion: String
    var isEnabled: Bool = true
    var requiresSpace: Bool = true // New property for space requirement
    var collectionId: UUID? // Reference to collection
    var variables: [SnippetVariable] = [] // Variables used in this snippet
    
    init(shortcut: String, expansion: String, requiresSpace: Bool = true, collectionId: UUID? = nil) {
        self.shortcut = shortcut
        self.expansion = expansion
        self.requiresSpace = requiresSpace
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
    
    // Process variables in expansion text - UPDATED WITH ALL NEW VARIABLES
    func processedExpansion() -> String {
        var processed = self.expansion
        
        // Get current date and time
        let now = Date()
        let calendar = Calendar.current
        
        // MARK: - Date Variables
        
        // Default date (medium style)
        let defaultDateFormatter = DateFormatter()
        defaultDateFormatter.dateStyle = .medium
        defaultDateFormatter.timeStyle = .none
        processed = processed.replacingOccurrences(of: "{{date}}", with: defaultDateFormatter.string(from: now))
        
        // Short numeric date (YYYY-MM-DD)
        let shortDateFormatter = DateFormatter()
        shortDateFormatter.dateFormat = "yyyy-MM-dd"
        processed = processed.replacingOccurrences(of: "{{date-short}}", with: shortDateFormatter.string(from: now))
        
        // Long written date
        let longDateFormatter = DateFormatter()
        longDateFormatter.dateFormat = "EEEE, MMMM d, yyyy"
        processed = processed.replacingOccurrences(of: "{{date-long}}", with: longDateFormatter.string(from: now))
        
        // ISO 8601 date
        let isoFormatter = ISO8601DateFormatter()
        processed = processed.replacingOccurrences(of: "{{date-iso}}", with: isoFormatter.string(from: now))
        
        // US format (MM/DD/YYYY)
        let usDateFormatter = DateFormatter()
        usDateFormatter.dateFormat = "MM/dd/yyyy"
        processed = processed.replacingOccurrences(of: "{{date-us}}", with: usDateFormatter.string(from: now))
        
        // UK format (DD/MM/YYYY)
        let ukDateFormatter = DateFormatter()
        ukDateFormatter.dateFormat = "dd/MM/yyyy"
        processed = processed.replacingOccurrences(of: "{{date-uk}}", with: ukDateFormatter.string(from: now))
        
        // Compact format (YYYYMMDD)
        let compactDateFormatter = DateFormatter()
        compactDateFormatter.dateFormat = "yyyyMMdd"
        processed = processed.replacingOccurrences(of: "{{date-compact}}", with: compactDateFormatter.string(from: now))
        
        // MARK: - Date Components
        
        // Day number
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        processed = processed.replacingOccurrences(of: "{{day}}", with: dayFormatter.string(from: now))
        
        // Day name (full)
        let dayNameFormatter = DateFormatter()
        dayNameFormatter.dateFormat = "EEEE"
        processed = processed.replacingOccurrences(of: "{{day-name}}", with: dayNameFormatter.string(from: now))
        
        // Day name (short)
        let dayShortFormatter = DateFormatter()
        dayShortFormatter.dateFormat = "EEE"
        processed = processed.replacingOccurrences(of: "{{day-short}}", with: dayShortFormatter.string(from: now))
        
        // Month number
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "M"
        processed = processed.replacingOccurrences(of: "{{month}}", with: monthFormatter.string(from: now))
        
        // Month name (full)
        let monthNameFormatter = DateFormatter()
        monthNameFormatter.dateFormat = "MMMM"
        processed = processed.replacingOccurrences(of: "{{month-name}}", with: monthNameFormatter.string(from: now))
        
        // Month name (short)
        let monthShortFormatter = DateFormatter()
        monthShortFormatter.dateFormat = "MMM"
        processed = processed.replacingOccurrences(of: "{{month-short}}", with: monthShortFormatter.string(from: now))
        
        // Year (full)
        let yearFormatter = DateFormatter()
        yearFormatter.dateFormat = "yyyy"
        processed = processed.replacingOccurrences(of: "{{year}}", with: yearFormatter.string(from: now))
        
        // Year (short)
        let yearShortFormatter = DateFormatter()
        yearShortFormatter.dateFormat = "yy"
        processed = processed.replacingOccurrences(of: "{{year-short}}", with: yearShortFormatter.string(from: now))
        
        // MARK: - Time Variables
        
        // Default time (short style)
        let defaultTimeFormatter = DateFormatter()
        defaultTimeFormatter.dateStyle = .none
        defaultTimeFormatter.timeStyle = .short
        processed = processed.replacingOccurrences(of: "{{time}}", with: defaultTimeFormatter.string(from: now))
        
        // 24-hour format
        let time24Formatter = DateFormatter()
        time24Formatter.dateFormat = "HH:mm"
        processed = processed.replacingOccurrences(of: "{{time-24}}", with: time24Formatter.string(from: now))
        
        // 12-hour with AM/PM
        let time12Formatter = DateFormatter()
        time12Formatter.dateFormat = "h:mm a"
        processed = processed.replacingOccurrences(of: "{{time-12}}", with: time12Formatter.string(from: now))
        
        // 12-hour no space
        let time12NoSpaceFormatter = DateFormatter()
        time12NoSpaceFormatter.dateFormat = "h:mma"
        processed = processed.replacingOccurrences(of: "{{time-12-no-space}}", with: time12NoSpaceFormatter.string(from: now))
        
        // With seconds (12-hour)
        let timeSecondsFormatter = DateFormatter()
        timeSecondsFormatter.dateFormat = "h:mm:ss a"
        processed = processed.replacingOccurrences(of: "{{time-seconds}}", with: timeSecondsFormatter.string(from: now))
        
        // 24-hour with seconds
        let time24SecondsFormatter = DateFormatter()
        time24SecondsFormatter.dateFormat = "HH:mm:ss"
        processed = processed.replacingOccurrences(of: "{{time-24-seconds}}", with: time24SecondsFormatter.string(from: now))
        
        // Hour (12-format)
        let hourFormatter = DateFormatter()
        hourFormatter.dateFormat = "h"
        processed = processed.replacingOccurrences(of: "{{hour}}", with: hourFormatter.string(from: now))
        
        // Hour (24-format)
        let hour24Formatter = DateFormatter()
        hour24Formatter.dateFormat = "HH"
        processed = processed.replacingOccurrences(of: "{{hour-24}}", with: hour24Formatter.string(from: now))
        
        // Minutes
        let minuteFormatter = DateFormatter()
        minuteFormatter.dateFormat = "mm"
        processed = processed.replacingOccurrences(of: "{{minute}}", with: minuteFormatter.string(from: now))
        
        // MARK: - Relative Dates
        
        // Yesterday
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        processed = processed.replacingOccurrences(of: "{{date-1}}", with: defaultDateFormatter.string(from: yesterday))
        
        // Tomorrow
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        processed = processed.replacingOccurrences(of: "{{date+1}}", with: defaultDateFormatter.string(from: tomorrow))
        
        // One week ago
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        processed = processed.replacingOccurrences(of: "{{date-7}}", with: defaultDateFormatter.string(from: weekAgo))
        
        // One week from now
        let weekFromNow = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        processed = processed.replacingOccurrences(of: "{{date+7}}", with: defaultDateFormatter.string(from: weekFromNow))
        
        // MARK: - Technical Formats
        
        // Unix timestamp
        processed = processed.replacingOccurrences(of: "{{timestamp}}", with: String(Int(now.timeIntervalSince1970)))
        
        // Unix timestamp with milliseconds
        processed = processed.replacingOccurrences(of: "{{timestamp-ms}}", with: String(Int(now.timeIntervalSince1970 * 1000)))
        
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
