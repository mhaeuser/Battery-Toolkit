import Cocoa

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var statusBarMenu: NSMenu!
    private var statusBarItem : NSStatusItem!
    
    @IBOutlet weak var powerAdapterMenuItem: NSMenuItem!
    @IBOutlet weak var chargingMenuItem: NSMenuItem!
    
    private var started: Bool = false

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        started = BatteryToolkit.start()
        // FIXME: Handle error

        self.statusBarItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
            )
        self.statusBarItem.button?.image = NSImage(named: NSImage.Name("StatusItemIcon"))
        self.statusBarItem.menu = self.statusBarMenu
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        if started {
            BatteryToolkit.stop()
        }
    }

    @IBAction private func disablePowerAdapter(sender: NSMenuItem) {
        BatteryToolkit.disablePowerAdapter()
    }
    
    @IBAction private func enablePowerAdapter(sender: NSMenuItem) {
        BatteryToolkit.enablePowerAdapter()
    }

    @IBAction private func chargeToMaximum(sender: NSMenuItem) {
        BatteryToolkit.chargeToMaximum()
    }

    @IBAction private func chargeToFull(sender: NSMenuItem) {
        BatteryToolkit.chargeToFull()
    }
}
