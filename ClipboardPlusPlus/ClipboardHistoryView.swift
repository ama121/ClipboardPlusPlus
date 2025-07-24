import SwiftUI

struct ClipboardHistoryView: View {
    @ObservedObject var clipboardManager: ClipboardManager
    
    var body: some View {
        VStack {
            HStack {
                Text("Clipboard++")
                    .font(.headline)
                Spacer()
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
                    ClipboardItemView(item: item, index: index, clipboardManager: clipboardManager)
                }
            }
            
            Text("Shortcuts: ⌘1-⌘9 to paste items")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom, 5)
        }
    }
}

struct ClipboardItemView: View {
    let item: ClipboardItem
    let index: Int
    let clipboardManager: ClipboardManager
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Display the shortcut number (index + 1 because arrays are 0-indexed)
            Text("\(index + 1)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.blue)
                .frame(width: 20, alignment: .center)
                .padding(.top, 2)
            
            VStack(alignment: .leading) {
                if item.type == "image", let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: 80, maxHeight: 60)
                        .cornerRadius(6)
                } else if let content = item.content {
                    Text(content)
                        .lineLimit(2)
                        .truncationMode(.tail)
                }
                
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
