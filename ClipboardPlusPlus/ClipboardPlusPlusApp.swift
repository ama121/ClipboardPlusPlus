import SwiftUI

@main
struct ClipboardPlusPlusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var clipboardManager: ClipboardManager!
    var popover: NSPopover!
    var shortcutManager: KeyboardShortcutManager!
    var shortcutPreferences: ShortcutPreferences!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon programmatically
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize preferences and clipboard manager
        shortcutPreferences = ShortcutPreferences()
        clipboardManager = ClipboardManager()
        
        // Setup status bar item
        statusBarItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusBarItem.button {
            button.image = NSImage(systemSymbolName: "clipboard", accessibilityDescription: "Clipboard++")
            button.action = #selector(togglePopover)
        }
        
        // Setup popover
        popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 400)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: ClipboardHistoryView(
                clipboardManager: clipboardManager,
                shortcutPreferences: shortcutPreferences
            )
        )
        
        // Register global shortcuts
        setupGlobalShortcuts()
    }
    
    @objc func togglePopover() {
        if let button = statusBarItem.button {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popover.contentViewController?.view.window?.makeKey()
            }
        }
    }
    
    private func setupGlobalShortcuts() {
        shortcutManager = KeyboardShortcutManager(
            clipboardManager: clipboardManager,
            shortcutPreferences: shortcutPreferences
        )
        
        // Listen for paste notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pasteClipboardItem),
            name: NSNotification.Name("PasteClipboardItem"),
            object: nil
        )
    }
    
    @objc func pasteClipboardItem(notification: Notification) {
        if let index = notification.userInfo?["index"] as? Int {
            if index < clipboardManager.clipboardItems.count {
                let item = clipboardManager.clipboardItems[index]
                clipboardManager.copyToClipboard(item: item)
                
                // Simulate paste command (Command+V)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    let source = CGEventSource(stateID: .hidSystemState)
                    
                    // Create key down event for Command+V
                    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
                    keyDown?.flags = .maskCommand
                    
                    // Create key up event for Command+V
                    let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
                    
                    // Post events
                    keyDown?.post(tap: .cghidEventTap)
                    keyUp?.post(tap: .cghidEventTap)
                }
            }
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
