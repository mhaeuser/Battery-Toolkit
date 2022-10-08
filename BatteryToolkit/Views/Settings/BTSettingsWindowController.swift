//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit
import Foundation

@MainActor
internal final class BTSettingsWindowController: NSWindowController {
    private static var currentTab = NSToolbarItem.Identifier("general")

    @IBOutlet private var toolbar: NSToolbar!

    override func windowDidLoad() {
        super.windowDidLoad()

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
        guard let currentTab = toolbar.selectedItemIdentifier else {
            return
        }

        BTSettingsWindowController.currentTab = currentTab

        super.close()
    }

    @IBAction private func generalAction(_ sender: NSToolbarItem) {
        guard
            let settingsViewControler =
            self.contentViewController as? BTSettingsViewController
        else {
            return
        }

        settingsViewControler.selectGeneralTab()
        self.window?.title = sender.label
    }

    @IBAction private func backgroundActivityAction(_ sender: NSToolbarItem) {
        guard
            let settingsViewControler =
            self.contentViewController as? BTSettingsViewController
        else {
            return
        }

        settingsViewControler.selectBackgroundActivityTab()
        self.window?.title = sender.label
    }
}
