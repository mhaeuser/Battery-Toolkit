/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import IOPMPrivate

internal struct BTDaemonManagement {
    private static let legacyHelperFiles = [
        BTLegacyHelperInfo.legacyHelperExec,
        BTLegacyHelperInfo.legacyHelperPlist
    ]

    @MainActor internal static func removeLegacyHelperFiles() -> Void {
        //
        // CommandLine is logically immutable and thus concurrency-safe.
        //
        let args = CommandLine.arguments
        guard args.count > 0 else {
            os_log("No command line arguments provided")
            return
        }

        guard args[0] == BTDaemonManagement.legacyHelperFiles[0] else {
            os_log("Legacy helper launched from unexpected location: \(args[0])")
            return
        }

        for path in BTDaemonManagement.legacyHelperFiles {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                os_log("Error deleting file \(path): \(error.localizedDescription)")
            }
        }
    }

    @MainActor internal static func getState(reply: @Sendable @escaping ([String: AnyObject]) -> Void) -> Void {
        let charging  = SMCPowerKit.isChargingEnabled()
        let connected = IOPSDrawingUnlimitedPower()
        let power     = SMCPowerKit.isPowerAdapterEnabled()
        let progress  = BTPowerEvents.getChargingProgress()
        let mode      = BTPowerEvents.chargeMode

        let state = [
            BTStateInfo.Keys.power: NSNumber(value: power),
            BTStateInfo.Keys.connected: NSNumber(value: connected),
            BTStateInfo.Keys.charging: NSNumber(value: charging),
            BTStateInfo.Keys.progress: NSNumber(value: progress.rawValue),
            BTStateInfo.Keys.chargingMode: NSNumber(value: mode.rawValue)
        ]
        reply(state)
    }
}
