import Cocoa

extension NSTextField {

    /// Return an `NSTextField` configured exactly like one created by dragging a “Label” into a storyboard.
    class func newLabel(stringValue: String) -> NSTextField {
        let label = NSTextField()
        label.isEditable = false
        label.isSelectable = false
        label.textColor = .labelColor
        label.backgroundColor = .controlColor
        label.drawsBackground = false
        label.isBezeled = false
        label.alignment = .natural
        label.font = NSFont.systemFont(ofSize: NSFont.systemFontSize(for: label.controlSize))
        label.lineBreakMode = .byClipping
        label.cell?.isScrollable = true
        label.cell?.wraps = false
        label.stringValue = stringValue
        return label
    }

    /// Return an `NSTextField` configured exactly like one created by dragging a “Wrapping Label” into a storyboard.
    class func newWrappingLabel(stringValue: String) -> NSTextField {
        let label = newLabel(stringValue: stringValue)
        label.lineBreakMode = .byWordWrapping
        label.cell?.isScrollable = false
        label.cell?.wraps = true
        return label
    }

}

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    // We need to declare NSStatusItem here, otherwise it gets destroyed after
    // applicationDidFinishLaunching is called
    var statusBarItem : NSStatusItem!
    var statusBarMenu : NSMenu!
    
    var textView: NSTextView!
    var textStore: NSTextStorage!
    
    var started: Bool = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Returns the system-wide status bar located in the menu bar.
        let statusBar = NSStatusBar.system

        // Returns a newly created status item that has been allotted a specified space within the status bar.
        self.statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        self.statusBarItem.button?.image = NSImage(systemSymbolName: "star.fill", accessibilityDescription: "Status bar icon")

        // An object that manages an app’s menus.
        self.statusBarMenu = NSMenu()
        
        //let title = NSMenuItem()
        //title.attributedTitle = NSAttributedString(string: "Battery Toolkit", attributes: [.font: NSFont.boldSystemFont(ofSize: 0.0)])
        //self.statusBarMenu.addItem(title)

        self.statusBarMenu.addItem(withTitle: "External Power: Enabled", action: nil, keyEquivalent: "")
        self.statusBarMenu.addItem(withTitle: "Charging On Hold", action: nil, keyEquivalent: "")
        
        self.statusBarMenu.addItem(NSMenuItem.separator())
        
        let disablePower = NSMenuItem(title: "Disable External Power", action: #selector(AppDelegate.disableExternalPower), keyEquivalent: "d")
        disablePower.target = AppDelegate.self
        self.statusBarMenu.addItem(disablePower)
        let enablePower = NSMenuItem(title: "Enable External Power", action: #selector(AppDelegate.enableExternalPower), keyEquivalent: "D")
        enablePower.target = AppDelegate.self
        enablePower.isAlternate = true
        self.statusBarMenu.addItem(enablePower)
        
        let chargeFull = NSMenuItem(title: "Charge to Full Now", action: #selector(AppDelegate.chargeToFull), keyEquivalent: "c")
        chargeFull.target = AppDelegate.self
        self.statusBarMenu.addItem(chargeFull)
        let chargeMax = NSMenuItem(title: "Charge to Maximum Now", action: #selector(AppDelegate.chargeToMaximum), keyEquivalent: "C")
        chargeMax.target = AppDelegate.self
        chargeMax.isAlternate = true
        self.statusBarMenu.addItem(chargeMax)
        
        self.statusBarMenu.addItem(NSMenuItem.separator())
        
        self.statusBarMenu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        // Add menu to statusbar
        self.statusBarItem.menu = self.statusBarMenu
        
        started = BatteryToolkit.start()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        if started {
            BatteryToolkit.stop()
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    @objc private static func disableExternalPower() {
        BatteryToolkit.disableExternalPower()
    }
    
    @objc private static func enableExternalPower() {
        BatteryToolkit.enableExternalPower()
    }

    @objc private static func chargeToMaximum() {
        BatteryToolkit.chargeToMaximum()
    }

    @objc private static func chargeToFull() {
        BatteryToolkit.chargeToFull()
    }
}
