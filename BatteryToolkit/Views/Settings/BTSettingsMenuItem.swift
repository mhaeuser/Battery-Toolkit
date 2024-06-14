//
// Copyright (C) 2022 - 2024 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import AppKit

internal final class BTSettingsMenuItem: NSMenuItem {
    override var title: String {
        get {
            //
            // Use "Preferences" over "Settings" for macOS versions prior to
            // Ventura for consistency.
            //
            guard #available(macOS 13.0, *) else {
                return BTLocalization.preferences + "…"
            }

            return super.title
        }

        set {
            super.title = newValue
        }
    }
}
