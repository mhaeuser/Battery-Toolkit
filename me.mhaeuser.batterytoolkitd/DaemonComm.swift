/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log
import IOPMPrivate

internal final class BTDaemonComm: NSObject, BTDaemonCommProtocol {
    private static let legacyHelperFiles = [
        BTLegacyHelperInfo.legacyHelperExec,
        BTLegacyHelperInfo.legacyHelperPlist
    ]

    @MainActor func getUniqueId(reply: @Sendable @escaping (NSData?) -> Void) -> Void {
        reply(CSIdentification.getUniqueIdSelf())
    }

    @MainActor internal func execute(command: UInt8) -> Void {
        switch command {
            case BTDaemonCommProtocolCommands.disablePowerAdapter.rawValue:
                BTPowerState.disablePowerAdapter()

            case BTDaemonCommProtocolCommands.enablePowerAdapter.rawValue:
                BTPowerState.enablePowerAdapter()

            case BTDaemonCommProtocolCommands.chargeToFull.rawValue:
                BTPowerEvents.chargeToFull()

            case BTDaemonCommProtocolCommands.chargeToMaximum.rawValue:
                BTPowerEvents.chargeToMaximum()

            case BTDaemonCommProtocolCommands.disableCharging.rawValue:
                BTPowerEvents.disableCharging()

            case BTDaemonCommProtocolCommands.removeLegacyHelperFiles.rawValue:
                BTDaemonComm.removeLegacyHelperFiles()

            default:
                os_log("Unknown command: \(command)")
        }
    }

    @MainActor internal func getState(reply: @Sendable @escaping ([String: AnyObject]) -> Void) -> Void {
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

    @MainActor internal func getSettings(reply: @Sendable @escaping ([String: AnyObject]) -> Void) {
        let settings = BTSettings.getSettings()
        reply(settings)
    }

    @MainActor internal func setSettings(settings: [String: AnyObject]) -> Void {
        BTSettings.setSettings(settings: settings)
    }
    
    @MainActor private static func removeLegacyHelperFiles() -> Void {
        //
        // CommandLine is logically immutable and thus concurrency-safe.
        //
        let args = CommandLine.arguments
        if args.count <= 0 {
            os_log("No command line arguments provided")
            return
        }
        
        if args[0] != BTDaemonComm.legacyHelperFiles[0] {
            os_log("Legacy helper launched from unexpected location: \(args[0])")
            return
        }

        for path in BTDaemonComm.legacyHelperFiles {
            do {
                try FileManager.default.removeItem(atPath: path)
            } catch {
                os_log("Error deleting file \(path): \(error)")
            }
        }
    }
}
