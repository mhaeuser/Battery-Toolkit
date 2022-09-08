import Cocoa

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var statusBarMenu: NSMenu!
    private var statusBarItem : NSStatusItem!
    
    @IBOutlet weak var powerAdapterExtraItem: NSMenuItem!
    @IBOutlet weak var chargingExtraItem: NSMenuItem!
    
    @IBOutlet weak var disableBackgroundMenuItem: NSMenuItem!
    
    private static let backgroundActivityRequiredStr = "To manage the power state of your Mac, Battery Toolkit needs to run in the background."

    private static func startDaemon() {
        BatteryToolkit.startDaemon() { (status) -> Void in
            switch status {
                case BTDaemonManagement.Status.enabled:
                    debugPrint("Daemon is enabled, start XPC connection")
                    _ = BatteryToolkit.startXpcClient()
                    
                case BTDaemonManagement.Status.requiresApproval:
                    debugPrint("Daemon requires approval")
                    
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Allow background activity?"
                        alert.informativeText = AppDelegate.backgroundActivityRequiredStr + "\n\nDo you want to approve the Battery Toolkit Login Item in System Settings?"
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
                    }

                case BTDaemonManagement.Status.notRegistered:
                    debugPrint("Daemon not registered")
                    
                    DispatchQueue.main.async {
                        let alert = NSAlert()
                        alert.messageText = "Failed to enable background activity."
                        alert.informativeText = AppDelegate.backgroundActivityRequiredStr
                        alert.alertStyle = NSAlert.Style.critical
                        alert.addButton(withTitle: "Retry")
                        alert.addButton(withTitle: "Quit")
                        let response = alert.runModal()
                        switch response {
                            case NSApplication.ModalResponse.alertFirstButtonReturn:
                                AppDelegate.startDaemon()
                                
                            case NSApplication.ModalResponse.alertSecondButtonReturn:
                                NSApplication.shared.terminate(self)
                                
                            default:
                                assert(false)
                        }
                    }
            }
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.startDaemon()
        
        if !BTDaemonManagement.presentUnregisterDaemon() {
            //self.disableBackgroundMenuItem.isHidden = true
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

    @IBAction private func disablePowerAdapterHandler(sender: NSMenuItem) {
        BatteryToolkit.disablePowerAdapter()
    }
    
    @IBAction private func enablePowerAdapterHandler(sender: NSMenuItem) {
        BatteryToolkit.enablePowerAdapter()
    }

    @IBAction private func chargeToMaximumHandler(sender: NSMenuItem) {
        BatteryToolkit.chargeToMaximum()
    }

    @IBAction private func chargeToFullHandler(sender: NSMenuItem) {
        BatteryToolkit.chargeToFull()
    }
    
    private static func unregisterDaemon() {
        BatteryToolkit.unregisterDaemon() { (success) -> Void in
            if success {
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(self)
                }

                return
            }

            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "An error occured disabling background activity."
                alert.alertStyle = NSAlert.Style.critical
                alert.addButton(withTitle: "OK")
                alert.addButton(withTitle: "Retry")
                let response = alert.runModal()
                if response == NSApplication.ModalResponse.alertSecondButtonReturn {
                    AppDelegate.unregisterDaemon()
                }
            }
        }
    }
    
    private static func promptUnregisterDaemon() {
        let alert = NSAlert()
        alert.messageText = "Disable background activity?"
        alert.informativeText = AppDelegate.backgroundActivityRequiredStr + "\n\nDo you want to disable the Battery Toolkit background activity?"
        alert.alertStyle = NSAlert.Style.warning
        alert.addButton(withTitle: "Disable and Quit")
        alert.addButton(withTitle: "Cancel")
        let response = alert.runModal()
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            AppDelegate.unregisterDaemon()
        }
    }
    
    @IBAction private func unregisterDaemonHandler(sender: NSMenuItem) {
        AppDelegate.promptUnregisterDaemon()
    }
}
