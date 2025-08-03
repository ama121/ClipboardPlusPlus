import Foundation
import Carbon
import AppKit

class KeyboardShortcutManager {
    private var eventHandlers: [EventHandlerRef] = []
    private var hotKeyRefs: [EventHotKeyRef] = []  // Store hot key references for proper cleanup
    private weak var clipboardManager: ClipboardManager?
    private let shortcutPreferences: ShortcutPreferences
    
    init(clipboardManager: ClipboardManager, shortcutPreferences: ShortcutPreferences) {
        self.clipboardManager = clipboardManager
        self.shortcutPreferences = shortcutPreferences
        registerShortcuts()
        
        // Listen for preference changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(shortcutPreferenceChanged),
            name: .shortcutPreferenceChanged,
            object: nil
        )
    }
    
    deinit {
        unregisterShortcuts()
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func shortcutPreferenceChanged() {
        // Re-register shortcuts with new modifier
        unregisterShortcuts()
        registerShortcuts()
    }
    
    private func registerShortcuts() {
        // Register shortcuts using the current preference
        for i in 1...9 {
            registerShortcut(
                keyCode: UInt32(0x12 + i - 1), 
                modifiers: shortcutPreferences.selectedModifier.carbonModifiers, 
                index: i - 1
            )
        }
    }
    
    private func registerShortcut(keyCode: UInt32, modifiers: UInt32, index: Int) {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D434C50), // "MCLP" for Clipboard++
                                     id: UInt32(index))
        var hotKeyRef: EventHotKeyRef? = nil
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr, let hotKey = hotKeyRef {
            // Store the hot key reference for later cleanup
            hotKeyRefs.append(hotKey)
            
            var handlerRef: EventHandlerRef? = nil
            let handler: EventHandlerUPP = { (_, event, _) -> OSStatus in
                var hotKeyID = EventHotKeyID()
                let status = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
                
                if status == noErr {
                    let index = Int(hotKeyID.id)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("PasteClipboardItem"), object: nil, userInfo: ["index": index])
                    }
                }
                
                return noErr
            }
            
            InstallEventHandler(GetApplicationEventTarget(), handler, 1, &eventType, nil, &handlerRef)
            
            if let handlerRef = handlerRef {
                eventHandlers.append(handlerRef)
            }
        }
    }
    
    private func unregisterShortcuts() {
        // Remove event handlers
        for handler in eventHandlers {
            RemoveEventHandler(handler)
        }
        eventHandlers.removeAll()
        
        // Unregister hot keys
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        hotKeyRefs.removeAll()
    }
}
