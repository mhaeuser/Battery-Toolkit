//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import BTPreprocessor
import Foundation

internal enum BTLegacyHelperInfo {
    static let legacyHelperExec = URL(
        fileURLWithPath: "/Library/PrivilegedHelperTools/" +
            BTPreprocessor.BT_DAEMON_ID,
        isDirectory: false
    )

    static let legacyHelperPlist = URL(
        fileURLWithPath: "/Library/LaunchDaemons/" +
            BTPreprocessor.BT_DAEMON_ID + ".plist",
        isDirectory: false
    )
}
