//
// Copyright (C) 2022 - 2025 Marvin Häuser. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//

import Foundation
import os.log

@MainActor
internal enum BTDaemonManagement {
    static func removeLegacyHelperFiles() -> Bool {
        let success1 =
            self.removeFile(path: BTLegacyHelperInfo.legacyHelperPlist)
        let success2 =
            self.removeFile(path: BTLegacyHelperInfo.legacyHelperExec)

        let success = success1 && success2

        os_log("Legacy helper removal: \(success)")

        return success
    }

    static func prepareDisable() -> Bool {
        let legacySuccess = self.removeLegacyHelperFiles()

        let rightStatus = SimpleAuth.removeRight(
            rightName: BTAuthorizationRights.manage
        )
        os_log("Manage right removal: \(rightStatus)")

        BTSettings.removeDefaults()

        return legacySuccess && rightStatus == errSecSuccess
    }

    private static func removeFile(path: URL) -> Bool {
        do {
            try FileManager.default.removeItem(at: path)
            return true
        } catch CocoaError.fileNoSuchFile {
            return true
        } catch {
            os_log("Error deleting file \(path): \(error, privacy: .public))")
            return false
        }
    }
}
