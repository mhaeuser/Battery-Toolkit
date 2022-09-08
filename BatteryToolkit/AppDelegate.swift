import Cocoa

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var statusBarMenu: NSMenu!
    private var statusBarItem : NSStatusItem!
    
    @IBOutlet weak var powerAdapterMenuItem: NSMenuItem!
    @IBOutlet weak var chargingMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        BatteryToolkit.startDaemon() { (status) -> Void in
            switch status {
                case BTDaemonManagement.Status.enabled:
                    debugPrint("Daemon is enabled, start XPC connection")
                    _ = BatteryToolkit.startXpcClient()
                    
                case BTDaemonManagement.Status.requiresApproval:
                    debugPrint("Daemon requires approval")
                    
                    let alert = NSAlert()
                    alert.messageText = "Allow background activity?"
                    alert.informativeText = "To manage the power state of your Mac, Battery Toolkit must be allowed to run in the background.\n\nDo you want to approve the Battery Toolkit Login Item in System Settings?"
                    alert.alertStyle = NSAlert.Style.warning
                    alert.addButton(withTitle: "Approve")
                    alert.addButton(withTitle: "Quit")
                    let response = alert.runModal()
                    switch response {
                        case NSApplication.ModalResponse.alertFirstButtonReturn:
                            BTDaemonManagement.approveDaemon()
                            
                        case NSApplication.ModalResponse.alertSecondButtonReturn:
                            NSApplication.shared.terminate(self)
                            
                        default:
                            assert(false)
                    }

                case BTDaemonManagement.Status.notRegistered:
                    debugPrint("Daemon not registered")
                    // FIXME: Show GUI error
                    break
            }
        }

        self.statusBarItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
            )
        self.statusBarItem.button?.image = NSImage(named: NSImage.Name("StatusItemIcon"))
        self.statusBarItem.menu = self.statusBarMenu
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        BatteryToolkit.stop()
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
    
    private static func unregisterDaemonHelper() {
        BatteryToolkit.unregisterDaemon() { (success) -> Void in
            if success {
                return
            }

            let alert = NSAlert()
            alert.messageText = "An error occured uninstalling the daemon."
            alert.alertStyle = NSAlert.Style.critical
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Retry")
            let response = alert.runModal()
            if response == NSApplication.ModalResponse.alertSecondButtonReturn {
                AppDelegate.unregisterDaemonHelper()
            }
        }
    }
    
    @IBAction private func unregisterDaemon(sender: NSMenuItem) {
        AppDelegate.unregisterDaemonHelper()
    }
}
