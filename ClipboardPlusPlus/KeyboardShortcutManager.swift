import Foundation
import Carbon
import AppKit

class KeyboardShortcutManager {
    private var eventHandlers: [EventHandlerRef] = []
    private weak var clipboardManager: ClipboardManager?
    
    init(clipboardManager: ClipboardManager) {
        self.clipboardManager = clipboardManager
        registerShortcuts()
    }
    
    deinit {
        unregisterShortcuts()
    }
    
    private func registerShortcuts() {
        // Register Command+1 through Command+9 for pasting items 1-9
        for i in 1...9 {
            registerShortcut(keyCode: UInt32(0x12 + i - 1), modifiers: UInt32(cmdKey), index: i - 1)
        }
    }
    
    private func registerShortcut(keyCode: UInt32, modifiers: UInt32, index: Int) {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D434C50), // "MCLP" for Clipboard++
                                     id: UInt32(index))
        var hotKeyRef: EventHotKeyRef? = nil
        
        let status = RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
        
        if status == noErr {
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
        for handler in eventHandlers {
            RemoveEventHandler(handler)
        }
        eventHandlers.removeAll()
    }
}
