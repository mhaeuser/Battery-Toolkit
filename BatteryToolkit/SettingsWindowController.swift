import Foundation
import AppKit

final class SettingsWindowController: NSWindowController {
    override func windowDidLoad() {
        if #unavailable(macOS 13.0) {
            self.window?.title = "Battery Toolkit Preferences"
        }
    }
}
