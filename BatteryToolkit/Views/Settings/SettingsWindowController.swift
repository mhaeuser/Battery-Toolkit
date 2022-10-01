/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import AppKit

final class SettingsWindowController: NSWindowController {
    private static var currentTab = NSToolbarItem.Identifier("general")

    @IBOutlet var toolbar: NSToolbar!

    override func windowDidLoad() {
        super.windowDidLoad()

        self.toolbar.selectedItemIdentifier = SettingsWindowController.currentTab
        for item in self.toolbar.items {
            if item.itemIdentifier == self.toolbar.selectedItemIdentifier {
                guard let action = item.action else {
                    assert(false)
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

        SettingsWindowController.currentTab = currentTab

        super.close()
    }

    @IBAction func generalAction(_ sender: NSToolbarItem) {
        guard let settingsViewControler = self.contentViewController as? SettingsViewController else {
            return
        }

        settingsViewControler.selectGeneralTab()
        self.window?.title = sender.label
    }


    @IBAction func backgroundActivityAction(_ sender: NSToolbarItem) {
        guard let settingsViewControler = self.contentViewController as? SettingsViewController else {
            return
        }

        settingsViewControler.selectBackgroundActivityTab()
        self.window?.title = sender.label
    }
}
