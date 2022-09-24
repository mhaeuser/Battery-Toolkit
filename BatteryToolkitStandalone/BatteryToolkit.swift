/*
  Copyright (C) 2022 Marvin Häuser. All rights reserved.
  SPDX-License-Identifier: BSD-3-Clause
*/

import Foundation

internal struct BTDaemonManagement {

}

@MainActor
internal struct BatteryToolkit {
    internal static func startDaemon(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        let result = BTPowerEvents.start()
        reply(result ? .enabled : .notRegistered)
    }

    internal static func approveDaemon(timeout: UInt8, reply: @escaping @Sendable (Bool) -> Void) {

    }

    internal static func upgradeDaemon(reply: @Sendable @escaping (BTDaemonManagement.Status) -> Void) {
        
    }

    internal static func stop() {
        BTPowerEvents.stop()
    }

    internal static func disablePowerAdapter(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        let success = BTPowerState.disablePowerAdapter()
        reply(BTError.init(fromBool: success).rawValue)
    }

    internal static func enablePowerAdapter(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        let success = BTPowerState.enablePowerAdapter()
        reply(BTError.init(fromBool: success).rawValue)
    }

    internal static func chargeToMaximum(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        let success = BTPowerEvents.chargeToMaximum()
        reply(BTError.init(fromBool: success).rawValue)
    }

    internal static func chargeToFull(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        let success = BTPowerEvents.chargeToFull()
        reply(BTError.init(fromBool: success).rawValue)
    }

    internal static func disableCharging(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        let success = BTPowerEvents.disableCharging()
        reply(BTError.init(fromBool: success).rawValue)
    }

    internal static func getState(reply: @Sendable @escaping (BTError.RawValue, [String: AnyObject]) -> Void) {
        reply(BTError.success.rawValue, BTDaemonState.getState())
    }

    internal static func getSettings(reply: @Sendable @escaping (BTError.RawValue, [String: AnyObject]) -> Void) {
        reply(BTError.success.rawValue, BTSettings.getSettings())
    }

    internal static func setSettings(settings: [String: AnyObject], reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        BTSettings.setSettings(settings: settings, reply: reply)
    }
    
    internal static func unregisterDaemon(reply: @Sendable @escaping (BTError.RawValue) -> Void) {
        reply(BTError.success.rawValue)
    }
}
