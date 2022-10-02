//
// Copyright (C) 2022 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import BTPreprocessor

public struct BTLegacyHelperInfo {
    public static let legacyHelperExec = URL(
        fileURLWithPath: "/Library/PrivilegedHelperTools/" + BTPreprocessor.BT_DAEMON_NAME,
        isDirectory: false
        )

    public static let legacyHelperPlist = URL(
        fileURLWithPath: "/Library/LaunchDaemons/" + BTPreprocessor.BT_DAEMON_NAME + ".plist",
        isDirectory: false
        )
}
