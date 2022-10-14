//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Cocoa
import os.log

@main
@MainActor
internal final class BTAppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarExtraItem: NSStatusItem?
    @IBOutlet private var menuBarExtraMenu: NSMenu!

    @IBOutlet private var settingsItem: NSMenuItem!
    @IBOutlet private var disableBackgroundItem: NSMenuItem!
    @IBOutlet private var commandsMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_: Notification) {
        BTActions.startDaemon(reply: self.daemonStatusHandler)
    }

    func applicationWillTerminate(_: Notification) {
        BTActions.stop()
    }

    func applicationWillBecomeActive(_: Notification) {
        //
        // Use the menuBarExtraItem value as an indicator for whether the app
        // has fully initialized.
        //
        guard self.menuBarExtraItem != nil else {
            return
        }

        BTAccessoryMode.deactivate()
    }

    func applicationWillResignActive(_: Notification) {
        guard self.menuBarExtraItem != nil else {
            return
        }

        BTAccessoryMode.activate()
    }

    @IBAction private func removeDaemonHandler(sender _: NSMenuItem) {
        BTAppPrompts.promptRemoveDaemon()
    }

    @Sendable private nonisolated func daemonStatusHandler(
        status: BTDaemonManagement.Status
    ) {
        DispatchQueue.main.async {
            switch status {
            case .notRegistered:
                os_log("Daemon not registered")

                if BTAppPrompts.promptRegisterDaemonError() {
                    BTActions.startDaemon(reply: self.daemonStatusHandler)
                }

            case .enabled:
                os_log("Daemon is enabled")

                BTDaemonXPCClient.isSupported { error in
                    DispatchQueue.main.async {
                        guard error != BTError.unsupported.rawValue else {
                            BTAppPrompts.promptMachineUnsupported()
                            return
                        }

                        self.disableBackgroundItem.isEnabled = true
                        self.settingsItem.isEnabled = true
                        self.commandsMenuItem.isHidden = false

                        let image = NSImage(
                            named: NSImage.Name("ExtraItemIcon")
                        )
                        image?.isTemplate = true

                        let extraItem = NSStatusBar.system.statusItem(
                            withLength: NSStatusItem.squareLength
                        )
                        extraItem.button?.image = image
                        extraItem.menu = self.menuBarExtraMenu
                        self.menuBarExtraItem = extraItem

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

                let storyboard = NSStoryboard(
                    name: "Upgrading",
                    bundle: nil
                )
                let upgradingController = storyboard
                    .instantiateInitialController() as! NSWindowController
                upgradingController.window?.center()
                upgradingController.showWindow(self)

                BTActions.upgradeDaemon { status in
                    DispatchQueue.main.async {
                        upgradingController.close()
                        self.daemonStatusHandler(status: status)
                    }
                }
            }
        }
    }
}
