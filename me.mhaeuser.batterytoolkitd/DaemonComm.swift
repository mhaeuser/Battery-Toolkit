/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation
import os.log

internal final class BTDaemonComm: NSObject, BTDaemonCommProtocol {
    @MainActor func getUniqueId(reply: @Sendable @escaping (NSData?) -> Void) -> Void {
        reply(CSIdentification.getUniqueIdSelf())
    }

    @MainActor internal func execute(command: UInt8, reply: @Sendable @escaping (Bool) -> Void) -> Void {
        var success = false
        switch command {
            case BTDaemonCommProtocolCommands.disablePowerAdapter.rawValue:
                success = BTPowerState.disablePowerAdapter()

            case BTDaemonCommProtocolCommands.enablePowerAdapter.rawValue:
                success = BTPowerState.enablePowerAdapter()

            case BTDaemonCommProtocolCommands.chargeToFull.rawValue:
                success = BTPowerEvents.chargeToFull()

            case BTDaemonCommProtocolCommands.chargeToMaximum.rawValue:
                success = BTPowerEvents.chargeToMaximum()

            case BTDaemonCommProtocolCommands.disableCharging.rawValue:
                success = BTPowerEvents.disableCharging()

            case BTDaemonCommProtocolCommands.removeLegacyHelperFiles.rawValue:
                success = BTDaemonManagement.removeLegacyHelperFiles()

            default:
                os_log("Unknown command: \(command)")
        }

        reply(success)
    }

    @MainActor internal func getState(reply: @Sendable @escaping ([String: AnyObject]) -> Void) -> Void {
        BTDaemonManagement.getState(reply: reply)
    }

    @MainActor internal func getSettings(reply: @Sendable @escaping ([String: AnyObject]) -> Void) {
        reply(BTSettings.getSettings())
    }

    @MainActor internal func setSettings(settings: [String: AnyObject]) -> Void {
        BTSettings.setSettings(settings: settings)
    }
}
