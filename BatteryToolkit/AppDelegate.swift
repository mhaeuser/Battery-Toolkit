/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Cocoa
import os.log

@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarExtraItem: NSStatusItem!
    @IBOutlet weak var menuBarExtraMenu: NSMenu!
    
    @IBOutlet weak var disableBackgroundMenuItem: NSMenuItem!

    @IBAction private func unregisterDaemonHandler(sender: NSMenuItem) {
        AppDelegate.promptUnregisterDaemon()
    }

    private static func startDaemon() {
        BatteryToolkit.startDaemon() { (status) -> Void in
            switch status {
                case BTDaemonManagement.Status.enabled:
                    os_log("Daemon is enabled")
                    
                case BTDaemonManagement.Status.requiresApproval:
                    os_log("Daemon requires approval")
                    
                    DispatchQueue.main.async {
                        AppDelegate.promptRegisterDaemon()
                    }

                case BTDaemonManagement.Status.notRegistered:
                    os_log("Daemon not registered")
                    
                    DispatchQueue.main.async {
                        AppDelegate.promptRegisterDaemonError()
                    }
            }
        }
    }

    //
    // NSApplicationDelegate is implicitly @MainActor and thus the warnings are
    // misleading.
    //

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        AppDelegate.startDaemon()

        self.menuBarExtraItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.squareLength
            )
        self.menuBarExtraItem.button?.image = NSImage(named: NSImage.Name("StatusItemIcon"))
        self.menuBarExtraItem.menu = self.menuBarExtraMenu
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        BatteryToolkit.stop()
    }
    
    private static func unregisterDaemon() {
        BatteryToolkit.unregisterDaemon() { (success) -> Void in
            DispatchQueue.main.async {
                if !success {
                    AppDelegate.promptUnregisterDaemonError()
                    return
                }

                NSApplication.shared.terminate(self)
            }
        }
    }

    private static func promptRegisterDaemon() {
        let alert             = NSAlert()
        alert.messageText     = BTLocalization.Prompts.Daemon.allowMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
            "\n\n" + BTLocalization.Prompts.Daemon.allowInfo
        alert.alertStyle      = NSAlert.Style.warning
        _ = alert.addButton(withTitle: BTLocalization.Prompts.approve)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
        let response = alert.runModal()
        switch response {
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                BatteryToolkit.approveDaemon()

            case NSApplication.ModalResponse.alertSecondButtonReturn:
                NSApplication.shared.terminate(self)

            default:
                assert(false)
        }
    }

    private static func promptRegisterDaemonError() {
        let alert             = NSAlert()
        alert.messageText     = BTLocalization.Prompts.Daemon.enableFailMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo
        alert.alertStyle      = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.quit)
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

    private static func promptUnregisterDaemon() {
        let alert             = NSAlert()
        alert.messageText     = BTLocalization.Prompts.Daemon.disableMessage
        alert.informativeText = BTLocalization.Prompts.Daemon.requiredInfo +
            "\n\n" + BTLocalization.Prompts.Daemon.disableInfo
        alert.alertStyle      = NSAlert.Style.warning
        _ = alert.addButton(withTitle: BTLocalization.Prompts.disableAndQuit)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = alert.runModal()
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            AppDelegate.unregisterDaemon()
        }
    }

    private static func promptUnregisterDaemonError() {
        let alert         = NSAlert()
        alert.messageText = BTLocalization.Prompts.Daemon.disableFailMessage
        alert.alertStyle  = NSAlert.Style.critical
        _ = alert.addButton(withTitle: BTLocalization.Prompts.retry)
        _ = alert.addButton(withTitle: BTLocalization.Prompts.cancel)
        let response = alert.runModal()
        if response == NSApplication.ModalResponse.alertFirstButtonReturn {
            AppDelegate.unregisterDaemon()
        }
    }
}
