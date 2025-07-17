import SwiftUI

// MARK: - All Shared UI Components
// Put ALL shared components in this one file to avoid duplicates

// MARK: - Resize Handle Component
struct ResizeHandle: View {
    @Binding var editorWidth: CGFloat
    let windowWidth: CGFloat
    @Binding var isDragging: Bool
    @State private var isHovered = false
    @State private var startWidth: CGFloat = 0
    @State private var startLocation: CGFloat = 0
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 12)
            .contentShape(Rectangle())
            .background(
                Rectangle()
                    .fill(isHovered || isDragging ? Color.accentColor.opacity(0.2) : Color.clear)
                    .animation(.easeInOut(duration: 0.2), value: isHovered || isDragging)
            )
            .overlay(
                Rectangle()
                    .fill(Color(NSColor.separatorColor))
                    .frame(width: isDragging ? 2 : 1)
                    .animation(.easeInOut(duration: 0.1), value: isDragging)
            )
            .cursor(NSCursor.resizeLeftRight)
            .onHover { hovering in
                isHovered = hovering
            }
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            startWidth = editorWidth
                            startLocation = value.startLocation.x
                        }
                        
                        let deltaX = value.location.x - startLocation
                        let deltaWidth = -deltaX / windowWidth
                        let newWidth = startWidth + deltaWidth
                        
                        editorWidth = min(max(newWidth, 0.25), 0.65)
                    }
                    .onEnded { _ in
                        isDragging = false
                        
                        let snapTargets: [CGFloat] = [0.25, 0.33, 0.4, 0.5, 0.6, 0.65]
                        let snapThreshold: CGFloat = 0.03
                        
                        for target in snapTargets {
                            if abs(editorWidth - target) < snapThreshold {
                                withAnimation(.easeOut(duration: 0.3)) {
                                    editorWidth = target
                                }
                                return
                            }
                        }
                    }
            )
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    let isSearching: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: isSearching ? "magnifyingglass" : "doc.text.below.ecg")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
            }
            
            VStack(spacing: 12) {
                Text(isSearching ? "No matching snippets" : "No snippets yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(isSearching ?
                     "Try adjusting your search terms or click 'Add' to create a new one" :
                     "Click 'Add' to create your first text expansion")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
    }
}

// MARK: - Compact Toggle Style
struct CompactToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 8)
                .fill(configuration.isOn ? Color.green : Color(NSColor.controlColor))
                .frame(width: 32, height: 18)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 14, height: 14)
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 0.5)
                        .offset(x: configuration.isOn ? 7 : -7)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

// MARK: - Modern Toggle Style
struct ModernToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
            
            RoundedRectangle(cornerRadius: 12)
                .fill(configuration.isOn ? Color.green : Color(NSColor.controlColor))
                .frame(width: 44, height: 24)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 20, height: 20)
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}

// MARK: - Compact Action Button
struct CompactActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .medium))
                Text(title)
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(color.opacity(isPressed ? 0.2 : 0.1))
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Compact Tip Component
struct CompactTip: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(Color.orange)
                .frame(width: 4, height: 4)
            
            Text(text)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Settings Section Component
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 16))
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            
            content
        }
    }
}

// MARK: - Settings Row Component
struct SettingsRow<Content: View>: View {
    let title: String
    let subtitle: String
    let control: Content
    
    init(title: String, subtitle: String, @ViewBuilder control: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.control = control()
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            control
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Collection Card Component
struct CollectionCard: View {
    let name: String
    let snippets: [Snippet]
    @State private var isExpanded = false
    
    var enabledCount: Int {
        snippets.filter(\.isEnabled).count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("\(snippets.count) snippets • \(enabledCount) enabled")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            
            if !isExpanded {
                HStack {
                    ForEach(Array(snippets.prefix(3)), id: \.id) { snippet in
                        Text(snippet.shortcut)
                            .font(.system(.caption, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.accentColor.opacity(0.1))
                            )
                            .foregroundColor(.accentColor)
                    }
                    
                    if snippets.count > 3 {
                        Text("+\(snippets.count - 3)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            
            if isExpanded {
                VStack(spacing: 8) {
                    ForEach(snippets) { snippet in
                        HStack {
                            Text(snippet.shortcut)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.accentColor.opacity(0.1))
                                )
                                .foregroundColor(.accentColor)
                            
                            Image(systemName: "arrow.right")
                                .foregroundColor(.secondary)
                                .font(.caption)
                            
                            Text(snippet.expansion.replacingOccurrences(of: "\n", with: " "))
                                .font(.caption)
                                .lineLimit(1)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Circle()
                                .fill(snippet.isEnabled ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
        )
    }
}
