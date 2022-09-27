/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log

@MainActor
internal struct BTIdentification {
    private static var uniqueId: NSData? = nil

    internal static func cacheUniqueId() {
        BTIdentification.uniqueId = CSIdentification.getUniqueIdSelf()
    }

    internal static func getUniqueId() -> NSData? {
        return BTIdentification.uniqueId
    }
}
