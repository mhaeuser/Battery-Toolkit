/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log

internal struct BTDaemonManagement {
    private static func removeFile(path: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: path)
            return true
        } catch CocoaError.fileNoSuchFile {
            return true
        } catch {
            os_log("Error deleting file \(path): \(error.localizedDescription)")
            return false
        }
    }

    @MainActor internal static func removeLegacyHelperFiles() -> Bool {
        let success1 = removeFile(path: BTLegacyHelperInfo.legacyHelperPlist)
        let success2 = removeFile(path: BTLegacyHelperInfo.legacyHelperExec)
        return success1 && success2
    }
}
