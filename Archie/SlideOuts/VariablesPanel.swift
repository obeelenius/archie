//  VariablesPanel.swift

import SwiftUI

// MARK: - Variables Panel Component 100044
struct VariablesPanel: View {
    let onVariableSelected: (String) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            variablesContent
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Header Section 100045
extension VariablesPanel {
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Variables")
                    .font(.system(size: 14, weight: .bold))
                
                Text("Click to insert")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Variables Content 100046
extension VariablesPanel {
    private var variablesContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                VariableSection(
                    title: "Dates",
                    icon: "calendar",
                    variables: dateVariables,
                    onVariableSelected: onVariableSelected
                )
                
                VariableSection(
                    title: "Times",
                    icon: "clock",
                    variables: timeVariables,
                    onVariableSelected: onVariableSelected
                )
                
                VariableSection(
                    title: "Relative",
                    icon: "arrow.left.and.right.circle",
                    variables: relativeVariables,
                    onVariableSelected: onVariableSelected
                )
                
                VariableSection(
                    title: "Components",
                    icon: "calendar.badge.gearshape",
                    variables: componentVariables,
                    onVariableSelected: onVariableSelected
                )
            }
            .padding(16)
        }
        .background(Color(NSColor.textBackgroundColor).opacity(0.5))
    }
}

// MARK: - Date Variables 100047
extension VariablesPanel {
    private var dateVariables: [VariableInfo] {
        [
            VariableInfo(
                variable: "{{date}}",
                title: "Today's Date",
                example: DateFormatterHelper.mediumDateFormatter.string(from: Date()),
                icon: "calendar",
                color: .blue
            ),
            VariableInfo(
                variable: "{{date-short}}",
                title: "Short Date",
                example: DateFormatterHelper.shortDateFormatter.string(from: Date()),
                icon: "calendar.badge.clock",
                color: .green
            ),
            VariableInfo(
                variable: "{{date-long}}",
                title: "Long Date",
                example: DateFormatterHelper.longDateFormatter.string(from: Date()),
                icon: "calendar.badge.plus",
                color: .purple
            ),
            VariableInfo(
                variable: "{{date-iso}}",
                title: "ISO Date",
                example: ISO8601DateFormatter().string(from: Date()),
                icon: "calendar.badge.exclamationmark",
                color: .orange
            ),
            VariableInfo(
                variable: "{{date-1}}",
                title: "Yesterday",
                example: DateFormatterHelper.mediumDateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
                icon: "calendar.badge.minus",
                color: .red
            ),
            VariableInfo(
                variable: "{{date+1}}",
                title: "Tomorrow",
                example: DateFormatterHelper.mediumDateFormatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()),
                icon: "calendar.badge.plus",
                color: .green
            )
        ]
    }
}

// MARK: - Time Variables 100048
extension VariablesPanel {
    private var timeVariables: [VariableInfo] {
        [
            VariableInfo(
                variable: "{{time}}",
                title: "Current Time",
                example: DateFormatterHelper.shortTimeFormatter.string(from: Date()),
                icon: "clock",
                color: .blue
            ),
            VariableInfo(
                variable: "{{time-24}}",
                title: "24-Hour Time",
                example: DateFormatterHelper.time24HourFormatter.string(from: Date()),
                icon: "clock.badge.checkmark",
                color: .green
            ),
            VariableInfo(
                variable: "{{time-12}}",
                title: "12-Hour Time",
                example: DateFormatterHelper.time12HourFormatter.string(from: Date()),
                icon: "clock.badge.questionmark",
                color: .orange
            ),
            VariableInfo(
                variable: "{{time-seconds}}",
                title: "Time with Seconds",
                example: DateFormatterHelper.timeWithSecondsFormatter.string(from: Date()),
                icon: "stopwatch",
                color: .purple
            ),
            VariableInfo(
                variable: "{{hour}}",
                title: "Current Hour",
                example: DateFormatterHelper.hourFormatter.string(from: Date()),
                icon: "h.circle",
                color: .indigo
            ),
            VariableInfo(
                variable: "{{minute}}",
                title: "Current Minute",
                example: DateFormatterHelper.minuteFormatter.string(from: Date()),
                icon: "m.circle",
                color: .teal
            )
        ]
    }
}

