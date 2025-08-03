import Foundation
import Carbon

enum ShortcutModifier: String, CaseIterable {
    case commandControl = "command_control"
    case commandOption = "command_option"
    
    var displayName: String {
        switch self {
        case .commandControl:
            return "⌘⌃ (Command + Control)"
        case .commandOption:
            return "⌘⌥ (Command + Option)"
        }
    }
    
    var shortDisplayName: String {
        switch self {
        case .commandControl:
            return "⌘⌃"
        case .commandOption:
            return "⌘⌥"
        }
    }
    
    var carbonModifiers: UInt32 {
        switch self {
        case .commandControl:
            return UInt32(cmdKey | controlKey)
        case .commandOption:
            return UInt32(cmdKey | optionKey)
        }
    }
}

class ShortcutPreferences: ObservableObject {
    @Published var selectedModifier: ShortcutModifier {
        didSet {
            UserDefaults.standard.set(selectedModifier.rawValue, forKey: "shortcut_modifier")
            NotificationCenter.default.post(name: .shortcutPreferenceChanged, object: selectedModifier)
        }
    }
    
    init() {
        let savedValue = UserDefaults.standard.string(forKey: "shortcut_modifier")
        self.selectedModifier = ShortcutModifier(rawValue: savedValue ?? "") ?? .commandControl
    }
    
    func getShortcutText(for number: Int) -> String {
        return "\(selectedModifier.shortDisplayName)\(number)"
    }
    
    func getFullShortcutText() -> String {
        return "\(selectedModifier.shortDisplayName)1-\(selectedModifier.shortDisplayName)9"
    }
}

extension Notification.Name {
    static let shortcutPreferenceChanged = Notification.Name("shortcutPreferenceChanged")
}