//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit
import Foundation

@MainActor
internal final class BTSettingsWindowController: NSWindowController {
    private static var currentTab = NSToolbarItem.Identifier("power")

    @IBOutlet private var toolbar: NSToolbar!

    override func windowDidLoad() {
        super.windowDidLoad()
        //
        // Restore the previous tab for the Settings window.
        //
        self.toolbar.selectedItemIdentifier =
            BTSettingsWindowController.currentTab
        for item in self.toolbar.items {
            if item.itemIdentifier == self.toolbar.selectedItemIdentifier {
                guard let action = item.action else {
                    assertionFailure()
                    return
                }

                NSApp.sendAction(action, to: item.target, from: item)
                break
            }
        }
    }

    override func close() {
        //
        // Preserve the current tab of the Settings window.
        //
        guard let currentTab = toolbar.selectedItemIdentifier else {
            return
        }

        BTSettingsWindowController.currentTab = currentTab

        super.close()
    }

    @IBAction private func userAction(_ sender: NSToolbarItem) {
        guard
            let settingsViewControler =
            self.contentViewController as? BTSettingsViewController
        else {
            return
        }

        settingsViewControler.selectUserTab()
        self.window?.title = sender.label
    }

    @IBAction private func powerAction(_ sender: NSToolbarItem) {
        guard
            let settingsViewControler =
            self.contentViewController as? BTSettingsViewController
        else {
            return
        }

        settingsViewControler.selectPowerTab()
        self.window?.title = sender.label
    }
}
