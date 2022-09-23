/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Cocoa
import os.log

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor private var menuBarExtraItem: NSStatusItem?
    @MainActor @IBOutlet weak var menuBarExtraMenu: NSMenu!

    @MainActor @IBOutlet weak var settingsItem: NSMenuItem!
    @MainActor @IBOutlet weak var disableBackgroundItem: NSMenuItem!

    @MainActor @IBAction private func unregisterDaemonHandler(sender: NSMenuItem) {
        BTAppPrompts.promptUnregisterDaemon()
    }

    private func daemonStatusHandler(status: BTDaemonManagement.Status) {
        DispatchQueue.main.async {
            switch status {
                case .notRegistered:
                    os_log("Daemon not registered")

                    if BTAppPrompts.promptRegisterDaemonError() {
                        BatteryToolkit.startDaemon(reply: self.daemonStatusHandler)
                    }

                case .enabled:
                    os_log("Daemon is enabled")

                    self.disableBackgroundItem.isEnabled = true
                    self.settingsItem.isEnabled          = true

                    let extraItem = NSStatusBar.system.statusItem(
                        withLength: NSStatusItem.squareLength
                        )
                    extraItem.button?.image = NSImage(named: NSImage.Name("StatusItemIcon"))
                    extraItem.menu = self.menuBarExtraMenu
                    self.menuBarExtraItem = extraItem

                    if !NSApp.isActive {
                        BTAccessoryMode.activate()
                    }

                case .requiresApproval:
                    os_log("Daemon requires approval")

                    BTAppPrompts.promptApproveDaemon(timeout: 20) { success in
                        guard success else {
                            self.daemonStatusHandler(status: .requiresApproval)
                            return
                        }

                        self.daemonStatusHandler(status: .enabled)
                    }

                case .requiresUpgrade:
                    os_log("Daemon requires upgrade")

                    let storyboard = NSStoryboard(name: "Upgrading", bundle: nil)
                    let upgradingController = storyboard.instantiateInitialController() as! NSWindowController
                    upgradingController.showWindow(nil)

                    BTDaemonManagement.upgrade() { status in
                        DispatchQueue.main.async {
                            upgradingController.close()
                            self.daemonStatusHandler(status: status)
                        }
                    }
            }
        }
    }

    //
    // NSApplicationDelegate is implicitly @MainActor and thus the warnings are
    // misleading.
    //

    @MainActor func applicationDidFinishLaunching(_ aNotification: Notification) {
        BatteryToolkit.startDaemon(reply: daemonStatusHandler)
    }
    
    @MainActor func applicationWillTerminate(_ aNotification: Notification) {
        BatteryToolkit.stop()
    }

    @MainActor func applicationWillBecomeActive(_ notification: Notification) {
        guard self.menuBarExtraItem != nil else {
            return
        }

        BTAccessoryMode.deactivate()
    }

    @MainActor func applicationWillResignActive(_ notification: Notification) {
        guard self.menuBarExtraItem != nil else {
            return
        }

        BTAccessoryMode.activate()
    }
}
