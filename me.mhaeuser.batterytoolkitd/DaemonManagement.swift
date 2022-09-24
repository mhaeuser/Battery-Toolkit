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
        //
        // CommandLine is logically immutable and thus concurrency-safe.
        //
        let args = CommandLine.arguments
        guard args.count > 0 else {
            os_log("No command line arguments provided")
            return false
        }

        let launchUrl = URL(fileURLWithPath: args[0], isDirectory: false)
        guard launchUrl == BTLegacyHelperInfo.legacyHelperExec else {
            os_log("Legacy helper launched from unexpected location: \(args[0])")
            return false
        }

        let success1 = removeFile(path: BTLegacyHelperInfo.legacyHelperPlist)
        let success2 = removeFile(path: BTLegacyHelperInfo.legacyHelperExec)
        return success1 && success2
    }
}
