import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    @ObservedObject var shortcutPreferences: ShortcutPreferences
    @State private var showingSettings = false
    
    var body: some View {
        VStack {
            HStack {
                Text("Clipboard++")
                    .font(.headline)
                Spacer()
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gear")
                }
                .buttonStyle(.borderless)
                .help("Settings")
                
                Button(action: {
                    clipboardManager.clearHistory()
                }) {
                    Text("Clear All")
                }
                .buttonStyle(.borderless)
            }
            .padding([.horizontal, .top])
            
            List {
                ForEach(Array(clipboardManager.clipboardItems.enumerated()), id: \.element.id) { index, item in
                    ClipboardItemView(item: item, index: index, clipboardManager: clipboardManager, shortcutPreferences: shortcutPreferences)
                }
            }
            
            // Force UI update by directly using the selectedModifier
            Text("Shortcuts: \(shortcutPreferences.selectedModifier.shortDisplayName)1-\(shortcutPreferences.selectedModifier.shortDisplayName)9 to paste items")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 5)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(shortcutPreferences: shortcutPreferences)
        }
    }
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    let index: Int
    let clipboardManager: ClipboardManager
    @ObservedObject var shortcutPreferences: ShortcutPreferences
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Display the shortcut number with current modifier - directly use selectedModifier for reactivity
            Text("\(shortcutPreferences.selectedModifier.shortDisplayName)\(index + 1)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.blue)
                .frame(width: 35, alignment: .center)
                .padding(.top, 2)
            
            VStack(alignment: .leading) {
                Text(item.content)
                    .lineLimit(2)
                    .truncationMode(.tail)
                
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            clipboardManager.copyToClipboard(item: item)
        }
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: item.date)
    }
}
