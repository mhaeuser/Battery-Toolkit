/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import BTPreprocessor

public struct BTLegacyHelperInfo {
    public static let legacyHelperExec  = "/Library/PrivilegedHelperTools/" +
        BTPreprocessor.BT_DAEMON_NAME

    public static let legacyHelperPlist = "/Library/LaunchDaemons/" +
        BTPreprocessor.BT_DAEMON_NAME + ".plist"
}
