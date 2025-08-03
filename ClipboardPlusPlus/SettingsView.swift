import SwiftUI

struct SettingsView: View {
    @ObservedObject var shortcutPreferences: ShortcutPreferences
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Fixed header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            // Scrollable content
            ScrollView {
                VStack(alignment: .leading, spacing: 15) {
                    Text("Keyboard Shortcuts")
                        .font(.headline)
                    
                    Text("Choose the modifier keys for pasting clipboard items:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 10) {
                        ForEach(ShortcutModifier.allCases, id: \.rawValue) { modifier in
                            HStack {
                                Button(action: {
                                    shortcutPreferences.selectedModifier = modifier
                                }) {
                                    HStack {
                                        Image(systemName: shortcutPreferences.selectedModifier == modifier ? "largecircle.fill.circle" : "circle")
                                            .foregroundColor(.blue)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(modifier.displayName)
                                                .font(.body)
                                            Text("Example: \(modifier.shortDisplayName)1 to paste first item")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(shortcutPreferences.selectedModifier == modifier ? Color.blue.opacity(0.1) : Color.clear)
                                            .stroke(shortcutPreferences.selectedModifier == modifier ? Color.blue : Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                    
                    VStack(spacing: 5) {
                        Text("Current shortcuts:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(shortcutPreferences.getFullShortcutText())
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding()
            }
        }
        .frame(width: 400, height: 300)
    }
}
