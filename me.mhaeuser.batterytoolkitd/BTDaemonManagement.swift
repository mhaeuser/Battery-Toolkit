/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log

@MainActor
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

    internal static func removeLegacyHelperFiles() -> Bool {
        let success1 = removeFile(path: BTLegacyHelperInfo.legacyHelperPlist)
        let success2 = removeFile(path: BTLegacyHelperInfo.legacyHelperExec)

        let success = success1 && success2
        os_log("Legacy helper removal: \(success)")

        return success
    }

    internal static func prepareDisable() -> Bool {
        let legacySuccess = removeLegacyHelperFiles()

        let rightStatus = BTAuthorization.removeRight(
            rightName: BTAuthorizationRights.manage
            )
        os_log("Manage right removal: \(rightStatus)")

        BTSettings.removeDefaults()

        return legacySuccess && rightStatus == errSecSuccess
    }
}
