/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Cocoa
import os.log

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    @MainActor private var menuBarExtraItem: NSStatusItem?
    @MainActor @IBOutlet var menuBarExtraMenu: NSMenu!

    @MainActor @IBOutlet var settingsItem: NSMenuItem!
    @MainActor @IBOutlet var disableBackgroundItem: NSMenuItem!
    @MainActor @IBOutlet var commandsMenuItem: NSMenuItem!

    @MainActor @IBAction private func removeDaemonHandler(sender: NSMenuItem) {
        BTAppPrompts.promptremoveDaemon()
    }

    @Sendable private func daemonStatusHandler(status: BTDaemonManagement.Status) {
        DispatchQueue.main.async {
            switch status {
                case .notRegistered:
                    os_log("Daemon not registered")

                    if BTAppPrompts.promptRegisterDaemonError() {
                        BatteryToolkit.startDaemon(reply: self.daemonStatusHandler)
                    }

                case .enabled:
                    os_log("Daemon is enabled")

                    BTDaemonXPCClient.isSupported() { error in
                        DispatchQueue.main.async {
                            guard error != BTError.unsupported.rawValue else {
                                BTAppPrompts.promptMachineUnsupported()
                                return
                            }

                            self.disableBackgroundItem.isEnabled = true
                            self.settingsItem.isEnabled          = true
                            self.commandsMenuItem.isHidden       = false

                            let image = NSImage(named: NSImage.Name("ExtraItemIcon"))
                            image?.isTemplate = true

                            let extraItem = NSStatusBar.system.statusItem(
                                withLength: NSStatusItem.squareLength
                                )
                            extraItem.button?.image = image
                            extraItem.menu          = self.menuBarExtraMenu
                            self.menuBarExtraItem   = extraItem

                            if !NSApp.isActive {
                                BTAccessoryMode.activate()
                            }
                        }
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
                    upgradingController.window?.center()
                    upgradingController.showWindow(self)

                    BatteryToolkit.upgradeDaemon() { status in
                        DispatchQueue.main.async {
                            upgradingController.close()
                            self.daemonStatusHandler(status: status)
                        }
                    }
            }
        }
    }

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
