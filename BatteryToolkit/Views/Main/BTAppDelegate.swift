//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
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
        Task {
            let status = await BTActions.startDaemon()
            await self.daemonStatusHandler(status: status)
        }
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
        Task {
            await BTAppPrompts.promptRemoveDaemon()
        }
    }

    private func daemonStatusHandler(status: BTDaemonManagement.Status) async {
        switch status {
        case .notRegistered:
            os_log("Daemon not registered")

            if BTAppPrompts.promptRegisterDaemonError() {
                let status = await BTActions.startDaemon()
                await self.daemonStatusHandler(status: status)
            }

        case .enabled:
            os_log("Daemon is enabled")

            do {
                try await BTDaemonXPCClient.isSupported()
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
            } catch BTError.unsupported {
                await BTAppPrompts.promptMachineUnsupported()
            } catch {
                BTErrorHandler.errorHandler(error: error)
            }

        case .requiresApproval:
            os_log("Daemon requires approval")

            do {
                try await BTAppPrompts.promptApproveDaemon(timeout: 20)
                await self.daemonStatusHandler(status: .enabled)
            } catch {
                await self.daemonStatusHandler(status: .requiresApproval)
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

            let status = await BTActions.upgradeDaemon()
            upgradingController.close()
            await self.daemonStatusHandler(status: status)
        }
    }
}
