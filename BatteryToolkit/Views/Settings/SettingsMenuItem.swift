//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

internal final class SettingsMenuItem: NSMenuItem {
    override var title: String {
        get {
            guard #available(macOS 13.0, *) else {
                return BTLocalization.preferences + "..."
            }

            return super.title
        }

        set {
            super.title = newValue
        }
    }
}
