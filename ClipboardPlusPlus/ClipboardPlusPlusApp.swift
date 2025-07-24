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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide dock icon programmatically
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize clipboard manager
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
        popover.contentViewController = NSHostingController(rootView: ClipboardHistoryView(clipboardManager: clipboardManager))
        
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
    
    func setupGlobalShortcuts() {
        shortcutManager = KeyboardShortcutManager(clipboardManager: clipboardManager)
        
        // Listen for paste notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePasteNotification(_:)),
            name: NSNotification.Name("PasteClipboardItem"),
            object: nil
        )
    }
    
    @objc func handlePasteNotification(_ notification: Notification) {
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