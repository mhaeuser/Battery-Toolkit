/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import AppKit

final class SettingsWindowController: NSWindowController {
    override func windowDidLoad() {
        if #unavailable(macOS 13.0) {
            self.window?.title = "Battery Toolkit " + BTLocalization.preferences
        }
    }
}