// MARK: - Relative Variables 100049
extension VariablesPanel {
    private var relativeVariables: [VariableInfo] {
        [
            VariableInfo(
                variable: "{{date-1}}",
                title: "Yesterday",
                example: DateFormatterHelper.mediumDateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()),
                icon: "arrow.left.circle",
                color: .red
            ),
            VariableInfo(
                variable: "{{date+1}}",
                title: "Tomorrow",
                example: DateFormatterHelper.mediumDateFormatter.string(from: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()),
                icon: "arrow.right.circle",
                color: .green
            ),
            VariableInfo(
                variable: "{{date+7}}",
                title: "Next Week",
                example: DateFormatterHelper.mediumDateFormatter.string(from: Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()),
                icon: "arrow.forward.circle",
                color: .blue
            ),
            VariableInfo(
                variable: "{{date-7}}",
                title: "Last Week",
                example: DateFormatterHelper.mediumDateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()),
                icon: "arrow.backward.circle",
                color: .orange
            )
        ]
    }
}

// MARK: - Component Variables 100050
extension VariablesPanel {
    private var componentVariables: [VariableInfo] {
        [
            VariableInfo(
                variable: "{{day}}",
                title: "Day of Month",
                example: DateFormatterHelper.dayFormatter.string(from: Date()),
                icon: "calendar.day.timeline.left",
                color: .blue
            ),
            VariableInfo(
                variable: "{{month}}",
                title: "Month Name",
                example: DateFormatterHelper.monthFormatter.string(from: Date()),
                icon: "calendar.circle",
                color: .green
            ),
            VariableInfo(
                variable: "{{year}}",
                title: "Year",
                example: DateFormatterHelper.yearFormatter.string(from: Date()),
                icon: "calendar.badge.clock",
                color: .purple
            ),
            VariableInfo(
                variable: "{{timestamp}}",
                title: "Unix Timestamp",
                example: String(Int(Date().timeIntervalSince1970)),
                icon: "number.circle",
                color: .orange
            )
        ]
    }
}

// MARK: - Variable Info Model 100051
struct VariableInfo {
    let variable: String
    let title: String
    let example: String
    let icon: String
    let color: Color
}

// MARK: - Variable Section Component 100052
struct VariableSection: View {
    let title: String
    let icon: String
    let variables: [VariableInfo]
    let onVariableSelected: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader
            variablesGrid
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(NSColor.controlBackgroundColor))
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
        )
    }
    
    private var sectionHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.system(size: 12, weight: .medium))
            
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    private var variablesGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 8),
            GridItem(.flexible(), spacing: 8)
        ], spacing: 10) {
            ForEach(variables, id: \.variable) { variableInfo in
                VariablePill(
                    variableInfo: variableInfo,
                    onTap: {
                        onVariableSelected(variableInfo.variable)
                    }
                )
            }
        }
    }
}

// MARK: - Enhanced Variable Pill Component 100053
struct VariablePill: View {
    let variableInfo: VariableInfo
    let onTap: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Variable code at top
                Text(variableInfo.variable)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(variableInfo.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(variableInfo.color.opacity(0.12))
                    )
                
                // Title and example
                VStack(alignment: .leading, spacing: 4) {
                    Text(variableInfo.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(variableInfo.example)
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(buttonBackground)
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.97 : (isHovered ? 1.02 : 1.0))
        .animation(.easeInOut(duration: 0.15), value: isPressed)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .help("\(variableInfo.title) - Example: \(variableInfo.example)")
    }
    
    private var buttonBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(buttonBackgroundColor)
            .stroke(buttonBorderColor, lineWidth: 1)
            .shadow(
                color: .black.opacity(isPressed ? 0.08 : 0.03),
                radius: isPressed ? 2 : 4,
                x: 0,
                y: isPressed ? 1 : 2
            )
    }
    
    private var buttonBackgroundColor: Color {
        if isPressed {
            return variableInfo.color.opacity(0.12)
        } else if isHovered {
            return variableInfo.color.opacity(0.06)
        } else {
            return Color(NSColor.controlBackgroundColor)
        }
    }
    
    private var buttonBorderColor: Color {
        if isPressed {
            return variableInfo.color.opacity(0.4)
        } else if isHovered {
            return variableInfo.color.opacity(0.25)
        } else {
            return Color(NSColor.separatorColor).opacity(0.3)
        }
    }
}

// MARK: - Date Formatter Helper 100054
struct DateFormatterHelper {
    static let mediumDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    static let longDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter
    }()
    
    static let shortTimeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let time24HourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    static let time12HourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
    
    static let timeWithSecondsFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
    
    static let hourFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH"
        return formatter
    }()
    
    static let minuteFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "mm"
        return formatter
    }()
    
    static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        return formatter
    }()
    
    static let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()
    
    static let yearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter
    }()
}
