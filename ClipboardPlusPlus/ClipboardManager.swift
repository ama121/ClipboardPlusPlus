import Foundation
import AppKit

class ClipboardItem: Identifiable, Codable {
    var id = UUID()
    var content: String? // For text
    var imageData: Data? // For images
    var date: Date
    var type: String
    
    init(content: String, type: String) {
        self.content = content
        self.imageData = nil
        self.date = Date()
        self.type = type
    }
    
    init(imageData: Data, type: String) {
        self.content = nil
        self.imageData = imageData
        self.date = Date()
        self.type = type
    }
}

class ClipboardManager: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []
    private let maxItems = 9
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    
    init() {
        loadFromDisk()
        startMonitoring()
    }
    
    private func startMonitoring() {
        // Check clipboard every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    private func checkClipboard() {
        let pasteboard = NSPasteboard.general
        
        // Only process if the pasteboard has changed
        if pasteboard.changeCount != lastChangeCount {
            lastChangeCount = pasteboard.changeCount
            
            // Check for image content first
            if let image = NSImage(pasteboard: pasteboard),
               let tiffData = image.tiffRepresentation {
                addImageItem(imageData: tiffData, type: "image")
                return
            }
            // Check for text content
            if let string = pasteboard.string(forType: .string) {
                addTextItem(content: string, type: "text")
            }
        }
    }
    
    func addTextItem(content: String, type: String) {
        // Don't add duplicates
        if !clipboardItems.contains(where: { $0.content == content && $0.type == "text" }) {
            let newItem = ClipboardItem(content: content, type: type)
            clipboardItems.insert(newItem, at: 0)
            if clipboardItems.count > maxItems {
                clipboardItems.removeLast()
            }
            saveToDisk()
        }
    }
    
    func addImageItem(imageData: Data, type: String) {
        // Don't add duplicates (by image data)
        if !clipboardItems.contains(where: { $0.imageData == imageData && $0.type == "image" }) {
            let newItem = ClipboardItem(imageData: imageData, type: type)
            clipboardItems.insert(newItem, at: 0)
            if clipboardItems.count > maxItems {
                clipboardItems.removeLast()
            }
            saveToDisk()
        }
    }
    
    func copyToClipboard(item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        if item.type == "text", let content = item.content {
            pasteboard.setString(content, forType: .string)
        } else if item.type == "image", let imageData = item.imageData, let image = NSImage(data: imageData) {
            pasteboard.writeObjects([image])
        }
    }
    
    func clearHistory() {
        clipboardItems.removeAll()
        saveToDisk()
    }
    
    // MARK: - Persistence
    
    private func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(clipboardItems)
            let url = getDocumentsDirectory().appendingPathComponent("clipboardHistory.json")
            try data.write(to: url)
        } catch {
            print("Failed to save clipboard history: \(error)")
        }
    }
    
    private func loadFromDisk() {
        let url = getDocumentsDirectory().appendingPathComponent("clipboardHistory.json")
        
        do {
            let data = try Data(contentsOf: url)
            clipboardItems = try JSONDecoder().decode([ClipboardItem].self, from: data)
        } catch {
            print("Failed to load clipboard history: \(error)")
            // It's okay if this fails on first run
        }
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
}
